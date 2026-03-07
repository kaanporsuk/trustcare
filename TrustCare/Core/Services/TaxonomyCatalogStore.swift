import Foundation

enum TaxonomyIdentity {
    static let cacheVersion = "taxonomy-v21-localization-phase1"

    static func normalizedLocale(_ locale: String) -> String {
        locale
            .components(separatedBy: ["-", "_"])
            .first?
            .lowercased() ?? "en"
    }

    static func normalizedCanonicalID(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    static func normalizedAliasKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}

struct TaxonomyCanonicalEntry: Decodable, Hashable {
    let canonicalID: String
    let entityType: String
    let displayEnglishLabel: String
    let aliasesEnglish: [String]
    let parentGroup: String?
    let relatedIDs: [String]?
    let modalityBucket: String?
    let launchScope: String?

    enum CodingKeys: String, CodingKey {
        case canonicalID = "canonical_id"
        case entityType = "entity_type"
        case displayEnglishLabel = "display_english_label"
        case aliasesEnglish = "aliases_english"
        case parentGroup = "parent_group"
        case relatedIDs = "related_ids"
        case modalityBucket = "modality_bucket"
        case launchScope = "launch_scope"
    }
}

struct SymptomConcernEntry: Decodable, Hashable {
    let canonicalID: String
    let displayEnglishLabel: String
    let aliasesEnglish: [String]
    let likelySpecialtyIDs: [String]
    let likelyTreatmentProcedureIDs: [String]
    let likelyFacilityTypeIDs: [String]
    let urgencyFlag: String?
    let careSettingHint: String?
    let launchScope: String?

    enum CodingKeys: String, CodingKey {
        case canonicalID = "canonical_id"
        case displayEnglishLabel = "display_english_label"
        case aliasesEnglish = "aliases_english"
        case exampleInputs = "example_inputs"
        case likelySpecialtyIDs = "likely_specialty_ids"
        case likelyTreatmentIDs = "likely_treatment_ids"
        case likelyTreatmentProcedureIDs = "likely_treatment_procedure_ids"
        case likelyFacilityTypeIDs = "likely_facility_type_ids"
        case relatedIDs = "related_ids"
        case urgencySensitive = "urgency_sensitive"
        case urgencyFlag = "urgency_flag"
        case careSettingHint = "care_setting_hint"
        case launchScope = "launch_scope"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        canonicalID = try container.decode(String.self, forKey: .canonicalID)
        displayEnglishLabel = try container.decode(String.self, forKey: .displayEnglishLabel)

        let legacyAliases = try container.decodeIfPresent([String].self, forKey: .aliasesEnglish) ?? []
        let proposalAliases = try container.decodeIfPresent([String].self, forKey: .exampleInputs) ?? []
        aliasesEnglish = Self.dedupeArray(legacyAliases + proposalAliases)

        let related = try container.decodeIfPresent([String].self, forKey: .relatedIDs) ?? []
        let proposalSpecialties = try container.decodeIfPresent([String].self, forKey: .likelySpecialtyIDs) ?? []
        let proposalTreatments =
            try container.decodeIfPresent([String].self, forKey: .likelyTreatmentProcedureIDs)
            ?? container.decodeIfPresent([String].self, forKey: .likelyTreatmentIDs)
            ?? []
        let proposalFacilities = try container.decodeIfPresent([String].self, forKey: .likelyFacilityTypeIDs) ?? []

        likelySpecialtyIDs = Self.dedupeArray(proposalSpecialties + related.filter { $0.hasPrefix("SPEC_") })
        likelyTreatmentProcedureIDs = Self.dedupeArray(proposalTreatments + related.filter { $0.hasPrefix("SERV_") })
        likelyFacilityTypeIDs = Self.dedupeArray(proposalFacilities + related.filter { $0.hasPrefix("FAC_") })

