-- ================================================================
-- MIGRATION: 20260221130000_add_provider_source_tracking.sql
-- PURPOSE: Add data source and external ID tracking for Apple Maps imports
-- ================================================================

-- Add data_source column to track where provider data originated
ALTER TABLE public.providers
ADD COLUMN IF NOT EXISTS data_source TEXT DEFAULT 'system' NOT NULL;

-- Add external_id column to store Apple Maps MKMapItem identifiers
-- This enables deduplication when syncing from Apple Maps
ALTER TABLE public.providers
ADD COLUMN IF NOT EXISTS external_id TEXT UNIQUE;

-- Add index on external_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_providers_external_id ON public.providers(external_id);

-- Add index on data_source for filtering by source
CREATE INDEX IF NOT EXISTS idx_providers_data_source ON public.providers(data_source);

-- Add comment to explain the columns
COMMENT ON COLUMN public.providers.data_source IS
  'Source of provider data: "system" (admin-entered), "apple_maps" (crowdsourced), etc.';

COMMENT ON COLUMN public.providers.external_id IS
  'External ID from source (e.g., MKMapItem identifier from Apple Maps)';

-- ================================================================
-- END MIGRATION
-- ================================================================
