DROP FUNCTION IF EXISTS public.search_taxonomy(text, text);
DROP FUNCTION IF EXISTS public.search_taxonomy(text, text, text);
DROP FUNCTION IF EXISTS public.search_taxonomy(text, text, text, text);

CREATE OR REPLACE FUNCTION public.search_taxonomy(
    search_query text,
    current_locale text,
    entity_type_filter text DEFAULT NULL,
    fallback_locale text DEFAULT 'en'
)
RETURNS TABLE(entity_id text, entity_type text, label text, score real)
LANGUAGE sql
STABLE
AS $$
WITH normalized AS (
    SELECT
        public.normalize_search_text(search_query) AS q,
        COALESCE(NULLIF(current_locale, ''), 'en') AS locale,
        COALESCE(NULLIF(fallback_locale, ''), 'en') AS fallback_locale,
        NULLIF(entity_type_filter, '') AS type_filter
),
candidates AS (
    SELECT
        a.entity_id,
        e.entity_type,
        a.locale AS alias_locale,
        a.alias_normalized,
        a.weight,
        CASE
            WHEN a.alias_normalized = (SELECT q FROM normalized) THEN 3
            WHEN a.alias_normalized LIKE (SELECT q FROM normalized) || '%' THEN 2
            WHEN a.alias_normalized LIKE '%' || (SELECT q FROM normalized) || '%' THEN 1
            ELSE 0
        END AS match_rank
    FROM public.taxonomy_aliases a
    JOIN public.taxonomy_entities e
      ON e.id = a.entity_id
    WHERE (SELECT q FROM normalized) <> ''
      AND (
          (SELECT type_filter FROM normalized) IS NULL
          OR e.entity_type = (SELECT type_filter FROM normalized)
      )
),
current_hits AS (
    SELECT COUNT(*)::int AS cnt
    FROM candidates c
    WHERE c.match_rank > 0
      AND c.alias_locale = (SELECT locale FROM normalized)
),
filtered AS (
    SELECT c.*
    FROM candidates c
    CROSS JOIN current_hits h
    WHERE c.match_rank > 0
      AND (
          (h.cnt > 0 AND c.alias_locale = (SELECT locale FROM normalized))
          OR
          (h.cnt = 0 AND c.alias_locale = (SELECT fallback_locale FROM normalized))
      )
),
best_per_entity AS (
    SELECT
        f.*,
        (
            (f.weight * 10.0)
            + CASE f.match_rank
                WHEN 3 THEN 300.0
                WHEN 2 THEN 200.0
                ELSE 100.0
              END
        )::real AS computed_score,
        ROW_NUMBER() OVER (
            PARTITION BY f.entity_id
            ORDER BY f.match_rank DESC, f.weight DESC, char_length(f.alias_normalized) ASC
        ) AS rn
    FROM filtered f
)
SELECT
    b.entity_id,
    b.entity_type,
    COALESCE(l_local.label, l_fallback.label, l_en.label, e.default_name) AS label,
    b.computed_score AS score
FROM best_per_entity b
JOIN public.taxonomy_entities e
  ON e.id = b.entity_id
LEFT JOIN public.taxonomy_labels l_local
  ON l_local.entity_id = b.entity_id
 AND l_local.locale = (SELECT locale FROM normalized)
LEFT JOIN public.taxonomy_labels l_fallback
  ON l_fallback.entity_id = b.entity_id
 AND l_fallback.locale = (SELECT fallback_locale FROM normalized)
LEFT JOIN public.taxonomy_labels l_en
  ON l_en.entity_id = b.entity_id
 AND l_en.locale = 'en'
WHERE b.rn = 1
ORDER BY b.computed_score DESC, char_length(b.alias_normalized) ASC, label ASC
LIMIT 50;
$$;
