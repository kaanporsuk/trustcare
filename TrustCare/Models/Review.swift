import Foundation

struct Review: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let providerId: UUID
    let visitDate: Date
    let visitType: VisitType
    let ratingWaitTime: Int
    let ratingBedside: Int
    let ratingEfficacy: Int
    let ratingCleanliness: Int
    let ratingOverall: Double
    let priceLevel: Int
    let title: String?
    let comment: String
    let wouldRecommend: Bool?
    let proofImageUrl: String?
    let isVerified: Bool
    let verificationConfidence: Int?
    let status: ReviewStatus
    let helpfulCount: Int
    let createdAt: Date

    // Joined fields
    let reviewerName: String?
    let reviewerAvatar: String?
    let media: [ReviewMedia]?

    enum CodingKeys: String, CodingKey {
        case id, title, comment, status, media
        case userId = "user_id"
        case providerId = "provider_id"
        case visitDate = "visit_date"
        case visitType = "visit_type"
        case ratingWaitTime = "rating_wait_time"
        case ratingBedside = "rating_bedside"
        case ratingEfficacy = "rating_efficacy"
        case ratingCleanliness = "rating_cleanliness"
        case ratingOverall = "rating_overall"
        case priceLevel = "price_level"
        case wouldRecommend = "would_recommend"
        case proofImageUrl = "proof_image_url"
        case isVerified = "is_verified"
        case verificationConfidence = "verification_confidence"
        case helpfulCount = "helpful_count"
        case createdAt = "created_at"
        case reviewerName = "reviewer_name"
        case reviewerAvatar = "reviewer_avatar"
    }
}
