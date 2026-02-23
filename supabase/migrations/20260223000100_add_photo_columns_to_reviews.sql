-- Add missing columns for photo uploads and verification proofs
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS photo_urls TEXT[] DEFAULT '{}';
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS proof_image_url TEXT;
-- Notify PostgREST to reload the schema cache
NOTIFY pgrst, 'reload schema';
