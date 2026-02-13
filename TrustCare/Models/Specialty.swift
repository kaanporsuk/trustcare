import Foundation

struct Specialty: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let category: String
    let subcategory: String?
    let iconName: String
    let displayOrder: Int
    let isPopular: Bool
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case subcategory
        case iconName = "icon_name"
        case displayOrder = "display_order"
        case isPopular = "is_popular"
        case isActive = "is_active"
    }
}
