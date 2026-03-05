# Supabase Schema Snapshot

Date: 2026-03-05
Scope: Read-only audit of local schema artifacts and iOS app usage.
Sources: `supabase/migrations/*.sql`, Swift Supabase call sites in `TrustCare/**/*.swift`.

## A) App-Relevant Tables and Views

This list includes tables/views directly used by the iOS app plus supporting taxonomy structures used by current search/discovery flows.

- `public.providers`
- `public.reviews`
- `public.reviews_public` (view)
- `public.review_media`
- `public.review_votes`
- `public.reported_reviews`
- `public.provider_services`
- `public.provider_claims`
- `public.specialties`
- `public.profiles`
- `public.saved_providers`
- `public.rehber_sessions`
- `public.rehber_messages`
- `public.taxonomy_entities`
- `public.taxonomy_labels`
- `public.taxonomy_aliases`
- `public.provider_taxonomy`
- `public.notifications`
- `public.user_events`
- `public.failed_verifications`
- `public.proof_hashes`

## B) Table/View Column Snapshot

Notes:
- Nullability is based on explicit `NOT NULL` constraints in migrations.
- If a column has a default but no `NOT NULL`, it is marked nullable.
- This is a migration-derived snapshot; remote environment drift is possible.

### `public.providers`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `uuid` | No | PK |
| `name` | `text` | No | Provider display name |
| `specialty` | `text` | No | Legacy specialty text |
| `clinic_name` | `text` | Yes | Clinic/institution name |
| `address` | `text` | No | Primary address |
| `city` | `text` | Yes | City |
| `country_code` | `text` | Yes | ISO-like country code |
| `latitude` | `double precision` | No | Geo coordinate |
| `longitude` | `double precision` | No | Geo coordinate |
| `phone` | `text` | Yes | Contact |
| `email` | `text` | Yes | Contact |
| `website` | `text` | Yes | Contact |
| `photo_url` | `text` | Yes | Avatar/profile image |
| `cover_url` | `text` | Yes | Hero/header image |
| `languages_spoken` | `text[]` | Yes | Display + filtering candidate |
| `rating_overall` | `numeric(3,2)` | Yes | Aggregate rating |
| `rating_wait_time` | `numeric(3,2)` | Yes | Aggregate metric |
| `rating_bedside` | `numeric(3,2)` | Yes | Aggregate metric |
| `rating_efficacy` | `numeric(3,2)` | Yes | Aggregate metric |
| `rating_cleanliness` | `numeric(3,2)` | Yes | Aggregate metric |
| `review_count` | `integer` | Yes | Aggregate count |
| `verified_review_count` | `integer` | Yes | Aggregate count |
| `price_level_avg` | `numeric(2,1)` | Yes | Aggregate affordability |
| `is_claimed` | `boolean` | Yes | Claim status |
| `claimed_by` | `uuid` | Yes | FK to `auth.users` |
| `claimed_at` | `timestamptz` | Yes | Claim timestamp |
| `subscription_tier` | `text` | Yes | `free/basic/premium` |
| `is_active` | `boolean` | Yes | Soft active flag |
| `is_featured` | `boolean` | Yes | Merchandising/boost |
| `created_by` | `uuid` | Yes | Creator |
| `deleted_at` | `timestamptz` | Yes | Soft delete |
| `created_at` | `timestamptz` | Yes | Created timestamp |
| `updated_at` | `timestamptz` | Yes | Updated timestamp |
| `search_vector` | `tsvector` | Yes | Full-text search index source |
| `data_source` | `text` | No | Added for source tracking (`system`, `apple_maps`, etc.) |
| `external_id` | `text` | Yes | External provider identifier |
| `slug` | `text` | Yes | Web profile slug |
| `description` | `text` | Yes | Web profile description |
| `gallery_urls` | `text[]` | Yes | Web profile gallery |
| `opening_hours` | `jsonb` | Yes | Web profile hours |
| `social_links` | `jsonb` | Yes | Web profile social links |
| `meta_title` | `text` | Yes | SEO |
| `meta_description` | `text` | Yes | SEO |

