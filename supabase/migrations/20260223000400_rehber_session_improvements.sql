-- Add DELETE policy for rehber_sessions to allow users to delete their own sessions
DROP POLICY IF EXISTS rehber_sessions_delete_own ON public.rehber_sessions;
CREATE POLICY rehber_sessions_delete_own ON public.rehber_sessions
FOR DELETE USING (user_id = auth.uid());

-- Ensure updated_at column exists
ALTER TABLE public.rehber_sessions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- Ensure has_emergency column exists (backwards compatibility check)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'rehber_sessions' 
        AND column_name = 'has_emergency'
    ) THEN
        -- If has_emergency doesn't exist but was_emergency does, add it as an alias
        -- The mobile app uses 'was_emergency' so we keep that as the source of truth
        ALTER TABLE public.rehber_sessions 
        ADD COLUMN IF NOT EXISTS has_emergency BOOLEAN 
        GENERATED ALWAYS AS (was_emergency) STORED;
    END IF;
END $$;

-- Add index for faster session queries
CREATE INDEX IF NOT EXISTS idx_rehber_sessions_user_updated 
ON public.rehber_sessions (user_id, updated_at DESC);

-- Add index for faster message queries
CREATE INDEX IF NOT EXISTS idx_rehber_messages_session_created 
ON public.rehber_messages (session_id, created_at ASC);
