import Foundation
import Supabase

enum NotificationService {
    private static var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    static func fetchUnreadCount() async throws -> Int {
        let session = try await client.auth.session
        let response = try await client
            .from("notifications")
            .select("id", count: .exact)
            .eq("user_id", value: session.user.id.uuidString)
            .eq("is_read", value: false)
            .execute()

        return response.count ?? 0
    }

    static func fetchNotifications(limit: Int = 20) async throws -> [AppNotification] {
        let session = try await client.auth.session
        let response: PostgrestResponse<[AppNotification]> = try await client
            .from("notifications")
            .select()
            .eq("user_id", value: session.user.id.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()

        return response.value
    }

    static func markAsRead(id: UUID) async throws {
        _ = try await client
            .from("notifications")
            .update(["is_read": true])
            .eq("id", value: id.uuidString)
            .execute()
    }
}
