CREATE EXTENSION IF NOT EXISTS unaccent;

ALTER TABLE public.specialties
ADD COLUMN IF NOT EXISTS canonical_id text;

CREATE TEMP TABLE _taxonomy_seed_map ON COMMIT DROP AS
WITH source_rows AS (
    SELECT
        s.id AS legacy_specialty_id,
        to_jsonb(s) AS data,
        COALESCE(
            NULLIF(btrim(to_jsonb(s) ->> 'name_en'), ''),
            NULLIF(btrim(to_jsonb(s) ->> 'name'), ''),
            NULLIF(btrim(to_jsonb(s) ->> 'name_key'), ''),
            'SPECIALTY_' || s.id::text
        ) AS default_name,
        COALESCE(NULLIF(btrim(to_jsonb(s) ->> 'icon_name'), ''), 'cross.case') AS icon_key,
        COALESCE((to_jsonb(s) ->> 'display_order')::integer, 0) AS sort_priority
    FROM public.specialties s
),
canonicalized AS (
    SELECT
        legacy_specialty_id,
        data,
        default_name,
        icon_key,
        sort_priority,
        'SPEC_' || btrim(
            regexp_replace(
                upper(unaccent(default_name)),
                '[^A-Z0-9]+',
                '_',
                'g'
            ),
            '_'
        ) AS canonical_base
    FROM source_rows
),
deduped AS (
    SELECT
        legacy_specialty_id,
        data,
        default_name,
        icon_key,
        sort_priority,
        canonical_base,
        row_number() OVER (PARTITION BY canonical_base ORDER BY legacy_specialty_id) AS rn
    FROM canonicalized
)
SELECT
    legacy_specialty_id,
    CASE
        WHEN rn = 1 THEN canonical_base
        ELSE canonical_base || '_' || legacy_specialty_id::text
    END AS canonical_id,
    default_name,
    icon_key,
    sort_priority,
    data
FROM deduped;

INSERT INTO public.taxonomy_specialties (id, default_name, icon_key, sort_priority)
SELECT
    m.canonical_id,
    m.default_name,
    m.icon_key,
    m.sort_priority
FROM _taxonomy_seed_map m
ON CONFLICT (id) DO UPDATE
SET
    default_name = EXCLUDED.default_name,
    icon_key = EXCLUDED.icon_key,
    sort_priority = EXCLUDED.sort_priority,
    updated_at = now();

WITH locale_list(locale) AS (
    VALUES
        ('en'), ('tr'), ('de'), ('pl'), ('nl'), ('da'),
        ('es'), ('fr'), ('it'), ('ro'), ('pt'), ('uk'),
        ('ru'), ('sv'), ('cs'), ('hu')
),
label_rows AS (
    SELECT
        'specialty'::text AS target_type,
        m.canonical_id AS target_id,
        l.locale,
        CASE l.locale
            WHEN 'tr' THEN COALESCE(NULLIF(btrim(m.data ->> 'name_tr'), ''), m.default_name)
            WHEN 'de' THEN COALESCE(NULLIF(btrim(m.data ->> 'name_de'), ''), m.default_name)
            WHEN 'pl' THEN COALESCE(NULLIF(btrim(m.data ->> 'name_pl'), ''), m.default_name)
            WHEN 'nl' THEN COALESCE(NULLIF(btrim(m.data ->> 'name_nl'), ''), m.default_name)
            WHEN 'da' THEN COALESCE(NULLIF(btrim(m.data ->> 'name_da'), ''), m.default_name)
            ELSE m.default_name
        END AS label
    FROM _taxonomy_seed_map m
    CROSS JOIN locale_list l
)
INSERT INTO public.taxonomy_labels (target_type, target_id, locale, label, short_label)
SELECT
    r.target_type,
    r.target_id,
    r.locale,
    r.label,
    r.label
FROM label_rows r
ON CONFLICT (target_type, target_id, locale) DO UPDATE
SET
    label = EXCLUDED.label,
    short_label = EXCLUDED.short_label,
    updated_at = now();

WITH label_aliases AS (
    SELECT
        l.locale,
        l.label AS alias_raw,
        public.normalize_search_text(l.label) AS alias_normalized,
        l.target_type,
        l.target_id,
        1.0::real AS weight
    FROM public.taxonomy_labels l
    WHERE l.target_type = 'specialty'
),
ent_target AS (
    SELECT m.canonical_id AS target_id
    FROM _taxonomy_seed_map m
    WHERE m.default_name IN ('ENT / Otolaryngology', 'ENT / Otorhinolaryngology')
    ORDER BY m.legacy_specialty_id
    LIMIT 1
),
ent_abbreviations AS (
    SELECT
        v.locale,
        v.alias_raw,
        public.normalize_search_text(v.alias_raw) AS alias_normalized,
        'specialty'::text AS target_type,
        t.target_id,
        1.25::real AS weight
    FROM ent_target t
    JOIN (
        VALUES
            ('en', 'ENT'),
            ('tr', 'KBB'),
            ('de', 'HNO'),
            ('fr', 'ORL'),
            ('es', 'ORL'),
            ('it', 'ORL'),
            ('pt', 'ORL'),
            ('ro', 'ORL'),
            ('pl', 'ORL'),
            ('nl', 'ORL'),
            ('da', 'ORL'),
            ('sv', 'ORL'),
            ('cs', 'ORL'),
            ('hu', 'ORL'),
            ('uk', 'ORL'),
            ('ru', 'ORL')
    ) AS v(locale, alias_raw) ON true
)
INSERT INTO public.taxonomy_aliases (locale, alias_raw, alias_normalized, target_type, target_id, weight)
SELECT
    x.locale,
    x.alias_raw,
    x.alias_normalized,
    x.target_type,
    x.target_id,
    x.weight
FROM (
    SELECT * FROM label_aliases
    UNION ALL
    SELECT * FROM ent_abbreviations
) x
WHERE x.alias_normalized <> ''
ON CONFLICT (locale, alias_normalized, target_type, target_id) DO UPDATE
SET
    alias_raw = EXCLUDED.alias_raw,
    weight = GREATEST(public.taxonomy_aliases.weight, EXCLUDED.weight),
    updated_at = now();

UPDATE public.specialties s
SET canonical_id = m.canonical_id
FROM _taxonomy_seed_map m
WHERE s.id = m.legacy_specialty_id
  AND s.canonical_id IS DISTINCT FROM m.canonical_id;

ALTER TABLE public.specialties
DROP CONSTRAINT IF EXISTS specialties_canonical_id_fk;

ALTER TABLE public.specialties
ADD CONSTRAINT specialties_canonical_id_fk
FOREIGN KEY (canonical_id)
REFERENCES public.taxonomy_specialties(id)
ON UPDATE CASCADE
ON DELETE SET NULL;
