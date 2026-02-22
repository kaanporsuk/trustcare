DROP POLICY IF EXISTS "Users can view their own reviews" ON reviews;
CREATE POLICY "Users can view their own reviews" 
ON reviews FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);
