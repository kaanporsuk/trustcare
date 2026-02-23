-- Language support update: remove Arabic from app usage, add Danish.
-- Keep existing name_ar column untouched for backward compatibility.

ALTER TABLE specialties
ADD COLUMN IF NOT EXISTS name_da TEXT;

ALTER TABLE specialties
ADD COLUMN IF NOT EXISTS name_de TEXT;

ALTER TABLE specialties
ADD COLUMN IF NOT EXISTS name_nl TEXT;

ALTER TABLE specialties
ADD COLUMN IF NOT EXISTS name_pl TEXT;

-- profiles.preferred_language is expected to be TEXT; no constraint change required.
DO $$
DECLARE
    column_data_type text;
BEGIN
    SELECT data_type
    INTO column_data_type
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'profiles'
      AND column_name = 'preferred_language';

    IF column_data_type IS NULL THEN
        RAISE NOTICE 'profiles.preferred_language column not found.';
    ELSIF column_data_type <> 'text' THEN
        RAISE NOTICE 'profiles.preferred_language is %, expected text.', column_data_type;
    ELSE
        RAISE NOTICE 'profiles.preferred_language is text and accepts ''da'' values.';
    END IF;
END $$;