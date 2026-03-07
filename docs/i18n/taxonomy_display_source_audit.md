# Taxonomy Display Source Audit

## Canonical Taxonomy Label Sources
- Canonical IDs and entity types: `supabase/migrations/20260305000000_seed_canonical_ontology.sql` (mapping CTE `mapping(legacy_id, entity_id, entity_type)`).
- Internal/canonical English label map used in last export: `TrustCare/Resources/TaxonomyI18n/en.json` (mechanically humanized labels).
- Legacy polished English names (seeded source): `supabase/migrations/20260221000000_specialties_table.sql` (`specialties.name` values, ids 1..99).

## Runtime Display Label Path (Taxonomy Picker)
1. `TaxonomyPickerView` renders `Text(suggestion.label)` in `taxonomyRows` (`TrustCare/Views/Components/TaxonomyPickerView.swift`).
2. `TaxonomyPickerViewModel.resolveAll/resolveTopPicks/resolveRecents` call `TaxonomyService` (`TrustCare/Views/Components/TaxonomyPickerView.swift`).
3. `TaxonomyService.labelsByEntityID` fetches `taxonomy_labels.label` from Supabase and falls back to EN/default_name (`TrustCare/Services/TaxonomyService.swift`).
4. `TaxonomyService` passes fetched labels through `TaxonomyI18nLoader.localizedLabel(...)` (`TrustCare/Services/TaxonomyService.swift`).
5. `TaxonomyI18nLoader.loadMapping` only loads `Bundle.main.url(forResource: locale, withExtension: "json", subdirectory: "TaxonomyI18n")` (`TrustCare/Core/Services/TaxonomyI18nLoader.swift`).
6. Build artifact check: simulator app bundle contains `/TrustCare.app/en.json` but no `/TrustCare.app/TaxonomyI18n/en.json`; therefore loader subdirectory lookup misses and fallback DB labels are used at runtime.

## Findings
- Polished UI-facing English labels DO exist explicitly in repo and in DB seed lineage (`specialties.name` and `taxonomy_labels`).
- Previous export `docs/i18n/taxonomy_display_export_en.json` used internal/humanized labels from `TrustCare/Resources/TaxonomyI18n/en.json`, not the runtime DB-backed polished labels.
- Translation should be based on `display_english_label` (runtime user-facing copy), not `canonical_english_label` (internal/humanized copy).

## Concrete Mismatch Examples (current export vs runtime display)

| canonical_id | current_export_label | actual_ui_display_label | source_file_or_function |
|---|---|---|---|
| FAC_HOSPITAL_GENERAL | Hospital General | Hospital (General) | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| FAC_LABORATORY | Laboratory | Laboratory / Blood Tests | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| FAC_URGENT_CARE | Urgent Care | Urgent Care / Walk-in Clinic | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SERV_BOTOX_FILLERS | Botox Fillers | Botox & Fillers | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SERV_BREAST_AUGMENTATION_REDUCTION | Breast Augmentation Reduction | Breast Augmentation / Reduction | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SERV_CHEMICAL_PEEL_MICRONEEDLING | Chemical Peel Microneedling | Chemical Peels & Microneedling | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SERV_FACELIFT_NECKLIFT | Facelift Necklift | Facelift & Neck Lift | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SERV_LASIK_REFRACTIVE | LASIK Refractive | LASIK / Refractive Surgery | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SERV_LIPOSUCTION_BODY_CONTOURING | Liposuction Body Contouring | Liposuction & Body Contouring | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SERV_PRP_SKIN_REJUVENATION | PRP Skin Rejuvenation | Skin Rejuvenation / PRP | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SERV_SMILE_DESIGN | Smile Design | Dental Aesthetics (Smile Design) | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SERV_TCM | TCM | Traditional Chinese Medicine | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SPEC_ALLERGY_IMMUNOLOGY | Allergy Immunology | Allergy & Immunology | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SPEC_CHILD_ADOLESCENT_PSYCHIATRY | Child Adolescent Psychiatry | Child & Adolescent Psychiatry | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SPEC_DENTISTRY_GENERAL | Dentistry General | General Dentistry | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SPEC_ENT | ENT | ENT / Otolaryngology | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SPEC_GENETICS_GENOMICS | Genetics Genomics | Genetics & Genomics | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SPEC_HEAD_NECK_SURGERY | Head Neck Surgery | Head & Neck Surgery | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SPEC_MATERNAL_FETAL_MEDICINE | Maternal Fetal Medicine | Maternal-Fetal Medicine | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |
| SPEC_NUTRITION_DIETETICS | Nutrition Dietetics | Nutrition & Dietetics | supabase/migrations/20260221000000_specialties_table.sql (name) -> TaxonomyService.labelsByEntityID -> TaxonomyPickerView.Text(suggestion.label) |

- Total mismatches found: 26
