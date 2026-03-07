#!/usr/bin/env swift
import Foundation

private let expectedTaxonomyCount = 150
private let expectedConcernCount = 19
private let shippedLocales = ["cs", "da", "de", "es", "fr", "hu", "it", "nl", "pl", "pt", "ro", "ru", "sv", "tr", "uk"]

struct TaxonomyEntry: Decodable {
    let canonicalID: String
    let entityType: String
    let displayEnglishLabel: String
    let aliasesEnglish: [String]
    let launchScope: String?

    enum CodingKeys: String, CodingKey {
        case canonicalID = "canonical_id"
        case entityType = "entity_type"
        case displayEnglishLabel = "display_english_label"
        case aliasesEnglish = "aliases_english"
        case launchScope = "launch_scope"
    }
}

struct ConcernEntry: Decodable {
    let canonicalID: String
    let displayEnglishLabel: String
    let exampleInputs: [String]
    let likelySpecialtyIDs: [String]
    let likelyTreatmentIDs: [String]
    let likelyFacilityTypeIDs: [String]
    let launchScope: String?

    enum CodingKeys: String, CodingKey {
        case canonicalID = "canonical_id"
        case displayEnglishLabel = "display_english_label"
        case exampleInputs = "example_inputs"
        case likelySpecialtyIDs = "likely_specialty_ids"
        case likelyTreatmentIDs = "likely_treatment_procedure_ids"
        case legacyLikelyTreatmentIDs = "likely_treatment_ids"
        case likelyFacilityTypeIDs = "likely_facility_type_ids"
        case launchScope = "launch_scope"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        canonicalID = try container.decode(String.self, forKey: .canonicalID)
        displayEnglishLabel = try container.decode(String.self, forKey: .displayEnglishLabel)
        exampleInputs = try container.decodeIfPresent([String].self, forKey: .exampleInputs) ?? []
        likelySpecialtyIDs = try container.decodeIfPresent([String].self, forKey: .likelySpecialtyIDs) ?? []
        likelyTreatmentIDs =
            try container.decodeIfPresent([String].self, forKey: .likelyTreatmentIDs)
            ?? container.decodeIfPresent([String].self, forKey: .legacyLikelyTreatmentIDs)
            ?? []
        likelyFacilityTypeIDs = try container.decodeIfPresent([String].self, forKey: .likelyFacilityTypeIDs) ?? []
        launchScope = try container.decodeIfPresent(String.self, forKey: .launchScope)
    }
}

struct CanonicalPayload: Decodable {
    let taxonomy: [TaxonomyEntry]
}

struct ConcernPayload: Decodable {
    let concernDomains: [ConcernEntry]

    enum CodingKeys: String, CodingKey {
        case concernDomains = "concern_domains"
        case legacySymptomConcerns = "symptom_concerns"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        concernDomains =
            try container.decodeIfPresent([ConcernEntry].self, forKey: .concernDomains)
            ?? container.decodeIfPresent([ConcernEntry].self, forKey: .legacySymptomConcerns)
            ?? []
    }
}

struct LabelsPayload: Decodable {
    let labels: [String: String]
}

struct AliasesPayload: Decodable {
    let aliases: [String: [String]]
}

struct ProposalTaxonomyItem: Decodable {
    let canonicalID: String
    let displayEnglishLabel: String
    let searchAliases: [String]

    enum CodingKeys: String, CodingKey {
        case canonicalID = "canonical_id"
        case displayEnglishLabel = "display_english_label"
        case searchAliases = "search_aliases"
    }
}

struct ProposalTaxonomyRoot: Decodable {
    let specialties: [ProposalTaxonomyItem]
    let treatmentProcedures: [ProposalTaxonomyItem]
    let facilityTypes: [ProposalTaxonomyItem]

    enum CodingKeys: String, CodingKey {
        case specialties
        case treatmentProcedures = "treatment_procedures"
        case facilityTypes = "facility_types"
    }
}

struct ProposalConcernItem: Decodable {
    let canonicalID: String
    let displayEnglishLabel: String
    let exampleInputs: [String]

    enum CodingKeys: String, CodingKey {
        case canonicalID = "canonical_id"
        case displayEnglishLabel = "display_english_label"
        case exampleInputs = "example_inputs"
    }
}

struct ProposalPayload: Decodable {
    let taxonomy: ProposalTaxonomyRoot
    let symptomConcernDomains: [ProposalConcernItem]

