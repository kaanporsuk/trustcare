# TrustCare Release Smoke Checklist

Run this checklist for release candidates after CI passes.

## Preconditions

1. Install and launch the latest RC build.
2. Use a clean test account and a seeded provider/test dataset.
3. Ensure network is available.
4. Confirm backend is pointing to production-ready Supabase project.

## A) Language Switcher

1. Open app language selector.
2. Verify all 16 languages are present:
   - en, tr, de, pl, nl, da, es, fr, it, ro, pt, uk, ru, sv, cs, hu
3. Verify labels are fully visible (no clipping, overlap, truncation in list rows).
4. Switch through at least 4 languages including `tr`, `de`, `fr`, `en` and verify app updates immediately.

## B) Discover Taxonomy Picker

1. Open Discover and open taxonomy picker.
2. In Turkish (`tr`), search `KBB` and verify ENT-related result appears.
3. In German (`de`), search `HNO` and verify ENT-related result appears.
4. In French (`fr`), search `ORL` and verify ENT-related result appears.
5. In English (`en`), search `GP` and verify `General Practice` appears.
6. Select multiple taxonomy items over time and verify **Recents** persist after app relaunch.
7. Verify **Top picks** labels are localized for active language.

## C) Provider Empty States (0 Results)

1. Apply strict filters to force 0 results.
2. Verify filtered empty state appears with correct premium guidance messaging.
3. Clear filters to unfiltered state where no data is available.
4. Verify unfiltered empty state appears and guidance differs from filtered state.

## D) Map/List Stability

1. Apply filters and select a provider.
2. Toggle between map and list views repeatedly.
3. Verify selected provider and filters are preserved.
4. Verify no UI flicker/jump or state reset occurs during toggles.

## E) Rehber

1. Send a normal query and verify response includes user-visible message and payload v1 structure.
2. Trigger malformed JSON response path (test stub or debug input) and verify app does not crash.
3. Tap suggestion pills and verify routing to Discover is reliable.
4. Submit emergency-urgency phrasing and verify emergency UI appears.

## F) Telemetry (taxonomy_search_logs)

1. Perform a no-results taxonomy search query in app.
2. In Supabase SQL editor, run:

```sql
select id, created_at, search_query, current_locale, results_count
from public.taxonomy_search_logs
order by created_at desc
limit 20;
```

3. Verify a new row exists for the no-results query with `results_count = 0`.
4. Verify row locale/query values match the test interaction.

## Pass/Fail Criteria

- PASS: All sections A-F pass without crash, data regression, or routing breakage.
- FAIL: Any missing language, incorrect taxonomy mapping, bad empty state guidance, unstable map/list state, Rehber routing/crash issue, or missing telemetry row.
