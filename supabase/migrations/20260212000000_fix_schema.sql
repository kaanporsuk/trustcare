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
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

DROP TRIGGER IF EXISTS providers_search_vector_trigger ON public.providers;
CREATE TRIGGER providers_search_vector_trigger
BEFORE INSERT OR UPDATE ON public.providers
FOR EACH ROW
EXECUTE FUNCTION public.providers_search_vector_update();

DROP TRIGGER IF EXISTS set_updated_at_profiles ON public.profiles;
CREATE TRIGGER set_updated_at_profiles
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_providers ON public.providers;
CREATE TRIGGER set_updated_at_providers
BEFORE UPDATE ON public.providers
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_provider_subscriptions ON public.provider_subscriptions;
CREATE TRIGGER set_updated_at_provider_subscriptions
BEFORE UPDATE ON public.provider_subscriptions
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_provider_services ON public.provider_services;
CREATE TRIGGER set_updated_at_provider_services
BEFORE UPDATE ON public.provider_services
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS compute_review_overall ON public.reviews;
CREATE TRIGGER compute_review_overall
BEFORE INSERT OR UPDATE ON public.reviews
FOR EACH ROW
EXECUTE FUNCTION public.compute_review_overall();

DROP TRIGGER IF EXISTS check_review_spam ON public.reviews;
CREATE TRIGGER check_review_spam
BEFORE INSERT ON public.reviews
FOR EACH ROW
EXECUTE FUNCTION public.check_review_spam();

DROP TRIGGER IF EXISTS update_provider_aggregates ON public.reviews;
CREATE TRIGGER update_provider_aggregates
AFTER INSERT OR UPDATE OR DELETE ON public.reviews
FOR EACH ROW
EXECUTE FUNCTION public.update_provider_aggregates();

DROP TRIGGER IF EXISTS check_provider_spam ON public.providers;
CREATE TRIGGER check_provider_spam
BEFORE INSERT ON public.providers
FOR EACH ROW
EXECUTE FUNCTION public.check_provider_spam();

DROP TRIGGER IF EXISTS check_claim_cooloff ON public.provider_claims;
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
DROP POLICY IF EXISTS profiles_select_all ON public.profiles;
CREATE POLICY profiles_select_all ON public.profiles
    FOR SELECT USING (true);
DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;
CREATE POLICY profiles_insert_own ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- user_roles
DROP POLICY IF EXISTS user_roles_select_own ON public.user_roles;
CREATE POLICY user_roles_select_own ON public.user_roles
    FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS user_roles_admin_all ON public.user_roles;
CREATE POLICY user_roles_admin_all ON public.user_roles
    FOR ALL USING (public.is_admin());

-- specialties
DROP POLICY IF EXISTS specialties_select_all ON public.specialties;
CREATE POLICY specialties_select_all ON public.specialties
    FOR SELECT USING (true);

-- providers
DROP POLICY IF EXISTS providers_select_active ON public.providers;
CREATE POLICY providers_select_active ON public.providers
    FOR SELECT USING (is_active = TRUE AND deleted_at IS NULL);
DROP POLICY IF EXISTS providers_insert_auth ON public.providers;
CREATE POLICY providers_insert_auth ON public.providers
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
DROP POLICY IF EXISTS providers_update_claimed ON public.providers;
CREATE POLICY providers_update_claimed ON public.providers
    FOR UPDATE USING (claimed_by = auth.uid());
DROP POLICY IF EXISTS providers_admin_all ON public.providers;
CREATE POLICY providers_admin_all ON public.providers
    FOR ALL USING (public.is_admin());

-- provider_claims
DROP POLICY IF EXISTS provider_claims_insert_own ON public.provider_claims;
CREATE POLICY provider_claims_insert_own ON public.provider_claims
    FOR INSERT WITH CHECK (claimant_user_id = auth.uid());
DROP POLICY IF EXISTS provider_claims_select_own ON public.provider_claims;
CREATE POLICY provider_claims_select_own ON public.provider_claims
    FOR SELECT USING (claimant_user_id = auth.uid());
DROP POLICY IF EXISTS provider_claims_admin_all ON public.provider_claims;
CREATE POLICY provider_claims_admin_all ON public.provider_claims
    FOR ALL USING (public.is_admin());

-- provider_subscriptions
DROP POLICY IF EXISTS provider_subscriptions_select_own ON public.provider_subscriptions;
CREATE POLICY provider_subscriptions_select_own ON public.provider_subscriptions
    FOR SELECT USING (user_id = auth.uid());
