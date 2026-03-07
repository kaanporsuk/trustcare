# TrustCare implementation backlog

This backlog converts the taxonomy v2.1 proposal into an execution-ready plan for exhaustive launch with pharmacy in core scope.

## Summary
- Epics: 6
- Tasks: 26
- P0 tasks: 16
- P1 tasks: 9
- P2 tasks: 1
- Launch taxonomy counts: 84 specialties, 47 treatments / procedures, 19 facility types, 19 symptom / concern domains

## Recommended build order
1. E1 Canonical Taxonomy and Content Assets
2. E3 Review Architecture: Provider vs Facility
3. E4 Provider and Facility Onboarding
4. E2 Search Experience and Discovery
5. E5 Localization and UX Hardening
6. E6 Launch Readiness, Analytics, and Quality

## Epics and tasks
### E1 — Canonical Taxonomy and Content Assets
**Priority:** P0
**Objective:** Finalize and ship the exhaustive launch taxonomy, aliases, and localized content assets for Specialty, Treatment / Procedure, Facility Type, and Symptom / Concern.

**Deliverables**
- Frozen English source of truth
- Localized taxonomy resource files for all launch languages
- Alias graph and search synonyms
- Coverage validation script

**E1-T1 — Freeze canonical taxonomy v2.1** (P0)
- Lock the launch set at 84 specialties, 47 treatments / procedures, 19 facility types, and 19 symptom / concern domains. Preserve canonical IDs and display labels.
- Acceptance criteria:
  - Canonical JSON is versioned and marked launch-frozen.
  - Every taxonomy item has canonical_id, entity_type, display label, and optional aliases.
  - No cross-layer leakage: specialty contains specialties only, treatment contains treatments / procedures only, facility contains facilities only.
- Outputs:
  - trustcare_taxonomy_v2_1_proposal.json
  - launch-freeze changelog

**E1-T2 — Create multilingual taxonomy resources** (P0)
- Generate locale files for every shipped language using the polished UI-facing English labels as the translation base. Keep canonical IDs unchanged.
- Depends on: E1-T1
- Acceptance criteria:
  - Locale files exist for en, tr, de, pl, nl, da, es, fr, it, ro, pt, uk, ru, sv, cs, hu.
  - Every taxonomy item has a non-empty localized display value in every shipped locale.
  - Translation review resolves medically sensitive or ambiguous terms before import.
- Outputs:
  - taxonomy_<locale>.json files
  - translation review sheet

**E1-T3 — Build alias graph and synonym coverage** (P0)
- Add patient-friendly synonyms, abbreviations, and alternate spellings for specialties, treatments, facility types, and symptom domains.
- Depends on: E1-T1
- Acceptance criteria:
  - Top patient intents map to at least one canonical entity.
  - Common abbreviations and variants are covered (e.g., ENT, OB-GYN, IVF, PRP, LASIK).
  - Aliases are locale-aware where appropriate.
- Outputs:
  - taxonomy_aliases.json or equivalent resource

**E1-T4 — Add taxonomy coverage validation** (P0)
- Implement a lightweight validation command that fails when any canonical item is missing from any launch locale or when any localized display value is blank.
- Depends on: E1-T2
- Acceptance criteria:
  - Validation reports missing locale file, missing key, and empty value precisely.
  - Validation runs locally and in CI.
  - Build/release cannot proceed with incomplete coverage.
- Outputs:
  - tools/taxonomy_coverage_validate.swift or equivalent
  - CI step

### E2 — Search Experience and Discovery
**Priority:** P0
**Depends on:** E1
**Objective:** Ship the two-mode search model: Symptom / Concern AI search and Direct search across provider, specialty, treatment / procedure, and facility.

**Deliverables**
- Symptom / Concern entry flow
- Direct search/autocomplete flow
- Mapped result ranking and fallback behavior
- Urgency-sensitive routing

**E2-T1 — Implement direct search index** (P0)
- Build a unified search index over provider names, specialties, treatments / procedures, facility types, facility names, and aliases.
- Depends on: E1-T1, E1-T3
- Acceptance criteria:
  - Search returns relevant matches across all indexed entity types.
  - Autocomplete supports exact, prefix, alias, and typo-tolerant matching.
  - Results can be filtered by entity type and location.
