CREATE EXTENSION IF NOT EXISTS unaccent;

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

DROP FUNCTION IF EXISTS public.search_taxonomy(text, text);
DROP FUNCTION IF EXISTS public.search_providers_by_taxonomy(text[]);

CREATE TABLE IF NOT EXISTS public.taxonomy_entities (
    id text PRIMARY KEY,
    entity_type text NOT NULL CHECK (entity_type IN ('specialty', 'service', 'facility')),
    default_name text NOT NULL,
    icon_key text,
    sort_priority integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

DO $$
BEGIN
    IF to_regclass('public.taxonomy_specialties') IS NOT NULL THEN
        INSERT INTO public.taxonomy_entities (id, entity_type, default_name, icon_key, sort_priority, created_at, updated_at)
        SELECT
            s.id,
            'specialty'::text,
            s.default_name,
            s.icon_key,
            s.sort_priority,
            COALESCE(s.created_at, now()),
            COALESCE(s.updated_at, now())
        FROM public.taxonomy_specialties s
        ON CONFLICT (id) DO UPDATE
        SET default_name = EXCLUDED.default_name,
            icon_key = EXCLUDED.icon_key,
            sort_priority = EXCLUDED.sort_priority,
            updated_at = now();
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.taxonomy_labels (
    entity_id text NOT NULL REFERENCES public.taxonomy_entities(id) ON DELETE CASCADE,
    locale text NOT NULL,
    label text NOT NULL,
    short_label text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'taxonomy_labels'
          AND column_name = 'target_id'
    ) THEN
        ALTER TABLE public.taxonomy_labels
            ADD COLUMN IF NOT EXISTS entity_id text;

        UPDATE public.taxonomy_labels
        SET entity_id = target_id
        WHERE entity_id IS NULL
          AND target_id IS NOT NULL;
    END IF;
END $$;

DELETE FROM public.taxonomy_labels a
USING public.taxonomy_labels b
WHERE a.ctid < b.ctid
  AND a.entity_id = b.entity_id
  AND a.locale = b.locale;

ALTER TABLE public.taxonomy_labels
    ALTER COLUMN entity_id SET NOT NULL,
    ALTER COLUMN locale SET NOT NULL,
    ALTER COLUMN label SET NOT NULL;

ALTER TABLE public.taxonomy_labels
    DROP CONSTRAINT IF EXISTS taxonomy_labels_pkey;

ALTER TABLE public.taxonomy_labels
    DROP CONSTRAINT IF EXISTS taxonomy_labels_target_type_target_id_locale_key,
    DROP CONSTRAINT IF EXISTS taxonomy_labels_target_id_fkey;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'taxonomy_labels_entity_id_fkey'
          AND conrelid = 'public.taxonomy_labels'::regclass
    ) THEN
        ALTER TABLE public.taxonomy_labels
            ADD CONSTRAINT taxonomy_labels_entity_id_fkey
            FOREIGN KEY (entity_id)
            REFERENCES public.taxonomy_entities(id)
            ON DELETE CASCADE;
    END IF;
END $$;

ALTER TABLE public.taxonomy_labels
    ADD CONSTRAINT taxonomy_labels_pkey PRIMARY KEY (entity_id, locale);

ALTER TABLE public.taxonomy_labels
    DROP COLUMN IF EXISTS target_type,
    DROP COLUMN IF EXISTS target_id;

CREATE TABLE IF NOT EXISTS public.taxonomy_aliases (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    locale text NOT NULL,
    entity_id text NOT NULL REFERENCES public.taxonomy_entities(id) ON DELETE CASCADE,
    alias_raw text NOT NULL,
    alias_normalized text GENERATED ALWAYS AS (public.normalize_search_text(alias_raw)) STORED,
    weight real NOT NULL DEFAULT 1.0,
    tag text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (locale, alias_normalized, entity_id)
);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'taxonomy_aliases'
          AND column_name = 'target_id'
    ) THEN
        ALTER TABLE public.taxonomy_aliases
            ADD COLUMN IF NOT EXISTS entity_id text;

        UPDATE public.taxonomy_aliases
        SET entity_id = target_id
        WHERE entity_id IS NULL
          AND target_id IS NOT NULL;
    END IF;
END $$;

ALTER TABLE public.taxonomy_aliases
    DROP CONSTRAINT IF EXISTS taxonomy_aliases_locale_alias_normalized_target_type_target_id_key,
    DROP CONSTRAINT IF EXISTS taxonomy_aliases_locale_alias_normalized_target_id_key,
    DROP CONSTRAINT IF EXISTS taxonomy_aliases_target_id_fkey;