DROP POLICY IF EXISTS provider_subscriptions_admin_all ON public.provider_subscriptions;
CREATE POLICY provider_subscriptions_admin_all ON public.provider_subscriptions
    FOR ALL USING (public.is_admin());

-- provider_services
DROP POLICY IF EXISTS provider_services_select_all ON public.provider_services;
CREATE POLICY provider_services_select_all ON public.provider_services
    FOR SELECT USING (true);
DROP POLICY IF EXISTS provider_services_owner_all ON public.provider_services;
CREATE POLICY provider_services_owner_all ON public.provider_services
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.providers p
            WHERE p.id = provider_id
              AND p.claimed_by = auth.uid()
        )
    );
DROP POLICY IF EXISTS provider_services_admin_all ON public.provider_services;
CREATE POLICY provider_services_admin_all ON public.provider_services
    FOR ALL USING (public.is_admin());

-- reviews
DROP POLICY IF EXISTS reviews_select_public ON public.reviews;
CREATE POLICY reviews_select_public ON public.reviews
    FOR SELECT USING (
        (status IN ('active', 'pending_verification') AND deleted_at IS NULL)
        OR user_id = auth.uid()
    );
DROP POLICY IF EXISTS reviews_insert_own ON public.reviews;
CREATE POLICY reviews_insert_own ON public.reviews
    FOR INSERT WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS reviews_update_own ON public.reviews;
CREATE POLICY reviews_update_own ON public.reviews
    FOR UPDATE USING (user_id = auth.uid());
DROP POLICY IF EXISTS reviews_delete_own ON public.reviews;
CREATE POLICY reviews_delete_own ON public.reviews
    FOR DELETE USING (user_id = auth.uid());
DROP POLICY IF EXISTS reviews_admin_all ON public.reviews;
CREATE POLICY reviews_admin_all ON public.reviews
    FOR ALL USING (public.is_admin());

-- review_media
DROP POLICY IF EXISTS review_media_select_all ON public.review_media;
CREATE POLICY review_media_select_all ON public.review_media
    FOR SELECT USING (true);
DROP POLICY IF EXISTS review_media_insert_own ON public.review_media;
CREATE POLICY review_media_insert_own ON public.review_media
    FOR INSERT WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS review_media_delete_own ON public.review_media;
CREATE POLICY review_media_delete_own ON public.review_media
    FOR DELETE USING (user_id = auth.uid());
DROP POLICY IF EXISTS review_media_admin_all ON public.review_media;
CREATE POLICY review_media_admin_all ON public.review_media
    FOR ALL USING (public.is_admin());

-- review_votes
DROP POLICY IF EXISTS review_votes_select_all ON public.review_votes;
CREATE POLICY review_votes_select_all ON public.review_votes
    FOR SELECT USING (true);
DROP POLICY IF EXISTS review_votes_insert_own ON public.review_votes;
CREATE POLICY review_votes_insert_own ON public.review_votes
    FOR INSERT WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS review_votes_update_own ON public.review_votes;
CREATE POLICY review_votes_update_own ON public.review_votes
    FOR UPDATE USING (user_id = auth.uid());

-- reported_reviews
DROP POLICY IF EXISTS reported_reviews_insert_own ON public.reported_reviews;
CREATE POLICY reported_reviews_insert_own ON public.reported_reviews
    FOR INSERT WITH CHECK (reporter_id = auth.uid());
DROP POLICY IF EXISTS reported_reviews_admin_all ON public.reported_reviews;
CREATE POLICY reported_reviews_admin_all ON public.reported_reviews
    FOR ALL USING (public.is_admin());

-- notifications
DROP POLICY IF EXISTS notifications_own_all ON public.notifications;
CREATE POLICY notifications_own_all ON public.notifications
    FOR ALL USING (user_id = auth.uid());

-- consent_records
DROP POLICY IF EXISTS consent_records_own_all ON public.consent_records;
CREATE POLICY consent_records_own_all ON public.consent_records
    FOR ALL USING (user_id = auth.uid());
DROP POLICY IF EXISTS consent_records_admin_select ON public.consent_records;
CREATE POLICY consent_records_admin_select ON public.consent_records
    FOR SELECT USING (public.is_admin());

-- user_events
DROP POLICY IF EXISTS user_events_insert_auth ON public.user_events;
CREATE POLICY user_events_insert_auth ON public.user_events
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
DROP POLICY IF EXISTS user_events_select_own ON public.user_events;
CREATE POLICY user_events_select_own ON public.user_events
    FOR SELECT USING (user_id = auth.uid());
