CREATE OR REPLACE FUNCTION public.search_providers(
    search_query TEXT DEFAULT NULL,
    specialty_filter TEXT DEFAULT NULL,
    country_filter TEXT DEFAULT NULL,
    price_level_filter INTEGER DEFAULT NULL,
    min_rating DECIMAL DEFAULT 0,
    verified_only BOOLEAN DEFAULT FALSE,
    max_distance_km INTEGER DEFAULT 50,
    user_lat DOUBLE PRECISION DEFAULT NULL,
    user_lng DOUBLE PRECISION DEFAULT NULL,
    offset_val INTEGER DEFAULT 0,
    limit_val INTEGER DEFAULT 20,
    specialty_ids TEXT[] DEFAULT NULL
)
RETURNS SETOF public.providers AS $$
BEGIN
    RETURN QUERY
    SELECT p.*
    FROM public.providers p
    WHERE p.is_active = TRUE
        AND p.deleted_at IS NULL
        AND p.rating_overall >= min_rating
        AND (specialty_filter IS NULL OR p.specialty = specialty_filter)
        AND (country_filter IS NULL OR p.country_code = country_filter)
        AND (price_level_filter IS NULL OR p.price_level_avg >= price_level_filter)
        AND (verified_only IS FALSE OR p.verified_review_count > 0)
        AND (
            specialty_ids IS NULL
            OR cardinality(specialty_ids) = 0
            OR EXISTS (
                SELECT 1
                FROM public.specialties s
                WHERE s.canonical_id = ANY(specialty_ids)
                  AND (
                    p.specialty = s.name
                    OR p.specialty = COALESCE(s.name_tr, '')
                    OR p.specialty = COALESCE(s.name_de, '')
                    OR p.specialty = COALESCE(s.name_pl, '')
                    OR p.specialty = COALESCE(s.name_nl, '')
                    OR p.specialty = COALESCE(s.name_da, '')
                  )
            )
        )
        AND (search_query IS NULL OR
             p.search_vector @@ plainto_tsquery('simple', search_query) OR
             p.name ILIKE '%' || search_query || '%' OR
             p.clinic_name ILIKE '%' || search_query || '%')
        AND (
            user_lat IS NULL
            OR user_lng IS NULL
            OR (
                6371 * acos(least(1, greatest(-1,
                    cos(radians(user_lat)) * cos(radians(p.latitude))
                    * cos(radians(p.longitude) - radians(user_lng))
                    + sin(radians(user_lat)) * sin(radians(p.latitude))
                )))
            ) <= max_distance_km
        )
    ORDER BY
        CASE WHEN search_query IS NOT NULL AND p.search_vector @@ plainto_tsquery('simple', search_query)
             THEN ts_rank(p.search_vector, plainto_tsquery('simple', search_query))
             ELSE 0 END DESC,
        p.rating_overall DESC,
        p.verified_review_count DESC,
        CASE
            WHEN user_lat IS NULL OR user_lng IS NULL THEN NULL
            ELSE 6371 * acos(least(1, greatest(-1,
                cos(radians(user_lat)) * cos(radians(p.latitude))
                * cos(radians(p.longitude) - radians(user_lng))
                + sin(radians(user_lat)) * sin(radians(p.latitude))
            )))
        END ASC
    LIMIT limit_val
    OFFSET offset_val;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