DROP INDEX IF EXISTS public.idx_taxonomy_aliases_locale_normalized;

ALTER TABLE public.taxonomy_aliases
    DROP COLUMN IF EXISTS alias_normalized;

ALTER TABLE public.taxonomy_aliases
    ADD COLUMN alias_normalized text GENERATED ALWAYS AS (public.normalize_search_text(alias_raw)) STORED;

ALTER TABLE public.taxonomy_aliases
    ALTER COLUMN entity_id SET NOT NULL,
    ALTER COLUMN locale SET NOT NULL,
    ALTER COLUMN alias_raw SET NOT NULL,
    ALTER COLUMN weight SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'taxonomy_aliases_entity_id_fkey'
          AND conrelid = 'public.taxonomy_aliases'::regclass
    ) THEN
        ALTER TABLE public.taxonomy_aliases
            ADD CONSTRAINT taxonomy_aliases_entity_id_fkey
            FOREIGN KEY (entity_id)
            REFERENCES public.taxonomy_entities(id)
            ON DELETE CASCADE;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'taxonomy_aliases_locale_alias_normalized_entity_id_key'
          AND conrelid = 'public.taxonomy_aliases'::regclass
    ) THEN
        ALTER TABLE public.taxonomy_aliases
            ADD CONSTRAINT taxonomy_aliases_locale_alias_normalized_entity_id_key
            UNIQUE (locale, alias_normalized, entity_id);
    END IF;
END $$;

ALTER TABLE public.taxonomy_aliases
    DROP COLUMN IF EXISTS target_type,
    DROP COLUMN IF EXISTS target_id;

CREATE INDEX IF NOT EXISTS idx_taxonomy_aliases_locale_normalized
    ON public.taxonomy_aliases(locale, alias_normalized);

CREATE TABLE IF NOT EXISTS public.provider_taxonomy (
    provider_id uuid NOT NULL REFERENCES public.providers(id) ON DELETE CASCADE,
    entity_id text NOT NULL REFERENCES public.taxonomy_entities(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (provider_id, entity_id)
);

CREATE INDEX IF NOT EXISTS idx_provider_taxonomy_entity_id
    ON public.provider_taxonomy(entity_id);

ALTER TABLE public.taxonomy_entities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.taxonomy_labels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.taxonomy_aliases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_taxonomy ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'taxonomy_entities'
          AND policyname = 'public_select_taxonomy_entities'
    ) THEN
        CREATE POLICY public_select_taxonomy_entities
        ON public.taxonomy_entities
        FOR SELECT
        TO public
        USING (true);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
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
        SELECT 1 FROM pg_policies
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

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'provider_taxonomy'
          AND policyname = 'public_select_provider_taxonomy'
    ) THEN
        CREATE POLICY public_select_provider_taxonomy
        ON public.provider_taxonomy
        FOR SELECT
        TO public
        USING (true);
    END IF;
END $$;

CREATE OR REPLACE FUNCTION public.search_taxonomy(search_query text, current_locale text)
RETURNS TABLE(entity_id text, entity_type text, label text, score real)
LANGUAGE sql
STABLE
AS $$
    WITH normalized AS (
        SELECT
            public.normalize_search_text(search_query) AS q,
            COALESCE(NULLIF(current_locale, ''), 'en') AS locale
    )
    SELECT
        a.entity_id,
        e.entity_type,
        COALESCE(l_local.label, l_en.label, e.default_name) AS label,
        a.weight AS score
    FROM public.taxonomy_aliases a
    JOIN public.taxonomy_entities e
      ON e.id = a.entity_id
    LEFT JOIN public.taxonomy_labels l_local
      ON l_local.entity_id = a.entity_id
     AND l_local.locale = (SELECT locale FROM normalized)
    LEFT JOIN public.taxonomy_labels l_en
      ON l_en.entity_id = a.entity_id
     AND l_en.locale = 'en'
    WHERE (SELECT q FROM normalized) <> ''
      AND a.alias_normalized LIKE (SELECT q FROM normalized) || '%'
    ORDER BY score DESC, label ASC
    LIMIT 50;
$$;

CREATE OR REPLACE FUNCTION public.search_providers_by_taxonomy(entity_ids text[])
RETURNS SETOF public.providers
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
    SELECT DISTINCT p.*
    FROM public.providers p
    JOIN public.provider_taxonomy pt
      ON pt.provider_id = p.id
    WHERE COALESCE(array_length(entity_ids, 1), 0) > 0
      AND pt.entity_id = ANY(entity_ids);
$$;