DROP POLICY IF EXISTS user_events_admin_all ON public.user_events;
CREATE POLICY user_events_admin_all ON public.user_events
    FOR ALL USING (public.is_admin());

-- feature_flags
DROP POLICY IF EXISTS feature_flags_select_all ON public.feature_flags;
CREATE POLICY feature_flags_select_all ON public.feature_flags
    FOR SELECT USING (true);

-- provider_campaigns
DROP POLICY IF EXISTS provider_campaigns_select_active ON public.provider_campaigns;
CREATE POLICY provider_campaigns_select_active ON public.provider_campaigns
    FOR SELECT USING (
        status = 'active'
        AND starts_at <= NOW()
        AND ends_at >= NOW()
    );
DROP POLICY IF EXISTS provider_campaigns_admin_all ON public.provider_campaigns;
CREATE POLICY provider_campaigns_admin_all ON public.provider_campaigns
    FOR ALL USING (public.is_admin());

-- referral_codes
DROP POLICY IF EXISTS referral_codes_select_active ON public.referral_codes;
CREATE POLICY referral_codes_select_active ON public.referral_codes
    FOR SELECT USING (is_active = TRUE);
DROP POLICY IF EXISTS referral_codes_select_own ON public.referral_codes;
CREATE POLICY referral_codes_select_own ON public.referral_codes
    FOR SELECT USING (owner_user_id = auth.uid());
DROP POLICY IF EXISTS referral_codes_admin_all ON public.referral_codes;
CREATE POLICY referral_codes_admin_all ON public.referral_codes
    FOR ALL USING (public.is_admin());

-- ai_chat_sessions
DROP POLICY IF EXISTS ai_chat_sessions_own_all ON public.ai_chat_sessions;
CREATE POLICY ai_chat_sessions_own_all ON public.ai_chat_sessions
    FOR ALL USING (user_id = auth.uid());

-- appointments
DROP POLICY IF EXISTS appointments_user_all ON public.appointments;
CREATE POLICY appointments_user_all ON public.appointments
    FOR ALL USING (user_id = auth.uid());
DROP POLICY IF EXISTS appointments_provider_select ON public.appointments;
CREATE POLICY appointments_provider_select ON public.appointments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.providers p
            WHERE p.id = provider_id
              AND p.claimed_by = auth.uid()
        )
    );
DROP POLICY IF EXISTS appointments_admin_all ON public.appointments;
CREATE POLICY appointments_admin_all ON public.appointments
    FOR ALL USING (public.is_admin());

-- contact_requests
DROP POLICY IF EXISTS contact_requests_insert_auth ON public.contact_requests;
CREATE POLICY contact_requests_insert_auth ON public.contact_requests
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
DROP POLICY IF EXISTS contact_requests_admin_all ON public.contact_requests;
CREATE POLICY contact_requests_admin_all ON public.contact_requests
    FOR ALL USING (public.is_admin());

-- proof_hashes
DROP POLICY IF EXISTS proof_hashes_admin_only ON public.proof_hashes;
CREATE POLICY proof_hashes_admin_only ON public.proof_hashes
    FOR ALL USING (public.is_admin());

-- failed_verifications
DROP POLICY IF EXISTS failed_verifications_admin_only ON public.failed_verifications;
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
DROP POLICY IF EXISTS storage_verification_upload_own ON storage.objects;
CREATE POLICY storage_verification_upload_own ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'verification-proofs'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS storage_verification_read_own_or_admin ON storage.objects;
CREATE POLICY storage_verification_read_own_or_admin ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'verification-proofs'
        AND (
            auth.uid()::text = (storage.foldername(name))[1]
            OR public.is_admin()
        )
    );

DROP POLICY IF EXISTS storage_avatars_upload_own ON storage.objects;
CREATE POLICY storage_avatars_upload_own ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS storage_avatars_public_read ON storage.objects;
CREATE POLICY storage_avatars_public_read ON storage.objects
    FOR SELECT TO public
    USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS storage_provider_photos_admin_upload ON storage.objects;
CREATE POLICY storage_provider_photos_admin_upload ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'provider-photos' AND public.is_admin());

DROP POLICY IF EXISTS storage_provider_photos_public_read ON storage.objects;
CREATE POLICY storage_provider_photos_public_read ON storage.objects
    FOR SELECT TO public
    USING (bucket_id = 'provider-photos');

