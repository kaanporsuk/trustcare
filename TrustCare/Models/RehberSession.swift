import Foundation

struct RehberSession: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let title: String?
    let wasEmergency: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case wasEmergency = "was_emergency"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        return "New Conversation"
    }
    
    var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(updatedAt) {
            return "Today"
        } else if calendar.isDateInYesterday(updatedAt) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: updatedAt)
        }
    }
}
