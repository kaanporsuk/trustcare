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
    
    var displayName: String {
        switch self {
        case .spam:
            return String(localized: "Spam or fake review")
        case .offensive:
            return String(localized: "Inappropriate content")
        case .inaccurate:
            return String(localized: "Inaccurate information")
        case .other:
            return String(localized: "Other")
        }
    }
}
