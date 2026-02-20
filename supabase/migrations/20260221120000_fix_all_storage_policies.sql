-- ================================================================
-- MIGRATION: 20260221120000_fix_all_storage_policies.sql
-- PURPOSE: Ensure all storage buckets exist with correct RLS policies
-- ================================================================

-- ================================
-- SECTION 1: CREATE BUCKETS
-- ================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
    ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png']),
    ('review-media', 'review-media', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/heic', 'video/mp4', 'video/quicktime', 'video/mov']),
    ('verification-proofs', 'verification-proofs', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/heic'])
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ================================
-- SECTION 2: AVATARS BUCKET POLICIES
-- ================================

-- Avatars: Public read (anyone can see profile pictures)
DROP POLICY IF EXISTS storage_avatars_public_read ON storage.objects;
CREATE POLICY storage_avatars_public_read ON storage.objects
    FOR SELECT TO public
    USING (bucket_id = 'avatars');

-- Avatars: Authenticated users can insert their own (uid must match first folder level)
DROP POLICY IF EXISTS storage_avatars_authenticated_insert ON storage.objects;
CREATE POLICY storage_avatars_authenticated_insert ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Avatars: Authenticated users can update their own
DROP POLICY IF EXISTS storage_avatars_authenticated_update ON storage.objects;
CREATE POLICY storage_avatars_authenticated_update ON storage.objects
    FOR UPDATE TO authenticated
    USING (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    )
    WITH CHECK (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Avatars: Authenticated users can delete their own
DROP POLICY IF EXISTS storage_avatars_authenticated_delete ON storage.objects;
CREATE POLICY storage_avatars_authenticated_delete ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- ================================
-- SECTION 3: REVIEW-MEDIA BUCKET POLICIES
-- ================================

-- Review Media: Public read (review media is visible to everyone)
DROP POLICY IF EXISTS storage_review_media_public_read ON storage.objects;
CREATE POLICY storage_review_media_public_read ON storage.objects
    FOR SELECT TO public
    USING (bucket_id = 'review-media');

-- Review Media: Authenticated users can insert their own
DROP POLICY IF EXISTS storage_review_media_authenticated_insert ON storage.objects;
CREATE POLICY storage_review_media_authenticated_insert ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'review-media'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Review Media: Authenticated users can update their own
DROP POLICY IF EXISTS storage_review_media_authenticated_update ON storage.objects;
CREATE POLICY storage_review_media_authenticated_update ON storage.objects
    FOR UPDATE TO authenticated
    USING (
        bucket_id = 'review-media'
        AND auth.uid()::text = (storage.foldername(name))[1]
    )
    WITH CHECK (
        bucket_id = 'review-media'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Review Media: Authenticated users can delete their own
DROP POLICY IF EXISTS storage_review_media_authenticated_delete ON storage.objects;
CREATE POLICY storage_review_media_authenticated_delete ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'review-media'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Review Media: Admins can perform all operations
DROP POLICY IF EXISTS storage_review_media_admin_all ON storage.objects;
CREATE POLICY storage_review_media_admin_all ON storage.objects
    FOR ALL TO authenticated
    USING (bucket_id = 'review-media' AND public.is_admin())
    WITH CHECK (bucket_id = 'review-media' AND public.is_admin());

-- ================================
-- SECTION 4: VERIFICATION-PROOFS BUCKET POLICIES
-- ================================

-- Verification Proofs: Authenticated users can insert their own
DROP POLICY IF EXISTS storage_verification_proofs_authenticated_insert ON storage.objects;
CREATE POLICY storage_verification_proofs_authenticated_insert ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'verification-proofs'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Verification Proofs: Users can read their own + admins read all
DROP POLICY IF EXISTS storage_verification_proofs_select ON storage.objects;
CREATE POLICY storage_verification_proofs_select ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'verification-proofs'
        AND (
            auth.uid()::text = (storage.foldername(name))[1]
            OR public.is_admin()
        )
    );

-- Verification Proofs: Users can update their own
DROP POLICY IF EXISTS storage_verification_proofs_authenticated_update ON storage.objects;
CREATE POLICY storage_verification_proofs_authenticated_update ON storage.objects
    FOR UPDATE TO authenticated
    USING (
        bucket_id = 'verification-proofs'
        AND auth.uid()::text = (storage.foldername(name))[1]
    )
    WITH CHECK (
        bucket_id = 'verification-proofs'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Verification Proofs: Users can delete their own
DROP POLICY IF EXISTS storage_verification_proofs_authenticated_delete ON storage.objects;
CREATE POLICY storage_verification_proofs_authenticated_delete ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'verification-proofs'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- ================================================================
-- END MIGRATION
-- ================================================================
