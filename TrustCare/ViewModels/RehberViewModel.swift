import Combine
import Foundation
import Supabase

@MainActor
final class RehberViewModel: ObservableObject {
    @Published var messages: [RehberMessage] = []
    @Published var isLoading: Bool = false
    @Published var currentSessionId: UUID?
    @Published var usageCount: Int = 0
    @Published var errorMessage: String?
    @Published var showEmergencyCard: Bool = false

    private let dailyLimit: Int = 5
    private static let usageDateKey = "rehber_usage_date"
    private static let usageCountKey = "rehber_usage_count"

    private static let emergencyKeywordsTR: [String] = [
        "göğüs ağrısı",
        "nefes darlığı",
        "intihar",
        "ciddi kanama",
        "felç belirtileri",
        "bilinç kaybı",
        "kalp krizi",
        "ağır alerjik reaksiyon",
        "zehirlenme"
    ]

    private static let emergencyKeywordsEN: [String] = [
        "chest pain",
        "can't breathe",
        "suicide",
        "severe bleeding",
        "stroke",
        "unconscious"
    ]

    init() {
        loadUsageCount()
    }

    var remainingDailyUsage: Int {
        max(0, dailyLimit - usageCount)
    }

    var canSendMoreToday: Bool {
        usageCount < dailyLimit
    }

    func startNewChat() {
        currentSessionId = nil
        messages = []
        isLoading = false
        errorMessage = nil
        showEmergencyCard = false
    }

    func dismissEmergencyCard() {
        showEmergencyCard = false
    }

    func sendMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        loadUsageCount()
        guard canSendMoreToday else {
            errorMessage = "Günlük ücretsiz limit doldu (5/5). Yarın tekrar deneyin."
            return
        }

        guard let authSession = await AuthService.currentSession() else {
            errorMessage = "Rehber'i kullanmak için giriş yapın."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let sessionId: UUID
            if let currentSessionId {
                sessionId = currentSessionId
            } else {
                sessionId = try await createSession(userId: authSession.user.id, firstText: trimmed)
                currentSessionId = sessionId
            }

            let userMessage = RehberMessage(
                id: UUID(),
                role: "user",
                content: trimmed,
                recommendedSpecialties: nil,
                wasEmergency: false,
                createdAt: Date()
            )
            messages.append(userMessage)
            try await saveMessage(userId: authSession.user.id, sessionId: sessionId, message: userMessage)

            if isEmergencyKeywordDetected(in: trimmed) {
                showEmergencyCard = true
                let emergencyResponse = RehberMessage(
                    id: UUID(),
                    role: "assistant",
                    content: "🚨 Acil risk olasılığı algılandı. Lütfen hemen 112'yi arayın.",
                    recommendedSpecialties: nil,
                    wasEmergency: true,
                    createdAt: Date()
                )
                messages.append(emergencyResponse)
                try await saveMessage(userId: authSession.user.id, sessionId: sessionId, message: emergencyResponse)
                await markSessionEmergency(userId: authSession.user.id, sessionId: sessionId)
                incrementUsageCount()
                isLoading = false
                return
            }

            let aiResponse = try await callRehberEdgeFunction(
                authToken: authSession.accessToken,
                sessionId: sessionId,
                messages: messages.map { EdgeChatMessage(role: $0.role, content: $0.content) }
            )

            let assistantText = aiResponse.message?.trimmingCharacters(in: .whitespacesAndNewlines)
            let emergencyFromAI = aiResponse.isEmergency || containsEmergencyTrigger(aiResponse.message)

            if emergencyFromAI {
                showEmergencyCard = true
            }

            let assistantMessage = RehberMessage(
                id: UUID(),
                role: "assistant",
                content: assistantText?.isEmpty == false ? assistantText! : "Yanıt oluşturulamadı. Lütfen tekrar deneyin.",
                recommendedSpecialties: aiResponse.recommendedSpecialties,
                wasEmergency: emergencyFromAI,
                createdAt: Date()
            )

            messages.append(assistantMessage)
            try await saveMessage(userId: authSession.user.id, sessionId: sessionId, message: assistantMessage)

            if emergencyFromAI {
                await markSessionEmergency(userId: authSession.user.id, sessionId: sessionId)
            }

            incrementUsageCount()
        } catch {
            errorMessage = localizedErrorMessage(error)
        }

