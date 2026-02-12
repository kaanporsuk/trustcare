CREATE OR REPLACE FUNCTION search_providers(
    search_query TEXT DEFAULT NULL,
    specialty_filter TEXT DEFAULT NULL,
    min_rating DECIMAL DEFAULT 0,
    max_distance_km INTEGER DEFAULT 50,
    user_lat DOUBLE PRECISION DEFAULT NULL,
    user_lng DOUBLE PRECISION DEFAULT NULL,
    offset_val INTEGER DEFAULT 0,
    limit_val INTEGER DEFAULT 20
)
RETURNS SETOF providers AS $$
BEGIN
    RETURN QUERY
    SELECT p.*
    FROM providers p
    WHERE p.is_active = TRUE
        AND p.deleted_at IS NULL
        AND p.rating_overall >= min_rating
        AND (specialty_filter IS NULL OR p.specialty = specialty_filter)
        AND (search_query IS NULL OR
             p.search_vector @@ plainto_tsquery('simple', search_query) OR
             p.name ILIKE '%' || search_query || '%' OR
             p.clinic_name ILIKE '%' || search_query || '%')
    ORDER BY
        CASE WHEN search_query IS NOT NULL AND p.search_vector @@ plainto_tsquery('simple', search_query)
             THEN ts_rank(p.search_vector, plainto_tsquery('simple', search_query))
             ELSE 0 END DESC,
        p.rating_overall DESC,
        p.verified_review_count DESC
    LIMIT limit_val
    OFFSET offset_val;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