DROP POLICY IF EXISTS storage_claim_documents_upload_own ON storage.objects;
CREATE POLICY storage_claim_documents_upload_own ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'claim-documents'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS storage_claim_documents_admin_read ON storage.objects;
CREATE POLICY storage_claim_documents_admin_read ON storage.objects
    FOR SELECT TO authenticated
    USING (bucket_id = 'claim-documents' AND public.is_admin());

DROP POLICY IF EXISTS storage_review_media_upload_own ON storage.objects;
CREATE POLICY storage_review_media_upload_own ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'review-media'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS storage_review_media_public_read ON storage.objects;
CREATE POLICY storage_review_media_public_read ON storage.objects
    FOR SELECT TO public
    USING (bucket_id = 'review-media');

DROP POLICY IF EXISTS storage_review_media_delete_own ON storage.objects;
CREATE POLICY storage_review_media_delete_own ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'review-media'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS storage_review_media_admin_all ON storage.objects;
CREATE POLICY storage_review_media_admin_all ON storage.objects
    FOR ALL TO authenticated
    USING (bucket_id = 'review-media' AND public.is_admin())
    WITH CHECK (bucket_id = 'review-media' AND public.is_admin());
-- Review verification webhook trigger

CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE OR REPLACE FUNCTION public.trigger_verify_review()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    base_url TEXT := COALESCE(current_setting('app.settings.supabase_url', true), 'http://127.0.0.1:54321');
    service_key TEXT := current_setting('app.settings.service_role_key', true);
BEGIN
    IF NEW.proof_image_url IS NULL THEN
        RETURN NEW;
    END IF;

    PERFORM net.http_post(
        url := base_url || '/functions/v1/verify-review',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || COALESCE(service_key, '')
        ),
        body := jsonb_build_object('review_id', NEW.id)
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS reviews_verify_trigger ON public.reviews;

CREATE TRIGGER reviews_verify_trigger
AFTER INSERT ON public.reviews
FOR EACH ROW
WHEN (NEW.proof_image_url IS NOT NULL)
EXECUTE FUNCTION public.trigger_verify_review();
-- Add unique constraint for failed_verifications upserts

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'failed_verifications_review_id_key'
    ) THEN
        ALTER TABLE public.failed_verifications
        ADD CONSTRAINT failed_verifications_review_id_key UNIQUE (review_id);
    END IF;
END;
$$;
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
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS email TEXT;

