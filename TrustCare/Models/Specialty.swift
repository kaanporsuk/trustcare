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
    }

    func resolvedName(using localizationManager: LocalizationManager) -> String {
        localizationManager.resolvedSpecialtyName(
            canonical: name,
            tr: nameTr,
            de: nameDe,
            pl: namePl,
            nl: nameNl,
            da: nameDa
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
