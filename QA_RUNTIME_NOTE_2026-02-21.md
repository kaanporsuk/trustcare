# Runtime QA Note — 2026-02-21

## Scope
Validation pass for the surgical refactor covering:
- Avatar upload storage behavior + Supabase RLS policy migration
- Home header pinning / empty-state jump fix
- Map legend and top pill filter synchronization
- Map "Search this area" interaction

## Automated Verification (Completed)
- ✅ Supabase project linkage verified as `wabgklhhrviqcfdiwofu`.
- ✅ Migration pushed: `20260221170000_avatar_insert_policy.sql` (`npx supabase db push` completed).
- ✅ App compiles successfully (`xcodebuild ... build` → `BUILD SUCCEEDED`).
- ✅ Home fixed-header structure present:
  - Top-level `VStack(spacing: 0)`
  - Header controls always rendered above a content `ZStack`
  - Content area uses `.frame(maxWidth: .infinity, maxHeight: .infinity)`
- ✅ Single source of truth enforced for category filtering:
  - `HomeViewModel.selectedSurveyType` is used by both top pills and map legend.
  - No remaining `mapFilterSurveyType` references.
- ✅ Map camera-based search interaction implemented:
  - `showSearchAreaButton` state
  - `.onMapCameraChange(frequency: .onEnd)` sets visibility
  - Floating "Search this area" pill triggers `fetchProviders(in:)` and hides after fetch

## Manual Runtime Checks (Simulator / Device)
- [ ] Home tab with zero provider results: verify search bar, category pills, and list/map toggle stay pinned at top with no vertical jump.
- [ ] Tap top category pills in map mode: verify map legend selected state updates immediately.
- [ ] Tap categories in map legend: verify top pill selected state updates immediately.
- [ ] Pan map in map mode: verify "Search this area" pill appears at top center.
- [ ] Tap "Search this area": verify provider list updates for new bounds and pill disappears.
- [ ] Upload profile photo twice in a row: verify both uploads succeed with no RLS collision and latest avatar appears.

## Status
- Code-level and build-level verification: PASSED.
- Visual/interaction runtime verification: pending manual execution in Simulator/device.