UPDATE public.profiles p
SET email = u.email
FROM auth.users u
WHERE p.id = u.id
  AND (p.email IS NULL OR p.email = '');

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

    INSERT INTO public.profiles (id, full_name, avatar_url, referral_code, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
        new_referral_code,
        NEW.email
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$;
CREATE OR REPLACE FUNCTION search_providers(
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
        AND (country_filter IS NULL OR p.country_code = country_filter)
        AND (price_level_filter IS NULL OR p.price_level_avg >= price_level_filter)
        AND (verified_only IS FALSE OR p.verified_review_count > 0)
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
-- Seed data for TrustCare

-- Disable spam check triggers temporarily for seed data
ALTER TABLE public.providers DISABLE TRIGGER check_provider_spam;
ALTER TABLE public.reviews DISABLE TRIGGER check_review_spam;

-- Delete existing seed data to make migration idempotent
DELETE FROM public.providers WHERE name IN (
    'Harbor View Clinic',
    'Spree Medical Center',
    'Canal Health Group',
    'Vistula Care',
    'Cukurova Health',
    'San Francisco Orthopedic Institute'
);

DELETE FROM auth.users WHERE id IN (
    '123e4567-e89b-12d3-a456-426614174000',
    '223e4567-e89b-12d3-a456-426614174000',
    '323e4567-e89b-12d3-a456-426614174000'
);

INSERT INTO public.specialties (name_key, name_en, name_de, name_nl, name_pl, name_tr, name_ar, icon_name, display_order, is_active)
VALUES
    ('general_practice', 'General Practice', 'Allgemeinmedizin', 'Huisarts', 'Medycyna rodzinna', 'Aile Hekimligi', 'طب عام', 'stethoscope', 1, TRUE),
    ('dentist', 'Dentist', 'Zahnarzt', 'Tandarts', 'Dentysta', 'Dis Hekimi', 'طب الاسنان', 'mouth', 2, TRUE),
    ('cardiologist', 'Cardiologist', 'Kardiologe', 'Cardioloog', 'Kardiolog', 'Kardiyolog', 'طبيب قلب', 'heart', 3, TRUE),
    ('dermatologist', 'Dermatologist', 'Dermatologe', 'Dermatoloog', 'Dermatolog', 'Dermatolog', 'طبيب جلدية', 'sun.max', 4, TRUE),
    ('pediatrician', 'Pediatrician', 'Kinderarzt', 'Kinderarts', 'Pediatra', 'Cocuk Doktoru', 'طب الاطفال', 'figure.and.child.holdinghands', 5, TRUE),
    ('orthopedic', 'Orthopedic', 'Orthopaede', 'Orthopedist', 'Ortopeda', 'Ortopedist', 'جراحة العظام', 'figure.walk', 6, TRUE),
    ('gynecologist', 'Gynecologist', 'Gynaekologe', 'Gynaecoloog', 'Ginekolog', 'Jinekolog', 'طب النساء', 'figure.stand', 7, TRUE),
    ('psychiatrist', 'Psychiatrist', 'Psychiater', 'Psychiater', 'Psychiatra', 'Psikiyatrist', 'طب نفسي', 'brain.head.profile', 8, TRUE),
    ('ophthalmologist', 'Ophthalmologist', 'Augenarzt', 'Oogarts', 'Okulista', 'Goz Doktoru', 'طب العيون', 'eye', 9, TRUE),
    ('ent', 'ENT', 'HNO-Arzt', 'KNO-arts', 'Laryngolog', 'Kulak Burun Bogaz', 'انف واذن وحنجرة', 'ear', 10, TRUE)
ON CONFLICT (name_key) DO NOTHING;

INSERT INTO public.providers (
    name,
    specialty,
    clinic_name,
    address,
    city,
    country_code,
    latitude,
    longitude,
    phone,
    email,
    website,
    languages_spoken,
    is_active,
    is_featured,
    subscription_tier
)
VALUES
    ('Harbor View Clinic', 'General Practice', 'Harbor View Clinic', '12 King Street', 'London', 'GB', 51.5074, -0.1278, '+44 20 7946 0101', 'hello@harborviewclinic.co.uk', 'https://harborviewclinic.co.uk', ARRAY['English'], TRUE, TRUE, 'basic'),
    ('Spree Medical Center', 'Cardiologist', 'Spree Medical Center', 'Friedrichstrasse 88', 'Berlin', 'DE', 52.5200, 13.4050, '+49 30 1234 5678', 'kontakt@spreemedical.de', 'https://spreemedical.de', ARRAY['Deutsch', 'English'], TRUE, FALSE, 'free'),
    ('Canal Health Group', 'Dermatologist', 'Canal Health Group', 'Prinsengracht 120', 'Amsterdam', 'NL', 52.3676, 4.9041, '+31 20 555 1234', 'info@canalhealth.nl', 'https://canalhealth.nl', ARRAY['Nederlands', 'English'], TRUE, FALSE, 'free'),
    ('Vistula Care', 'Pediatrician', 'Vistula Care', 'Nowy Swiat 25', 'Warsaw', 'PL', 52.2297, 21.0122, '+48 22 555 9876', 'kontakt@vistulacare.pl', 'https://vistulacare.pl', ARRAY['Polski', 'English'], TRUE, FALSE, 'free'),
    ('Cukurova Health', 'Orthopedic', 'Cukurova Health', 'Ataturk Caddesi 45', 'Adana', 'TR', 37.0000, 35.3213, '+90 322 555 4321', 'iletisim@cukurovahealth.com', 'https://cukurovahealth.com', ARRAY['Turkce', 'English'], TRUE, FALSE, 'free');

-- San Francisco orthopedic clinic sample data (all public tables)
INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    aud,
    role,
    created_at,
    updated_at
)
VALUES
    (
        '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
        '00000000-0000-0000-0000-000000000000',
        'owner.sf.ortho@trustcare.dev',
        '$2a$10$CwTycUXWue0Thq9StjUM0uJ8bP0uH/.N/7eXQp6o0n/lbS0w2J4q2',
        NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Dr. Elena Harper","avatar_url":"https://images.unsplash.com/photo-1559839734-2b71ea197ec2"}'::jsonb,
        'authenticated',
        'authenticated',
        NOW(),
        NOW()
    ),
    (
        '1b2c3d4e-5f60-789a-bcde-f0123456789a',
        '00000000-0000-0000-0000-000000000000',
        'patient.sf.ortho@trustcare.dev',
        '$2a$10$CwTycUXWue0Thq9StjUM0uJ8bP0uH/.N/7eXQp6o0n/lbS0w2J4q2',
        NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Jordan Lee","avatar_url":"https://images.unsplash.com/photo-1524504388940-b1c1722653e1"}'::jsonb,
        'authenticated',
        'authenticated',
        NOW(),
        NOW()
    )
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (
    id,
    full_name,
    avatar_url,
    phone,
    country_code,
    preferred_language,
    preferred_currency,
    date_of_birth
)
VALUES
    (
        '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
        'Dr. Elena Harper',
        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2',
        '+1 415 555 0131',
        'US',
        'en',
        'USD',
        '1984-06-12'
    ),
    (
        '1b2c3d4e-5f60-789a-bcde-f0123456789a',
        'Jordan Lee',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1',
        '+1 415 555 0199',
        'US',
        'en',
        'USD',
        '1992-03-04'
    )
ON CONFLICT (id) DO UPDATE
SET
    full_name = EXCLUDED.full_name,
    avatar_url = EXCLUDED.avatar_url,
    phone = EXCLUDED.phone,
    country_code = EXCLUDED.country_code,
    preferred_language = EXCLUDED.preferred_language,
    preferred_currency = EXCLUDED.preferred_currency,
    date_of_birth = EXCLUDED.date_of_birth;

INSERT INTO public.user_roles (id, user_id, role)
VALUES
    ('2c3d4e5f-6071-89ab-cdef-0123456789ab', '0a1b2c3d-4e5f-6789-abcd-ef0123456789', 'user')
ON CONFLICT (user_id, role) DO NOTHING;

INSERT INTO public.providers (
    id,
    name,
    specialty,
    clinic_name,
    address,
    city,
    country_code,
    latitude,
    longitude,
    phone,
    email,
    website,
    photo_url,
    cover_url,
    languages_spoken,
    subscription_tier,
    is_featured,
    is_claimed,
    claimed_by,
    claimed_at,
    created_by
)
VALUES (
    '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
    'Bayview Orthopedic Institute',
    'Orthopedic',
    'Bayview Orthopedic Institute',
    '650 Market Street, Suite 2100',
    'San Francisco',
    'US',
    37.7749,
    -122.4194,
    '+1 415 555 0110',
    'hello@bayviewortho.com',
    'https://bayviewortho.com',
    'https://images.unsplash.com/photo-1580281658629-7f915f9d87b1',
    'https://images.unsplash.com/photo-1504814532849-927e54f0b3ad',
    ARRAY['English', 'Spanish'],
    'premium',
    TRUE,
    TRUE,
    '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
    NOW() - INTERVAL '14 days',
    '0a1b2c3d-4e5f-6789-abcd-ef0123456789'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.provider_claims (
    id,
    provider_id,
    claimant_user_id,
    claimant_role,
    business_email,
    phone,
    license_number,
    proof_document_url,
    status,
    reviewed_by,
    reviewed_at
)
VALUES (
    '13579bdf-2468-1357-2468-13579bdf2468',
    '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
    '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
    'owner',
    'billing@bayviewortho.com',
    '+1 415 555 0122',
    'CA-ORTHO-44219',
    'https://example.com/claims/bayview-ortho-proof.pdf',
    'approved',
    '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
    NOW() - INTERVAL '10 days'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.provider_subscriptions (
    id,
    provider_id,
    user_id,
    tier,
    status,
    started_at,
    expires_at,
    auto_renew,
    payment_provider,
    payment_reference,
    monthly_price_cents,
    currency
)
VALUES (
    '2468ace0-1357-2468-1357-2468ace01357',
    '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
    '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
    'premium',
    'active',
    NOW() - INTERVAL '21 days',
    NOW() + INTERVAL '11 months',
    TRUE,
    'stripe',
    'sub_ortho_sf_2026',
    19900,
    'USD'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.provider_services (
    id,
    provider_id,
    category,
    name,
    description,
    price_min,
    price_max,
    currency,
    duration_minutes,
    display_order
)
VALUES
    (
        'f1f1f1f1-1111-2222-3333-444444444444',
        '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
        'Consultation',
        'Orthopedic Consultation',
        'Comprehensive orthopedic evaluation with imaging review.',
        250.00,
        350.00,
        'USD',
        45,
        1
    ),
    (
        'f2f2f2f2-2222-3333-4444-555555555555',
        '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
        'Imaging',
        'Knee MRI Review',
        'Specialist interpretation with treatment recommendations.',
        180.00,
        240.00,
        'USD',
        30,
        2
    ),
    (
        'f3f3f3f3-3333-4444-5555-666666666666',
        '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
        'Rehab',
        'Post-Surgery Recovery Plan',
        'Personalized rehabilitation plan and follow-up check-ins.',
        320.00,
        420.00,
        'USD',
        60,
        3
    )
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.reviews (
    id,
    user_id,
    provider_id,
    visit_date,
    visit_type,
    rating_wait_time,
    rating_bedside,
    rating_efficacy,
    rating_cleanliness,
    rating_overall,
    price_level,
    title,
    comment,
    would_recommend,
    proof_image_url,
    is_verified,
    verification_confidence,
    status,
    helpful_count,
    created_at
)
VALUES
    (
        '12345678-1234-1234-1234-1234567890ab',
        '1b2c3d4e-5f60-789a-bcde-f0123456789a',
        '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
        CURRENT_DATE - INTERVAL '120 days',
        'consultation',
        4,
        5,
        5,
        4,
        4.5,
        3,
        'Clear plan and calm team',
        'Dr. Harper reviewed my MRI in detail, explained next steps clearly, and the staff made the whole visit smooth and reassuring.',
        TRUE,
        'https://example.com/proofs/bayview-ortho-visit.jpg',
        FALSE,
        NULL,
        'pending_verification',
        3,
        NOW() - INTERVAL '118 days'
    ),
    (
        'abcdefab-cdef-cdef-cdef-abcdefabcdef',
        '1b2c3d4e-5f60-789a-bcde-f0123456789a',
        '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
        CURRENT_DATE - INTERVAL '30 days',
        'procedure',
        5,
        5,
        4,
        5,
        4.8,
        3,
        'Excellent post-op follow-up',
        'Follow-up was thorough and proactive, and the recovery plan felt tailored to my lifestyle with helpful check-ins.',
        TRUE,
        NULL,
        FALSE,
        NULL,
        'active',
        1,
        NOW() - INTERVAL '28 days'
    )
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.review_media (
    id,
    review_id,
    user_id,
    media_type,
    storage_path,
    url,
    thumbnail_url,
    file_size_bytes,
    width,
    height,
    display_order
)
VALUES
    (
        '11111111-aaaa-bbbb-cccc-111111111111',
        '12345678-1234-1234-1234-1234567890ab',
        '1b2c3d4e-5f60-789a-bcde-f0123456789a',
        'image',
        'reviews/12345678-1234-1234-1234-1234567890ab/proof-1.jpg',
        'https://example.com/media/bayview-ortho-proof-1.jpg',
        'https://example.com/media/bayview-ortho-proof-1-thumb.jpg',
        182340,
        1280,
        960,
        1
    ),
    (
        '22222222-bbbb-cccc-dddd-222222222222',
        '12345678-1234-1234-1234-1234567890ab',
        '1b2c3d4e-5f60-789a-bcde-f0123456789a',
        'image',
        'reviews/12345678-1234-1234-1234-1234567890ab/proof-2.jpg',
        'https://example.com/media/bayview-ortho-proof-2.jpg',
        'https://example.com/media/bayview-ortho-proof-2-thumb.jpg',
        168004,
        1280,
        960,
        2
    )
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.review_votes (id, review_id, user_id, is_helpful)
VALUES (
    '33333333-cccc-dddd-eeee-333333333333',
    '12345678-1234-1234-1234-1234567890ab',
    '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
    TRUE
)
ON CONFLICT (review_id, user_id) DO NOTHING;

INSERT INTO public.reported_reviews (id, review_id, reporter_id, reason, description, status)
VALUES (
    '44444444-dddd-eeee-ffff-444444444444',
    'abcdefab-cdef-cdef-cdef-abcdefabcdef',
    '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
    'other',
    'Follow-up looks accurate but requires additional clinic verification.',
    'pending'
)
ON CONFLICT (review_id, reporter_id) DO NOTHING;

INSERT INTO public.proof_hashes (id, review_id, image_hash, file_size_bytes)
VALUES (
    '55555555-eeee-ffff-aaaa-555555555555',
    '12345678-1234-1234-1234-1234567890ab',
    'b6a1f2d3e4c5a6b7c8d9e0f1a2b3c4d5',
    182340
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.failed_verifications (id, review_id, error_message, retry_count, resolved)
VALUES (
    '66666666-ffff-aaaa-bbbb-666666666666',
    '12345678-1234-1234-1234-1234567890ab',
    'Vision API timeout during initial scan.',
    1,
    FALSE
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.notifications (id, user_id, type, title, body, data, is_read)
VALUES (
    '77777777-aaaa-bbbb-cccc-777777777777',
    '1b2c3d4e-5f60-789a-bcde-f0123456789a',
    'review_verified',
    'Review verified',
    'Your Bayview Orthopedic Institute review was verified.',
    '{"provider_id":"0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11"}'::jsonb,
    FALSE
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.consent_records (id, user_id, consent_type, version, granted, granted_at)
VALUES
    (
        '88888888-bbbb-cccc-dddd-888888888888',
        '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
        'terms_of_service',
        'v1',
        TRUE,
        NOW() - INTERVAL '30 days'
    ),
    (
        '99999999-cccc-dddd-eeee-999999999999',
        '1b2c3d4e-5f60-789a-bcde-f0123456789a',
        'privacy_policy',
        'v1',
        TRUE,
        NOW() - INTERVAL '30 days'
    )
ON CONFLICT (user_id, consent_type, version) DO NOTHING;

INSERT INTO public.user_events (id, user_id, event_type, event_data, device_info, app_version, session_id)
VALUES (
    'aaaaaaaa-dddd-eeee-ffff-aaaaaaaaaaaa',
    '1b2c3d4e-5f60-789a-bcde-f0123456789a',
    'review_submitted',
    '{"provider_id":"0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11","channel":"ios"}'::jsonb,
    'iPhone 15 Pro',
    '1.0.0',
    'sess_sf_ortho_001'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.provider_campaigns (
    id,
    provider_id,
    campaign_type,
    title,
    description,
    budget_cents,
    currency,
    starts_at,
    ends_at,
    status,
    impressions,
    clicks
)
VALUES (
    'bbbbbbbb-eeee-ffff-aaaa-bbbbbbbbbbbb',
    '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
    'featured_listing',
    'San Francisco Orthopedic Launch',
    'Featured placement for orthopedic launch campaign.',
    50000,
    'USD',
    NOW() - INTERVAL '7 days',
    NOW() + INTERVAL '30 days',
    'active',
    1240,
    84
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.referral_codes (
    id,
    code,
    owner_type,
    owner_provider_id,
    description,
    usage_count,
    max_uses,
    is_active,
    expires_at
)
VALUES (
    'cccccccc-ffff-aaaa-bbbb-cccccccccccc',
    'SFORTHO20',
    'provider',
    '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
    '20 USD off first orthopedic consultation.',
    3,
    100,
    TRUE,
    NOW() + INTERVAL '6 months'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.ai_chat_sessions (id, user_id, title, messages)
VALUES (
    'dddddddd-aaaa-bbbb-cccc-dddddddddddd',
    '1b2c3d4e-5f60-789a-bcde-f0123456789a',
    'Knee pain guidance',
    '[{"role":"user","content":"Looking for an orthopedic specialist in San Francisco."}]'::jsonb
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.appointments (
    id,
    provider_id,
    user_id,
    requested_date,
    requested_time,
    reason,
    insurance_info,
    status
)
VALUES (
    'eeeeeeee-bbbb-cccc-dddd-eeeeeeeeeeee',
    '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
    '1b2c3d4e-5f60-789a-bcde-f0123456789a',
    CURRENT_DATE + INTERVAL '10 days',
    '10:30:00',
    'Follow-up knee pain assessment',
    'Blue Shield PPO',
    'requested'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.contact_requests (
    id,
    provider_id,
    user_id,
    name,
    email,
    phone,
    message,
    is_read
)
VALUES (
    'ffffffff-cccc-dddd-eeee-ffffffffffff',
    '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
    '1b2c3d4e-5f60-789a-bcde-f0123456789a',
    'Jordan Lee',
    'patient.sf.ortho@trustcare.dev',
    '+1 415 555 0199',
    'Interested in booking a consultation for knee pain and recovery planning.',
    FALSE
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.feature_flags (flag_name, description, is_enabled, rollout_percentage)
VALUES
    ('ai_verification', 'AI verification of review proofs', TRUE, 100),
    ('video_reviews', 'Video review uploads', TRUE, 100),
    ('ai_health_chat', 'AI health chat assistant', FALSE, 0),
    ('campaigns', 'Provider marketing campaigns', FALSE, 0),
    ('appointments', 'Appointment requests', FALSE, 0),
    ('push_notifications', 'Push notifications', FALSE, 0)
ON CONFLICT (flag_name) DO NOTHING;


-- Re-enable spam check triggers
ALTER TABLE public.providers ENABLE TRIGGER check_provider_spam;
ALTER TABLE public.reviews ENABLE TRIGGER check_review_spam;
CREATE OR REPLACE FUNCTION search_providers(
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
        AND (country_filter IS NULL OR p.country_code = country_filter)
        AND (price_level_filter IS NULL OR p.price_level_avg >= price_level_filter)
        AND (verified_only IS FALSE OR p.verified_review_count > 0)
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