    enum CodingKeys: String, CodingKey {
        case taxonomy
        case symptomConcernDomains = "symptom_concern_domains"
    }
}

let fileManager = FileManager.default
let repoRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let canonicalURL = repoRoot.appendingPathComponent("TrustCare/Resources/TaxonomyV21/base/taxonomy_v21_base_en.json")
let concernsURL = repoRoot.appendingPathComponent("TrustCare/Resources/TaxonomyV21/concerns/taxonomy_v21_concern_domains_en.json")
let labelsURL = repoRoot.appendingPathComponent("TrustCare/Resources/TaxonomyV21/labels/taxonomy_v21_locale_labels_en.json")
let aliasesURL = repoRoot.appendingPathComponent("TrustCare/Resources/TaxonomyV21/aliases/taxonomy_v21_aliases_en.json")
let proposalURL = repoRoot.appendingPathComponent("docs/taxonomy/trustcare_taxonomy_v2_1_proposal.json")

func fail(_ message: String) -> Never {
    fputs("FAIL: \(message)\n", stderr)
    exit(1)
}

guard fileManager.fileExists(atPath: canonicalURL.path) else {
    fail("Missing canonical file at TrustCare/Resources/TaxonomyV21/base/taxonomy_v21_base_en.json")
}

guard fileManager.fileExists(atPath: concernsURL.path) else {
    fail("Missing concern file at TrustCare/Resources/TaxonomyV21/concerns/taxonomy_v21_concern_domains_en.json")
}

guard fileManager.fileExists(atPath: labelsURL.path) else {
    fail("Missing labels file at TrustCare/Resources/TaxonomyV21/labels/taxonomy_v21_locale_labels_en.json")
}

guard fileManager.fileExists(atPath: aliasesURL.path) else {
    fail("Missing aliases file at TrustCare/Resources/TaxonomyV21/aliases/taxonomy_v21_aliases_en.json")
}

guard fileManager.fileExists(atPath: proposalURL.path) else {
    fail("Missing proposal source at docs/taxonomy/trustcare_taxonomy_v2_1_proposal.json")
}

let decoder = JSONDecoder()

let canonicalPayload: CanonicalPayload
let concernPayload: ConcernPayload
let labelsPayload: LabelsPayload
let aliasesPayload: AliasesPayload
let proposalPayload: ProposalPayload

do {
    canonicalPayload = try decoder.decode(CanonicalPayload.self, from: Data(contentsOf: canonicalURL))
    concernPayload = try decoder.decode(ConcernPayload.self, from: Data(contentsOf: concernsURL))
    labelsPayload = try decoder.decode(LabelsPayload.self, from: Data(contentsOf: labelsURL))
    aliasesPayload = try decoder.decode(AliasesPayload.self, from: Data(contentsOf: aliasesURL))
    proposalPayload = try decoder.decode(ProposalPayload.self, from: Data(contentsOf: proposalURL))
} catch {
    fail("Unable to decode taxonomy v2.1 files: \(error.localizedDescription)")
}

let allowedEntityTypes: Set<String> = ["specialty", "treatment_procedure", "facility_type"]

var errors: [String] = []

if canonicalPayload.taxonomy.count != expectedTaxonomyCount {
    errors.append("Expected exactly \(expectedTaxonomyCount) taxonomy entries, found \(canonicalPayload.taxonomy.count)")
}

if concernPayload.concernDomains.count != expectedConcernCount {
    errors.append("Expected exactly \(expectedConcernCount) concern-domain entries, found \(concernPayload.concernDomains.count)")
}

let canonicalIDs = canonicalPayload.taxonomy.map(\.canonicalID)
let duplicateIDs = Dictionary(grouping: canonicalIDs, by: { $0 }).filter { $1.count > 1 }.keys.sorted()
if !duplicateIDs.isEmpty {
    errors.append("Duplicate canonical_id entries: \(duplicateIDs)")
}

for item in canonicalPayload.taxonomy {
    if !allowedEntityTypes.contains(item.entityType) {
        errors.append("Invalid entity_type for \(item.canonicalID): \(item.entityType)")
    }

    if item.displayEnglishLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        errors.append("Missing display_english_label for \(item.canonicalID)")
    }

    if item.launchScope != "v2_1_core" {
        errors.append("Unexpected launch_scope for \(item.canonicalID): \(item.launchScope ?? "<nil>")")
    }

    if labelsPayload.labels[item.canonicalID]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
        errors.append("Missing English label mapping in labels file for \(item.canonicalID)")
    }

    if aliasesPayload.aliases[item.canonicalID] == nil {
        errors.append("Missing aliases mapping for canonical ID \(item.canonicalID)")
    }
}