        if let urgencyFlag = try container.decodeIfPresent(String.self, forKey: .urgencyFlag) {
            self.urgencyFlag = urgencyFlag
        } else if let urgencySensitive = try container.decodeIfPresent(Bool.self, forKey: .urgencySensitive) {
            self.urgencyFlag = urgencySensitive ? "medium" : "low"
        } else {
            self.urgencyFlag = nil
        }

        careSettingHint = try container.decodeIfPresent(String.self, forKey: .careSettingHint)
        launchScope = try container.decodeIfPresent(String.self, forKey: .launchScope)
    }

    private static func dedupeArray(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []

        for value in values {
            guard seen.insert(value).inserted else { continue }
            ordered.append(value)
        }

        return ordered
    }
}

final class TaxonomyCatalogStore {
    static let shared = TaxonomyCatalogStore()

    struct LabelResolution {
        let label: String
        let normalizedIncomingID: String
        let source: String
    }

    private struct CanonicalPayload: Decodable {
        let taxonomy: [TaxonomyCanonicalEntry]
        let symptomConcerns: [SymptomConcernEntry]

        enum CodingKeys: String, CodingKey {
            case taxonomy
            case symptomConcerns = "symptom_concerns"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            taxonomy = try container.decodeIfPresent([TaxonomyCanonicalEntry].self, forKey: .taxonomy) ?? []
            symptomConcerns = try container.decodeIfPresent([SymptomConcernEntry].self, forKey: .symptomConcerns) ?? []
        }

        init(taxonomy: [TaxonomyCanonicalEntry], symptomConcerns: [SymptomConcernEntry]) {
            self.taxonomy = taxonomy
            self.symptomConcerns = symptomConcerns
        }
    }

    private struct ConcernPayload: Decodable {
        let concernDomains: [SymptomConcernEntry]

        enum CodingKeys: String, CodingKey {
            case concernDomains = "concern_domains"
            case symptomConcerns = "symptom_concerns"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            concernDomains =
                try container.decodeIfPresent([SymptomConcernEntry].self, forKey: .concernDomains)
                ?? container.decodeIfPresent([SymptomConcernEntry].self, forKey: .symptomConcerns)
                ?? []
        }

        init(concernDomains: [SymptomConcernEntry]) {
            self.concernDomains = concernDomains
        }
    }

    private struct LabelsPayload: Decodable {
        let labels: [String: String]
    }

    private struct AliasesPayload: Decodable {
        let aliases: [String: [String]]
    }

    private let lock = NSLock()
    private var canonicalCache: CanonicalPayload?
    private var concernCache: ConcernPayload?
    private var labelsCache: [String: [String: String]] = [:]
    private var aliasesCache: [String: [String: [String]]] = [:]
    private var aliasLookupCache: [String: [String: String]] = [:]
    private var activeCacheVersion: String = TaxonomyIdentity.cacheVersion

    private init() {}

    func localizedLabel(for canonicalID: String, locale: String) -> String? {
        localizedLabelResolution(for: canonicalID, locale: locale)?.label
    }

    func localizedLabelResolution(for canonicalOrAlias: String, locale: String) -> LabelResolution? {
        ensureCacheVersion()

        let incomingID = canonicalOrAlias.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedIncomingID = TaxonomyIdentity.normalizedCanonicalID(incomingID)
        guard !normalizedIncomingID.isEmpty else { return nil }

        let localeCode = TaxonomyIdentity.normalizedLocale(locale)
        let localeMap = labels(for: localeCode)
        let englishMap = labels(for: "en")

        let resolvedCanonicalID: String
        let idResolutionSource: String

        if hasExactCanonicalID(incomingID) {
            resolvedCanonicalID = incomingID
            idResolutionSource = "exact_canonical_id"
        } else if containsCanonicalID(normalizedIncomingID) {
            resolvedCanonicalID = normalizedIncomingID
            idResolutionSource = "normalized_canonical_id"
        } else if let aliasResolvedID = canonicalIDFromAlias(incomingID, locale: localeCode) {
            resolvedCanonicalID = aliasResolvedID
            idResolutionSource = "normalized_alias"
        } else {
            resolvedCanonicalID = normalizedIncomingID
            idResolutionSource = "normalized_canonical_id"
        }

        if let value = localeMap[resolvedCanonicalID], !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return LabelResolution(
                label: value,
                normalizedIncomingID: normalizedIncomingID,
                source: "\(idResolutionSource)>locale_label_map"
            )
        }

