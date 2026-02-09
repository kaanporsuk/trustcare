import Foundation

struct Notification: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let type: String
    let title: String
    let body: String
    let data: [String: String]?
    var isRead: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, type, title, body, data
        case userId = "user_id"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}
