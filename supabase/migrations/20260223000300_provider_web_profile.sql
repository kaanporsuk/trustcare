-- ================================================================
-- PROVIDER WEB PROFILE MIGRATION
-- Adds slug, description, gallery, hours, social links, SEO fields
-- ================================================================

-- 1. ADD NEW COLUMNS TO PROVIDERS TABLE
ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS slug TEXT;
ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS gallery_urls TEXT[] DEFAULT '{}';
ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS opening_hours JSONB;
ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS social_links JSONB DEFAULT '{}';
ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS meta_title TEXT;
ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS meta_description TEXT;

-- Add unique constraint on slug (allowing NULL for now during backfill)
ALTER TABLE public.providers DROP CONSTRAINT IF EXISTS providers_slug_unique;
ALTER TABLE public.providers ADD CONSTRAINT providers_slug_unique UNIQUE (slug);

-- 2. CREATE SLUG GENERATION FUNCTION
CREATE OR REPLACE FUNCTION public.generate_provider_slug(provider_name TEXT, city TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    base_slug TEXT;
    candidate_slug TEXT;
    slug_exists BOOLEAN;
    random_suffix TEXT;
    attempt_count INTEGER := 0;
BEGIN
    -- Normalize the input: lowercase and combine name + city
    base_slug := LOWER(TRIM(COALESCE(provider_name, '') || ' ' || COALESCE(city, '')));
    
    -- Replace Turkish special characters
    base_slug := REPLACE(base_slug, 'ş', 's');
    base_slug := REPLACE(base_slug, 'ğ', 'g');
    base_slug := REPLACE(base_slug, 'ü', 'u');
    base_slug := REPLACE(base_slug, 'ö', 'o');
    base_slug := REPLACE(base_slug, 'ç', 'c');
    base_slug := REPLACE(base_slug, 'ı', 'i');
    base_slug := REPLACE(base_slug, 'İ', 'i');
    
    -- Replace German special characters
    base_slug := REPLACE(base_slug, 'ä', 'a');
    base_slug := REPLACE(base_slug, 'ß', 'ss');
    
    -- Replace Polish special characters
    base_slug := REPLACE(base_slug, 'ł', 'l');
    base_slug := REPLACE(base_slug, 'ż', 'z');
    base_slug := REPLACE(base_slug, 'ź', 'z');
    base_slug := REPLACE(base_slug, 'ń', 'n');
    base_slug := REPLACE(base_slug, 'ą', 'a');
    base_slug := REPLACE(base_slug, 'ę', 'e');
    base_slug := REPLACE(base_slug, 'ć', 'c');
    base_slug := REPLACE(base_slug, 'ś', 's');
    
    -- Replace spaces and special characters with hyphens
    base_slug := REGEXP_REPLACE(base_slug, '[^a-z0-9]+', '-', 'g');
    
    -- Remove consecutive hyphens
    base_slug := REGEXP_REPLACE(base_slug, '-+', '-', 'g');
    
    -- Trim leading/trailing hyphens
    base_slug := TRIM(BOTH '-' FROM base_slug);
    
    -- If empty after cleanup, use a default
    IF base_slug = '' OR base_slug IS NULL THEN
        base_slug := 'provider';
    END IF;
    
    candidate_slug := base_slug;
    
    -- Check if slug exists and add random suffix if needed
    LOOP
        SELECT EXISTS(
            SELECT 1 FROM public.providers WHERE slug = candidate_slug
        ) INTO slug_exists;
        
        EXIT WHEN NOT slug_exists OR attempt_count > 10;
        
        -- Generate 4-character random suffix (alphanumeric lowercase)
        random_suffix := LOWER(SUBSTRING(MD5(RANDOM()::TEXT || NOW()::TEXT) FROM 1 FOR 4));
        candidate_slug := base_slug || '-' || random_suffix;
        attempt_count := attempt_count + 1;
    END LOOP;
    
    RETURN candidate_slug;
END;
$$;

-- 3. CREATE TRIGGER FOR AUTO-GENERATING SLUG ON INSERT
DROP TRIGGER IF EXISTS trigger_auto_generate_slug ON public.providers;

CREATE OR REPLACE FUNCTION public.auto_generate_slug_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.slug IS NULL OR NEW.slug = '' THEN
        NEW.slug := public.generate_provider_slug(NEW.name, NEW.city);
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_auto_generate_slug
BEFORE INSERT ON public.providers
FOR EACH ROW
EXECUTE FUNCTION public.auto_generate_slug_trigger();

-- 4. BACKFILL SLUGS FOR EXISTING PROVIDERS
DO $$
DECLARE
    provider_record RECORD;
    new_slug TEXT;
BEGIN
    FOR provider_record IN 
        SELECT id, name, city FROM public.providers WHERE slug IS NULL
    LOOP
        new_slug := public.generate_provider_slug(provider_record.name, provider_record.city);
        UPDATE public.providers SET slug = new_slug WHERE id = provider_record.id;
    END LOOP;
END;
$$;

-- 5. ENSURE RLS POLICY FOR PUBLIC SLUG LOOKUP
-- Drop existing public select policy if it exists and recreate with new columns
DROP POLICY IF EXISTS providers_public_select ON public.providers;

CREATE POLICY providers_public_select
ON public.providers
FOR SELECT
TO anon, authenticated
USING (is_active = TRUE AND deleted_at IS NULL);

-- 6. CREATE PUBLIC RPC FUNCTION TO GET PROVIDER BY SLUG
CREATE OR REPLACE FUNCTION public.get_provider_by_slug(provider_slug TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    provider_data JSON;
    provider_id_var UUID;
BEGIN
    -- Check if provider exists
    SELECT id INTO provider_id_var
    FROM public.providers
    WHERE slug = provider_slug
      AND is_active = TRUE
      AND deleted_at IS NULL;
    
    IF provider_id_var IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Build complete provider JSON with services and reviews
    SELECT json_build_object(
        'provider', (
            SELECT row_to_json(p.*)
            FROM public.providers p
            WHERE p.id = provider_id_var
        ),
        'services', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'id', ps.id,
                    'name', ps.name,
                    'description', ps.description,
                    'price', ps.price,
                    'currency', ps.currency,
                    'duration_minutes', ps.duration_minutes,
                    'is_active', ps.is_active,
                    'display_order', ps.display_order,
                    'created_at', ps.created_at
                )
                ORDER BY ps.display_order, ps.name
            ), '[]'::json)
            FROM public.provider_services ps
            WHERE ps.provider_id = provider_id_var
              AND ps.is_active = TRUE
              AND ps.deleted_at IS NULL
        ),
        'reviews', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'id', r.id,
                    'user_id', r.user_id,
                    'rating_overall', r.rating_overall,
                    'rating_wait_time', r.rating_wait_time,
                    'rating_bedside', r.rating_bedside,
                    'rating_efficacy', r.rating_efficacy,
                    'rating_cleanliness', r.rating_cleanliness,
                    'comment', r.comment,
                    'visit_date', r.visit_date,
                    'is_verified', r.is_verified,
                    'created_at', r.created_at,
                    'price_level', r.price_level,
                    'reviewer', json_build_object(
                        'full_name', prof.full_name,
                        'avatar_url', prof.avatar_url
                    )
                )
                ORDER BY r.created_at DESC
            ), '[]'::json)
            FROM public.reviews r
            LEFT JOIN public.profiles prof ON prof.id = r.user_id
            WHERE r.provider_id = provider_id_var
              AND r.status = 'active'
              AND r.deleted_at IS NULL
            LIMIT 20
        )
    ) INTO provider_data;
    
    RETURN provider_data;
