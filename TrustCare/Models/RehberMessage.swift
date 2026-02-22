import Foundation

struct RehberMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: String
    let content: String
    let recommendedSpecialties: [String]?
    let wasEmergency: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, role, content
        case recommendedSpecialties = "recommended_specialties"
        case wasEmergency = "was_emergency"
        case createdAt = "created_at"
    }
}
