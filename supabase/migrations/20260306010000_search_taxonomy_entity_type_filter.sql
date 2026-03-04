DROP FUNCTION IF EXISTS public.search_taxonomy(text, text);
DROP FUNCTION IF EXISTS public.search_taxonomy(text, text, text);

CREATE OR REPLACE FUNCTION public.search_taxonomy(
    search_query text,
    current_locale text,
    entity_type_filter text DEFAULT NULL
)
RETURNS TABLE(entity_id text, entity_type text, label text, score real)
LANGUAGE sql
STABLE
AS $$
    WITH normalized AS (
        SELECT
            public.normalize_search_text(search_query) AS q,
            COALESCE(NULLIF(current_locale, ''), 'en') AS locale,
            NULLIF(entity_type_filter, '') AS type_filter
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
      AND (
            (SELECT type_filter FROM normalized) IS NULL
            OR e.entity_type = (SELECT type_filter FROM normalized)
      )
    ORDER BY score DESC, label ASC
    LIMIT 50;
$$;
