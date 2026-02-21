-- Drop existing review RLS policies to start clean
DROP POLICY IF EXISTS "Reviews: users can insert own reviews" ON reviews;
DROP POLICY IF EXISTS "Reviews: enable select for authenticated users" ON reviews;
DROP POLICY IF EXISTS "Reviews: enable insert for authenticated users" ON reviews;
DROP POLICY IF EXISTS "Reviews: enable update for authenticated users" ON reviews;

-- Enable RLS on reviews table
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Policy: Public read access (anyone can view reviews)
CREATE POLICY "Reviews: public read access"
ON reviews FOR SELECT
USING (true);

-- Policy: Authenticated users can INSERT their own reviews
CREATE POLICY "Reviews: authenticated insert own reviews"
ON reviews FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Authenticated users can UPDATE their own reviews
CREATE POLICY "Reviews: authenticated update own reviews"
ON reviews FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Authenticated users can DELETE their own reviews
CREATE POLICY "Reviews: authenticated delete own reviews"
ON reviews FOR DELETE
USING (auth.uid() = user_id);