- Outputs:
  - Unified search index
  - search API/view model updates

**E2-T2 — Implement symptom / concern intake flow** (P0)
- Create the patient-first search mode where a user enters a complaint or symptom and receives likely specialties, treatments, and facility recommendations.
- Depends on: E1-T1, E1-T3
- Acceptance criteria:
  - User can enter free text and receive mapped concern results.
  - UI clearly frames outputs as guidance, not diagnosis.
  - Concern flow supports both typed input and suggestion chips.
- Outputs:
  - Symptom search UI
  - mapping service

**E2-T3 — Integrate AI mapping backend** (P0)
- Use the AI backend to interpret symptom text, detect intent, rank candidate specialties/treatments/facilities, and flag urgency-sensitive patterns.
- Depends on: E2-T2
- Acceptance criteria:
  - AI returns structured candidates with confidence and rationale metadata for internal use.
  - Urgency-sensitive inputs route toward urgent care / emergency recommendations without diagnostic claims.
  - Fallback rules exist when AI confidence is low.
- Outputs:
  - AI symptom mapping contract
  - backend prompt/spec
  - confidence thresholds

**E2-T4 — Design ranked result orchestration** (P1)
- Define how direct search and symptom search rank providers, facilities, specialties, and treatments based on relevance, trust, location, availability, and review separation.
- Depends on: E2-T1, E2-T3, E3-T1
- Acceptance criteria:
  - Ranking policy is explicit and testable.
  - Provider and facility scores remain separate in ranking inputs.
  - Complementary/alternative care can be surfaced but visually bucketed and de-emphasized where appropriate.
- Outputs:
  - ranking policy doc
  - ranking config/tests

**E2-T5 — Localize search behavior** (P1)
- Ensure search works against localized display names while retaining alias support for English and common variants.
- Depends on: E1-T2, E1-T3, E2-T1
- Acceptance criteria:
  - Users can search successfully in launch locales.
  - Search uses localized labels in suggestions and results.
  - Alias matching does not reintroduce English-only UX in localized mode.
- Outputs:
  - localized search tests

### E3 — Review Architecture: Provider vs Facility
**Priority:** P0
**Objective:** Build separate trust objects, capture flows, dimensions, storage, and UI for provider reviews and facility reviews.

**Deliverables**
- Separate provider review model
- Separate facility review model
- Visit flow that can generate one or both reviews
- Separate public ratings and review cards

**E3-T1 — Define review domain models** (P0)
- Create explicit schemas, aggregation logic, and API boundaries for provider reviews and facility reviews. Public scores must never be merged.
- Acceptance criteria:
  - Provider and facility reviews have different review_target types.
  - Separate aggregation pipelines exist for provider and facility scores.
  - Data model supports a single care episode linking both targets without merging their public ratings.
- Outputs:
  - review schema
  - aggregation spec
  - API contracts

**E3-T2 — Define rating dimensions** (P0)
- Finalize rating dimensions for providers and facilities separately, including pharmacy-specific dimensions in facility scope.
- Depends on: E3-T1
- Acceptance criteria:
  - Provider review dimensions focus on expertise, communication, trust, explanation, bedside manner, and outcomes.
  - Facility review dimensions focus on cleanliness, operations, waiting time, organization, staff, transparency, infrastructure, and pharmacy-relevant service quality where applicable.
  - UI text is localized and category-specific.
- Outputs:
  - dimension dictionary
  - localized labels

**E3-T3 — Build review submission flows** (P0)
- Allow users to submit a provider review, facility review, or both after a care episode. Keep the targets separate in UI and backend.
- Depends on: E3-T1, E3-T2
- Acceptance criteria:
  - User can review provider only, facility only, or both.
  - Review forms clearly state what is being reviewed.
  - Submission flow prevents target confusion and preserves separate ratings.
- Outputs:
  - review screens
  - submission endpoints

