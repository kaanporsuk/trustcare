# Localization Workflow

This phase adds repeatable localization verification without changing UI behavior.

## Add New Localized Strings

1. Add the key to `TrustCare/Localizable.xcstrings` using `snake_case` key names.
2. Provide an English source value (`en`) and translated values for launch locales.
3. Use the key in Swift via `tcString("your_key", fallback: "English fallback")` or `Text(tcKey: "your_key", fallback: "English fallback")`.
4. Avoid using literal English sentences as lookup keys in new code. Use stable keys.
5. Before shipping, run `make localization-regression` and an app build.

## Taxonomy Locale Resolution At Runtime

Runtime taxonomy labels are resolved by `TaxonomyCatalogStore` first, then compatibility fallbacks:

1. Primary base taxonomy file:
   - `TrustCare/Resources/TaxonomyV21/base/taxonomy_v21_base_en.json`
2. Primary concern domains file:
   - `TrustCare/Resources/TaxonomyV21/concerns/taxonomy_v21_concern_domains_en.json`
3. Primary locale label files:
   - `TrustCare/Resources/TaxonomyV21/labels/taxonomy_v21_locale_labels_<locale>.json`
4. Primary locale alias files:
   - `TrustCare/Resources/TaxonomyV21/aliases/taxonomy_v21_aliases_<locale>.json`
5. Legacy compatibility fallbacks (English only) remain in code for safety:
   - `taxonomy_v21_canonical_en.json`
   - `taxonomy_v21_symptom_concern_en.json`
   - `taxonomy_v21_labels_en.json`
   - `taxonomy_v21_aliases_en.json`

Reference implementation:
- `TrustCare/Core/Services/TaxonomyCatalogStore.swift`
- `TrustCare/Core/Services/TaxonomyI18nLoader.swift`

## Localization Verification Before Shipping

Run the repeatable localization regression suite:

```sh
make localization-regression
```

This runs:
- `swift tools/taxonomy_phase2_regression.swift`
- `swift tools/my_reviews_empty_state_regression.swift`
- `swift tools/localization_ui_fit_regression.swift`

CI also runs this suite in:
- `.github/workflows/verify.yml`

Then run build verification:

```sh
xcodebuild -scheme TrustCare -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Deprecated/Stale Localization Audit Snapshot (2026-03-07)

Remaining deprecated or stale paths/keys identified:

1. Deprecated key still present in string catalog:
   - `TrustCare/Localizable.xcstrings` contains `my_reviews_empty_subtitle` (replaced in UI by `my_reviews_empty_message`).
2. Deprecated import helper still targets old key:
   - `scripts/import_my_reviews_empty_subtitle.py`
3. Legacy taxonomy fallback resources are still referenced in runtime store for compatibility:
   - `TrustCare/Core/Services/TaxonomyCatalogStore.swift` references `taxonomy_v21_canonical_en`, `taxonomy_v21_symptom_concern_en`, `taxonomy_v21_labels_en`, `taxonomy_v21_aliases_en`.
4. Legacy taxonomy i18n folder loader remains as fallback compatibility path:
   - `TrustCare/Core/Services/TaxonomyI18nLoader.swift` reads from `TaxonomyI18n/<locale>.json`.
5. Additional cleanup candidate (not changed in this phase): several call sites still pass literal English strings as `tcString` keys instead of stable key IDs.

Note: QA deep links/tools are still guarded with `#if DEBUG` in `TrustCare/TrustCareApp.swift` and `TrustCare/Views/Debug/LocalizationFitPreviewView.swift`.
