import Foundation

struct ReportedReview: Identifiable, Codable {
    let id: UUID
    let reviewId: UUID
    let reporterId: UUID
    let reason: String
    let description: String?
    let status: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case reviewId = "review_id"
        case reporterId = "reporter_id"
        case reason
        case description
        case status
        case createdAt = "created_at"
    }
}

enum ReportReason: String, CaseIterable {
    case spam = "spam"
    case offensive = "offensive"
    case inaccurate = "inaccurate"
    case other = "other"
    
    var displayNameKey: String {
        switch self {
        case .spam:
            return "Spam or fake review"
        case .offensive:
            return "Inappropriate content"
        case .inaccurate:
            return "Inaccurate information"
        case .other:
            return "Other"
        }
    }
}