        if let value = englishMap[resolvedCanonicalID], !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return LabelResolution(
                label: value,
                normalizedIncomingID: normalizedIncomingID,
                source: "\(idResolutionSource)>english_label_map"
            )
        }

        if let value = canonicalEntry(by: resolvedCanonicalID)?.displayEnglishLabel,
           !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return LabelResolution(
                label: value,
                normalizedIncomingID: normalizedIncomingID,
                source: "\(idResolutionSource)>canonical_english_default"
            )
        }

        return nil
    }

    func aliases(for canonicalID: String, locale: String) -> [String] {
        ensureCacheVersion()

        let normalizedID = TaxonomyIdentity.normalizedCanonicalID(canonicalID)
        guard !normalizedID.isEmpty else { return [] }

        let localeCode = TaxonomyIdentity.normalizedLocale(locale)
        let localeAliases = aliasMap(for: localeCode)[normalizedID] ?? []
        let englishAliases = aliasMap(for: "en")[normalizedID] ?? []
        let canonicalAliases = canonicalEntry(by: normalizedID)?.aliasesEnglish ?? []

        let merged = localeAliases + englishAliases + canonicalAliases
        return dedupeAliases(merged)
    }

    func containsCanonicalID(_ canonicalID: String) -> Bool {
        ensureCacheVersion()

        let normalizedID = TaxonomyIdentity.normalizedCanonicalID(canonicalID)
        guard !normalizedID.isEmpty else { return false }
        return canonicalEntry(by: normalizedID) != nil || symptomConcerns().contains(where: { $0.canonicalID == normalizedID })
    }

    func canonicalEntry(by canonicalID: String) -> TaxonomyCanonicalEntry? {
        ensureCacheVersion()

        let normalizedID = TaxonomyIdentity.normalizedCanonicalID(canonicalID)
        guard !normalizedID.isEmpty else { return nil }
        return canonicalPayload().taxonomy.first(where: { $0.canonicalID == normalizedID })
    }

    func canonicalEntries(for entityType: TaxonomyEntityType) -> [TaxonomyCanonicalEntry] {
        ensureCacheVersion()

        return canonicalPayload().taxonomy.filter { entry in
            TaxonomyEntityType.fromBackend(entry.entityType) == entityType || entry.entityType == entityType.rawValue
        }
    }

    func symptomConcerns() -> [SymptomConcernEntry] {
        ensureCacheVersion()

        let concerns = concernPayload().concernDomains
        return concerns.isEmpty ? canonicalPayload().symptomConcerns : concerns
    }

    func localSuggestions(entityType: TaxonomyEntityType?, locale: String, limit: Int) -> [TaxonomySuggestion] {
        var rows: [TaxonomySuggestion] = []

        if entityType == nil || entityType == .symptomConcern {
            rows.append(contentsOf: symptomConcerns().map { entry in
                TaxonomySuggestion(
                    entityId: entry.canonicalID,
                    entityType: TaxonomyEntityType.symptomConcern.rawValue,
                    label: localizedLabel(for: entry.canonicalID, locale: locale) ?? entry.displayEnglishLabel,
                    score: nil
                )
            })
        }

        for type in TaxonomyEntityType.pickerCases where entityType == nil || entityType == type {
            rows.append(contentsOf: canonicalEntries(for: type).map { entry in
                TaxonomySuggestion(
                    entityId: entry.canonicalID,
                    entityType: type.rawValue,
                    label: localizedLabel(for: entry.canonicalID, locale: locale) ?? entry.displayEnglishLabel,
                    score: nil
                )
            })
        }

        return Array(rows.prefix(limit))
    }

    func hasLocalTaxonomyCorpus() -> Bool {
        ensureCacheVersion()
        return !canonicalPayload().taxonomy.isEmpty
    }

    func hasLocalConcernCorpus() -> Bool {
        ensureCacheVersion()
        return !symptomConcerns().isEmpty
    }

    private func hasExactCanonicalID(_ value: String) -> Bool {
        guard !value.isEmpty else { return false }
        return canonicalPayload().taxonomy.contains(where: { $0.canonicalID == value })
            || symptomConcerns().contains(where: { $0.canonicalID == value })
    }

    private func canonicalIDFromAlias(_ aliasOrID: String, locale: String) -> String? {
        let normalizedAlias = TaxonomyIdentity.normalizedAliasKey(aliasOrID)
        guard !normalizedAlias.isEmpty else { return nil }

        if let localeMatch = aliasLookup(for: locale)[normalizedAlias] {
            return localeMatch
        }

        if locale != "en", let englishMatch = aliasLookup(for: "en")[normalizedAlias] {
            return englishMatch
        }

        return nil
    }

    private func aliasLookup(for locale: String) -> [String: String] {
        lock.lock()
        if let cached = aliasLookupCache[locale] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let localeAliases = aliasMap(for: locale)
        let englishAliases = aliasMap(for: "en")
        let localeLabels = labels(for: locale)
        let englishLabels = labels(for: "en")

        var mapping: [String: String] = [:]

        func insert(_ rawValue: String, canonicalID: String) {
            let key = TaxonomyIdentity.normalizedAliasKey(rawValue)
            guard !key.isEmpty else { return }
            if mapping[key] == nil {
                mapping[key] = canonicalID
            }
        }

        let canonicalIDs = Set(canonicalPayload().taxonomy.map(\.canonicalID) + symptomConcerns().map(\.canonicalID))
        for canonicalID in canonicalIDs {
            insert(canonicalID, canonicalID: canonicalID)
            insert(localeLabels[canonicalID] ?? "", canonicalID: canonicalID)
            insert(englishLabels[canonicalID] ?? "", canonicalID: canonicalID)
            for alias in localeAliases[canonicalID] ?? [] {
                insert(alias, canonicalID: canonicalID)
            }
            for alias in englishAliases[canonicalID] ?? [] {
                insert(alias, canonicalID: canonicalID)
            }
            for alias in canonicalEntry(by: canonicalID)?.aliasesEnglish ?? [] {
                insert(alias, canonicalID: canonicalID)
            }
        }

        lock.lock()
        aliasLookupCache[locale] = mapping
        lock.unlock()

        return mapping
    }

    private func ensureCacheVersion() {
        lock.lock()
        defer { lock.unlock() }

        guard activeCacheVersion != TaxonomyIdentity.cacheVersion else { return }

        canonicalCache = nil
        concernCache = nil
        labelsCache = [:]
        aliasesCache = [:]
        aliasLookupCache = [:]
        activeCacheVersion = TaxonomyIdentity.cacheVersion
    }

    private func canonicalPayload() -> CanonicalPayload {
        lock.lock()
        if let cached = canonicalCache {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let loaded = loadCanonicalPayload()

        lock.lock()
        canonicalCache = loaded
        lock.unlock()

        return loaded
    }

    private func labels(for locale: String) -> [String: String] {
        lock.lock()
        if let cached = labelsCache[locale] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let loaded = loadLabels(locale: locale)

        lock.lock()
        labelsCache[locale] = loaded
        lock.unlock()

        return loaded
    }

    private func concernPayload() -> ConcernPayload {
        lock.lock()
        if let cached = concernCache {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let loaded = loadConcernPayload()

        lock.lock()
        concernCache = loaded
        lock.unlock()

        return loaded
    }

    private func aliasMap(for locale: String) -> [String: [String]] {
        lock.lock()
        if let cached = aliasesCache[locale] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let loaded = loadAliases(locale: locale)

        lock.lock()
        aliasesCache[locale] = loaded
        lock.unlock()

        return loaded
    }

    private func loadCanonicalPayload() -> CanonicalPayload {
        let baseLookup = bundleLookup(forResource: "taxonomy_v21_base_en", withExtension: "json", subdirectory: "TaxonomyV21/base")
        let canonicalLookup = bundleLookup(forResource: "taxonomy_v21_canonical_en", withExtension: "json", subdirectory: nil)
        let selected = baseLookup.url != nil ? baseLookup : canonicalLookup
        let url = selected.url

        guard let url else {
            return CanonicalPayload(taxonomy: [], symptomConcerns: [])
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(CanonicalPayload.self, from: data)
        } catch {
            return CanonicalPayload(taxonomy: [], symptomConcerns: [])
        }
    }

    private func loadConcernPayload() -> ConcernPayload {
        let concernLookup = bundleLookup(forResource: "taxonomy_v21_concern_domains_en", withExtension: "json", subdirectory: "TaxonomyV21/concerns")
        let legacyLookup = bundleLookup(forResource: "taxonomy_v21_symptom_concern_en", withExtension: "json", subdirectory: nil)
        let selected = concernLookup.url != nil ? concernLookup : legacyLookup
        let url = selected.url

        guard let url else {
            return ConcernPayload(concernDomains: [])
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(ConcernPayload.self, from: data)
        } catch {
            return ConcernPayload(concernDomains: [])
        }
    }

    private func loadLabels(locale: String) -> [String: String] {
        let normalized = TaxonomyIdentity.normalizedLocale(locale)
        let primaryLookup = bundleLookup(forResource: "taxonomy_v21_locale_labels_\(normalized)", withExtension: "json", subdirectory: "TaxonomyV21/labels")
        let fallbackLookup = normalized == "en"
            ? bundleLookup(forResource: "taxonomy_v21_labels_en", withExtension: "json", subdirectory: nil)
            : (nil, false)
        let selected = primaryLookup.url != nil ? primaryLookup : fallbackLookup
        let url = selected.0

        guard let url else {
            return [:]
        }

        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(LabelsPayload.self, from: data)
            return payload.labels
        } catch {
            return [:]
        }
    }

    private func loadAliases(locale: String) -> [String: [String]] {
        let normalized = TaxonomyIdentity.normalizedLocale(locale)
        let primaryLookup = bundleLookup(forResource: "taxonomy_v21_aliases_\(normalized)", withExtension: "json", subdirectory: "TaxonomyV21/aliases")
        let fallbackLookup = normalized == "en"
            ? bundleLookup(forResource: "taxonomy_v21_aliases_en", withExtension: "json", subdirectory: nil)
            : (nil, false)
        let selected = primaryLookup.url != nil ? primaryLookup : fallbackLookup
        let url = selected.0

        guard let url else {
            return [:]
        }

        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(AliasesPayload.self, from: data)
            return payload.aliases
        } catch {
            return [:]
        }
    }

    private func dedupeAliases(_ aliases: [String]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []

        for alias in aliases {
            let normalized = alias
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            guard !normalized.isEmpty else { continue }
            if seen.insert(normalized).inserted {
                ordered.append(alias)
            }
        }

        return ordered
    }

    private func bundleLookup(forResource name: String, withExtension ext: String, subdirectory: String?) -> (url: URL?, usedSubdirectory: Bool) {
        if let subdirectory,
           let nested = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
            return (nested, true)
        }

        // Some Xcode resource copy modes flatten folder hierarchy at runtime.
        if let root = Bundle.main.url(forResource: name, withExtension: ext) {
            return (root, false)
        }

        return (nil, false)
    }

}
