import Foundation

struct ProviderServiceItem: Identifiable, Codable {
    let id: UUID
    let providerId: UUID
    let category: String?
    let name: String
    let description: String?
    let priceMin: Double?
    let priceMax: Double?
    let currency: String
    let durationMinutes: Int?
    let displayOrder: Int
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, category, name, description, currency
        case providerId = "provider_id"
        case priceMin = "price_min"
        case priceMax = "price_max"
        case durationMinutes = "duration_minutes"
        case displayOrder = "display_order"
        case isActive = "is_active"
    }
}
