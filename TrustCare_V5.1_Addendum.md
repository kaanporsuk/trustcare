# TrustCare — V5.1 Addendum
## Review Media, Technical Hardening, Compliance & Risk Mitigation
### This document patches V5_Master with all outstanding concerns

---

## TABLE OF CONTENTS

1. [Review Media Support (Images, Videos, Text)](#1-review-media)
2. [Database Schema Additions & Fixes](#2-schema-additions)
3. [AI Verification Hardening](#3-ai-verification)
4. [Search & Performance Overhaul](#4-search-performance)
5. [Compliance & Regulatory](#5-compliance)
6. [Apple Sign-In Nonce Handling](#6-apple-signin)
7. [MapKit iOS 17 Clustering](#7-mapkit)
8. [Push Notifications Strategy](#8-push-notifications)
9. [Provider Claim Conflict Resolution](#9-claim-conflicts)
10. [Rate Limiting & Fraud Prevention](#10-rate-limiting)
11. [Image & Video Optimization Pipeline](#11-media-optimization)
12. [Analytics & Feature Flags](#12-analytics)
13. [Deep Linking & Universal Links](#13-deep-linking)
14. [GDPR Data Export & Soft Delete](#14-gdpr)
15. [Testing Strategy](#15-testing)
16. [Cold Start & Seeding Strategy](#16-cold-start)
17. [Updated Screen Specifications](#17-updated-screens)
18. [Updated Vibe Coding Prompts](#18-updated-prompts)
19. [Risk Register](#19-risk-register)

---

## 1. REVIEW MEDIA SUPPORT {#1-review-media}

### 1.1 Design Decision

Reviews now support three types of content:
- **Written commentary** (text — already in V5, min 50 / max 1000 chars)
- **Images** (up to 5 photos per review — procedure results, facility photos, etc.)
- **Short videos** (1 video up to 30 seconds per review — facility walkthrough, brief testimonial)

These are **separate from the verification proof image**, which remains private. Review media is public-facing and displayed alongside the review.

### 1.2 New Table: review_media

```sql
-- ================================================================
-- TABLE: review_media (images + videos attached to reviews)
-- ================================================================
CREATE TABLE review_media (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
    storage_path TEXT NOT NULL,           -- path in storage bucket
    url TEXT NOT NULL,                    -- public/signed URL
    thumbnail_url TEXT,                   -- auto-generated thumbnail (for videos)
    file_size_bytes INTEGER NOT NULL,
    duration_seconds INTEGER,            -- only for video
    width INTEGER,                       -- pixel dimensions
    height INTEGER,
    display_order INTEGER DEFAULT 0,
    content_status TEXT DEFAULT 'active'
        CHECK (content_status IN ('active', 'flagged', 'removed')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_review_media_review ON review_media(review_id);
CREATE INDEX idx_review_media_user ON review_media(user_id);
```

### 1.3 Storage Bucket for Review Media

```sql
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
    ('review-media', 'review-media', true, 52428800,  -- 50MB max (for video)
     ARRAY[
         'image/jpeg', 'image/png', 'image/heic',
         'video/mp4', 'video/quicktime', 'video/mov'
     ]);

-- Public read (review media is visible to all)
CREATE POLICY "review_media_read" ON storage.objects FOR SELECT
    USING (bucket_id = 'review-media');

-- Users can upload to their own folder
CREATE POLICY "review_media_upload" ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'review-media' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Users can delete their own media
CREATE POLICY "review_media_delete" ON storage.objects FOR DELETE
    USING (bucket_id = 'review-media' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Admins can manage all
CREATE POLICY "review_media_admin" ON storage.objects FOR ALL
    USING (bucket_id = 'review-media' AND is_admin());
```

### 1.4 RLS for review_media

```sql
ALTER TABLE review_media ENABLE ROW LEVEL SECURITY;

CREATE POLICY "review_media_select" ON review_media FOR SELECT USING (true);
CREATE POLICY "review_media_insert" ON review_media FOR INSERT
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "review_media_delete" ON review_media FOR DELETE
    USING (auth.uid() = user_id);
CREATE POLICY "review_media_admin" ON review_media FOR ALL USING (is_admin());
```

### 1.5 Media Constraints (Enforced Client-Side + Edge Function)

| Constraint | Images | Videos |
|-----------|--------|--------|
| Max per review | 5 | 1 |
| Max file size | 10 MB | 50 MB |
| Formats | JPEG, PNG, HEIC | MP4, MOV |
| Max duration | N/A | 30 seconds |
| Min resolution | 200×200 | 480p |
| Compression | JPEG 0.7 quality client-side | H.264, client-side via AVAssetExportSession |
| Thumbnails | Auto-generated 200×200 | First-frame extraction server-side |

### 1.6 Updated Review Submission Flow (Step added)

The review submission flow changes from **6 steps to 7 steps**:

```
Step 1: Find Provider
Step 2: Visit Details
Step 3: Ratings (4 sliders)
Step 4: Price Level ($-$$$$)
Step 5: Written Review (text)
Step 6: Photos & Video (NEW)  ← added
Step 7: Verification Upload (proof image, optional)
```

**Step 6 — Photos & Video:**
- Title: "Add Photos or Video" (title2)
- Subtitle: "Help others see what to expect" (body, secondary)
- **Photos section:**
  - PhotosPicker (multi-select, max 5)
  - Horizontal ScrollView of selected image thumbnails, each with × remove button
  - Counter: "3 of 5 photos"
- **Video section:**
  - PhotosPicker (video filter, max 1)
  - Video preview with play button overlay
  - Duration shown (if > 30s: error "Maximum 30 seconds" + auto-trim option)
  - × remove button
- "Skip" text button at bottom (all media is optional)
- Note: "Photos and videos are visible to everyone." (footnote)

### 1.7 Updated ReviewItemView Display

```
┌─────────────────────────────────────────────┐
│ [Avatar] John D. · ✓ Verified               │
│ ★★★★☆  ·  Jan 15, 2026  ·  $$$             │
│ "Great doctor, very thorough and explain..." │
│                                              │
│ ┌──────┐ ┌──────┐ ┌──────┐                  │
│ │ img1 │ │ img2 │ │ ▶vid │  ← media strip   │
│ └──────┘ └──────┘ └──────┘                  │
│                                              │
│ 👍 12 helpful                                │
└─────────────────────────────────────────────┘
```

- Images shown as horizontal ScrollView of 64×64 thumbnails
- Tap image → full-screen gallery with swipe (native PhotosUI viewer or custom)
- Video thumbnail shows ▶ overlay; tap → AVPlayerViewController (inline or full-screen)
- On ProviderDetailView: show media in a larger grid layout

### 1.8 Media Moderation

- All uploaded media is immediately visible (optimistic)
- Admin panel gets a "Media Moderation" section:
  - Grid view of recently uploaded images/videos
  - Quick actions: Flag, Remove, Approve
  - AI content moderation via OpenAI moderation endpoint (V1.5 — for launch, manual review)
- Reported media: users can report individual images/videos via flag icon
- Flagged media hidden until admin reviews

---

## 2. DATABASE SCHEMA ADDITIONS & FIXES {#2-schema-additions}

### 2.1 Composite Indexes (from gap analysis)

```sql
-- Common query: specialty + rating for filtered search
CREATE INDEX idx_providers_specialty_rating
    ON providers(specialty, rating_overall DESC) WHERE is_active = TRUE;

-- Common query: user's reviews sorted by date
CREATE INDEX idx_reviews_user_created
    ON reviews(user_id, created_at DESC);

-- Common query: provider reviews sorted for display
CREATE INDEX idx_reviews_provider_status_created
    ON reviews(provider_id, status, created_at DESC);

-- Review votes: common aggregation
CREATE INDEX idx_review_votes_helpful
    ON review_votes(review_id) WHERE is_helpful = TRUE;
```

### 2.2 Full-Text Search on Providers

```sql
-- Add search vector column
ALTER TABLE providers ADD COLUMN search_vector tsvector;

-- Function to build multi-language search vector
CREATE OR REPLACE FUNCTION providers_search_vector_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('simple', COALESCE(NEW.name, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(NEW.clinic_name, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(NEW.specialty, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(NEW.city, '')), 'D') ||
        setweight(to_tsvector('simple', COALESCE(NEW.address, '')), 'D');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_providers_search_vector
BEFORE INSERT OR UPDATE ON providers
FOR EACH ROW EXECUTE FUNCTION providers_search_vector_update();

-- GIN index for fast full-text search
CREATE INDEX idx_providers_fts ON providers USING gin(search_vector);
```

> **Note:** Using `'simple'` dictionary instead of `'english'` because the app is multi-language. The `simple` dictionary does basic whitespace tokenization without language-specific stemming, which works better across English/German/Dutch/Polish/Turkish/Arabic provider names.

### 2.3 Updated search_providers Function (FTS + Haversine)

Replace the `ILIKE` search in V5's `search_providers` with:

```sql
-- Replace the search_text filter clause in search_providers:
-- OLD:
--   AND (search_text IS NULL OR
--        p.name ILIKE '%' || search_text || '%' OR ...)
-- NEW:
        AND (search_text IS NULL OR
             p.search_vector @@ plainto_tsquery('simple', search_text) OR
             p.name ILIKE '%' || search_text || '%')
             -- ILIKE kept as fallback for partial matches and typos
```

### 2.4 Failed Verifications Table (Dead-Letter Queue)

```sql
CREATE TABLE failed_verifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    last_attempted_at TIMESTAMPTZ DEFAULT NOW(),
    resolved BOOLEAN DEFAULT FALSE,
    resolved_by UUID REFERENCES auth.users(id),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_failed_verifications_unresolved
    ON failed_verifications(resolved, created_at)
    WHERE resolved = FALSE;
```

### 2.5 User Events Table (Analytics)

```sql
CREATE TABLE user_events (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL,
    event_data JSONB,
    device_info TEXT,
    app_version TEXT,
    session_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Partition-friendly index (for future partitioning by month)
CREATE INDEX idx_user_events_type_date ON user_events(event_type, created_at DESC);
CREATE INDEX idx_user_events_user ON user_events(user_id, created_at DESC);
```

### 2.6 Feature Flags Table

```sql
CREATE TABLE feature_flags (
    id SERIAL PRIMARY KEY,
    flag_name TEXT UNIQUE NOT NULL,
    description TEXT,
    is_enabled BOOLEAN DEFAULT FALSE,
    rollout_percentage INTEGER DEFAULT 0 CHECK (rollout_percentage BETWEEN 0 AND 100),
    target_countries TEXT[],        -- NULL = all countries
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed initial flags
INSERT INTO feature_flags (flag_name, description, is_enabled, rollout_percentage) VALUES
    ('ai_verification', 'AI-powered review verification', true, 100),
    ('ai_health_chat', 'AI health chat assistant (V2)', false, 0),
    ('campaigns', 'Provider campaigns & ads (V2)', false, 0),
    ('appointments', 'Appointment booking (V3)', false, 0),
    ('video_reviews', 'Video upload in reviews', true, 100),
    ('push_notifications', 'Native push notifications (V1.5)', false, 0);
```

### 2.7 Duplicate Proof Detection Table

```sql
CREATE TABLE proof_hashes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    image_hash TEXT NOT NULL,         -- perceptual hash of the proof image
    file_size_bytes INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_proof_hashes_hash ON proof_hashes(image_hash);
```

### 2.8 Soft Delete Support

```sql
-- Add soft delete columns to key tables
ALTER TABLE profiles ADD COLUMN deleted_at TIMESTAMPTZ;
ALTER TABLE reviews ADD COLUMN deleted_at TIMESTAMPTZ;
ALTER TABLE providers ADD COLUMN deleted_at TIMESTAMPTZ;

-- Update RLS to exclude soft-deleted records
-- Example for reviews:
DROP POLICY IF EXISTS "reviews_select" ON reviews;
CREATE POLICY "reviews_select" ON reviews FOR SELECT
    USING (
        deleted_at IS NULL AND
        (status IN ('active', 'pending_verification') OR user_id = auth.uid())
    );

-- Example for providers:
DROP POLICY IF EXISTS "providers_select" ON providers;
CREATE POLICY "providers_select" ON providers FOR SELECT
    USING (is_active = TRUE AND deleted_at IS NULL);
```

---

## 3. AI VERIFICATION HARDENING {#3-ai-verification}

### 3.1 Confidence Tiers & Escalation

Replace the binary auto-verify logic with a 3-tier system:

| Confidence | Action | Status Set |
|-----------|--------|-----------|
| ≥ 80% | Auto-verify | `is_verified = true`, `status = 'active'` |
| 50–79% | Escalate to admin queue | `status = 'pending_verification'` (stays) |
| < 50% | Auto-reject verification (review stays as unverified) | `is_verified = false`, `status = 'active'` |

### 3.2 Updated Edge Function with Retry Logic

```typescript
// supabase/functions/verify-review/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const MAX_RETRIES = 3
const RETRY_DELAY_MS = 5000

serve(async (req) => {
    const { review_id, retry_count = 0 } = await req.json()

    const supabase = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    try {
        // 1. Fetch review with provider info
        const { data: review, error } = await supabase
            .from("reviews")
            .select("*, providers(name, clinic_name)")
            .eq("id", review_id)
            .single()

        if (error || !review?.proof_image_url) {
            return new Response(JSON.stringify({ error: "No proof found" }), { status: 400 })
        }

        // 2. Download proof image
        const storagePath = review.proof_image_url.replace(/^.*verification-proofs\//, '')
        const { data: imageBlob, error: dlError } = await supabase.storage
            .from("verification-proofs")
            .download(storagePath)

        if (dlError || !imageBlob) throw new Error("Image download failed")

        // 3. Compute perceptual hash for duplicate detection
        const arrayBuffer = await imageBlob.arrayBuffer()
        const base64 = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)))
        const fileSize = arrayBuffer.byteLength

        // Simple hash for duplicate detection (use actual perceptual hash library in production)
        const hashBuffer = await crypto.subtle.digest('SHA-256', new Uint8Array(arrayBuffer))
        const imageHash = Array.from(new Uint8Array(hashBuffer))
            .map(b => b.toString(16).padStart(2, '0')).join('')

        // 4. Check for duplicate proof
        const { data: existingProof } = await supabase
            .from("proof_hashes")
            .select("review_id")
            .eq("image_hash", imageHash)
            .neq("review_id", review_id)
            .limit(1)

        if (existingProof && existingProof.length > 0) {
            // Duplicate detected — flag the review
            await supabase.from("reviews").update({
                status: 'flagged',
                verification_confidence: 0,
                verification_reason: `Duplicate proof: matches review ${existingProof[0].review_id}`
            }).eq("id", review_id)

            return new Response(JSON.stringify({
                review_id, is_verified: false, reason: "Duplicate proof detected"
            }), { headers: { "Content-Type": "application/json" } })
        }

        // Store hash for future duplicate checks
        await supabase.from("proof_hashes").insert({
            review_id, image_hash: imageHash, file_size_bytes: fileSize
        })

        // 5. Send to OpenAI Vision
        const providerName = review.providers?.name || "Unknown"
        const clinicName = review.providers?.clinic_name || ""

        const aiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                model: "gpt-4o-mini",
                messages: [{
                    role: "system",
                    content: "You verify medical documents. Respond ONLY with valid JSON."
                }, {
                    role: "user",
                    content: [
                        {
                            type: "text",
                            text: `Analyze this image. Is it a legitimate medical/healthcare document?
The review claims a visit to "${providerName}" at "${clinicName}".

Check for:
1. Is this a real medical document (receipt, prescription, appointment, report)?
2. Does it mention the provider name or clinic?
3. Does it contain a date?
4. Are there signs of image manipulation or forgery?
5. What language/script is the document in?

Respond ONLY with JSON:
{
    "is_legitimate": true/false,
    "confidence": 0-100,
    "document_type": "receipt|prescription|appointment|report|unknown",
    "mentions_provider": true/false,
    "has_date": true/false,
    "forgery_indicators": true/false,
    "document_language": "en|de|nl|pl|tr|ar|other",
    "reason": "brief explanation"
}`
                        },
                        {
                            type: "image_url",
                            image_url: { url: `data:image/jpeg;base64,${base64}` }
                        }
                    ]
                }],
                max_tokens: 400,
                temperature: 0.1
            })
        })

        const aiResult = await aiResponse.json()
        let analysis
        try {
            const content = aiResult.choices[0].message.content
            analysis = JSON.parse(content.replace(/```json|```/g, '').trim())
        } catch {
            throw new Error("Failed to parse AI response")
        }

        // 6. Apply 3-tier verification logic
        const updateData: Record<string, any> = {
            verification_confidence: analysis.confidence,
            verification_reason: analysis.reason,
        }

        if (analysis.forgery_indicators) {
            // Forgery detected — flag immediately
            updateData.status = 'flagged'
            updateData.is_verified = false
            updateData.verification_reason = `FORGERY SUSPECTED: ${analysis.reason}`
        } else if (analysis.is_legitimate && analysis.confidence >= 80) {
            // HIGH confidence — auto-verify
            updateData.is_verified = true
            updateData.verified_at = new Date().toISOString()
            updateData.status = 'active'
        } else if (analysis.confidence >= 50) {
            // MEDIUM confidence — stays pending for human review
            // status remains 'pending_verification'
            updateData.verification_reason =
                `NEEDS HUMAN REVIEW (${analysis.confidence}%): ${analysis.reason}`
        } else {
            // LOW confidence — mark as unverified, publish anyway
            updateData.is_verified = false
            updateData.status = 'active'
        }

        await supabase.from("reviews").update(updateData).eq("id", review_id)

        return new Response(JSON.stringify({
            review_id,
            is_verified: updateData.is_verified || false,
            confidence: analysis.confidence,
            tier: analysis.confidence >= 80 ? 'auto_verified' :
                  analysis.confidence >= 50 ? 'escalated' : 'unverified',
            reason: analysis.reason
        }), { headers: { "Content-Type": "application/json" } })

    } catch (error) {
        // RETRY LOGIC
        if (retry_count < MAX_RETRIES) {
            // Re-invoke self with incremented retry count
            const retryResponse = await fetch(
                `${Deno.env.get("SUPABASE_URL")}/functions/v1/verify-review`,
                {
                    method: "POST",
                    headers: {
                        "Authorization": `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify({ review_id, retry_count: retry_count + 1 })
                }
            )
            return retryResponse
        }

        // Max retries exhausted — log to dead-letter queue
        await supabase.from("failed_verifications").insert({
            review_id,
            error_message: (error as Error).message,
            retry_count: retry_count
        })

        return new Response(JSON.stringify({
            error: "Verification failed after retries",
            review_id
        }), { status: 500, headers: { "Content-Type": "application/json" } })
    }
})
```

### 3.3 AI Verification Cost Controls

| Control | Implementation |
|---------|---------------|
| Model choice | `gpt-4o-mini` (cheapest vision model) — ~$0.01 per verification |
| Image compression | Client compresses to JPEG 0.5 quality before upload for proof (separate from display quality) |
| Batch processing | For V1.5: queue verifications and process in batches during off-peak hours |
| Cost monitoring | Track in `user_events` table: `event_type = 'ai_verification'`, `event_data = {cost_cents, confidence}` |
| Rate limit | Max 5 verified reviews per user per day |
| Skip re-verification | If proof_hash matches an already-verified proof from same user, auto-verify |

### 3.4 Admin Panel — Verification Queue Enhancement

The admin `/reviews` page now shows:

| Column | Description |
|--------|------------|
| AI Confidence | Color-coded: Green ≥80, Yellow 50-79, Red <50 |
| AI Reason | Tooltip with full explanation |
| Proof Image | Click to view full-size in modal |
| Duplicate? | ⚠️ icon if hash matches another review |
| Forgery? | 🚨 icon if AI flagged forgery indicators |
| Actions | Verify / Reject / Flag / View Review |

Priority sorting: Flagged first, then Pending (50-79), then all others.

---

## 4. SEARCH & PERFORMANCE {#4-search-performance}

### 4.1 Geohash Strategy (V1.5 Migration Path)

For V1, keep Haversine with bounding-box pre-filter (works fine up to ~10k providers). Plan for:

```sql
-- V1.5: Add geohash column for faster spatial queries
ALTER TABLE providers ADD COLUMN geohash TEXT;

-- Function to compute geohash from lat/lng
CREATE OR REPLACE FUNCTION compute_geohash(lat DOUBLE PRECISION, lng DOUBLE PRECISION, precision INT DEFAULT 6)
RETURNS TEXT AS $$
    -- Use Supabase pg_geohash extension or implement in Edge Function
    -- Precision 6 ≈ 1.2km × 0.6km cell
$$ LANGUAGE plpgsql IMMUTABLE;

-- Index on geohash prefix for fast range queries
CREATE INDEX idx_providers_geohash ON providers(geohash);
```

**For launch:** The bounding-box filter in `search_providers` is sufficient. Monitor query performance in Supabase dashboard. If p95 latency exceeds 200ms, implement geohash.

### 4.2 Connection Pooling

Configure in Supabase Dashboard → Settings → Database:
- **Pool Mode:** Transaction (recommended for serverless)
- **Pool Size:** Start with default, increase if connection errors appear
- **Use connection string with pooler** (port 6543, not 5432) in Edge Functions

### 4.3 Materialized View for Provider Rankings (V1.5)

```sql
-- For expensive aggregation queries (homepage "Top Rated" section)
CREATE MATERIALIZED VIEW mv_top_providers AS
SELECT
    p.id, p.name, p.specialty, p.city, p.country_code,
    p.rating_overall, p.review_count, p.verified_review_count,
    p.price_level_avg, p.photo_url, p.is_claimed
FROM providers p
WHERE p.is_active = TRUE AND p.deleted_at IS NULL AND p.review_count >= 3
ORDER BY p.rating_overall DESC, p.verified_review_count DESC
LIMIT 100;

-- Refresh nightly via Supabase cron (pg_cron extension)
SELECT cron.schedule('refresh-top-providers', '0 3 * * *',
    'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_top_providers');
```

---

## 5. COMPLIANCE & REGULATORY {#5-compliance}

### 5.1 Age Gating

Add to the **Sign Up flow** (AuthView, signup mode):

```swift
// After "I agree to Terms & Privacy" toggle:
// Add date of birth picker with validation
DatePicker("Date of Birth", selection: $dateOfBirth,
           in: ...Calendar.current.date(byAdding: .year, value: -100, to: Date())!
              ...Calendar.current.date(byAdding: .year, value: -16, to: Date())!,
           displayedComponents: .date)

// Validation: must be 16+ (GDPR-K / COPPA equivalent)
// If under 16: show error "You must be at least 16 to use TrustCare"
```

Add to profiles table:

```sql
ALTER TABLE profiles ADD COLUMN date_of_birth DATE;
ALTER TABLE profiles ADD CONSTRAINT age_minimum
    CHECK (date_of_birth IS NULL OR date_of_birth <= CURRENT_DATE - INTERVAL '16 years');
```

### 5.2 Data Processing Consent

```sql
CREATE TABLE consent_records (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    consent_type TEXT NOT NULL
        CHECK (consent_type IN (
            'terms_of_service',
            'privacy_policy',
            'review_data_processing',
            'ai_verification_consent',
            'marketing_communications',
            'analytics_tracking'
        )),
    version TEXT NOT NULL,              -- "1.0", "1.1" etc.
    granted BOOLEAN NOT NULL,
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_at TIMESTAMPTZ,
    ip_address INET,
    UNIQUE(user_id, consent_type, version)
);

ALTER TABLE consent_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "consent_own" ON consent_records FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "consent_admin" ON consent_records FOR SELECT USING (is_admin());
```

**On Signup:** Record consent for `terms_of_service`, `privacy_policy`, `review_data_processing`, and `ai_verification_consent`.

**In Settings:** Allow users to manage `marketing_communications` and `analytics_tracking`.

### 5.3 GDPR Article 17 — Cascading Deletes

The `ON DELETE CASCADE` constraints already handle this for most tables. Verify the cascade chain:

```
User requests deletion
  → profiles row deleted (CASCADE from auth.users)
    → reviews deleted (CASCADE from profiles)
      → review_media deleted (CASCADE from reviews)
      → review_votes deleted (CASCADE from reviews)
      → proof_hashes deleted (CASCADE from reviews)
    → review_votes (as voter) deleted
    → reported_reviews deleted
    → appointments deleted
    → ai_chat_sessions deleted
    → consent_records deleted
  → providers: claimed_by set to NULL (not deleted — provider data is community-owned)
  → provider_claims: deleted (CASCADE from auth.users)
```

For **soft delete** (preferred for GDPR audit trail):
1. Set `profiles.deleted_at = NOW()`
2. Anonymize: set `full_name = 'Deleted User'`, `avatar_url = NULL`, `phone = NULL`
3. Reviews remain but show "Deleted User" as author
4. After 30-day grace period: hard delete via scheduled function

### 5.4 HIPAA Considerations

> **For US market:** Supabase **does not** offer BAA on their cloud offering as of early 2025. If targeting US healthcare data:
> - Option A: Use Supabase self-hosted on HIPAA-compliant infra (AWS with BAA)
> - Option B: Exclude US from initial launch; add when self-hosted infra is ready
> - Option C: Consult healthcare attorney — TrustCare may not constitute a "covered entity" since it processes patient *opinions*, not *medical records*

**Recommendation for V1:** Launch in EU/UK/Turkey/Poland first. Defer US until legal review is complete. Add a `blocked_countries` feature flag.

---

## 6. APPLE SIGN-IN NONCE HANDLING {#6-apple-signin}

### 6.1 Critical Implementation Detail

Add this **exact specification** to Prompt 2 to prevent agent errors:

```
CRITICAL: Apple Sign-In Nonce Implementation

The agent MUST implement Apple Sign-In with the following exact flow:

1. Generate a random nonce BEFORE presenting the Apple Sign-In button:
   ```swift
   import CryptoKit

   func randomNonceString(length: Int = 32) -> String {
       precondition(length > 0)
       var randomBytes = [UInt8](repeating: 0, count: length)
       let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
       if errorCode != errSecSuccess { fatalError("Unable to generate nonce") }
       let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
       return String(randomBytes.map { charset[Int($0) % charset.count] })
   }

   func sha256(_ input: String) -> String {
       let inputData = Data(input.utf8)
       let hashedData = SHA256.hash(data: inputData)
       return hashedData.compactMap { String(format: "%02x", $0) }.joined()
   }
   ```

2. Store the RAW nonce as a @State property. Pass the SHA256 HASH to Apple.

3. In the SignInWithAppleButton completion handler:
   ```swift
   SignInWithAppleButton(.signIn) { request in
       let nonce = randomNonceString()
       currentNonce = nonce  // Store raw nonce
       request.requestedScopes = [.fullName, .email]
       request.nonce = sha256(nonce)  // Pass HASH to Apple
   } onCompletion: { result in
       switch result {
       case .success(let authorization):
           guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                 let identityTokenData = appleIDCredential.identityToken,
                 let identityToken = String(data: identityTokenData, encoding: .utf8),
                 let nonce = currentNonce else { return }

           Task {
               try await supabase.auth.signInWithIdToken(
                   credentials: .init(
                       provider: .apple,
                       idToken: identityToken,
                       nonce: nonce  // Pass RAW nonce (not hash)
                   )
               )
           }
       case .failure(let error):
           // Handle error
       }
   }
   ```

4. DO NOT use ASAuthorizationAppleIDProvider delegate methods.
   Use the SwiftUI SignInWithAppleButton directly.

5. Enable "Sign in with Apple" in both:
   - Xcode → Target → Signing & Capabilities
   - Supabase Dashboard → Authentication → Providers → Apple
```

---

## 7. MAPKIT iOS 17 CLUSTERING {#7-mapkit}

### 7.1 Correct iOS 17 Implementation

Add to Prompt 3:

```
CRITICAL: MapKit Implementation (iOS 17+)

Use the NEW SwiftUI Map API, NOT MKMapView or UIViewRepresentable.

```swift
import MapKit

struct ProviderMapView: View {
    @State private var position: MapCameraPosition = .userLocation(
        fallback: .automatic
    )
    let providers: [Provider]

    var body: some View {
        Map(position: $position) {
            // User location
            UserAnnotation()

            // Provider annotations with clustering
            ForEach(providers) { provider in
                Annotation(
                    provider.name,
                    coordinate: CLLocationCoordinate2D(
                        latitude: provider.latitude,
                        longitude: provider.longitude
                    ),
                    anchor: .bottom
                ) {
                    ProviderMapPin(provider: provider)
                }
                .annotationTitles(.hidden) // Custom view handles title
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .mapStyle(.standard(pointsOfInterest: .including([.hospital, .pharmacy])))
    }
}

// Custom pin view
struct ProviderMapPin: View {
    let provider: Provider
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "cross.case.fill")
                .font(.title3)
                .foregroundColor(.white)
                .padding(8)
                .background(provider.isVerifiedMajority ? AppColor.success : AppColor.trustBlue)
                .clipShape(Circle())
            Image(systemName: "triangle.fill")
                .font(.caption2)
                .foregroundColor(provider.isVerifiedMajority ? AppColor.success : AppColor.trustBlue)
                .offset(y: -5)
        }
    }
}
```

DO NOT use MKClusterAnnotation or MKAnnotationView.
DO NOT wrap MKMapView in UIViewRepresentable.
The iOS 17 Map view handles clustering automatically when annotations overlap.
```

---

## 8. PUSH NOTIFICATIONS STRATEGY {#8-push-notifications}

### 8.1 V1: In-App + Email Only

For V1 launch, **defer native push notifications**. Use:

1. **In-app toast/banner notifications:**
   - When review verification completes → show banner on next app open
   - When provider claim is approved → show banner
   - Store pending notifications in a `notifications` table

2. **Email notifications (via Supabase Auth emails + custom SMTP):**
   - Review verified
   - Provider claim approved/rejected
   - Weekly digest (optional, V1.5)

```sql
-- In-app notification queue
CREATE TABLE notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN (
        'review_verified', 'review_flagged', 'claim_approved',
        'claim_rejected', 'helpful_vote', 'provider_reply'
    )),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB,                    -- e.g., {"review_id": "...", "provider_id": "..."}
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_unread
    ON notifications(user_id, created_at DESC) WHERE is_read = FALSE;

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notifications_own" ON notifications FOR ALL USING (auth.uid() = user_id);
```

### 8.2 V1.5: Native APNs

When ready, add:
- APNs certificate (`.p8` key) in Apple Developer Portal
- Supabase Edge Function to send pushes via APNs HTTP/2 API
- `device_tokens` table linked to profiles
- Notification categories: verification_update, claim_update, review_activity

---

## 9. PROVIDER CLAIM CONFLICT RESOLUTION {#9-claim-conflicts}

### 9.1 Updated Claim Workflow

```sql
-- Add conflict detection columns to provider_claims
ALTER TABLE provider_claims ADD COLUMN priority_score INTEGER DEFAULT 0;
-- Priority: owner > manager > representative (3 > 2 > 1)

-- Add cooling-off constraint
ALTER TABLE provider_claims ADD COLUMN cooloff_until TIMESTAMPTZ;
```

**Rules:**
1. **Simultaneous claims:** If two claims exist for the same provider in `pending` status, admin sees both in a comparison view. Higher-priority role wins if documents are equal.
2. **Post-rejection cooloff:** After rejection, `cooloff_until` is set to 90 days in the future. New claims from the same user for the same provider are blocked.
3. **Evidence matching:** Admin panel shows provider address vs. claim documents side-by-side. Auto-flag if business email domain doesn't match website domain.

```sql
-- Prevent duplicate pending claims
CREATE UNIQUE INDEX idx_claims_pending_provider
    ON provider_claims(provider_id)
    WHERE status = 'pending';
-- This allows only ONE pending claim per provider at a time.
-- Second claimant sees: "A claim for this provider is already under review."

-- Prevent cooloff violations
CREATE OR REPLACE FUNCTION check_claim_cooloff()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM provider_claims
        WHERE provider_id = NEW.provider_id
        AND claimant_user_id = NEW.claimant_user_id
        AND status = 'rejected'
        AND cooloff_until > NOW()
    ) THEN
        RAISE EXCEPTION 'Claim rejected recently. Please wait before re-applying.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_claim_cooloff
BEFORE INSERT ON provider_claims
FOR EACH ROW EXECUTE FUNCTION check_claim_cooloff();
```

---

## 10. RATE LIMITING & FRAUD PREVENTION {#10-rate-limiting}

### 10.1 Client-Side Rate Limits

| Action | Limit | Window |
|--------|-------|--------|
| Review submissions | 5 per day | 24 hours |
| Provider additions | 3 per day | 24 hours |
| Provider claims | 2 per week | 7 days |
| Helpful votes | 50 per day | 24 hours |
| Media uploads | 20 per day | 24 hours |
| AI chat messages (V2) | 20 per day | 24 hours |
| Report submissions | 10 per day | 24 hours |

### 10.2 Server-Side Enforcement

```sql
-- Function to check rate limits
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_user_id UUID,
    p_action TEXT,
    p_max_count INTEGER,
    p_window_hours INTEGER DEFAULT 24
) RETURNS BOOLEAN AS $$
DECLARE
    action_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO action_count
    FROM user_events
    WHERE user_id = p_user_id
      AND event_type = p_action
      AND created_at > NOW() - (p_window_hours || ' hours')::INTERVAL;

    RETURN action_count < p_max_count;
END;
$$ LANGUAGE plpgsql STABLE;
```

### 10.3 Review Spam Prevention

```sql
-- Anti-spam trigger on review insert
CREATE OR REPLACE FUNCTION check_review_spam()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Rate limit: max 5 reviews per day
    IF (SELECT COUNT(*) FROM reviews
        WHERE user_id = NEW.user_id
        AND created_at > NOW() - INTERVAL '24 hours') >= 5 THEN
        RAISE EXCEPTION 'Review limit reached. Try again tomorrow.';
    END IF;

    -- 2. Duplicate content: same comment text submitted recently
    IF EXISTS (
        SELECT 1 FROM reviews
        WHERE user_id = NEW.user_id
        AND comment = NEW.comment
        AND created_at > NOW() - INTERVAL '7 days'
    ) THEN
        RAISE EXCEPTION 'Duplicate review content detected.';
    END IF;

    -- 3. Extreme rating with short comment: flag for review
    IF (NEW.rating_overall <= 1.5 OR NEW.rating_overall >= 4.8)
       AND length(NEW.comment) < 100 THEN
        NEW.status := 'flagged';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_review_spam
BEFORE INSERT ON reviews
FOR EACH ROW EXECUTE FUNCTION check_review_spam();
```

### 10.4 Fake Provider Prevention

```sql
-- Anti-spam trigger on provider insert
CREATE OR REPLACE FUNCTION check_provider_spam()
RETURNS TRIGGER AS $$
BEGIN
    -- Max 3 providers per user per day
    IF (SELECT COUNT(*) FROM providers
        WHERE created_by = NEW.created_by
        AND created_at > NOW() - INTERVAL '24 hours') >= 3 THEN
        RAISE EXCEPTION 'Provider creation limit reached.';
    END IF;

    -- Duplicate name + address check
    IF EXISTS (
        SELECT 1 FROM providers
        WHERE name = NEW.name AND address = NEW.address
        AND deleted_at IS NULL
    ) THEN
        RAISE EXCEPTION 'A provider with this name and address already exists.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_provider_spam
BEFORE INSERT ON providers
FOR EACH ROW EXECUTE FUNCTION check_provider_spam();
```

---

## 11. IMAGE & VIDEO OPTIMIZATION {#11-media-optimization}

### 11.1 Client-Side Pipeline (Swift)

```swift
// ImageService.swift additions:

/// Compress image to target size
static func compressImage(_ image: UIImage, maxSizeKB: Int = 1024, quality: CGFloat = 0.7) -> Data? {
    var compression = quality
    var data = image.jpegData(compressionQuality: compression)
    while let d = data, d.count > maxSizeKB * 1024, compression > 0.1 {
        compression -= 0.1
        data = image.jpegData(compressionQuality: compression)
    }
    return data
}

/// Generate thumbnail
static func generateThumbnail(_ image: UIImage, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    image.draw(in: CGRect(origin: .zero, size: size))
    let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return thumbnail
}

/// Compress video to 720p and max 30 seconds
static func compressVideo(inputURL: URL) async throws -> URL {
    let asset = AVAsset(url: inputURL)
    let duration = try await asset.load(.duration)

    // Trim to 30 seconds if needed
    let timeRange = CMTimeRange(
        start: .zero,
        duration: min(duration, CMTime(seconds: 30, preferredTimescale: 600))
    )

    guard let exportSession = AVAssetExportSession(
        asset: asset, presetName: AVAssetExportPresetMediumQuality
    ) else { throw AppError.uploadFailed }

    let outputURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("mp4")

    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mp4
    exportSession.timeRange = timeRange

    await exportSession.export()

    guard exportSession.status == .completed else {
        throw AppError.uploadFailed
    }
    return outputURL
}
```

### 11.2 Upload Strategy

```
User selects media
  → Client compresses images (JPEG 0.7, max 1MB each)
  → Client compresses video (720p, H.264, max 30s, AVAssetExportPresetMediumQuality)
  → Client generates thumbnails (200×200 for images, first-frame for video)
  → Upload thumbnails first (instant preview)
  → Upload full-res in background
  → On complete: insert review_media rows
  → Storage path: review-media/{userId}/{reviewId}/{UUID}.{ext}
```

### 11.3 Display Strategy

- List views: show thumbnails only (64×64)
- Detail views: show medium (400px width, lazy loaded)
- Full-screen: load original on demand
- Videos: show thumbnail with ▶ overlay; stream via signed URL (no full download)

For V1.5: Add Cloudflare R2 or CDN in front of Supabase Storage for global delivery.

---

## 12. ANALYTICS & FEATURE FLAGS {#12-analytics}

### 12.1 Event Schema (Standardized)

```swift
// AnalyticsService.swift
enum AnalyticsEvent: String {
    // Navigation
    case screenView = "screen_view"
    case tabChanged = "tab_changed"

    // Search
    case searchPerformed = "search_performed"
    case specialtyFiltered = "specialty_filtered"
    case providerViewed = "provider_viewed"

    // Reviews
    case reviewStarted = "review_started"
    case reviewStepCompleted = "review_step_completed"
    case reviewSubmitted = "review_submitted"
    case reviewMediaAdded = "review_media_added"
    case reviewHelpfulVoted = "review_helpful_voted"

    // Verification
    case verificationUploaded = "verification_uploaded"
    case verificationCompleted = "verification_completed"

    // Provider
    case providerCalled = "provider_called"
    case providerDirections = "provider_directions"
    case providerClaimed = "provider_claimed"
    case providerAdded = "provider_added"

    // Profile
    case profileEdited = "profile_edited"
    case languageChanged = "language_changed"
    case signedOut = "signed_out"

    // AI Chat (V2)
    case chatStarted = "chat_started"
    case chatMessageSent = "chat_message_sent"
}

class AnalyticsService {
    static let shared = AnalyticsService()

    func track(_ event: AnalyticsEvent, data: [String: Any]? = nil) {
        Task {
            try? await SupabaseManager.shared.client
                .from("user_events")
                .insert([
                    "user_id": SupabaseManager.shared.client.auth.session?.user.id.uuidString,
                    "event_type": event.rawValue,
                    "event_data": data,
                    "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"],
                    "device_info": UIDevice.current.model
                ])
                .execute()
        }
    }
}
```

### 12.2 Feature Flag Client

```swift
// FeatureFlagService.swift
class FeatureFlagService: ObservableObject {
    static let shared = FeatureFlagService()
    @Published var flags: [String: Bool] = [:]

    func loadFlags() async {
        let result = try? await SupabaseManager.shared.client
            .from("feature_flags")
            .select()
            .eq("is_enabled", value: true)
            .execute()
        // Parse and cache flags
    }

    func isEnabled(_ flag: String) -> Bool {
        flags[flag] ?? false
    }
}

// Usage:
if FeatureFlagService.shared.isEnabled("video_reviews") {
    // Show video upload option
}
```

---

## 13. DEEP LINKING {#13-deep-linking}

### 13.1 URL Scheme (Custom)

```
trustcare://provider/{provider_id}
trustcare://review/{review_id}
trustcare://search?q={query}&specialty={specialty}
trustcare://chat                    (V2)
```

### 13.2 Universal Links (V1.5)

Configure Apple App Site Association file at `https://trustcare.app/.well-known/apple-app-site-association`:

```json
{
    "applinks": {
        "apps": [],
        "details": [{
            "appID": "TEAMID.com.trustcare.app",
            "paths": ["/provider/*", "/review/*", "/search*"]
        }]
    }
}
```

### 13.3 SwiftUI Handler

```swift
// In TrustCareApp.swift:
.onOpenURL { url in
    DeepLinkHandler.handle(url)
}

// DeepLinkHandler.swift
enum DeepLinkHandler {
    static func handle(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }

        switch components.host {
        case "provider":
            if let id = UUID(uuidString: components.path.replacingOccurrences(of: "/", with: "")) {
                // Navigate to provider detail
                NavigationState.shared.navigateToProvider(id)
            }
        case "review":
            // Navigate to review detail
        case "search":
            let query = components.queryItems?.first(where: { $0.name == "q" })?.value
            // Navigate to search with query
        default: break
        }
    }
}
```

---

## 14. GDPR DATA EXPORT & SOFT DELETE {#14-gdpr}

### 14.1 Data Export Edge Function

```typescript
// supabase/functions/export-user-data/index.ts
serve(async (req) => {
    const authHeader = req.headers.get("Authorization")
    const supabase = createClient(/* ... */)

    const { data: { user } } = await supabase.auth.getUser(
        authHeader!.replace("Bearer ", "")
    )
    if (!user) return new Response("Unauthorized", { status: 401 })

    // Gather all user data
    const [profile, reviews, votes, chatSessions, events, consents] = await Promise.all([
        supabase.from("profiles").select("*").eq("id", user.id).single(),
        supabase.from("reviews").select("*").eq("user_id", user.id),
        supabase.from("review_votes").select("*").eq("user_id", user.id),
        supabase.from("ai_chat_sessions").select("*").eq("user_id", user.id),
        supabase.from("user_events").select("*").eq("user_id", user.id),
        supabase.from("consent_records").select("*").eq("user_id", user.id),
    ])

    const exportData = {
        exported_at: new Date().toISOString(),
        profile: profile.data,
        reviews: reviews.data,
        votes: votes.data,
        chat_sessions: chatSessions.data,
        events: events.data,
        consents: consents.data,
    }

    return new Response(JSON.stringify(exportData, null, 2), {
        headers: {
            "Content-Type": "application/json",
            "Content-Disposition": `attachment; filename="trustcare_data_${user.id}.json"`
        }
    })
})
```

### 14.2 Account Deletion Flow

In SettingsView → "Delete Account":

1. First confirmation: "This will permanently delete your account and all data."
2. Second confirmation: "Type DELETE to confirm"
3. Call Edge Function `delete-account` which:
   - Sets `profiles.deleted_at = NOW()`
   - Anonymizes: `full_name = 'Deleted User'`, clears PII
   - Keeps reviews visible but attributed to "Deleted User"
   - Schedules hard delete in 30 days (via pg_cron)
   - Signs user out

---

## 15. TESTING STRATEGY {#15-testing}

### 15.1 Testing Pyramid

| Layer | What | Tools | Priority |
|-------|------|-------|----------|
| Unit | ViewModels, Services, Validators, Enums | XCTest | Must-have for V1 |
| Integration | Supabase CRUD, Auth flows, Edge Functions | XCTest + Supabase local | Should-have |
| UI/Snapshot | Critical flows (auth, review submission) | XCUITest | Nice-to-have V1 |
| Manual | Full E2E on device | TestFlight | Must-have |

### 15.2 Key Test Cases

```swift
// HomeViewModelTests.swift
func testSearchDebounce() async { /* verify 300ms debounce */ }
func testSpecialtyFilter() async { /* verify filter applies correctly */ }
func testEmptyResults() async { /* verify empty state triggered */ }

// ReviewSubmissionViewModelTests.swift
func testStepValidation() { /* each step's canAdvance logic */ }
func testOverallRatingComputation() { /* average of 4 criteria / 2 */ }
func testCommentMinLength() { /* <50 chars → canAdvance false */ }
func testMediaLimits() { /* >5 images rejected, >30s video rejected */ }

// AuthViewModelTests.swift
func testEmailValidation() { /* various email formats */ }
func testPasswordMinLength() { /* <8 chars → error */ }

// ProviderServiceTests.swift
func testSearchProvidersRPC() async { /* verify Supabase RPC call */ }
func testDistanceCalculation() { /* known lat/lng pair → expected km */ }
```

---

## 16. COLD START & SEEDING {#16-cold-start}

### 16.1 Strategy

| Phase | Action |
|-------|--------|
| Pre-launch | Seed 50-100 providers per target city from public directories |
| Soft launch | Invite 20-30 beta testers per city to submit real reviews |
| Launch | Enable crowdsourced adding; incentivize with gamification (review count badges) |
| Growth | Provider claims drive organic data quality improvements |

### 16.2 Seeding Script

Add to Prompt 1's SQL migration a more comprehensive seed:

```sql
-- Seed providers from public data (expand per target country)
-- UK
INSERT INTO providers (name, specialty, clinic_name, address, city, country_code, latitude, longitude) VALUES
    ('Dr. Sarah Mitchell', 'Cardiologist', 'London Heart Centre', '123 Harley St, London W1G 6AX', 'London', 'GB', 51.5194, -0.1483),
    -- ... 20+ more per city

-- Germany
    ('Dr. Hans Weber', 'Dentist', 'Zahnarztpraxis Weber', 'Friedrichstr. 100, 10117 Berlin', 'Berlin', 'DE', 52.5200, 13.3880),
    -- ...

-- Netherlands
    ('Dr. Jan de Vries', 'General Practice', 'Huisartsenpraktijk de Vries', 'Keizersgracht 200, 1016 DW Amsterdam', 'Amsterdam', 'NL', 52.3676, 4.8936),
    -- ...

-- Poland
    ('Dr. Anna Kowalska', 'Dermatologist', 'Klinika Skóry', 'ul. Marszałkowska 50, 00-683 Warszawa', 'Warsaw', 'PL', 52.2297, 21.0122),
    -- ...

-- Turkey
    ('Dr. Ayşe Yılmaz', 'Pediatrician', 'Çocuk Sağlığı Merkezi', 'Seyhan, 01170 Adana', 'Adana', 'TR', 36.9914, 35.3308),
    -- ...
```

---

## 17. UPDATED SCREEN SPECIFICATIONS {#17-updated-screens}

### 17.1 SubmitReviewView — Updated Step Count

V5 had 6 steps. Now **7 steps** with media:

| Step | Screen | Validation |
|------|--------|-----------|
| 1 | Find Provider (search or add new) | Provider selected |
| 2 | Visit Details (date, type) | Date not future |
| 3 | Ratings (4 sliders, 1-10) | Always valid |
| 4 | Price Level ($-$$$$) | Always valid |
| 5 | Written Review (title, comment, recommend) | comment ≥ 50 chars |
| 6 | **Photos & Video** (up to 5 images + 1 video, all optional) | Always valid |
| 7 | Verification Upload (proof image, optional) | Always valid |

### 17.2 ProviderDetailView — Media in Reviews

Update the Reviews Section to show media:
- Each `ReviewItemView` shows horizontal media strip below the comment text
- Tap image → full-screen gallery (sheet with `TabView` for swipe)
- Tap video thumbnail → `AVPlayerViewController` (sheet, full-screen)
- On "See All Reviews" page: larger media grid per review

### 17.3 Admin Panel — New Sections

Add to the admin panel:

**`/media-moderation` page:**
- Grid of recently uploaded review media (images + video thumbnails)
- Filters: All, Images Only, Videos Only, Flagged
- Each item shows: thumbnail, uploader, review link, upload date
- Actions: Approve, Flag, Remove
- Click thumbnail → full preview

**`/failed-verifications` page:**
- Table of reviews where AI verification failed after all retries
- Columns: Review ID, Provider, Error, Retry Count, Last Attempt
- Actions: Manual Verify, Manual Reject, Retry

**`/analytics` page (enhanced):**
- Daily active users chart
- Reviews submitted per day
- AI verification success rate
- Verification confidence distribution histogram
- Top searched specialties
- Geographic heatmap of activity

---

## 18. UPDATED VIBE CODING PROMPTS {#18-updated-prompts}

### Changes to Prompt 2 (Auth):
Add the **exact Apple Sign-In nonce code** from Section 6 above. Add age gating (date of birth picker, 16+ validation). Add consent recording on signup.

### Changes to Prompt 3 (Home + Detail):
Add the **exact MapKit iOS 17 code** from Section 7. Add media strip to `ReviewItemView`. Add full-screen image gallery and video player.

### Changes to Prompt 4 (Review Submission):
**Now 7 steps instead of 6.** Add Step 6: Photos & Video (multi-image PhotosPicker, video picker with 30s limit, client-side compression, thumbnail generation). Update ReviewSubmissionViewModel with `selectedImages: [UIImage]`, `selectedVideo: URL?`, `mediaUploadProgress`. Add `review_media` inserts after review creation.

### Changes to Prompt 5 (Profile + Admin):
Add notifications table queries (show unread count badge on Profile tab). Add data export button in Settings (calls `export-user-data` Edge Function). Add age verification display. Add enhanced admin panel pages: `/media-moderation`, `/failed-verifications`, `/analytics`. Deploy spam prevention triggers.

### New: Prompt 0 (Pre-Flight — Run BEFORE Prompt 1):

```
IMPORTANT AGENT INSTRUCTIONS — Read before starting any code:

1. APPLE SIGN-IN: You MUST use SignInWithAppleButton (SwiftUI native) with
   raw nonce + SHA256 hash. See exact code pattern provided in Prompt 2.
   Do NOT use ASAuthorizationAppleIDProvider delegate methods.

2. MAPKIT: You MUST use the iOS 17 SwiftUI Map API (Map(position:) with
   Annotation). Do NOT use MKMapView or UIViewRepresentable. Clustering
   is handled automatically by the SwiftUI Map view.

3. PUSH NOTIFICATIONS: Do NOT implement APNs for V1. Use in-app
   notifications table + email only. We will add push in V1.5.

4. SUPABASE AUTH: For phone auth, use Supabase's built-in phone OTP.
   Do NOT implement a custom SMS provider.

5. MEDIA UPLOADS: Images compressed to JPEG 0.7 (max 1MB) client-side.
   Videos compressed to 720p H.264 (max 30s) via AVAssetExportSession.
   Generate thumbnails client-side before uploading.

6. LOCALIZATION: Use iOS 17 String Catalogs (.xcstrings). All user-facing
   text must use localization keys. Support RTL layout for Arabic.

7. NAVIGATION: Use NavigationStack with NavigationPath. No Coordinator
   pattern. No UIKit wrappers unless absolutely necessary.

8. ERROR HANDLING: Every async call must be wrapped in do/catch. Show
   errors via .alert modifier. Never crash on network failure.

9. RATE LIMITS: Enforce client-side limits (5 reviews/day, 3 providers/day,
   20 media uploads/day). Server triggers will also enforce.

10. TESTING: Write XCTest unit tests for all ViewModels. At minimum test
    validation logic, state transitions, and computed properties.

Acknowledge these instructions before proceeding to Prompt 1.
```

---

## 19. RISK REGISTER {#19-risk-register}

### Critical Risks

| # | Risk | Impact | Likelihood | Mitigation | Owner |
|---|------|--------|-----------|------------|-------|
| R1 | AI verification cost spike | High | Medium | gpt-4o-mini ($0.01/call), rate limits (5/user/day), duplicate hash skip, batch processing V1.5 | Backend |
| R2 | Multi-country phone auth complexity | High | High | Launch with email + Apple first, add phone for 2 countries initially (UK, TR), expand gradually | Auth |
| R3 | Provider claim fraud | High | Medium | Manual admin review, document verification, cooloff period, unique pending constraint | Admin |
| R4 | HIPAA non-compliance (US) | Critical | Low (defer US) | Launch EU/UK/TR first, legal review before US, feature flag to block US signups | Legal |
| R5 | Apple Sign-In nonce failure | High | Medium | Exact code pattern in spec, test on real device before submission | iOS |

### High Risks

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|--------|-----------|------------|
| R6 | Review spam / fake reviews | Medium | High | Rate limits, duplicate detection, extreme-rating flagging, reputation system V1.5 |
| R7 | Location query performance | Medium | Medium | Bounding-box pre-filter, composite indexes, geohash V1.5, monitor p95 latency |
| R8 | Cold start (empty cities) | Medium | High | Pre-seed 50-100 providers/city, beta tester program, gamification |
| R9 | Video storage costs | Medium | Medium | 30s limit, client compression, max 1 per review, monitor usage |
| R10 | AI verification false positives | Medium | Medium | 3-tier confidence system, human escalation for 50-79%, first 1000 manual review |

### Medium Risks

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|--------|-----------|------------|
| R11 | Arabic RTL layout bugs | Low | High | Dedicated QA pass, `.environment(\.layoutDirection)`, test all screens |
| R12 | Edge Function timeout | Low | Medium | Retry logic (3 attempts), dead-letter queue, admin fallback |
| R13 | Offensive media uploads | Medium | Medium | Manual moderation V1, AI content moderation V1.5, user reporting |
| R14 | Supabase vendor lock-in | Medium | Low | Standard PostgreSQL, exportable data, self-host option for V3 |
| R15 | App Store rejection (Medical category) | High | Low | Privacy policy, age gating, "not medical advice" disclaimers, no diagnosis claims |

---

## APPENDIX: COMPLETE TABLE COUNT

### V5.1 Total Tables: 22

| # | Table | Version | Purpose |
|---|-------|---------|---------|
| 1 | profiles | V1 | User profiles |
| 2 | user_roles | V1 | Admin/moderator roles |
| 3 | specialties | V1 | Reference data |
| 4 | providers | V1 | Doctors/clinics |
| 5 | provider_claims | V1 | Claim requests |
| 6 | provider_subscriptions | V1 | Monetization |
| 7 | provider_services | V1 | Service catalog |
| 8 | reviews | V1 | User reviews |
| 9 | **review_media** | **V1 (new)** | **Images + videos on reviews** |
| 10 | review_votes | V1 | Helpful votes |
| 11 | reported_reviews | V1 | Report queue |
| 12 | **proof_hashes** | **V1 (new)** | **Duplicate proof detection** |
| 13 | **failed_verifications** | **V1 (new)** | **AI retry dead-letter queue** |
| 14 | **notifications** | **V1 (new)** | **In-app notification queue** |
| 15 | **consent_records** | **V1 (new)** | **GDPR consent tracking** |
| 16 | **user_events** | **V1 (new)** | **Analytics events** |
| 17 | **feature_flags** | **V1 (new)** | **Feature toggles** |
| 18 | provider_campaigns | V2 | Ads & promotions |
| 19 | referral_codes | V2 | Referral system |
| 20 | ai_chat_sessions | V2 | AI chat history |
| 21 | appointments | V3 | Booking system |
| 22 | contact_requests | V3 | Contact forms |

### Storage Buckets: 5
1. `verification-proofs` (private)
2. `avatars` (public)
3. `provider-photos` (public)
4. `claim-documents` (private)
5. **`review-media` (public) — NEW**

### Edge Functions: 3
1. `verify-review` (V1 — hardened with retry + duplicate detection)
2. `health-chat` (V2)
3. **`export-user-data` (V1 — GDPR compliance) — NEW**

### Indexes: 25+ (including composite, FTS, partial)
