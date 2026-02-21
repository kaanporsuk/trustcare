-- ================================================================
-- PART A2: ALTER REVIEWS TABLE FOR DYNAMIC SURVEYS
-- Add survey_type and all possible rating columns
-- ================================================================

-- A2a: Remove old triggers that auto-compute rating_overall
-- These triggers produce garbage results for non-general_clinic reviews
-- where some rating columns are NULL. After this, rating_overall is
-- purely user-supplied.
DROP TRIGGER IF EXISTS trigger_compute_review_overall ON reviews;
DROP FUNCTION IF EXISTS compute_review_overall();
DROP TRIGGER IF EXISTS trigger_calculate_overall ON reviews;
DROP FUNCTION IF EXISTS calculate_overall_rating();

-- A2b: Add survey_type column with CHECK constraint
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS survey_type TEXT;
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS valid_survey_type;
ALTER TABLE reviews ADD CONSTRAINT valid_survey_type
    CHECK (survey_type IS NULL OR survey_type IN (
        'general_clinic', 'dental', 'pharmacy', 'hospital',
        'diagnostic', 'mental_health', 'rehabilitation', 'aesthetics'
    ));

-- A2c: Add all new rating columns (one per unique sub-metric across 8 surveys)
-- Each column is optional (nullable) and restricted to 1-5 range
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_pain_mgmt INTEGER CHECK (rating_pain_mgmt BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_accuracy INTEGER CHECK (rating_accuracy BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_knowledge INTEGER CHECK (rating_knowledge BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_courtesy INTEGER CHECK (rating_courtesy BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_care_quality INTEGER CHECK (rating_care_quality BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_admin INTEGER CHECK (rating_admin BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_comfort INTEGER CHECK (rating_comfort BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_turnaround INTEGER CHECK (rating_turnaround BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_empathy INTEGER CHECK (rating_empathy BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_environment INTEGER CHECK (rating_environment BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_communication INTEGER CHECK (rating_communication BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_effectiveness INTEGER CHECK (rating_effectiveness BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_attentiveness INTEGER CHECK (rating_attentiveness BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_equipment INTEGER CHECK (rating_equipment BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_consultation INTEGER CHECK (rating_consultation BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_results INTEGER CHECK (rating_results BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_aftercare INTEGER CHECK (rating_aftercare BETWEEN 1 AND 5);

-- A2d: Backfill existing reviews so they display correctly
-- Assume all existing reviews are general_clinic type
UPDATE reviews SET survey_type = 'general_clinic' WHERE survey_type IS NULL;