**E3-T4 — Build public trust surfaces** (P1)
- Update provider profiles and facility profiles to display separate review counts, scores, category breakdowns, and linked practice relationships.
- Depends on: E3-T3
- Acceptance criteria:
  - Provider cards show provider rating and provider review count only.
  - Facility cards show facility rating and facility review count only.
  - Relationship text like 'Practices at X' or 'Available at X' does not imply shared score.
- Outputs:
  - profile UI updates
  - public review components

**E3-T5 — Moderation and abuse policy** (P1)
- Define moderation rules, reporting, abuse detection, and dispute pathways for both provider and facility reviews.
- Depends on: E3-T1
- Acceptance criteria:
  - Report/review moderation works independently for provider and facility content.
  - Internal tooling can hide, review, or reinstate reviews.
  - Audit trail exists for moderation actions.
- Outputs:
  - moderation spec
  - admin backlog

### E4 — Provider and Facility Onboarding
**Priority:** P0
**Depends on:** E1, E3
**Objective:** Make onboarding and profile maintenance support the full taxonomy, separate review architecture, and exhaustive launch scope including pharmacy.

**Deliverables**
- Expanded onboarding forms
- Facility-linked provider relationships
- Pharmacy onboarding
- Validation rules

**E4-T1 — Expand provider onboarding taxonomy selection** (P0)
- Allow providers to select multiple specialties, treatments/procedures offered, languages, and linked facilities from the exhaustive launch taxonomy.
- Depends on: E1-T1, E1-T2
- Acceptance criteria:
  - Provider onboarding supports multi-select specialty and treatment/procedure assignment.
  - Selection UI is localized and searchable.
  - Validation prevents semantically impossible or irrelevant combinations where needed.
- Outputs:
  - provider onboarding form updates

**E4-T2 — Expand facility onboarding** (P0)
- Support facility type, supported specialties, available treatments/procedures, pharmacy-specific capability flags, and linked providers.
- Depends on: E1-T1, E1-T2
- Acceptance criteria:
  - Facilities can be onboarded as hospitals, clinics, labs, pharmacies, telehealth, and other launch types.
  - Facility profile can list supported specialties, treatments, and providers.
  - Pharmacy-specific data fields exist if pharmacy is in core scope.
- Outputs:
  - facility onboarding form updates
  - facility data model updates

**E4-T3 — Relationship model between providers and facilities** (P0)
- Model how providers practice at one or more facilities and how a facility lists one or more providers.
- Depends on: E3-T1
- Acceptance criteria:
  - Provider-to-facility relationship is explicit and many-to-many if required.
  - Provider and facility profiles can reference each other without score leakage.
  - Search and result cards can surface relationship context.
- Outputs:
  - relationship schema
  - linking UI

**E4-T4 — Admin taxonomy management** (P1)
- Create an internal workflow for adding, deprecating, aliasing, or relabeling taxonomy nodes without breaking canonical IDs.
- Depends on: E1-T1
- Acceptance criteria:
  - Canonical IDs are stable.
  - Admin can update display labels and aliases safely.
  - Deprecated items can be hidden without corrupting historical data.
- Outputs:
  - admin spec
  - future backlog

### E5 — Localization and UX Hardening
**Priority:** P0
**Depends on:** E1, E2, E3, E4
**Objective:** Finish the multilingual UX so exhaustive launch taxonomy, search, onboarding, and reviews work cleanly across all shipped languages and long-label scenarios.

**Deliverables**
- Complete translation coverage
- Long-label-safe controls
- Locale-aware sorting/grouping/search
- Regression guardrails

**E5-T1 — Complete UI string coverage** (P0)
- Audit and fill all missing localized UI strings, including review empty states and search/help/legal content.
- Depends on: E1-T2
- Acceptance criteria:
  - No English leakage remains in launch locales for the TrustCare search, review, help, and legal flows.
  - All missing keys are added to the translation source of truth.
  - Coverage checks pass in CI.
- Outputs:
  - updated translation files
  - localization audit report

