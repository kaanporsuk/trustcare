import Foundation

struct TaxonomySuggestion: Identifiable, Decodable, Hashable {
    let entityId: String
    let entityType: String
    let label: String
    let score: Double?

    enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case entityType = "entity_type"
        case label
        case score
    }

    var id: String {
        "\(entityType):\(entityId):\(label)"
    }
}
