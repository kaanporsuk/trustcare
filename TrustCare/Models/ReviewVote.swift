import Foundation

struct ReviewVote: Identifiable, Codable {
    let id: UUID
    let reviewId: UUID
    let userId: UUID
    let isHelpful: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case reviewId = "review_id"
        case userId = "user_id"
        case isHelpful = "is_helpful"
        case createdAt = "created_at"
    }
}
