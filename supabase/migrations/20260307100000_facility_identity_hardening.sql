-- Facility identity hardening and provider linkage backfill.
-- Keeps existing behavior backward compatible while transitioning from clinic_name matching
-- to stable provider.facility_id relationships.

BEGIN;

ALTER TABLE public.providers
    ADD COLUMN IF NOT EXISTS facility_id uuid REFERENCES public.facilities(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_providers_facility_id
    ON public.providers(facility_id)
    WHERE facility_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_facilities_identity_lookup
    ON public.facilities (
        lower(trim(name)),
        COALESCE(lower(trim(city)), ''),
        COALESCE(lower(trim(country_code)), '')
    );

-- Re-point duplicate facility references to a stable canonical row per normalized identity.
WITH ranked_facilities AS (
    SELECT
        id,
        first_value(id) OVER (
            PARTITION BY
                lower(trim(name)),
                COALESCE(lower(trim(city)), ''),
                COALESCE(lower(trim(country_code)), '')
            ORDER BY created_at ASC, id ASC
        ) AS canonical_id
    FROM public.facilities
),
facility_repoint AS (
    SELECT id, canonical_id
    FROM ranked_facilities
    WHERE id <> canonical_id
)
UPDATE public.providers p
SET facility_id = r.canonical_id
FROM facility_repoint r
WHERE p.facility_id = r.id;

WITH ranked_facilities AS (
    SELECT
        id,
        first_value(id) OVER (
            PARTITION BY
                lower(trim(name)),
                COALESCE(lower(trim(city)), ''),
                COALESCE(lower(trim(country_code)), '')
            ORDER BY created_at ASC, id ASC
        ) AS canonical_id
    FROM public.facilities
),
facility_repoint AS (
    SELECT id, canonical_id
    FROM ranked_facilities
    WHERE id <> canonical_id
)
UPDATE public.reviews r
SET facility_id = rp.canonical_id
FROM facility_repoint rp
WHERE r.facility_id = rp.id;

WITH ranked_facilities AS (
    SELECT
        id,
        first_value(id) OVER (
            PARTITION BY
                lower(trim(name)),
                COALESCE(lower(trim(city)), ''),
                COALESCE(lower(trim(country_code)), '')
            ORDER BY created_at ASC, id ASC
        ) AS canonical_id
    FROM public.facilities
)
DELETE FROM public.facilities f
USING ranked_facilities rf
WHERE f.id = rf.id
  AND rf.id <> rf.canonical_id;

CREATE UNIQUE INDEX IF NOT EXISTS idx_facilities_identity_unique
    ON public.facilities (
        lower(trim(name)),
        COALESCE(lower(trim(city)), ''),
        COALESCE(lower(trim(country_code)), '')
    );

-- Ensure facilities exist for legacy provider clinic_name values, then backfill provider.facility_id.
INSERT INTO public.facilities (name, city, country_code)
SELECT DISTINCT
    trim(p.clinic_name) AS name,
    NULLIF(trim(p.city), '') AS city,
    NULLIF(trim(p.country_code), '') AS country_code
FROM public.providers p
WHERE p.clinic_name IS NOT NULL
  AND trim(p.clinic_name) <> ''
  AND NOT EXISTS (
      SELECT 1
      FROM public.facilities f
      WHERE lower(trim(f.name)) = lower(trim(p.clinic_name))
        AND COALESCE(lower(trim(f.city)), '') = COALESCE(lower(NULLIF(trim(p.city), '')), '')
        AND COALESCE(lower(trim(f.country_code)), '') = COALESCE(lower(NULLIF(trim(p.country_code), '')), '')
  );

UPDATE public.providers p
SET facility_id = f.id
FROM public.facilities f
WHERE p.facility_id IS NULL
  AND p.clinic_name IS NOT NULL
  AND trim(p.clinic_name) <> ''
  AND lower(trim(f.name)) = lower(trim(p.clinic_name))
  AND COALESCE(lower(trim(f.city)), '') = COALESCE(lower(NULLIF(trim(p.city), '')), '')
  AND COALESCE(lower(trim(f.country_code)), '') = COALESCE(lower(NULLIF(trim(p.country_code), '')), '');

CREATE OR REPLACE VIEW public.facility_review_stats
WITH (security_invoker = true)
AS
SELECT
    r.facility_id,
    ROUND(AVG(r.rating_overall)::numeric, 2) AS rating_overall,
    COUNT(*)::int AS review_count,
    COUNT(*) FILTER (WHERE r.is_verified)::int AS verified_review_count
FROM public.reviews r
WHERE r.review_target_type = 'facility'
  AND r.facility_id IS NOT NULL
  AND r.deleted_at IS NULL
GROUP BY r.facility_id;

GRANT SELECT ON public.facility_review_stats TO anon, authenticated;

COMMIT;
