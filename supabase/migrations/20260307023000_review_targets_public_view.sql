-- Review target rollout completion
-- 1) Make facilities discoverable to authenticated users for review targeting.
-- 2) Extend reviews_public with target metadata and facility display name.
-- 3) Backfill facilities from existing provider clinic names for immediate usability.

BEGIN;

-- Allow signed-in users to discover facilities when submitting facility reviews.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'facilities'
          AND policyname = 'authenticated_select_facilities'
    ) THEN
        CREATE POLICY authenticated_select_facilities
        ON public.facilities
        FOR SELECT
        TO authenticated
        USING (true);
    END IF;
END $$;

-- Backfill facility rows from provider clinic names (best-effort and idempotent).
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
      WHERE lower(f.name) = lower(trim(p.clinic_name))
        AND COALESCE(lower(f.city), '') = COALESCE(lower(NULLIF(trim(p.city), '')), '')
        AND COALESCE(lower(f.country_code), '') = COALESCE(lower(NULLIF(trim(p.country_code), '')), '')
  );

CREATE OR REPLACE VIEW public.reviews_public
WITH (security_invoker = true)
AS
SELECT
  r.id,
  r.user_id,
  r.provider_id,
  r.facility_id,
  r.review_target_type,
  r.visit_date,
  r.visit_type,
  r.survey_type,
  r.rating_wait_time,
  r.rating_bedside,
  r.rating_efficacy,
  r.rating_cleanliness,
  r.rating_staff,
  r.rating_value,
  r.rating_pain_mgmt,
  r.rating_accuracy,
  r.rating_knowledge,
  r.rating_courtesy,
  r.rating_care_quality,
  r.rating_admin,
  r.rating_comfort,
  r.rating_turnaround,
  r.rating_empathy,
  r.rating_environment,
  r.rating_communication,
  r.rating_effectiveness,
  r.rating_attentiveness,
  r.rating_equipment,
  r.rating_consultation,
  r.rating_results,
  r.rating_aftercare,
  r.rating_overall,
  r.price_level,
  r.title,
  r.comment,
  r.would_recommend,
  CASE
    WHEN auth.uid() = r.user_id OR public.is_admin() THEN r.proof_image_url
    ELSE NULL
  END AS proof_image_url,
  r.is_verified,
  r.verification_confidence,
  r.status,
  r.helpful_count,
  r.created_at,
  r.updated_at,
  r.deleted_at,
  p.name AS provider_name,
  p.specialty AS provider_specialty,
  f.name AS facility_name
FROM public.reviews r
LEFT JOIN public.providers p ON p.id = r.provider_id
LEFT JOIN public.facilities f ON f.id = r.facility_id;

GRANT SELECT ON public.reviews_public TO anon, authenticated;

COMMIT;
