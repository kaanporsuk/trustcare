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