### `public.reviews`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `uuid` | No | PK |
| `user_id` | `uuid` | No | Reviewer |
| `provider_id` | `uuid` | No | FK to provider |
| `visit_date` | `date` | No | Visit date |
| `visit_type` | `text` | No | consultation/procedure/checkup/emergency/follow_up |
| `survey_type` | `text` | Yes | Dynamic survey family |
| `rating_wait_time` | `integer` | No | 1-5 |
| `rating_bedside` | `integer` | No | 1-5 |
| `rating_efficacy` | `integer` | No | 1-5 |
| `rating_cleanliness` | `integer` | No | 1-5 |
| `rating_staff` | `integer` | No | 1-5 |
| `rating_value` | `integer` | No | 1-5 |
| `rating_pain_mgmt` | `integer` | Yes | Dynamic metric |
| `rating_accuracy` | `integer` | Yes | Dynamic metric |
| `rating_knowledge` | `integer` | Yes | Dynamic metric |
| `rating_courtesy` | `integer` | Yes | Dynamic metric |
| `rating_care_quality` | `integer` | Yes | Dynamic metric |
| `rating_admin` | `integer` | Yes | Dynamic metric |
| `rating_comfort` | `integer` | Yes | Dynamic metric |
| `rating_turnaround` | `integer` | Yes | Dynamic metric |
| `rating_empathy` | `integer` | Yes | Dynamic metric |
| `rating_environment` | `integer` | Yes | Dynamic metric |
| `rating_communication` | `integer` | Yes | Dynamic metric |
| `rating_effectiveness` | `integer` | Yes | Dynamic metric |
| `rating_attentiveness` | `integer` | Yes | Dynamic metric |
| `rating_equipment` | `integer` | Yes | Dynamic metric |
| `rating_consultation` | `integer` | Yes | Dynamic metric |
| `rating_results` | `integer` | Yes | Dynamic metric |
| `rating_aftercare` | `integer` | Yes | Dynamic metric |
| `rating_overall` | `numeric(2,1)` | No | 1.0-5.0 |
| `price_level` | `integer` | No | 1-4 |
| `title` | `text` | Yes | Optional headline |
| `comment` | `text` | No | Review body |
| `would_recommend` | `boolean` | Yes | Recommendation |
| `proof_image_url` | `text` | Yes | Verification proof pointer |
| `photo_urls` | `text[]` | Yes | Extra uploaded photos |
| `is_verified` | `boolean` | Yes | Verification state |
| `verification_confidence` | `integer` | Yes | Verification score |
| `verification_reason` | `text` | Yes | Verification explanation |
| `verified_at` | `timestamptz` | Yes | Verification timestamp |
| `status` | `text` | Yes | active/pending_verification/flagged/removed |
| `helpful_count` | `integer` | Yes | Cached helpful count |
| `waiting_time` | `integer` | Yes | Contextual metric |
| `facility_cleanliness` | `integer` | Yes | Contextual metric |
| `doctor_communication` | `integer` | Yes | Contextual metric |
| `treatment_outcome` | `integer` | Yes | Contextual metric |
| `procedural_comfort` | `integer` | Yes | Contextual metric |
| `clear_explanations` | `integer` | Yes | Contextual metric |
| `checkout_speed` | `integer` | Yes | Contextual metric |
| `stock_availability` | `integer` | Yes | Contextual metric |
| `pharmacist_advice` | `integer` | Yes | Contextual metric |
| `staff_courtesy` | `integer` | Yes | Contextual metric |
| `response_time` | `integer` | Yes | Contextual metric |
| `nursing_care` | `integer` | Yes | Contextual metric |
| `check_in_process` | `integer` | Yes | Contextual metric |
| `test_comfort` | `integer` | Yes | Contextual metric |
| `result_turnaround` | `integer` | Yes | Contextual metric |
| `session_punctuality` | `integer` | Yes | Contextual metric |
| `empathy_listening` | `integer` | Yes | Contextual metric |
| `session_privacy` | `integer` | Yes | Contextual metric |
| `actionable_advice` | `integer` | Yes | Contextual metric |
| `therapy_progress` | `integer` | Yes | Contextual metric |
| `active_supervision` | `integer` | Yes | Contextual metric |
| `facility_gear` | `integer` | Yes | Contextual metric |
| `consultation_quality` | `integer` | Yes | Contextual metric |
| `result_satisfaction` | `integer` | Yes | Contextual metric |
| `aftercare_support` | `integer` | Yes | Contextual metric |
| `deleted_at` | `timestamptz` | Yes | Soft delete |
| `created_at` | `timestamptz` | Yes | Created timestamp |
| `updated_at` | `timestamptz` | Yes | Updated timestamp |

