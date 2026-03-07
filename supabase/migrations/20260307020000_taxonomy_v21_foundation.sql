-- TrustCare Taxonomy v2.1 foundation
-- Canonical IDs remain immutable; display labels are localization resources keyed by canonical ID.

BEGIN;

CREATE TABLE IF NOT EXISTS public.taxonomy_v21_entities (
    canonical_id text PRIMARY KEY REFERENCES public.taxonomy_entities(id) ON DELETE CASCADE,
    entity_type text NOT NULL CHECK (entity_type IN ('specialty', 'treatment_procedure', 'facility_type', 'symptom_concern')),
    display_english_label text NOT NULL,
    parent_group text,
    modality_bucket text,
    launch_scope text NOT NULL DEFAULT 'v2_1_core',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.taxonomy_v21_aliases (
    canonical_id text NOT NULL REFERENCES public.taxonomy_v21_entities(canonical_id) ON DELETE CASCADE,
    locale text NOT NULL DEFAULT 'en',
    alias_raw text NOT NULL,
    alias_normalized text GENERATED ALWAYS AS (public.normalize_search_text(alias_raw)) STORED,
    source_tag text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (canonical_id, locale, alias_normalized)
);

CREATE INDEX IF NOT EXISTS idx_taxonomy_v21_aliases_locale
    ON public.taxonomy_v21_aliases(locale, alias_normalized);

INSERT INTO public.taxonomy_v21_entities (canonical_id, entity_type, display_english_label, launch_scope)
SELECT
    e.id,
    CASE e.entity_type
        WHEN 'service' THEN 'treatment_procedure'
        WHEN 'facility' THEN 'facility_type'
        ELSE 'specialty'
    END,
    COALESCE(l_en.label, e.default_name),
    'v2_1_core'
FROM public.taxonomy_entities e
LEFT JOIN public.taxonomy_labels l_en
    ON l_en.entity_id = e.id
   AND l_en.locale = 'en'
ON CONFLICT (canonical_id) DO UPDATE
SET
    entity_type = EXCLUDED.entity_type,
    display_english_label = EXCLUDED.display_english_label,
    updated_at = now();

INSERT INTO public.taxonomy_v21_aliases (canonical_id, locale, alias_raw, source_tag)
SELECT
    a.entity_id,
    a.locale,
    a.alias_raw,
    COALESCE(a.tag, 'legacy_alias')
FROM public.taxonomy_aliases a
JOIN public.taxonomy_v21_entities v
  ON v.canonical_id = a.entity_id
ON CONFLICT (canonical_id, locale, alias_normalized) DO UPDATE
SET
    source_tag = COALESCE(public.taxonomy_v21_aliases.source_tag, EXCLUDED.source_tag),
    updated_at = now();

CREATE TABLE IF NOT EXISTS public.taxonomy_symptom_concerns (
    canonical_id text PRIMARY KEY,
    display_english_label text NOT NULL,
    launch_scope text NOT NULL DEFAULT 'v2_1_core',
    urgency_flag text CHECK (urgency_flag IN ('low', 'medium', 'high')),
    care_setting_hint text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.taxonomy_symptom_links (
    symptom_id text NOT NULL REFERENCES public.taxonomy_symptom_concerns(canonical_id) ON DELETE CASCADE,
    linked_canonical_id text NOT NULL REFERENCES public.taxonomy_v21_entities(canonical_id) ON DELETE CASCADE,
    linked_entity_type text NOT NULL CHECK (linked_entity_type IN ('specialty', 'treatment_procedure', 'facility_type')),
    link_weight real NOT NULL DEFAULT 1.0,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (symptom_id, linked_canonical_id)
);

CREATE INDEX IF NOT EXISTS idx_taxonomy_symptom_links_weight
    ON public.taxonomy_symptom_links(symptom_id, link_weight DESC);

ALTER TABLE public.taxonomy_v21_entities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.taxonomy_v21_aliases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.taxonomy_symptom_concerns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.taxonomy_symptom_links ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'taxonomy_v21_entities'
          AND policyname = 'public_select_taxonomy_v21_entities'
    ) THEN
        CREATE POLICY public_select_taxonomy_v21_entities
        ON public.taxonomy_v21_entities
        FOR SELECT
        TO public
        USING (true);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'taxonomy_v21_aliases'
          AND policyname = 'public_select_taxonomy_v21_aliases'
    ) THEN
        CREATE POLICY public_select_taxonomy_v21_aliases
        ON public.taxonomy_v21_aliases
        FOR SELECT
        TO public
        USING (true);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'taxonomy_symptom_concerns'
          AND policyname = 'public_select_taxonomy_symptom_concerns'
    ) THEN
        CREATE POLICY public_select_taxonomy_symptom_concerns
        ON public.taxonomy_symptom_concerns
        FOR SELECT
        TO public
        USING (true);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'taxonomy_symptom_links'
          AND policyname = 'public_select_taxonomy_symptom_links'
    ) THEN
        CREATE POLICY public_select_taxonomy_symptom_links
        ON public.taxonomy_symptom_links
        FOR SELECT
        TO public
        USING (true);
    END IF;
END $$;

-- Review target separation foundation: keep provider reviews intact and add facility review path.
CREATE TABLE IF NOT EXISTS public.facilities (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    city text,
    country_code text,
    canonical_facility_type_id text REFERENCES public.taxonomy_entities(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.facilities ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'facilities'
          AND policyname = 'public_select_facilities'
    ) THEN
        CREATE POLICY public_select_facilities
        ON public.facilities
        FOR SELECT
        TO public
        USING (true);
    END IF;
END $$;

ALTER TABLE public.reviews
    ADD COLUMN IF NOT EXISTS review_target_type text NOT NULL DEFAULT 'provider' CHECK (review_target_type IN ('provider', 'facility')),
    ADD COLUMN IF NOT EXISTS facility_id uuid REFERENCES public.facilities(id) ON DELETE CASCADE;

ALTER TABLE public.reviews
    ALTER COLUMN provider_id DROP NOT NULL;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'reviews_user_id_provider_id_visit_date_key'
          AND conrelid = 'public.reviews'::regclass
    ) THEN
        ALTER TABLE public.reviews DROP CONSTRAINT reviews_user_id_provider_id_visit_date_key;
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_reviews_unique_provider_target
    ON public.reviews(user_id, provider_id, visit_date)
    WHERE review_target_type = 'provider' AND provider_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_reviews_unique_facility_target
    ON public.reviews(user_id, facility_id, visit_date)
    WHERE review_target_type = 'facility' AND facility_id IS NOT NULL;

ALTER TABLE public.reviews DROP CONSTRAINT IF EXISTS reviews_target_consistency_check;
ALTER TABLE public.reviews
    ADD CONSTRAINT reviews_target_consistency_check CHECK (
        (review_target_type = 'provider' AND provider_id IS NOT NULL AND facility_id IS NULL) OR
        (review_target_type = 'facility' AND facility_id IS NOT NULL AND provider_id IS NULL)
    );

COMMIT;