let canonicalIDSet = Set(canonicalIDs)

let concernIDs = concernPayload.concernDomains.map(\.canonicalID)
let duplicateConcernIDs = Dictionary(grouping: concernIDs, by: { $0 }).filter { $1.count > 1 }.keys.sorted()
if !duplicateConcernIDs.isEmpty {
    errors.append("Duplicate concern canonical_id entries: \(duplicateConcernIDs)")
}

for concern in concernPayload.concernDomains {
    if !concern.canonicalID.hasPrefix("CONCERN_") {
        errors.append("Concern ID must be CONCERN_*: \(concern.canonicalID)")
    }

    if concern.displayEnglishLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        errors.append("Missing display_english_label for concern \(concern.canonicalID)")
    }

    if concern.launchScope != "v2_1_core" {
        errors.append("Unexpected launch_scope for concern \(concern.canonicalID): \(concern.launchScope ?? "<nil>")")
    }

    let allLinks = concern.likelySpecialtyIDs + concern.likelyTreatmentIDs + concern.likelyFacilityTypeIDs
    if allLinks.isEmpty {
        errors.append("Concern \(concern.canonicalID) has no taxonomy links")
    }

    let missingLinks = allLinks.filter { !canonicalIDSet.contains($0) }
    if !missingLinks.isEmpty {
        errors.append("Concern \(concern.canonicalID) references unknown IDs: \(missingLinks)")
    }

    if labelsPayload.labels[concern.canonicalID]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
        errors.append("Missing English label mapping in labels file for concern \(concern.canonicalID)")
    }
}

let allowedAliasIDs = Set(canonicalIDs + concernIDs)
let unknownAliasIDs = aliasesPayload.aliases.keys.filter { !allowedAliasIDs.contains($0) }.sorted()
if !unknownAliasIDs.isEmpty {
    errors.append("Aliases file contains unknown canonical IDs: \(unknownAliasIDs)")
}

for concernID in concernIDs where aliasesPayload.aliases[concernID] == nil {
    errors.append("Missing aliases mapping for concern ID \(concernID)")
}

let proposalTaxonomyItems = proposalPayload.taxonomy.specialties
    + proposalPayload.taxonomy.treatmentProcedures
    + proposalPayload.taxonomy.facilityTypes
let proposalTaxonomyIDs = Set(proposalTaxonomyItems.map(\.canonicalID))
let runtimeTaxonomyIDs = Set(canonicalIDs)

if proposalTaxonomyIDs != runtimeTaxonomyIDs {
    let missing = proposalTaxonomyIDs.subtracting(runtimeTaxonomyIDs).sorted()
    let extra = runtimeTaxonomyIDs.subtracting(proposalTaxonomyIDs).sorted()
    if !missing.isEmpty {
        errors.append("Runtime taxonomy missing proposal IDs: \(missing)")
    }
    if !extra.isEmpty {
        errors.append("Runtime taxonomy has extra non-proposal IDs: \(extra)")
    }
}

let proposalConcernIDs = Set(proposalPayload.symptomConcernDomains.map(\.canonicalID))
let runtimeConcernIDs = Set(concernIDs)
if proposalConcernIDs != runtimeConcernIDs {
    let missing = proposalConcernIDs.subtracting(runtimeConcernIDs).sorted()
    let extra = runtimeConcernIDs.subtracting(proposalConcernIDs).sorted()
    if !missing.isEmpty {
        errors.append("Runtime concerns missing proposal IDs: \(missing)")
    }
    if !extra.isEmpty {
        errors.append("Runtime concerns have extra non-proposal IDs: \(extra)")
    }
}

let runtimeLabelMap = labelsPayload.labels
let runtimeAliasMap = aliasesPayload.aliases

