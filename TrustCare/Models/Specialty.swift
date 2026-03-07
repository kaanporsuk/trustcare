import Foundation

struct Specialty: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let nameTr: String?
    let nameDe: String?
    let namePl: String?
    let nameNl: String?
    let nameDa: String?
    let category: String
    let subcategory: String?
    let iconName: String
    let surveyType: String
    let colorHex: String?
    let displayOrder: Int
    let isPopular: Bool
    let isActive: Bool
    let canonicalId: String?
    let canonicalEntityId: String?
    let canonicalEntityType: String?

    enum CodingKeys: String, CodingKey {
        case id, name, category, subcategory
        case nameTr = "name_tr"
        case nameDe = "name_de"
        case namePl = "name_pl"
        case nameNl = "name_nl"
        case nameDa = "name_da"
        case iconName = "icon_name"
        case surveyType = "survey_type"
        case colorHex = "color_hex"
        case displayOrder = "display_order"
        case isPopular = "is_popular"
        case isActive = "is_active"
        case canonicalId = "canonical_id"
        case canonicalEntityId = "canonical_entity_id"
        case canonicalEntityType = "canonical_entity_type"
    }

    func localizedName(for lang: String) -> String {
        switch lang {
        case "tr": return nameTr ?? name
        case "de": return nameDe ?? name
        case "pl": return namePl ?? name
        case "nl": return nameNl ?? name
        case "da": return nameDa ?? name
        default: return name
        }
    }

    @available(*, deprecated, message: "Use taxonomyDisplayName(using:) for UI display labels.")
    func resolvedName(using localizationManager: LocalizationManager) -> String {
        localizedName(for: localizationManager.effectiveLanguage)
    }

    func taxonomyDisplayName(using localizationManager: LocalizationManager) -> String {
        let fallback = localizedName(for: localizationManager.effectiveLanguage)
        let taxonomyID = canonicalEntityId ?? canonicalId

        guard let taxonomyID, !taxonomyID.isEmpty else {
            return fallback
        }

        return TaxonomyService.localizedLabel(
            for: taxonomyID,
            locale: localizationManager.effectiveLanguage,
            fallback: fallback
        )
    }

    func matchesSearch(_ query: String) -> Bool {
        let normalized = query
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
        guard !normalized.isEmpty else { return true }

        let searchable = [name, nameTr, nameDe, namePl, nameNl, nameDa, category, subcategory]
            .compactMap { $0 }

        return searchable.contains {
            $0.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
                .contains(normalized)
        }
    }
}