END;
$$;

-- Grant public access to the RPC function
GRANT EXECUTE ON FUNCTION public.get_provider_by_slug(TEXT) TO anon, authenticated;

-- Create index on slug for fast lookups
CREATE INDEX IF NOT EXISTS providers_slug_idx ON public.providers (slug) WHERE slug IS NOT NULL;
CREATE INDEX IF NOT EXISTS providers_active_slug_idx ON public.providers (slug, is_active) WHERE is_active = TRUE AND deleted_at IS NULL;

-- Add comments for documentation
COMMENT ON COLUMN public.providers.slug IS 'URL-friendly identifier for public web profiles';
COMMENT ON COLUMN public.providers.description IS 'Provider self-description for claimed profiles';
COMMENT ON COLUMN public.providers.gallery_urls IS 'Array of photo URLs for provider gallery';
COMMENT ON COLUMN public.providers.opening_hours IS 'Structured operating hours (JSONB)';
COMMENT ON COLUMN public.providers.social_links IS 'Social media links and website';
COMMENT ON COLUMN public.providers.meta_title IS 'Custom SEO title (falls back to name)';
COMMENT ON COLUMN public.providers.meta_description IS 'Custom SEO description';
COMMENT ON FUNCTION public.generate_provider_slug(TEXT, TEXT) IS 'Generates URL-friendly slug from provider name and city';
COMMENT ON FUNCTION public.get_provider_by_slug(TEXT) IS 'Public RPC to fetch provider with services and reviews by slug';