### `public.reviews_public` (view)

Purpose: public-safe projection of `reviews`, including conditional proof image visibility.

Current selected columns include core rating/status fields and omit some newer review columns (for example `photo_urls` and contextual metrics). This can cause schema/model drift risk for consumers that expect newer fields.

### `public.review_media`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `uuid` | No | PK |
| `review_id` | `uuid` | No | FK |
| `user_id` | `uuid` | No | FK |
| `media_type` | `text` | No | image/video |
| `storage_path` | `text` | No | Bucket path |
| `url` | `text` | No | Public/signed URL source |
| `thumbnail_url` | `text` | Yes | Thumbnail |
| `file_size_bytes` | `integer` | No | File size |
| `duration_seconds` | `integer` | Yes | Video duration |
| `width` | `integer` | Yes | Pixel width |
| `height` | `integer` | Yes | Pixel height |
| `display_order` | `integer` | Yes | Sorting |
| `content_status` | `text` | Yes | active/flagged/removed |
| `created_at` | `timestamptz` | Yes | Created timestamp |

### `public.review_votes`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `uuid` | No | PK |
| `review_id` | `uuid` | No | FK |
| `user_id` | `uuid` | No | FK |
| `is_helpful` | `boolean` | No | Helpful vote |
| `created_at` | `timestamptz` | Yes | Timestamp |

### `public.reported_reviews`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `uuid` | No | PK |
| `review_id` | `uuid` | No | FK |
| `reporter_id` | `uuid` | No | FK |
| `reason` | `text` | No | spam/offensive/inaccurate/other |
| `description` | `text` | Yes | Report details |
| `status` | `text` | Yes | pending/reviewed/dismissed |
| `reviewed_by` | `uuid` | Yes | Moderator/admin |
| `reviewed_at` | `timestamptz` | Yes | Review timestamp |
| `created_at` | `timestamptz` | Yes | Created timestamp |

### `public.provider_services`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `uuid` | No | PK |
| `provider_id` | `uuid` | No | FK |
| `category` | `text` | Yes | Service grouping |
| `name` | `text` | No | Service name |
| `description` | `text` | Yes | Service details |
| `price_min` | `numeric(10,2)` | Yes | Minimum price |
| `price_max` | `numeric(10,2)` | Yes | Maximum price |
| `currency` | `text` | Yes | Currency code |
| `duration_minutes` | `integer` | Yes | Duration |
| `display_order` | `integer` | Yes | Sorting |
| `is_active` | `boolean` | Yes | Active flag |
| `created_at` | `timestamptz` | Yes | Timestamp |
| `updated_at` | `timestamptz` | Yes | Timestamp |

### `public.provider_claims`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `uuid` | No | PK |
| `provider_id` | `uuid` | No | FK |
| `claimant_user_id` | `uuid` | No | Claim owner |
| `claimant_role` | `text` | No | owner/manager/representative |
| `business_email` | `text` | No | Contact |
| `phone` | `text` | Yes | Contact |
| `license_number` | `text` | Yes | Credential |
| `proof_document_url` | `text` | Yes | Claim proof |
| `status` | `text` | Yes | pending/approved/rejected |
| `reviewed_by` | `uuid` | Yes | Admin reviewer |
| `reviewed_at` | `timestamptz` | Yes | Timestamp |
| `rejection_reason` | `text` | Yes | Reason |
| `cooloff_until` | `timestamptz` | Yes | Retry control |
| `created_at` | `timestamptz` | Yes | Timestamp |

