-- 1. FIX REHBER CRASH: Add the missing 'title' column
ALTER TABLE rehber_sessions ADD COLUMN IF NOT EXISTS title TEXT DEFAULT 'Yeni Sohbet';

-- 2. FIX REVIEW CRASH: Create the missing storage buckets
INSERT INTO storage.buckets (id, name, public)
VALUES ('review-photos', 'review-photos', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('verification-proofs', 'verification-proofs', false)
ON CONFLICT (id) DO NOTHING;

-- 3. SET UP STORAGE POLICIES: Allow authenticated users to upload
DROP POLICY IF EXISTS "Anyone can view review photos" ON storage.objects;
CREATE POLICY "Anyone can view review photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'review-photos');

DROP POLICY IF EXISTS "Authenticated users can upload review photos" ON storage.objects;
CREATE POLICY "Authenticated users can upload review photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'review-photos');

DROP POLICY IF EXISTS "Authenticated users can upload proofs" ON storage.objects;
CREATE POLICY "Authenticated users can upload proofs"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'verification-proofs');