        isLoading = false
    }

    private func createSession(userId: UUID, firstText: String) async throws -> UUID {
        struct SessionInsert: Encodable {
            let userId: String
            let title: String
            let expiresAt: Date

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case title
                case expiresAt = "expires_at"
            }
        }

        struct SessionInsertFallback: Encodable {
            let userId: String
            let title: String

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case title
            }
        }

        struct SessionRow: Decodable {
            let id: UUID
        }

        let title = String(firstText.prefix(48))
        let expiresAt = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()

        do {
            let full = SessionInsert(userId: userId.uuidString, title: title, expiresAt: expiresAt)
            let response: PostgrestResponse<SessionRow> = try await SupabaseManager.shared.client
                .from("rehber_sessions")
                .insert(full)
                .select("id")
                .single()
                .execute()
            return response.value.id
        } catch {
            let fallback = SessionInsertFallback(userId: userId.uuidString, title: title)
            let response: PostgrestResponse<SessionRow> = try await SupabaseManager.shared.client
                .from("rehber_sessions")
                .insert(fallback)
                .select("id")
                .single()
                .execute()
            return response.value.id
        }
    }

    private func saveMessage(userId: UUID, sessionId: UUID, message: RehberMessage) async throws {
        struct MessageInsert: Encodable {
            let id: String
            let sessionId: String
            let userId: String
            let role: String
            let content: String
            let recommendedSpecialties: [String]?
            let wasEmergency: Bool

            enum CodingKeys: String, CodingKey {
                case id
                case sessionId = "session_id"
                case userId = "user_id"
                case role
                case content
                case recommendedSpecialties = "recommended_specialties"
                case wasEmergency = "was_emergency"
            }
        }

        struct MessageInsertFallback: Encodable {
            let id: String
            let sessionId: String
            let userId: String
            let role: String
            let content: String

            enum CodingKeys: String, CodingKey {
                case id
                case sessionId = "session_id"
                case userId = "user_id"
                case role
                case content
            }
        }

        do {
            let full = MessageInsert(
                id: message.id.uuidString,
                sessionId: sessionId.uuidString,
                userId: userId.uuidString,
                role: message.role,
                content: message.content,
                recommendedSpecialties: message.recommendedSpecialties,
                wasEmergency: message.wasEmergency
            )

            _ = try await SupabaseManager.shared.client
                .from("rehber_messages")
                .insert(full)
                .execute()
        } catch {
            let fallback = MessageInsertFallback(
                id: message.id.uuidString,
                sessionId: sessionId.uuidString,
                userId: userId.uuidString,
                role: message.role,
                content: message.content
            )

            _ = try await SupabaseManager.shared.client
                .from("rehber_messages")
                .insert(fallback)
                .execute()
        }
    }

    private func markSessionEmergency(userId: UUID, sessionId: UUID) async {
        struct SessionEmergencyUpdate: Encodable {
            let wasEmergency: Bool

            enum CodingKeys: String, CodingKey {
                case wasEmergency = "was_emergency"
            }
        }

        do {
            _ = try await SupabaseManager.shared.client
                .from("rehber_sessions")
                .update(SessionEmergencyUpdate(wasEmergency: true))
                .eq("id", value: sessionId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
        } catch {
            return
        }
    }

    private func callRehberEdgeFunction(
        authToken: String,
        sessionId: UUID,
        messages: [EdgeChatMessage]
    ) async throws -> RehberEdgeResponse {
        guard let endpoint = URL(string: "\(SupabaseConfig.url)/functions/v1/rehber-chat") else {
            throw AppError.unknown
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let payload = EdgeRequest(sessionId: sessionId.uuidString, messages: messages)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.unknown
        }

        guard (200...299).contains(http.statusCode) else {
            if let decodedError = try? JSONDecoder().decode(EdgeErrorResponse.self, from: data),
               let message = decodedError.error,
               !message.isEmpty {
                throw NSError(domain: "Rehber", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw NSError(domain: "Rehber", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Rehber yanıt veremedi. Lütfen tekrar deneyin."])
        }

        if let structured = try? JSONDecoder().decode(RehberEdgeResponse.self, from: data) {
            return structured
        }

        if let fallbackText = String(data: data, encoding: .utf8), !fallbackText.isEmpty {
            return RehberEdgeResponse(message: fallbackText, recommendedSpecialties: nil, isEmergency: containsEmergencyTrigger(fallbackText))
        }

        return RehberEdgeResponse(message: "Yanıt alınamadı.", recommendedSpecialties: nil, isEmergency: false)
    }

    private func isEmergencyKeywordDetected(in text: String) -> Bool {
        let normalized = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
        return Self.emergencyKeywordsTR.contains(where: { normalized.contains($0.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR")) ) })
            || Self.emergencyKeywordsEN.contains(where: { normalized.contains($0.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US")) ) })
    }

    private func containsEmergencyTrigger(_ text: String?) -> Bool {
        guard let text else { return false }
        return text.localizedCaseInsensitiveContains("[EMERGENCY_TRIGGER_112]")
    }

    private func loadUsageCount() {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())

        if let savedDate = defaults.object(forKey: Self.usageDateKey) as? Date,
           Calendar.current.isDate(savedDate, inSameDayAs: today) {
            usageCount = defaults.integer(forKey: Self.usageCountKey)
        } else {
            usageCount = 0
            defaults.set(today, forKey: Self.usageDateKey)
            defaults.set(0, forKey: Self.usageCountKey)
        }
    }

    private func incrementUsageCount() {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        let savedDate = defaults.object(forKey: Self.usageDateKey) as? Date
        let currentCount: Int

        if let savedDate, Calendar.current.isDate(savedDate, inSameDayAs: today) {
            currentCount = defaults.integer(forKey: Self.usageCountKey)
        } else {
            defaults.set(today, forKey: Self.usageDateKey)
            currentCount = 0
        }

        let updated = currentCount + 1
        defaults.set(updated, forKey: Self.usageCountKey)
        usageCount = updated
    }

    private func localizedErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }

        let localized = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !localized.isEmpty {
            return localized
        }
        return "Bilinmeyen bir hata oluştu."
    }
}

private struct EdgeRequest: Encodable {
    let sessionId: String
    let messages: [EdgeChatMessage]

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case messages
    }
}

struct EdgeChatMessage: Encodable {
    let role: String
    let content: String
}

struct RehberEdgeResponse: Decodable {
    let message: String?
    let recommendedSpecialties: [String]?
    let isEmergency: Bool

    enum CodingKeys: String, CodingKey {
        case message
        case recommendedSpecialties = "recommended_specialties"
        case isEmergency = "is_emergency"
    }
}

private struct EdgeErrorResponse: Decodable {
    let error: String?
}
