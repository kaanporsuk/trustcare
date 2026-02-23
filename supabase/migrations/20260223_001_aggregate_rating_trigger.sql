CREATE OR REPLACE FUNCTION public.update_provider_aggregates()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    provider_ids UUID[] := ARRAY[]::UUID[];
    current_provider_id UUID;
    has_price_level_avg BOOLEAN;
    aggregate_row RECORD;
BEGIN
    IF TG_OP = 'INSERT' THEN
        provider_ids := ARRAY_APPEND(provider_ids, NEW.provider_id);
    ELSIF TG_OP = 'DELETE' THEN
        provider_ids := ARRAY_APPEND(provider_ids, OLD.provider_id);
    ELSIF TG_OP = 'UPDATE' THEN
        provider_ids := ARRAY_APPEND(provider_ids, NEW.provider_id);

        IF OLD.provider_id IS DISTINCT FROM NEW.provider_id THEN
            provider_ids := ARRAY_APPEND(provider_ids, OLD.provider_id);
        END IF;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'providers'
          AND column_name = 'price_level_avg'
    )
    INTO has_price_level_avg;

    FOREACH current_provider_id IN ARRAY provider_ids LOOP
        CONTINUE WHEN current_provider_id IS NULL;

        SELECT
            ROUND(AVG(r.rating_overall)::NUMERIC, 1) AS rating_overall,
            ROUND(AVG(r.rating_wait_time)::NUMERIC, 1) AS rating_wait_time,
            ROUND(AVG(r.rating_bedside)::NUMERIC, 1) AS rating_bedside,
            ROUND(AVG(r.rating_efficacy)::NUMERIC, 1) AS rating_efficacy,
            ROUND(AVG(r.rating_cleanliness)::NUMERIC, 1) AS rating_cleanliness,
            COUNT(*)::INTEGER AS review_count,
            COUNT(*) FILTER (WHERE r.is_verified = TRUE)::INTEGER AS verified_review_count,
            ROUND(AVG(r.price_level)::NUMERIC, 0) AS price_level_avg
        INTO aggregate_row
        FROM public.reviews r
        WHERE r.provider_id = current_provider_id
          AND r.status = 'active';

        IF has_price_level_avg THEN
            UPDATE public.providers p
            SET
                rating_overall = aggregate_row.rating_overall,
                rating_wait_time = aggregate_row.rating_wait_time,
                rating_bedside = aggregate_row.rating_bedside,
                rating_efficacy = aggregate_row.rating_efficacy,
                rating_cleanliness = aggregate_row.rating_cleanliness,
                review_count = COALESCE(aggregate_row.review_count, 0),
                verified_review_count = COALESCE(aggregate_row.verified_review_count, 0),
                price_level_avg = aggregate_row.price_level_avg
            WHERE p.id = current_provider_id;
        ELSE
            UPDATE public.providers p
            SET
                rating_overall = aggregate_row.rating_overall,
                rating_wait_time = aggregate_row.rating_wait_time,
                rating_bedside = aggregate_row.rating_bedside,
                rating_efficacy = aggregate_row.rating_efficacy,
                rating_cleanliness = aggregate_row.rating_cleanliness,
                review_count = COALESCE(aggregate_row.review_count, 0),
                verified_review_count = COALESCE(aggregate_row.verified_review_count, 0)
            WHERE p.id = current_provider_id;
        END IF;
    END LOOP;

    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_provider_aggregates ON public.reviews;
DROP TRIGGER IF EXISTS update_provider_aggregates ON public.reviews;

CREATE TRIGGER trigger_update_provider_aggregates
AFTER INSERT OR UPDATE OR DELETE ON public.reviews
FOR EACH ROW
EXECUTE FUNCTION public.update_provider_aggregates();

DO $$
DECLARE
    has_price_level_avg BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'providers'
          AND column_name = 'price_level_avg'
    )
    INTO has_price_level_avg;

    IF has_price_level_avg THEN
        WITH provider_aggregates AS (
            SELECT
                p.id AS provider_id,
                ROUND(AVG(r.rating_overall)::NUMERIC, 1) AS rating_overall,
                ROUND(AVG(r.rating_wait_time)::NUMERIC, 1) AS rating_wait_time,
                ROUND(AVG(r.rating_bedside)::NUMERIC, 1) AS rating_bedside,
                ROUND(AVG(r.rating_efficacy)::NUMERIC, 1) AS rating_efficacy,
                ROUND(AVG(r.rating_cleanliness)::NUMERIC, 1) AS rating_cleanliness,
                COUNT(r.id)::INTEGER AS review_count,
                COUNT(r.id) FILTER (WHERE r.is_verified = TRUE)::INTEGER AS verified_review_count,
                ROUND(AVG(r.price_level)::NUMERIC, 0) AS price_level_avg
            FROM public.providers p
            LEFT JOIN public.reviews r
              ON r.provider_id = p.id
             AND r.status = 'active'
            GROUP BY p.id
        )
        UPDATE public.providers p
        SET
            rating_overall = pa.rating_overall,
            rating_wait_time = pa.rating_wait_time,
            rating_bedside = pa.rating_bedside,
            rating_efficacy = pa.rating_efficacy,
            rating_cleanliness = pa.rating_cleanliness,
            review_count = COALESCE(pa.review_count, 0),
            verified_review_count = COALESCE(pa.verified_review_count, 0),
            price_level_avg = pa.price_level_avg
        FROM provider_aggregates pa
        WHERE p.id = pa.provider_id;
    ELSE
        WITH provider_aggregates AS (
            SELECT
                p.id AS provider_id,
                ROUND(AVG(r.rating_overall)::NUMERIC, 1) AS rating_overall,
                ROUND(AVG(r.rating_wait_time)::NUMERIC, 1) AS rating_wait_time,
                ROUND(AVG(r.rating_bedside)::NUMERIC, 1) AS rating_bedside,
                ROUND(AVG(r.rating_efficacy)::NUMERIC, 1) AS rating_efficacy,
                ROUND(AVG(r.rating_cleanliness)::NUMERIC, 1) AS rating_cleanliness,
                COUNT(r.id)::INTEGER AS review_count,
                COUNT(r.id) FILTER (WHERE r.is_verified = TRUE)::INTEGER AS verified_review_count
            FROM public.providers p
            LEFT JOIN public.reviews r
              ON r.provider_id = p.id
             AND r.status = 'active'
            GROUP BY p.id
        )
        UPDATE public.providers p
        SET
            rating_overall = pa.rating_overall,
            rating_wait_time = pa.rating_wait_time,
            rating_bedside = pa.rating_bedside,
            rating_efficacy = pa.rating_efficacy,
            rating_cleanliness = pa.rating_cleanliness,
            review_count = COALESCE(pa.review_count, 0),
            verified_review_count = COALESCE(pa.verified_review_count, 0)
        FROM provider_aggregates pa
        WHERE p.id = pa.provider_id;
    END IF;
END;
$$;