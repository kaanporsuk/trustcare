import Foundation

struct Specialty: Identifiable, Codable, Hashable {
    let id: Int
    let nameKey: String
    let nameEn: String
    let iconName: String

    enum CodingKeys: String, CodingKey {
        case id
        case nameKey = "name_key"
        case nameEn = "name_en"
        case iconName = "icon_name"
    }
}
