import Foundation

struct RehberMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: String
    let content: String
    let recommendedSpecialties: [String]?
    let wasEmergency: Bool
    let isFallback: Bool
    let isRateLimited: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, role, content
        case recommendedSpecialties = "recommended_specialties"
        case wasEmergency = "was_emergency"
        case isFallback = "is_fallback"
        case isRateLimited = "is_rate_limited"
        case createdAt = "created_at"
    }

    init(
        id: UUID,
        role: String,
        content: String,
        recommendedSpecialties: [String]?,
        wasEmergency: Bool,
        isFallback: Bool = false,
        isRateLimited: Bool = false,
        createdAt: Date
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.recommendedSpecialties = recommendedSpecialties
        self.wasEmergency = wasEmergency
        self.isFallback = isFallback
        self.isRateLimited = isRateLimited
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        role = try container.decode(String.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
        recommendedSpecialties = try container.decodeIfPresent([String].self, forKey: .recommendedSpecialties)
        wasEmergency = try container.decodeIfPresent(Bool.self, forKey: .wasEmergency) ?? false
        isFallback = try container.decodeIfPresent(Bool.self, forKey: .isFallback) ?? false
        isRateLimited = try container.decodeIfPresent(Bool.self, forKey: .isRateLimited) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
