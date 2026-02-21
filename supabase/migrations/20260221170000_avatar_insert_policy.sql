DROP POLICY IF EXISTS "Avatar all access" ON storage.objects;
CREATE POLICY "Avatar all access"
ON storage.objects FOR ALL TO authenticated
USING (bucket_id = 'avatars' AND auth.uid() = owner)
WITH CHECK (bucket_id = 'avatars' AND auth.uid() = owner);
