import Foundation

struct ReviewMedia: Identifiable, Codable {
    let id: UUID
    let reviewId: UUID
    let userId: UUID
    let mediaType: MediaType
    let url: String
    let thumbnailUrl: String?
    let fileSizeBytes: Int
    let durationSeconds: Int?
    let displayOrder: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, url
        case reviewId = "review_id"
        case userId = "user_id"
        case mediaType = "media_type"
        case thumbnailUrl = "thumbnail_url"
        case fileSizeBytes = "file_size_bytes"
        case durationSeconds = "duration_seconds"
        case displayOrder = "display_order"
        case createdAt = "created_at"
    }
}
