-- TrustCare schema

-- EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE OR REPLACE FUNCTION public.uuid_generate_v4()
RETURNS uuid
LANGUAGE SQL
AS $$
    SELECT gen_random_uuid();
$$;

-- TABLES
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    full_name TEXT,
    avatar_url TEXT,
    phone TEXT,
    country_code TEXT DEFAULT 'GB',
    preferred_language TEXT DEFAULT 'en',
    preferred_currency TEXT DEFAULT 'EUR',
    referral_code TEXT UNIQUE,
    referred_by TEXT,
    date_of_birth DATE,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT profiles_dob_check CHECK (date_of_birth IS NULL OR date_of_birth <= CURRENT_DATE - INTERVAL '16 years')
);

CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'moderator', 'admin')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, role)
);

CREATE TABLE IF NOT EXISTS public.specialties (
    id SERIAL PRIMARY KEY,
    name_key TEXT UNIQUE NOT NULL,
    name_en TEXT NOT NULL,
    name_de TEXT,
    name_nl TEXT,
    name_pl TEXT,
    name_tr TEXT,
    name_ar TEXT,
    icon_name TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS public.providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    specialty TEXT NOT NULL,
    clinic_name TEXT,
    address TEXT NOT NULL,
    city TEXT,
    country_code TEXT DEFAULT 'GB',
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    phone TEXT,
    email TEXT,
    website TEXT,
    photo_url TEXT,
    cover_url TEXT,
    languages_spoken TEXT[] DEFAULT '{English}',
    rating_overall NUMERIC(3,2) DEFAULT 0.00,
    rating_wait_time NUMERIC(3,2) DEFAULT 0.00,
    rating_bedside NUMERIC(3,2) DEFAULT 0.00,
    rating_efficacy NUMERIC(3,2) DEFAULT 0.00,
    rating_cleanliness NUMERIC(3,2) DEFAULT 0.00,
    review_count INTEGER DEFAULT 0,
    verified_review_count INTEGER DEFAULT 0,
    price_level_avg NUMERIC(2,1) DEFAULT 0.0,
    is_claimed BOOLEAN DEFAULT FALSE,
    claimed_by UUID REFERENCES auth.users(id),
    claimed_at TIMESTAMPTZ,
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'basic', 'premium')),
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES auth.users(id),
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    search_vector tsvector,
    CONSTRAINT providers_valid_coords CHECK (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180),
    CONSTRAINT providers_valid_ratings CHECK (rating_overall BETWEEN 0 AND 5)
);

CREATE TABLE IF NOT EXISTS public.provider_claims (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES public.providers ON DELETE CASCADE,
    claimant_user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
    claimant_role TEXT NOT NULL CHECK (claimant_role IN ('owner', 'manager', 'representative')),
    business_email TEXT NOT NULL,
    phone TEXT,
    license_number TEXT,
    proof_document_url TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewed_by UUID REFERENCES auth.users,
    reviewed_at TIMESTAMPTZ,
    rejection_reason TEXT,
    cooloff_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.provider_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES public.providers ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
    tier TEXT NOT NULL CHECK (tier IN ('basic', 'premium')),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'trial')),
    started_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    auto_renew BOOLEAN DEFAULT TRUE,
    payment_provider TEXT,
    payment_reference TEXT,
    monthly_price_cents INTEGER,
    currency TEXT DEFAULT 'EUR',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.provider_services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES public.providers ON DELETE CASCADE,
    category TEXT,
    name TEXT NOT NULL,
    description TEXT,
    price_min NUMERIC(10,2),
    price_max NUMERIC(10,2),
    currency TEXT DEFAULT 'EUR',
    duration_minutes INTEGER,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES public.providers ON DELETE CASCADE,
    visit_date DATE NOT NULL DEFAULT CURRENT_DATE,
    visit_type TEXT NOT NULL DEFAULT 'consultation' CHECK (visit_type IN ('consultation', 'procedure', 'checkup', 'emergency')),
    rating_wait_time INTEGER NOT NULL CHECK (rating_wait_time BETWEEN 1 AND 5),
    rating_bedside INTEGER NOT NULL CHECK (rating_bedside BETWEEN 1 AND 5),
    rating_efficacy INTEGER NOT NULL CHECK (rating_efficacy BETWEEN 1 AND 5),
    rating_cleanliness INTEGER NOT NULL CHECK (rating_cleanliness BETWEEN 1 AND 5),
    rating_overall NUMERIC(2,1) NOT NULL CHECK (rating_overall BETWEEN 1.0 AND 5.0),
    price_level INTEGER NOT NULL CHECK (price_level BETWEEN 1 AND 4),
    title TEXT,
    comment TEXT NOT NULL CHECK (char_length(comment) BETWEEN 50 AND 1000),
    would_recommend BOOLEAN DEFAULT TRUE,
    proof_image_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_confidence INTEGER,
    verification_reason TEXT,
    verified_at TIMESTAMPTZ,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'pending_verification', 'flagged', 'removed')),
    helpful_count INTEGER DEFAULT 0,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, provider_id, visit_date)
);