**E5-T2 — Replace truncation-prone controls** (P0)
- Update any segmented controls or fixed-width label containers that fail with longer translations. Use adaptive pills, scrolling chips, or other localization-safe patterns.
- Depends on: E1-T2
- Acceptance criteria:
  - Status filters and taxonomy controls remain readable in long-string languages such as Polish, German, and French.
  - No awkward mid-word truncation on key filter/search surfaces.
  - Accessibility and tap targets remain acceptable.
- Outputs:
  - UI component updates
  - snapshot tests

**E5-T3 — Localized taxonomy grouping and search QA** (P0)
- Verify that taxonomy browsing, search, grouping, and selected chips behave correctly in every launch language.
- Depends on: E1-T2, E2-T5
- Acceptance criteria:
  - Picker rows, chips, summaries, grouping, and search are localized consistently.
  - No duplicate rows appear due to localized label collisions unless intentionally handled.
  - Fallback-to-English is only used for genuinely missing entries and is caught by validation.
- Outputs:
  - QA matrix
  - locale test cases

**E5-T4 — Add regression guards** (P1)
- Extend existing validation and linting to catch hardcoded user-facing strings, missing taxonomy locale coverage, and locale-specific UI overflows.
- Depends on: E5-T1, E5-T2
- Acceptance criteria:
  - Localization checks run in local verify and CI.
  - Taxonomy coverage validation is mandatory.
  - At least one automated UI/snapshot test exists for long-label languages.
- Outputs:
  - verify/CI updates
  - snapshot baseline

### E6 — Launch Readiness, Analytics, and Quality
**Priority:** P1
**Depends on:** E1, E2, E3, E4, E5
**Objective:** Make the exhaustive launch measurable, safe, and operationally ready.

**Deliverables**
- QA matrix
- Instrumentation
- Launch gates
- Fallback and rollback plan

**E6-T1 — Define launch acceptance gates** (P1)
- Specify the mandatory pass criteria for taxonomy coverage, search quality, review separation, localization, and onboarding completeness.
- Acceptance criteria:
  - Go-live gates are explicit and measurable.
  - No launch without full locale coverage and separate review targets.
  - Owner assigned for each gate.
- Outputs:
  - launch checklist

**E6-T2 — Instrument search and review funnels** (P1)
- Track symptom search usage, direct search usage, result engagement, provider-vs-facility review submission rates, and taxonomy miss queries.
- Depends on: E2-T1, E2-T2, E3-T3
- Acceptance criteria:
  - Key events are defined and implemented.
  - Taxonomy gaps and zero-result searches are visible in analytics.
  - Review target confusion can be detected through funnel metrics.
- Outputs:
  - event schema
  - analytics dashboard spec

**E6-T3 — Create exhaustive QA matrix** (P1)
- Build a test matrix covering languages, taxonomy layers, search modes, provider/facility review targets, onboarding, and top symptom intents.
- Depends on: E5-T3
- Acceptance criteria:
  - Matrix covers all shipped locales and critical user journeys.
  - Top 50 symptom/concern intents are manually spot-checked.
  - Provider/facility review separation is validated in QA.
- Outputs:
  - qa_matrix
  - test cases

**E6-T4 — Rollout and rollback plan** (P2)
- Plan staged rollout, feature flags if needed, and rollback paths for taxonomy/search/review changes.
- Acceptance criteria:
  - Critical launch features can be disabled independently if needed.
  - Rollback path does not corrupt taxonomy or review data.
  - Operational runbook exists.
- Outputs:
  - runbook
  - flag matrix

## Immediate first sprint recommendation
1. Freeze the canonical taxonomy and create multilingual taxonomy resource files.
2. Define provider vs facility review schemas and rating dimensions.
3. Expand provider/facility onboarding to support the full taxonomy and pharmacy scope.
4. Implement unified direct search and the symptom / concern intake flow.
5. Harden localization, long-label controls, and validation in CI.

## Critical launch gates
- Full taxonomy coverage in all shipped locales.
- No English leakage in localized UX.
- Provider and facility public ratings remain separate everywhere.
- Symptom search presents guidance without diagnostic claims.
- Search works across direct and symptom modes with alias coverage.
- Pharmacy is fully supported in onboarding, search, and facility reviews.