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
        return String(localized: "rehber_new_conversation")
    }
    
    var formattedDate: String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(updatedAt) {
            return String(localized: "date_today")
        } else if calendar.isDateInYesterday(updatedAt) {
            return String(localized: "date_yesterday")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: updatedAt)
        }
    }
}
