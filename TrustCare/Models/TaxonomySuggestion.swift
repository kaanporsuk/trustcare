import Foundation

struct TaxonomySuggestion: Identifiable, Decodable, Hashable {
    let targetType: String
    let targetId: String
    let label: String
    let weight: Double?

    enum CodingKeys: String, CodingKey {
        case targetType = "target_type"
        case targetId = "target_id"
        case label
        case weight
    }

    var id: String {
        "\(targetType):\(targetId):\(label)"
    }
}
