import Foundation
import Supabase

final class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    private struct UserEventInsert: Encodable {
        let userId: UUID?
        let eventType: String
        let eventData: [String: String]?
        let createdAt: Date

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case eventType = "event_type"
            case eventData = "event_data"
            case createdAt = "created_at"
        }
    }

    func track(_ event: String, data: [String: Any]? = nil) {
        let client = SupabaseManager.shared.client
        let eventData = data?.reduce(into: [String: String]()) { result, item in
            result[item.key] = String(describing: item.value)
        }

        Task {
            do {
                let session = try await client.auth.session
                let payload = UserEventInsert(
                    userId: session.user.id,
                    eventType: event,
                    eventData: eventData,
                    createdAt: Date()
                )
                _ = try await client
                    .from("user_events")
                    .insert(payload)
                    .execute()
            } catch {
                return
            }
        }
    }
}
