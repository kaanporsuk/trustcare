import Foundation

struct SymptomConcernSuggestion: Identifiable, Hashable {
    let canonicalID: String
    let label: String
    let aliases: [String]
    let likelySpecialtyIDs: [String]
    let likelyTreatmentProcedureIDs: [String]
    let likelyFacilityTypeIDs: [String]
    let urgencyFlag: String?
    let careSettingHint: String?

    var id: String { canonicalID }
}

enum SymptomConcernService {
    static func search(query: String, locale: String, limit: Int = 20) -> [SymptomConcernSuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let entries = TaxonomyCatalogStore.shared.symptomConcerns()

        let mapped = entries.map { entry in
            let label = TaxonomyCatalogStore.shared.localizedLabel(for: entry.canonicalID, locale: locale) ?? entry.displayEnglishLabel

            return SymptomConcernSuggestion(
                canonicalID: entry.canonicalID,
                label: label,
                aliases: entry.aliasesEnglish,
                likelySpecialtyIDs: entry.likelySpecialtyIDs,
                likelyTreatmentProcedureIDs: entry.likelyTreatmentProcedureIDs,
                likelyFacilityTypeIDs: entry.likelyFacilityTypeIDs,
                urgencyFlag: entry.urgencyFlag,
                careSettingHint: entry.careSettingHint
            )
        }

        guard !trimmed.isEmpty else {
            return Array(mapped.prefix(limit))
        }

        let normalizedQuery = normalize(trimmed)
        let filtered = mapped.filter { suggestion in
            if normalize(suggestion.label).contains(normalizedQuery) {
                return true
            }
            return suggestion.aliases.contains { normalize($0).contains(normalizedQuery) }
        }

        return Array(filtered.prefix(limit))
    }

    private static func normalize(_ value: String) -> String {
        value
            .lowercased()
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