CREATE TABLE IF NOT EXISTS public.review_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES public.reviews ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
    media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
    storage_path TEXT NOT NULL,
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    file_size_bytes INTEGER NOT NULL,
    duration_seconds INTEGER,
    width INTEGER,
    height INTEGER,
    display_order INTEGER DEFAULT 0,
    content_status TEXT DEFAULT 'active' CHECK (content_status IN ('active', 'flagged', 'removed')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.review_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES public.reviews ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
    is_helpful BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (review_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.reported_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES public.reviews ON DELETE CASCADE,
    reporter_id UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
    reason TEXT NOT NULL CHECK (reason IN ('inaccurate', 'offensive', 'spam', 'other')),
    description TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed')),
    reviewed_by UUID REFERENCES auth.users,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (review_id, reporter_id)
);

CREATE TABLE IF NOT EXISTS public.proof_hashes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES public.reviews ON DELETE CASCADE,
    image_hash TEXT NOT NULL,
    file_size_bytes INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.failed_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES public.reviews ON DELETE CASCADE,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    last_attempted_at TIMESTAMPTZ DEFAULT NOW(),
    resolved BOOLEAN DEFAULT FALSE,
    resolved_by UUID REFERENCES auth.users,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('review_verified', 'review_flagged', 'claim_approved', 'claim_rejected', 'helpful_vote', 'provider_reply')),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.consent_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
    consent_type TEXT NOT NULL CHECK (consent_type IN ('terms_of_service', 'privacy_policy', 'review_data_processing', 'ai_verification_consent', 'marketing_communications', 'analytics_tracking')),
    version TEXT NOT NULL,
    granted BOOLEAN NOT NULL,
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_at TIMESTAMPTZ,
    UNIQUE (user_id, consent_type, version)
);

CREATE TABLE IF NOT EXISTS public.user_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles ON DELETE SET NULL,
    event_type TEXT NOT NULL,
    event_data JSONB,
    device_info TEXT,
    app_version TEXT,
    session_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.feature_flags (
    id SERIAL PRIMARY KEY,
    flag_name TEXT UNIQUE NOT NULL,
    description TEXT,
    is_enabled BOOLEAN DEFAULT FALSE,
    rollout_percentage INTEGER DEFAULT 0 CHECK (rollout_percentage BETWEEN 0 AND 100),
    target_countries TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.provider_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID REFERENCES public.providers ON DELETE CASCADE,
    campaign_type TEXT CHECK (campaign_type IN ('featured_listing', 'promoted_card', 'banner_ad')),
    title TEXT,
    description TEXT,
    budget_cents INTEGER,
    spent_cents INTEGER DEFAULT 0,
    currency TEXT DEFAULT 'EUR',
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'paused', 'completed', 'cancelled')),
    impressions INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.referral_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT UNIQUE NOT NULL,
    owner_type TEXT NOT NULL CHECK (owner_type IN ('provider', 'user')),
    owner_provider_id UUID REFERENCES public.providers ON DELETE CASCADE,
    owner_user_id UUID REFERENCES public.profiles ON DELETE CASCADE,
    description TEXT,
    usage_count INTEGER DEFAULT 0,
    max_uses INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT referral_codes_owner_check CHECK (
        (owner_type = 'provider' AND owner_provider_id IS NOT NULL AND owner_user_id IS NULL) OR
        (owner_type = 'user' AND owner_user_id IS NOT NULL AND owner_provider_id IS NULL)
    )
);

