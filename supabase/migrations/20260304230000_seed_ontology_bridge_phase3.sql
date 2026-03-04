ALTER TABLE public.specialties
ADD COLUMN IF NOT EXISTS canonical_entity_id text,
ADD COLUMN IF NOT EXISTS canonical_entity_type text;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'specialties_canonical_entity_type_check'
          AND conrelid = 'public.specialties'::regclass
    ) THEN
        ALTER TABLE public.specialties
        ADD CONSTRAINT specialties_canonical_entity_type_check
        CHECK (canonical_entity_type IN ('specialty', 'service', 'facility'));
    END IF;
END $$;

WITH specialty_seed AS (
    SELECT
        s.id AS specialty_id,
        COALESCE(
            NULLIF(btrim(s.canonical_entity_id), ''),
            NULLIF(btrim(s.canonical_id), ''),
            'SPEC_' || btrim(
                regexp_replace(
                    upper(unaccent(COALESCE(NULLIF(btrim(s.name), ''), 'SPECIALTY_' || s.id::text))),
                    '[^A-Z0-9]+',
                    '_',
                    'g'
                ),
                '_'
            )
        ) AS entity_id,
        COALESCE(NULLIF(btrim(s.name), ''), 'Specialty ' || s.id::text) AS default_name,
        COALESCE(NULLIF(btrim(s.icon_name), ''), 'cross.case') AS icon_key,
        COALESCE(s.display_order, 0) AS sort_priority
    FROM public.specialties s
)
INSERT INTO public.taxonomy_entities (id, entity_type, default_name, icon_key, sort_priority)
SELECT
    seed.entity_id,
    'specialty',
    seed.default_name,
    seed.icon_key,
    seed.sort_priority
FROM specialty_seed seed
ON CONFLICT (id) DO UPDATE
SET
    entity_type = EXCLUDED.entity_type,
    default_name = EXCLUDED.default_name,
    icon_key = EXCLUDED.icon_key,
    sort_priority = EXCLUDED.sort_priority,
    updated_at = now();

WITH specialty_seed AS (
    SELECT
        s.id AS specialty_id,
        COALESCE(
            NULLIF(btrim(s.canonical_entity_id), ''),
            NULLIF(btrim(s.canonical_id), ''),
            'SPEC_' || btrim(
                regexp_replace(
                    upper(unaccent(COALESCE(NULLIF(btrim(s.name), ''), 'SPECIALTY_' || s.id::text))),
                    '[^A-Z0-9]+',
                    '_',
                    'g'
                ),
                '_'
            )
        ) AS entity_id
    FROM public.specialties s
)
UPDATE public.specialties s
SET
    canonical_entity_id = seed.entity_id,
    canonical_entity_type = 'specialty',
    canonical_id = seed.entity_id
FROM specialty_seed seed
WHERE s.id = seed.specialty_id
  AND (
      s.canonical_entity_id IS DISTINCT FROM seed.entity_id
      OR s.canonical_entity_type IS DISTINCT FROM 'specialty'
      OR s.canonical_id IS DISTINCT FROM seed.entity_id
  );

INSERT INTO public.taxonomy_labels (entity_id, locale, label, short_label)
SELECT
    e.id,
    'en',
    e.default_name,
    e.default_name
FROM public.taxonomy_entities e
WHERE NOT EXISTS (
    SELECT 1
    FROM public.taxonomy_labels l
    WHERE l.entity_id = e.id
      AND l.locale = 'en'
)
ON CONFLICT (entity_id, locale) DO UPDATE
SET
    label = EXCLUDED.label,
    short_label = COALESCE(public.taxonomy_labels.short_label, EXCLUDED.short_label),
    updated_at = now();

ALTER TABLE public.taxonomy_aliases
ADD COLUMN IF NOT EXISTS tag text;

