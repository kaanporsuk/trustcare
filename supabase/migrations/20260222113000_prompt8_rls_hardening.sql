-- Prompt 8 RLS hardening
-- Ensures required access patterns for providers/reviews/saved providers/rehber/specialties

-- 1) Specialties readable by everyone
ALTER TABLE IF EXISTS public.specialties ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS specialties_select_all ON public.specialties;
CREATE POLICY specialties_select_all ON public.specialties
FOR SELECT USING (true);

-- 2) Providers readable by everyone
ALTER TABLE IF EXISTS public.providers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS providers_select_active ON public.providers;
CREATE POLICY providers_select_active ON public.providers
FOR SELECT USING (is_active = true AND deleted_at IS NULL);

-- 3) Reviews: public read + own write, with proof URL visibility via view
ALTER TABLE IF EXISTS public.reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS reviews_select_public ON public.reviews;
CREATE POLICY reviews_select_public ON public.reviews
FOR SELECT USING ((status IN ('active', 'pending_verification') AND deleted_at IS NULL) OR user_id = auth.uid());

DROP POLICY IF EXISTS reviews_insert_own ON public.reviews;
CREATE POLICY reviews_insert_own ON public.reviews
FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS reviews_update_own ON public.reviews;
CREATE POLICY reviews_update_own ON public.reviews
FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS reviews_delete_own ON public.reviews;
CREATE POLICY reviews_delete_own ON public.reviews
FOR DELETE USING (user_id = auth.uid());

CREATE OR REPLACE VIEW public.reviews_public
WITH (security_invoker = true)
AS
SELECT
  r.id,
  r.user_id,
  r.provider_id,
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
  r.deleted_at
FROM public.reviews r;

GRANT SELECT ON public.reviews_public TO anon, authenticated;

-- 4) saved_providers ownership policies
CREATE TABLE IF NOT EXISTS public.saved_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES public.providers(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, provider_id)
);

ALTER TABLE public.saved_providers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS saved_providers_select_own ON public.saved_providers;
CREATE POLICY saved_providers_select_own ON public.saved_providers
FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS saved_providers_insert_own ON public.saved_providers;
CREATE POLICY saved_providers_insert_own ON public.saved_providers
FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS saved_providers_delete_own ON public.saved_providers;
CREATE POLICY saved_providers_delete_own ON public.saved_providers
FOR DELETE USING (user_id = auth.uid());

-- 5) Rehber ownership policies
CREATE TABLE IF NOT EXISTS public.rehber_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT,
  was_emergency BOOLEAN NOT NULL DEFAULT false,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.rehber_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.rehber_sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  recommended_specialties TEXT[],
  was_emergency BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Add user_id column to rehber_messages if it doesn't exist (for migration compatibility)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'rehber_messages' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE public.rehber_messages ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

ALTER TABLE public.rehber_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rehber_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS rehber_sessions_select_own ON public.rehber_sessions;
CREATE POLICY rehber_sessions_select_own ON public.rehber_sessions
FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS rehber_sessions_insert_own ON public.rehber_sessions;
CREATE POLICY rehber_sessions_insert_own ON public.rehber_sessions
FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS rehber_sessions_update_own ON public.rehber_sessions;
CREATE POLICY rehber_sessions_update_own ON public.rehber_sessions
FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS rehber_messages_select_own ON public.rehber_messages;
CREATE POLICY rehber_messages_select_own ON public.rehber_messages
FOR SELECT USING (user_id IS NOT NULL AND user_id = auth.uid());

DROP POLICY IF EXISTS rehber_messages_insert_own ON public.rehber_messages;
CREATE POLICY rehber_messages_insert_own ON public.rehber_messages
FOR INSERT WITH CHECK (user_id IS NOT NULL AND user_id = auth.uid());