CREATE TABLE IF NOT EXISTS public.ai_chat_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
    title TEXT,
    messages JSONB DEFAULT '[]'::JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES public.providers ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
    requested_date DATE NOT NULL,
    requested_time TIME,
    reason TEXT,
    insurance_info TEXT,
    status TEXT DEFAULT 'requested' CHECK (status IN ('requested', 'confirmed', 'cancelled_by_user', 'cancelled_by_provider', 'completed', 'no_show')),
    provider_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.contact_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES public.providers ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles ON DELETE SET NULL,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- FUNCTIONS
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.user_roles
        WHERE user_id = auth.uid()
          AND role IN ('admin', 'moderator')
    );
$$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_referral_code TEXT;
BEGIN
    new_referral_code := UPPER(SUBSTRING(NEW.id::TEXT FROM 1 FOR 4))
        || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');

    INSERT INTO public.profiles (id, full_name, avatar_url, referral_code)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
        new_referral_code
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.providers_search_vector_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('simple', COALESCE(NEW.name, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(NEW.clinic_name, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(NEW.specialty, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(NEW.city, '') || ' ' || COALESCE(NEW.address, '')), 'D');
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.compute_review_overall()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    computed_overall NUMERIC(2,1);
BEGIN
    computed_overall := ROUND((NEW.rating_wait_time + NEW.rating_bedside + NEW.rating_efficacy + NEW.rating_cleanliness) / 4.0, 1);
    NEW.rating_overall := computed_overall;

    IF TG_OP = 'INSERT' THEN
        IF NEW.proof_image_url IS NOT NULL AND LENGTH(TRIM(NEW.proof_image_url)) > 0 THEN
            NEW.status := 'pending_verification';
        ELSE
            NEW.status := 'active';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.check_review_spam()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    recent_count INTEGER;
    duplicate_count INTEGER;
    computed_overall NUMERIC(2,1);
BEGIN
    SELECT COUNT(*) INTO recent_count
    FROM public.reviews
    WHERE user_id = NEW.user_id
      AND created_at >= NOW() - INTERVAL '24 hours';

    IF recent_count >= 5 THEN
        RAISE EXCEPTION 'Rate limit exceeded for reviews';
    END IF;

    SELECT COUNT(*) INTO duplicate_count
    FROM public.reviews
    WHERE user_id = NEW.user_id
      AND comment = NEW.comment
      AND created_at >= NOW() - INTERVAL '7 days';

    IF duplicate_count > 0 THEN
        RAISE EXCEPTION 'Duplicate review detected';
    END IF;

    computed_overall := COALESCE(NEW.rating_overall,
        ROUND((NEW.rating_wait_time + NEW.rating_bedside + NEW.rating_efficacy + NEW.rating_cleanliness) / 4.0, 1)
    );

    IF (computed_overall <= 1.5 OR computed_overall >= 4.8) AND LENGTH(NEW.comment) < 100 THEN
        NEW.status := 'flagged';
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_provider_aggregates()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    target_provider UUID;
BEGIN
    target_provider := COALESCE(NEW.provider_id, OLD.provider_id);

    UPDATE public.providers p
    SET
        rating_overall = COALESCE((
            SELECT ROUND(AVG(r.rating_overall)::NUMERIC, 2)
            FROM public.reviews r
            WHERE r.provider_id = target_provider
              AND r.status IN ('active', 'pending_verification')
              AND r.deleted_at IS NULL
        ), 0.00),
        rating_wait_time = COALESCE((
            SELECT ROUND(AVG(r.rating_wait_time)::NUMERIC, 2)
            FROM public.reviews r
            WHERE r.provider_id = target_provider
              AND r.status IN ('active', 'pending_verification')
              AND r.deleted_at IS NULL
        ), 0.00),
        rating_bedside = COALESCE((
            SELECT ROUND(AVG(r.rating_bedside)::NUMERIC, 2)
            FROM public.reviews r
            WHERE r.provider_id = target_provider
              AND r.status IN ('active', 'pending_verification')
              AND r.deleted_at IS NULL
        ), 0.00),
        rating_efficacy = COALESCE((
            SELECT ROUND(AVG(r.rating_efficacy)::NUMERIC, 2)
            FROM public.reviews r
            WHERE r.provider_id = target_provider
              AND r.status IN ('active', 'pending_verification')
              AND r.deleted_at IS NULL
        ), 0.00),
        rating_cleanliness = COALESCE((
            SELECT ROUND(AVG(r.rating_cleanliness)::NUMERIC, 2)
            FROM public.reviews r
            WHERE r.provider_id = target_provider
              AND r.status IN ('active', 'pending_verification')
              AND r.deleted_at IS NULL
        ), 0.00),
        review_count = COALESCE((
            SELECT COUNT(*)
            FROM public.reviews r
            WHERE r.provider_id = target_provider
              AND r.status IN ('active', 'pending_verification')
              AND r.deleted_at IS NULL
        ), 0),
        verified_review_count = COALESCE((
            SELECT COUNT(*)
            FROM public.reviews r
            WHERE r.provider_id = target_provider
              AND r.status IN ('active', 'pending_verification')
              AND r.deleted_at IS NULL
              AND r.is_verified = TRUE
        ), 0),
        price_level_avg = COALESCE((
            SELECT ROUND(AVG(r.price_level)::NUMERIC, 1)
            FROM public.reviews r
            WHERE r.provider_id = target_provider
              AND r.status IN ('active', 'pending_verification')
              AND r.deleted_at IS NULL
        ), 0.0)
    WHERE p.id = target_provider;

    IF NEW.provider_id IS NOT NULL AND OLD.provider_id IS NOT NULL AND NEW.provider_id <> OLD.provider_id THEN
        UPDATE public.providers p
        SET
            rating_overall = COALESCE((
                SELECT ROUND(AVG(r.rating_overall)::NUMERIC, 2)
                FROM public.reviews r
                WHERE r.provider_id = OLD.provider_id
                  AND r.status IN ('active', 'pending_verification')
                  AND r.deleted_at IS NULL
            ), 0.00),
            rating_wait_time = COALESCE((
                SELECT ROUND(AVG(r.rating_wait_time)::NUMERIC, 2)
                FROM public.reviews r
                WHERE r.provider_id = OLD.provider_id
                  AND r.status IN ('active', 'pending_verification')
                  AND r.deleted_at IS NULL
            ), 0.00),
            rating_bedside = COALESCE((
                SELECT ROUND(AVG(r.rating_bedside)::NUMERIC, 2)
                FROM public.reviews r
                WHERE r.provider_id = OLD.provider_id
                  AND r.status IN ('active', 'pending_verification')
                  AND r.deleted_at IS NULL
            ), 0.00),
            rating_efficacy = COALESCE((
                SELECT ROUND(AVG(r.rating_efficacy)::NUMERIC, 2)
                FROM public.reviews r
                WHERE r.provider_id = OLD.provider_id
                  AND r.status IN ('active', 'pending_verification')
                  AND r.deleted_at IS NULL
            ), 0.00),
            rating_cleanliness = COALESCE((
                SELECT ROUND(AVG(r.rating_cleanliness)::NUMERIC, 2)
                FROM public.reviews r
                WHERE r.provider_id = OLD.provider_id
                  AND r.status IN ('active', 'pending_verification')
                  AND r.deleted_at IS NULL
            ), 0.00),
            review_count = COALESCE((
                SELECT COUNT(*)
                FROM public.reviews r
                WHERE r.provider_id = OLD.provider_id
                  AND r.status IN ('active', 'pending_verification')
                  AND r.deleted_at IS NULL
            ), 0),
            verified_review_count = COALESCE((
                SELECT COUNT(*)
                FROM public.reviews r
                WHERE r.provider_id = OLD.provider_id
                  AND r.status IN ('active', 'pending_verification')
                  AND r.deleted_at IS NULL
                  AND r.is_verified = TRUE
            ), 0),
            price_level_avg = COALESCE((
                SELECT ROUND(AVG(r.price_level)::NUMERIC, 1)
                FROM public.reviews r
                WHERE r.provider_id = OLD.provider_id
                  AND r.status IN ('active', 'pending_verification')
                  AND r.deleted_at IS NULL
            ), 0.0)
        WHERE p.id = OLD.provider_id;
    END IF;

    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.check_provider_spam()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    recent_count INTEGER;
    duplicate_count INTEGER;
BEGIN
    IF NEW.created_by IS NOT NULL THEN
        SELECT COUNT(*) INTO recent_count
        FROM public.providers
        WHERE created_by = NEW.created_by
          AND created_at >= NOW() - INTERVAL '24 hours';

        IF recent_count >= 3 THEN
            RAISE EXCEPTION 'Rate limit exceeded for providers';
        END IF;
    END IF;

    SELECT COUNT(*) INTO duplicate_count
    FROM public.providers
    WHERE LOWER(name) = LOWER(NEW.name)
      AND LOWER(address) = LOWER(NEW.address)
      AND deleted_at IS NULL;

    IF duplicate_count > 0 THEN
        RAISE EXCEPTION 'Duplicate provider detected';
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.check_claim_cooloff()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    existing_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO existing_count
    FROM public.provider_claims
    WHERE provider_id = NEW.provider_id
      AND claimant_user_id = NEW.claimant_user_id
      AND status = 'rejected'
      AND cooloff_until IS NOT NULL
      AND cooloff_until > NOW();

    IF existing_count > 0 THEN
        RAISE EXCEPTION 'Claim cooloff period active';
    END IF;

    RETURN NEW;
END;
$$;

-- TRIGGERS
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER providers_search_vector_trigger
BEFORE INSERT OR UPDATE ON public.providers
FOR EACH ROW
EXECUTE FUNCTION public.providers_search_vector_update();

CREATE TRIGGER set_updated_at_profiles
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_updated_at_providers
BEFORE UPDATE ON public.providers
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_updated_at_provider_subscriptions
BEFORE UPDATE ON public.provider_subscriptions
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_updated_at_provider_services
BEFORE UPDATE ON public.provider_services
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER compute_review_overall
BEFORE INSERT OR UPDATE ON public.reviews
FOR EACH ROW
EXECUTE FUNCTION public.compute_review_overall();

CREATE TRIGGER check_review_spam
BEFORE INSERT ON public.reviews
FOR EACH ROW
EXECUTE FUNCTION public.check_review_spam();

CREATE TRIGGER update_provider_aggregates
AFTER INSERT OR UPDATE OR DELETE ON public.reviews
FOR EACH ROW
EXECUTE FUNCTION public.update_provider_aggregates();

CREATE TRIGGER check_provider_spam
BEFORE INSERT ON public.providers
FOR EACH ROW
EXECUTE FUNCTION public.check_provider_spam();

CREATE TRIGGER check_claim_cooloff
BEFORE INSERT ON public.provider_claims
FOR EACH ROW
EXECUTE FUNCTION public.check_claim_cooloff();

-- INDEXES
CREATE INDEX IF NOT EXISTS providers_specialty_idx ON public.providers (specialty);
CREATE INDEX IF NOT EXISTS providers_rating_overall_desc_idx ON public.providers (rating_overall DESC);
CREATE INDEX IF NOT EXISTS providers_active_idx ON public.providers (id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS providers_lat_lng_idx ON public.providers (latitude, longitude);
CREATE INDEX IF NOT EXISTS providers_country_code_idx ON public.providers (country_code);
CREATE INDEX IF NOT EXISTS providers_is_claimed_idx ON public.providers (is_claimed);
CREATE INDEX IF NOT EXISTS providers_featured_idx ON public.providers (id) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS providers_specialty_rating_active_idx ON public.providers (specialty, rating_overall DESC) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS providers_search_vector_idx ON public.providers USING GIN (search_vector);
CREATE INDEX IF NOT EXISTS providers_not_deleted_idx ON public.providers (id) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS reviews_provider_id_idx ON public.reviews (provider_id);
CREATE INDEX IF NOT EXISTS reviews_user_id_idx ON public.reviews (user_id);
CREATE INDEX IF NOT EXISTS reviews_created_at_desc_idx ON public.reviews (created_at DESC);
CREATE INDEX IF NOT EXISTS reviews_verified_active_idx ON public.reviews (provider_id) WHERE is_verified = TRUE AND status = 'active';
CREATE INDEX IF NOT EXISTS reviews_pending_verification_idx ON public.reviews (status) WHERE status = 'pending_verification';
CREATE INDEX IF NOT EXISTS reviews_user_created_at_desc_idx ON public.reviews (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS reviews_provider_status_created_idx ON public.reviews (provider_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS review_media_review_id_idx ON public.review_media (review_id);
CREATE INDEX IF NOT EXISTS review_media_user_id_idx ON public.review_media (user_id);

CREATE INDEX IF NOT EXISTS review_votes_helpful_idx ON public.review_votes (review_id) WHERE is_helpful = TRUE;

CREATE INDEX IF NOT EXISTS user_roles_user_id_idx ON public.user_roles (user_id);
CREATE INDEX IF NOT EXISTS provider_claims_status_idx ON public.provider_claims (status);
CREATE UNIQUE INDEX IF NOT EXISTS provider_claims_one_pending_idx ON public.provider_claims (provider_id) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS provider_services_provider_id_idx ON public.provider_services (provider_id);

CREATE INDEX IF NOT EXISTS provider_campaigns_active_idx ON public.provider_campaigns (status, starts_at, ends_at) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS referral_codes_active_idx ON public.referral_codes (code) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS appointments_provider_date_idx ON public.appointments (provider_id, requested_date);
CREATE INDEX IF NOT EXISTS appointments_user_idx ON public.appointments (user_id);
CREATE INDEX IF NOT EXISTS ai_chat_sessions_user_idx ON public.ai_chat_sessions (user_id);
CREATE INDEX IF NOT EXISTS notifications_unread_idx ON public.notifications (user_id, created_at DESC) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS user_events_type_created_idx ON public.user_events (event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS user_events_user_created_idx ON public.user_events (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS failed_verifications_unresolved_idx ON public.failed_verifications (resolved, created_at) WHERE resolved = FALSE;
CREATE INDEX IF NOT EXISTS proof_hashes_image_hash_idx ON public.proof_hashes (image_hash);

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.specialties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reported_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.proof_hashes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.failed_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consent_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_requests ENABLE ROW LEVEL SECURITY;

-- profiles
CREATE POLICY profiles_select_all ON public.profiles
    FOR SELECT USING (true);
CREATE POLICY profiles_insert_own ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY profiles_update_own ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- user_roles
CREATE POLICY user_roles_select_own ON public.user_roles
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY user_roles_admin_all ON public.user_roles
    FOR ALL USING (public.is_admin());

-- specialties
CREATE POLICY specialties_select_all ON public.specialties
    FOR SELECT USING (true);

-- providers
CREATE POLICY providers_select_active ON public.providers
    FOR SELECT USING (is_active = TRUE AND deleted_at IS NULL);
CREATE POLICY providers_insert_auth ON public.providers
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY providers_update_claimed ON public.providers
    FOR UPDATE USING (claimed_by = auth.uid());
CREATE POLICY providers_admin_all ON public.providers
    FOR ALL USING (public.is_admin());

-- provider_claims
CREATE POLICY provider_claims_insert_own ON public.provider_claims
    FOR INSERT WITH CHECK (claimant_user_id = auth.uid());
CREATE POLICY provider_claims_select_own ON public.provider_claims
    FOR SELECT USING (claimant_user_id = auth.uid());
CREATE POLICY provider_claims_admin_all ON public.provider_claims
    FOR ALL USING (public.is_admin());

-- provider_subscriptions
CREATE POLICY provider_subscriptions_select_own ON public.provider_subscriptions
    FOR SELECT USING (user_id = auth.uid());
CREATE POLICY provider_subscriptions_admin_all ON public.provider_subscriptions
    FOR ALL USING (public.is_admin());

-- provider_services
CREATE POLICY provider_services_select_all ON public.provider_services
    FOR SELECT USING (true);
CREATE POLICY provider_services_owner_all ON public.provider_services
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.providers p
            WHERE p.id = provider_id
              AND p.claimed_by = auth.uid()
        )
    );
CREATE POLICY provider_services_admin_all ON public.provider_services
    FOR ALL USING (public.is_admin());

-- reviews
CREATE POLICY reviews_select_public ON public.reviews
    FOR SELECT USING (
        (status IN ('active', 'pending_verification') AND deleted_at IS NULL)
        OR user_id = auth.uid()
    );
CREATE POLICY reviews_insert_own ON public.reviews
    FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY reviews_update_own ON public.reviews
    FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY reviews_delete_own ON public.reviews
    FOR DELETE USING (user_id = auth.uid());
CREATE POLICY reviews_admin_all ON public.reviews
    FOR ALL USING (public.is_admin());

-- review_media
CREATE POLICY review_media_select_all ON public.review_media
    FOR SELECT USING (true);
CREATE POLICY review_media_insert_own ON public.review_media
    FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY review_media_delete_own ON public.review_media
    FOR DELETE USING (user_id = auth.uid());
CREATE POLICY review_media_admin_all ON public.review_media
    FOR ALL USING (public.is_admin());

-- review_votes
CREATE POLICY review_votes_select_all ON public.review_votes
    FOR SELECT USING (true);
CREATE POLICY review_votes_insert_own ON public.review_votes
    FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY review_votes_update_own ON public.review_votes
    FOR UPDATE USING (user_id = auth.uid());

-- reported_reviews
CREATE POLICY reported_reviews_insert_own ON public.reported_reviews
    FOR INSERT WITH CHECK (reporter_id = auth.uid());
CREATE POLICY reported_reviews_admin_all ON public.reported_reviews
    FOR ALL USING (public.is_admin());

-- notifications
CREATE POLICY notifications_own_all ON public.notifications
    FOR ALL USING (user_id = auth.uid());

-- consent_records
CREATE POLICY consent_records_own_all ON public.consent_records
    FOR ALL USING (user_id = auth.uid());
CREATE POLICY consent_records_admin_select ON public.consent_records
    FOR SELECT USING (public.is_admin());

-- user_events
CREATE POLICY user_events_insert_auth ON public.user_events
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY user_events_select_own ON public.user_events
    FOR SELECT USING (user_id = auth.uid());
CREATE POLICY user_events_admin_all ON public.user_events
    FOR ALL USING (public.is_admin());

-- feature_flags
CREATE POLICY feature_flags_select_all ON public.feature_flags
    FOR SELECT USING (true);

-- provider_campaigns
CREATE POLICY provider_campaigns_select_active ON public.provider_campaigns
    FOR SELECT USING (
        status = 'active'
        AND starts_at <= NOW()
        AND ends_at >= NOW()
    );
CREATE POLICY provider_campaigns_admin_all ON public.provider_campaigns
    FOR ALL USING (public.is_admin());

-- referral_codes
CREATE POLICY referral_codes_select_active ON public.referral_codes
    FOR SELECT USING (is_active = TRUE);
CREATE POLICY referral_codes_select_own ON public.referral_codes
    FOR SELECT USING (owner_user_id = auth.uid());
CREATE POLICY referral_codes_admin_all ON public.referral_codes
    FOR ALL USING (public.is_admin());

-- ai_chat_sessions
CREATE POLICY ai_chat_sessions_own_all ON public.ai_chat_sessions
    FOR ALL USING (user_id = auth.uid());

-- appointments
CREATE POLICY appointments_user_all ON public.appointments
    FOR ALL USING (user_id = auth.uid());
CREATE POLICY appointments_provider_select ON public.appointments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.providers p
            WHERE p.id = provider_id
              AND p.claimed_by = auth.uid()
        )
    );
CREATE POLICY appointments_admin_all ON public.appointments
    FOR ALL USING (public.is_admin());

-- contact_requests
CREATE POLICY contact_requests_insert_auth ON public.contact_requests
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY contact_requests_admin_all ON public.contact_requests
    FOR ALL USING (public.is_admin());

-- proof_hashes
CREATE POLICY proof_hashes_admin_only ON public.proof_hashes
    FOR ALL USING (public.is_admin());

-- failed_verifications
CREATE POLICY failed_verifications_admin_only ON public.failed_verifications
    FOR ALL USING (public.is_admin());

-- STORAGE BUCKETS
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
    ('verification-proofs', 'verification-proofs', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/heic']),
    ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png']),
    ('provider-photos', 'provider-photos', true, 10485760, ARRAY['image/jpeg', 'image/png']),
    ('claim-documents', 'claim-documents', false, 10485760, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
    ('review-media', 'review-media', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/heic', 'video/mp4', 'video/quicktime'])
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- STORAGE POLICIES
CREATE POLICY storage_verification_upload_own ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'verification-proofs'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY storage_verification_read_own_or_admin ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'verification-proofs'
        AND (
            auth.uid()::text = (storage.foldername(name))[1]
            OR public.is_admin()
        )
    );

CREATE POLICY storage_avatars_upload_own ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY storage_avatars_public_read ON storage.objects
    FOR SELECT TO public
    USING (bucket_id = 'avatars');

CREATE POLICY storage_provider_photos_admin_upload ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'provider-photos' AND public.is_admin());

CREATE POLICY storage_provider_photos_public_read ON storage.objects
    FOR SELECT TO public
    USING (bucket_id = 'provider-photos');

CREATE POLICY storage_claim_documents_upload_own ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'claim-documents'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY storage_claim_documents_admin_read ON storage.objects
    FOR SELECT TO authenticated
    USING (bucket_id = 'claim-documents' AND public.is_admin());

CREATE POLICY storage_review_media_upload_own ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'review-media'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY storage_review_media_public_read ON storage.objects
    FOR SELECT TO public
    USING (bucket_id = 'review-media');

CREATE POLICY storage_review_media_delete_own ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'review-media'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY storage_review_media_admin_all ON storage.objects
    FOR ALL TO authenticated
    USING (bucket_id = 'review-media' AND public.is_admin())
    WITH CHECK (bucket_id = 'review-media' AND public.is_admin());
