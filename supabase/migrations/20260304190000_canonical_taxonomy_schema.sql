CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE TABLE IF NOT EXISTS public.taxonomy_specialties (
    id text PRIMARY KEY,
    default_name text NOT NULL,
    icon_key text,
    sort_priority integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.taxonomy_labels (
    target_type text NOT NULL,
    target_id text NOT NULL REFERENCES public.taxonomy_specialties(id) ON DELETE CASCADE,
    locale text NOT NULL,
    label text NOT NULL,
    short_label text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(target_type, target_id, locale)
);

CREATE TABLE IF NOT EXISTS public.taxonomy_aliases (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    locale text NOT NULL,
    alias_raw text NOT NULL,
    alias_normalized text NOT NULL,
    target_type text NOT NULL,
    target_id text NOT NULL REFERENCES public.taxonomy_specialties(id) ON DELETE CASCADE,
    weight real NOT NULL DEFAULT 1.0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(locale, alias_normalized, target_type, target_id)
);

CREATE INDEX IF NOT EXISTS idx_taxonomy_aliases_locale_normalized
    ON public.taxonomy_aliases(locale, alias_normalized);

ALTER TABLE public.taxonomy_specialties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.taxonomy_labels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.taxonomy_aliases ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'taxonomy_specialties'
          AND policyname = 'public_select_taxonomy_specialties'
    ) THEN
        CREATE POLICY public_select_taxonomy_specialties
        ON public.taxonomy_specialties
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
          AND tablename = 'taxonomy_labels'
          AND policyname = 'public_select_taxonomy_labels'
    ) THEN
        CREATE POLICY public_select_taxonomy_labels
        ON public.taxonomy_labels
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
          AND tablename = 'taxonomy_aliases'
          AND policyname = 'public_select_taxonomy_aliases'
    ) THEN
        CREATE POLICY public_select_taxonomy_aliases
        ON public.taxonomy_aliases
        FOR SELECT
        TO public
        USING (true);
    END IF;
END $$;

CREATE OR REPLACE FUNCTION public.normalize_search_text(input_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT trim(
        regexp_replace(
            regexp_replace(
                lower(unaccent(coalesce(input_text, ''))),
                '[^[:alnum:]\s]+',
                ' ',
                'g'
            ),
            '\s+',
            ' ',
            'g'
        )
    );
$$;

CREATE OR REPLACE FUNCTION public.search_taxonomy(search_query text, current_locale text)
RETURNS TABLE(target_type text, target_id text, label text, weight real)
LANGUAGE sql
STABLE
AS $$
    WITH normalized AS (
        SELECT public.normalize_search_text(search_query) AS q,
               coalesce(nullif(current_locale, ''), 'en') AS locale
    )
    SELECT
        a.target_type,
        a.target_id,
        coalesce(l_local.label, l_en.label, s.default_name) AS label,
        a.weight
    FROM public.taxonomy_aliases a
    JOIN public.taxonomy_specialties s
      ON s.id = a.target_id
    LEFT JOIN public.taxonomy_labels l_local
      ON l_local.target_type = a.target_type
     AND l_local.target_id = a.target_id
     AND l_local.locale = (SELECT locale FROM normalized)
    LEFT JOIN public.taxonomy_labels l_en
      ON l_en.target_type = a.target_type
     AND l_en.target_id = a.target_id
     AND l_en.locale = 'en'
    WHERE (SELECT q FROM normalized) <> ''
      AND a.alias_normalized LIKE (SELECT q FROM normalized) || '%'
    ORDER BY a.weight DESC, a.alias_normalized ASC
    LIMIT 50;
$$;