### `public.specialties`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `serial` | No | PK |
| `name` | `text` | No | Base label |
| `name_tr` | `text` | Yes | Turkish label |
| `name_de` | `text` | Yes | German label |
| `name_pl` | `text` | Yes | Polish label |
| `name_nl` | `text` | Yes | Dutch label |
| `name_da` | `text` | Yes | Danish label |
| `category` | `text` | No | Group |
| `subcategory` | `text` | Yes | Subgroup |
| `icon_name` | `text` | No | UI icon key |
| `survey_type` | `text` | No | Dynamic survey mapping |
| `color_hex` | `text` | Yes | UI color |
| `display_order` | `integer` | Yes | Sorting |
| `is_popular` | `boolean` | Yes | Popular flag |
| `is_active` | `boolean` | Yes | Active flag |
| `canonical_id` | `text` | Yes | Legacy-canonical bridge |
| `canonical_entity_id` | `text` | Yes | FK to `taxonomy_entities.id` |
| `canonical_entity_type` | `text` | Yes | specialty/service/facility |

### `public.profiles`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `uuid` | No | PK/FK auth user |
| `full_name` | `text` | Yes | Display name |
| `avatar_url` | `text` | Yes | Avatar |
| `bio` | `text` | Yes | Bio |
| `phone` | `text` | Yes | Contact |
| `country_code` | `text` | Yes | Locale/country |
| `preferred_language` | `text` | Yes | UI locale |
| `preferred_currency` | `text` | Yes | Pricing locale |
| `referral_code` | `text` | Yes | Referral |
| `referred_by` | `text` | Yes | Referral source |
| `date_of_birth` | `date` | Yes | Age gating |
| `deleted_at` | `timestamptz` | Yes | Soft delete |
| `created_at` | `timestamptz` | Yes | Timestamp |
| `updated_at` | `timestamptz` | Yes | Timestamp |

### `public.saved_providers`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `uuid` | No | PK |
| `user_id` | `uuid` | No | Owner |
| `provider_id` | `uuid` | No | Saved provider |
| `created_at` | `timestamptz` | No | Timestamp |

### `public.rehber_sessions`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `uuid` | No | PK |
| `user_id` | `uuid` | No | Owner |
| `title` | `text` | Yes | Session title |
| `was_emergency` | `boolean` | No | Emergency marker |
| `expires_at` | `timestamptz` | Yes | TTL |
| `created_at` | `timestamptz` | No | Timestamp |
| `updated_at` | `timestamptz` | No | Timestamp |

### `public.rehber_messages`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `uuid` | No | PK |
| `session_id` | `uuid` | No | FK session |
| `user_id` | `uuid` | No | Owner |
| `role` | `text` | No | user/assistant/system |
| `content` | `text` | No | Message body |
| `recommended_specialties` | `text[]` | Yes | Suggested specialties |
| `was_emergency` | `boolean` | No | Emergency marker |
| `created_at` | `timestamptz` | No | Timestamp |

### `public.taxonomy_entities`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `text` | No | Canonical entity id |
| `entity_type` | `text` | No | specialty/service/facility |
| `default_name` | `text` | No | Fallback label |
| `icon_key` | `text` | Yes | Icon |
| `sort_priority` | `integer` | No | Ordering |
| `created_at` | `timestamptz` | No | Timestamp |
| `updated_at` | `timestamptz` | No | Timestamp |

### `public.taxonomy_labels`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `entity_id` | `text` | No | FK taxonomy entity |
| `locale` | `text` | No | Locale code |
| `label` | `text` | No | Display label |
| `short_label` | `text` | Yes | Optional compact label |
| `created_at` | `timestamptz` | No | Timestamp |
| `updated_at` | `timestamptz` | No | Timestamp |

### `public.taxonomy_aliases`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `uuid` | No | PK |
| `locale` | `text` | No | Locale code |
| `entity_id` | `text` | No | FK taxonomy entity |
| `alias_raw` | `text` | No | Alias text |
| `alias_normalized` | `text` | Generated | Normalized alias |
| `weight` | `real` | No | Ranking weight |
| `tag` | `text` | Yes | Alias metadata |
| `created_at` | `timestamptz` | No | Timestamp |
| `updated_at` | `timestamptz` | No | Timestamp |

