import Foundation

struct Specialty: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let nameTr: String?
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
        case iconName = "icon_name"
        case surveyType = "survey_type"
        case colorHex = "color_hex"
        case displayOrder = "display_order"
        case isPopular = "is_popular"
        case isActive = "is_active"
    }
}