for item in proposalTaxonomyItems {
    if runtimeLabelMap[item.canonicalID] != item.displayEnglishLabel {
        errors.append("Label drift for \(item.canonicalID): runtime='\(runtimeLabelMap[item.canonicalID] ?? "<nil>")' proposal='\(item.displayEnglishLabel)'")
    }

    let runtimeAliases = Set((runtimeAliasMap[item.canonicalID] ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
    let proposalAliases = Set(item.searchAliases.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
    if runtimeAliases != proposalAliases {
        errors.append("Alias drift for \(item.canonicalID)")
    }
}

for concern in proposalPayload.symptomConcernDomains {
    if runtimeLabelMap[concern.canonicalID] != concern.displayEnglishLabel {
        errors.append("Label drift for concern \(concern.canonicalID): runtime='\(runtimeLabelMap[concern.canonicalID] ?? "<nil>")' proposal='\(concern.displayEnglishLabel)'")
    }

    let runtimeAliases = Set((runtimeAliasMap[concern.canonicalID] ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
    let proposalAliases = Set(concern.exampleInputs.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
    if runtimeAliases != proposalAliases {
        errors.append("Alias drift for concern \(concern.canonicalID)")
    }
}

// Locale coverage validation for imported shipped locales.
for locale in shippedLocales {
    let localeLabelsURL = repoRoot.appendingPathComponent("TrustCare/Resources/TaxonomyV21/labels/taxonomy_v21_locale_labels_\(locale).json")
    let localeAliasesURL = repoRoot.appendingPathComponent("TrustCare/Resources/TaxonomyV21/aliases/taxonomy_v21_aliases_\(locale).json")

    guard fileManager.fileExists(atPath: localeLabelsURL.path) else {
        errors.append("Missing locale labels file: \(localeLabelsURL.path)")
        continue
    }
    guard fileManager.fileExists(atPath: localeAliasesURL.path) else {
        errors.append("Missing locale aliases file: \(localeAliasesURL.path)")
        continue
    }

    let localeLabelsPayload: LabelsPayload
    let localeAliasesPayload: AliasesPayload
    do {
        localeLabelsPayload = try decoder.decode(LabelsPayload.self, from: Data(contentsOf: localeLabelsURL))
        localeAliasesPayload = try decoder.decode(AliasesPayload.self, from: Data(contentsOf: localeAliasesURL))
    } catch {
        errors.append("Unable to decode locale files for \(locale): \(error.localizedDescription)")
        continue
    }

    let localeLabelIDs = Set(localeLabelsPayload.labels.keys)
    let localeAliasIDs = Set(localeAliasesPayload.aliases.keys)

    let missingLabelIDs = allowedAliasIDs.subtracting(localeLabelIDs).sorted()
    let extraLabelIDs = localeLabelIDs.subtracting(allowedAliasIDs).sorted()
    if !missingLabelIDs.isEmpty {
        errors.append("Locale \(locale) missing label IDs: \(missingLabelIDs)")
    }
    if !extraLabelIDs.isEmpty {
        errors.append("Locale \(locale) has unknown label IDs: \(extraLabelIDs)")
    }

    let missingAliasIDs = allowedAliasIDs.subtracting(localeAliasIDs).sorted()
    let extraAliasIDs = localeAliasIDs.subtracting(allowedAliasIDs).sorted()
    if !missingAliasIDs.isEmpty {
        errors.append("Locale \(locale) missing alias IDs: \(missingAliasIDs)")
    }
    if !extraAliasIDs.isEmpty {
        errors.append("Locale \(locale) has unknown alias IDs: \(extraAliasIDs)")
    }

    let emptyLocalizedLabels = localeLabelsPayload.labels
        .filter { $0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .map(\.key)
        .sorted()
    if !emptyLocalizedLabels.isEmpty {
        errors.append("Locale \(locale) has empty localized labels: \(emptyLocalizedLabels)")
    }

    let emptyConcernAliases = concernIDs.filter { concernID in
        let aliases = localeAliasesPayload.aliases[concernID] ?? []
        return aliases.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.isEmpty
    }.sorted()
    if !emptyConcernAliases.isEmpty {
        errors.append("Locale \(locale) has empty concern example-input aliases: \(emptyConcernAliases)")
    }
}

if errors.isEmpty {
    print("PASS: taxonomy_v2_1 validation succeeded")
    print("- taxonomy entries: \(canonicalPayload.taxonomy.count)")
    print("- concern entries: \(concernPayload.concernDomains.count)")
    print("- english labels: \(labelsPayload.labels.count)")
    print("- english alias groups: \(aliasesPayload.aliases.count)")
    print("- locale coverage verified: \(shippedLocales.count) locales")
    exit(0)
}

print("FAIL: taxonomy_v2_1 validation found \(errors.count) issue(s)")
for issue in errors {
    print("- \(issue)")
}
exit(1)