### `public.provider_taxonomy`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `provider_id` | `uuid` | No | FK provider |
| `entity_id` | `text` | No | FK taxonomy entity |
| `created_at` | `timestamptz` | No | Timestamp |

### Verification-support tables

#### `public.proof_hashes`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `uuid` | No | PK |
| `review_id` | `uuid` | No | FK review |
| `image_hash` | `text` | No | Fingerprint |
| `file_size_bytes` | `integer` | Yes | File size |
| `created_at` | `timestamptz` | Yes | Timestamp |

#### `public.failed_verifications`

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `id` | `uuid` | No | PK |
| `review_id` | `uuid` | No | FK review |
| `error_message` | `text` | Yes | Failure reason |
| `retry_count` | `integer` | Yes | Retry tracking |
| `last_attempted_at` | `timestamptz` | Yes | Attempt timestamp |
| `resolved` | `boolean` | Yes | Resolution state |
| `resolved_by` | `uuid` | Yes | Resolver |
| `resolved_at` | `timestamptz` | Yes | Resolution timestamp |
| `created_at` | `timestamptz` | Yes | Timestamp |

## C) RPC Functions Used by iOS

### `public.search_providers`

Swift call site:
- `TrustCare/Services/ProviderService.swift`

Parameters used by app:
- `search_query text?`
- `specialty_filter text?`
- `specialty_ids text[]?`
- `country_filter text?`
- `price_level_filter integer?`
- `min_rating decimal` (defaults to 0)
- `verified_only boolean`
- `max_distance_km integer`
- `user_lat double precision?`
- `user_lng double precision?`
- `offset_val integer`
- `limit_val integer`

Return shape:
- SQL returns `SETOF public.providers`.
- Swift decodes to `[Provider]`.

### `public.search_taxonomy`

Swift call site:
- `TrustCare/Services/TaxonomyService.swift`

Parameters used by app:
- `search_query text`
- `current_locale text`
- `entity_type_filter text?`
- `fallback_locale text` (default `en`)

Return shape:
- `TABLE(entity_id text, entity_type text, label text, score real)`
- Swift decodes to `[TaxonomySuggestion]`.

### `public.search_providers_by_taxonomy`

Swift call site:
- `TrustCare/Services/TaxonomyService.swift`

Parameters used by app:
- `entity_ids text[]`

Return shape:
- SQL returns `SETOF public.providers`.
- Swift decodes to `[Provider]`.

## D) Swift Models Mapped to Tables/RPC Outputs

- `Provider` -> `providers` rows and `search_providers`/`search_providers_by_taxonomy` RPC results.
- `Review` -> `reviews` rows and `reviews_public` view rows (+ profile join fields in client decoding).
- `ReviewMedia` -> `review_media`.
- `ReviewVote` -> `review_votes`.
- `ReportedReview` -> `reported_reviews`.
- `ProviderServiceItem` -> `provider_services`.
- `ProviderClaim` -> `provider_claims`.
- `Specialty` -> `specialties`.
- `UserProfile` -> `profiles`.
- `RehberSession` -> `rehber_sessions`.
- `RehberMessage` -> `rehber_messages`.
- `TaxonomySuggestion` -> `search_taxonomy` RPC response.

Inline/anonymous decoding structs also map to schema slices in:
- `SavedProvidersView` (`saved_providers.provider_id`)
- `ProviderService.fetchReviewsForProvider` (joined `profiles(full_name, avatar_url)`)
- `ProfileViewModel.loadReviews` (joined `providers(name, specialty)`)

## UI Required Fields for Living Trust v1

Legend:
- `EXISTS`: present in schema artifacts and currently queryable by app paths.
- `MISSING`: not found as a dedicated field/table in current schema artifacts.
- `UNKNOWN`: local migrations and app expectations appear out of sync.

### Find Card (Discover list/map cards)

