DO $$
BEGIN
    IF to_regclass('public.specialties') IS NULL THEN
        RAISE EXCEPTION 'public.specialties table is missing';
    END IF;

    IF to_regclass('public.taxonomy_entities') IS NULL THEN
        RAISE EXCEPTION 'public.taxonomy_entities table is missing';
    END IF;

    IF to_regclass('public.taxonomy_labels') IS NULL THEN
        RAISE EXCEPTION 'public.taxonomy_labels table is missing';
    END IF;
END $$;

DO $$
DECLARE
    has_canonical_entity_id boolean;
    locale_code text;
    legacy_col text;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'specialties'
          AND column_name = 'canonical_entity_id'
    ) INTO has_canonical_entity_id;

    IF NOT has_canonical_entity_id THEN
        RAISE NOTICE 'Skipping taxonomy label backfill: specialties.canonical_entity_id not found';
        RETURN;
    END IF;

    -- Keep EN aligned with legacy specialty names as baseline fallback.
    INSERT INTO public.taxonomy_labels (entity_id, locale, label)
    SELECT
        s.canonical_entity_id,
        'en',
        MIN(NULLIF(btrim(s.name), '')) AS label
    FROM public.specialties s
    JOIN public.taxonomy_entities e
      ON e.id = s.canonical_entity_id
    WHERE s.canonical_entity_id IS NOT NULL
      AND NULLIF(btrim(s.name), '') IS NOT NULL
    GROUP BY s.canonical_entity_id
    ON CONFLICT (entity_id, locale) DO UPDATE
    SET
        label = EXCLUDED.label,
        updated_at = now();

    FOR locale_code, legacy_col IN
        SELECT *
        FROM (VALUES
            ('tr'::text, 'name_tr'::text),
            ('de'::text, 'name_de'::text),
            ('pl'::text, 'name_pl'::text),
            ('nl'::text, 'name_nl'::text),
            ('da'::text, 'name_da'::text)
        ) AS mapping(locale_code, column_name)
    LOOP
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'specialties'
                            AND column_name = legacy_col
        ) THEN
            EXECUTE format(
                $sql$
                INSERT INTO public.taxonomy_labels (entity_id, locale, label)
                SELECT
                    s.canonical_entity_id,
                    %L,
                    MIN(NULLIF(btrim(%I), '')) AS label
                FROM public.specialties s
                JOIN public.taxonomy_entities e
                  ON e.id = s.canonical_entity_id
                WHERE s.canonical_entity_id IS NOT NULL
                  AND NULLIF(btrim(%I), '') IS NOT NULL
                GROUP BY s.canonical_entity_id
                ON CONFLICT (entity_id, locale) DO UPDATE
                SET
                    label = EXCLUDED.label,
                    updated_at = now();
                $sql$,
                locale_code,
                legacy_col,
                legacy_col
            );
        ELSE
            RAISE NOTICE 'Skipping locale %: specialties.% does not exist', locale_code, legacy_col;
        END IF;
    END LOOP;

    -- Enforce canonical Turkish display names where needed.
    UPDATE public.taxonomy_labels
    SET
        label = 'Aile Hekimliği',
        updated_at = now()
    WHERE locale = 'tr'
      AND entity_id = 'SPEC_GENERAL_PRACTICE'
      AND label IS DISTINCT FROM 'Aile Hekimliği';

    UPDATE public.taxonomy_labels
    SET
        label = 'Kulak Burun Boğaz',
        updated_at = now()
    WHERE locale = 'tr'
      AND entity_id IN ('SPEC_ENT', 'SPEC_ENT_OTOLARYNGOLOGY')
      AND label IS DISTINCT FROM 'Kulak Burun Boğaz';
END $$;