WITH core_aliases(entity_id, locale, alias_raw, weight, tag) AS (
    VALUES
        ('SPEC_ENT_OTOLARYNGOLOGY', 'en', 'ENT', 1.30::real, 'abbr'),
        ('SPEC_ENT_OTOLARYNGOLOGY', 'tr', 'KBB', 1.30::real, 'abbr'),
        ('SPEC_ENT_OTOLARYNGOLOGY', 'de', 'HNO', 1.30::real, 'abbr'),
        ('SPEC_ENT_OTOLARYNGOLOGY', 'fr', 'ORL', 1.30::real, 'abbr'),
        ('SPEC_ENT_OTOLARYNGOLOGY', 'es', 'ORL', 1.30::real, 'abbr'),
        ('SPEC_ENT_OTOLARYNGOLOGY', 'it', 'ORL', 1.30::real, 'abbr'),
        ('SPEC_ENT_OTOLARYNGOLOGY', 'pt', 'ORL', 1.30::real, 'abbr'),
        ('SPEC_ENT_OTOLARYNGOLOGY', 'ro', 'ORL', 1.30::real, 'abbr'),
        ('SPEC_ENT_OTOLARYNGOLOGY', 'pl', 'ORL', 1.30::real, 'abbr'),
        ('SPEC_ENT_OTOLARYNGOLOGY', 'nl', 'ORL', 1.30::real, 'abbr'),
        ('SPEC_ENT_OTOLARYNGOLOGY', 'sv', 'ORL', 1.30::real, 'abbr'),
        ('SPEC_ENT_OTOLARYNGOLOGY', 'cs', 'ORL', 1.30::real, 'abbr'),
        ('SPEC_ENT_OTOLARYNGOLOGY', 'hu', 'ORL', 1.30::real, 'abbr'),
        ('SPEC_ENT_OTOLARYNGOLOGY', 'uk', 'ORL', 1.30::real, 'abbr'),
        ('SPEC_ENT_OTOLARYNGOLOGY', 'ru', 'ORL', 1.30::real, 'abbr'),

        ('SPEC_GENERAL_PRACTICE', 'en', 'GP', 1.25::real, 'abbr'),
        ('SPEC_GENERAL_PRACTICE', 'de', 'Hausarzt', 1.25::real, 'synonym'),
        ('SPEC_GENERAL_PRACTICE', 'tr', 'Aile hekimi', 1.25::real, 'synonym')
)
INSERT INTO public.taxonomy_aliases (locale, entity_id, alias_raw, weight, tag)
SELECT
    c.locale,
    c.entity_id,
    c.alias_raw,
    c.weight,
    c.tag
FROM core_aliases c
JOIN public.taxonomy_entities e
  ON e.id = c.entity_id
ON CONFLICT (locale, alias_normalized, entity_id) DO UPDATE
SET
    weight = GREATEST(public.taxonomy_aliases.weight, EXCLUDED.weight),
    tag = COALESCE(public.taxonomy_aliases.tag, EXCLUDED.tag),
    updated_at = now();

DO $$
BEGIN
    IF to_regclass('public.provider_specialties') IS NOT NULL THEN
        INSERT INTO public.provider_taxonomy (provider_id, entity_id)
        SELECT DISTINCT
            ps.provider_id,
            s.canonical_entity_id
        FROM public.provider_specialties ps
        JOIN public.specialties s
          ON s.id = ps.specialty_id
        WHERE s.canonical_entity_id IS NOT NULL
        ON CONFLICT (provider_id, entity_id) DO NOTHING;
    ELSIF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'providers'
          AND column_name = 'specialty_id'
    ) THEN
        INSERT INTO public.provider_taxonomy (provider_id, entity_id)
        SELECT DISTINCT
            p.id,
            s.canonical_entity_id
        FROM public.providers p
        JOIN public.specialties s
          ON s.id = p.specialty_id
        WHERE p.specialty_id IS NOT NULL
          AND s.canonical_entity_id IS NOT NULL
        ON CONFLICT (provider_id, entity_id) DO NOTHING;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'specialties_canonical_entity_id_fk'
          AND conrelid = 'public.specialties'::regclass
    ) THEN
        ALTER TABLE public.specialties
        ADD CONSTRAINT specialties_canonical_entity_id_fk
        FOREIGN KEY (canonical_entity_id)
        REFERENCES public.taxonomy_entities(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL;
    END IF;
END $$;