| Field Needed | Status | Source / Note |
|---|---|---|
| `providers.id` | EXISTS | card navigation |
| `providers.name` | EXISTS | card title |
| `providers.specialty` | EXISTS | subtitle |
| `providers.rating_overall` | EXISTS | star rating |
| `providers.review_count` | EXISTS | review count |
| `providers.verified_review_count` | EXISTS | verified marker |
| `providers.distance_km` | UNKNOWN | not a physical column; computed client-side from coordinates |
| `providers.latitude` + `providers.longitude` | EXISTS | map distance calc |
| `providers.photo_url` | EXISTS | avatar image |
| `providers.data_source` | EXISTS | source-aware UI logic |
| `institution_type` | MISSING | no dedicated institutions model/table |
| `treatment_tags` | MISSING | no dedicated treatments table; taxonomy exists instead |

### Provider Detail

| Field Needed | Status | Source / Note |
|---|---|---|
| `providers.cover_url` | EXISTS | hero section |
| `providers.photo_url` | EXISTS | provider avatar |
| `providers.name` | EXISTS | title |
| `providers.specialty` | EXISTS | subtitle |
| `providers.clinic_name` | EXISTS | clinic label |
| `providers.address` | EXISTS | maps deeplink |
| `providers.phone` | EXISTS | tap to call |
| `providers.website` | EXISTS | external link |
| `providers.rating_overall` | EXISTS | summary rating |
| `providers.review_count` | EXISTS | summary count |
| `providers.price_level_avg` | EXISTS | price UI |
| `providers.is_claimed` | EXISTS | claimed badge/banner |
| `provider_services.*` | EXISTS | services section |
| `providers.description` | EXISTS | web profile text available |
| `providers.opening_hours` | EXISTS | available but not wired in current iOS view |
| `providers.gallery_urls` | EXISTS | available but not wired in current iOS view |
| `providers.price_level` | UNKNOWN | in Swift `Provider` model, not found in audited migrations |

### Review Card

| Field Needed | Status | Source / Note |
|---|---|---|
| `reviews.id` | EXISTS | identity/navigation |
| `reviews.user_id` | EXISTS | ownership checks |
| `reviews.comment` | EXISTS | body text |
| `reviews.rating_overall` | EXISTS | stars |
| `reviews.price_level` | EXISTS | price display |
| `reviews.created_at` | EXISTS | date |
| `reviews.is_verified` | EXISTS | verified badge |
| `reviews.status` | EXISTS | pending state |
| `reviews.helpful_count` | EXISTS | vote seed |
| `review_media.*` | EXISTS | gallery strip |
| `profiles.full_name` + `profiles.avatar_url` | EXISTS | reviewer identity via join |
| `reviews.photo_urls` | EXISTS (table) / MISSING (view) | column exists on `reviews` but omitted from `reviews_public` view currently used by provider detail flow |
| contextual metrics (`waiting_time`, etc.) | EXISTS (table) / UNKNOWN (view consumer) | columns exist on `reviews`; `reviews_public` view definition does not include them |

### Verification Badge / Trust Signals

| Field Needed | Status | Source / Note |
|---|---|---|
| `reviews.is_verified` | EXISTS | primary verified boolean |
| `reviews.status` | EXISTS | pending verification state |
| `reviews.verification_confidence` | EXISTS | confidence score |
| `reviews.verification_reason` | EXISTS | rationale/audit detail |
| `reviews.verified_at` | EXISTS | timestamp |
| `providers.verified_review_count` | EXISTS | aggregate trust counter |
| proof asset storage path | EXISTS | `reviews.proof_image_url`, `provider_claims.proof_document_url`, `proof_hashes` |

## Observed Gaps and Drift (Read-Only)

- No dedicated `institutions` table found.
- No dedicated `treatments` table found.
- Current semantic replacement appears to be taxonomy (`taxonomy_entities` with `entity_type` = `facility`/`service`).
- `reviews_public` view appears behind newer `reviews` columns (for example `photo_urls` and contextual metrics), which can produce partial payloads for detail/review UI.
- `Provider` Swift model includes `priceLevel` (`price_level`) but this column was not found in audited migrations for `providers`.
- `Specialty` Swift model expects `canonical_entity_id`/`canonical_entity_type` and localized name columns (`name_de`/`name_pl`/`name_nl`/`name_da`), which are partially migration-dependent; schema consistency should be verified against live DB.
