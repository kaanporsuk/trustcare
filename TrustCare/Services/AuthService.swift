import Foundation
import Supabase

enum AuthService {
    private static var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private struct ReferralUpdate: Encodable {
        let referredBy: String

        enum CodingKeys: String, CodingKey {
            case referredBy = "referred_by"
        }
    }

    private struct ProfileUpdate: Encodable {
        let fullName: String?
        let avatarUrl: String?
        let phone: String?
        let countryCode: String?
        let preferredLanguage: String?
        let preferredCurrency: String?

        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
            case avatarUrl = "avatar_url"
            case phone
            case countryCode = "country_code"
            case preferredLanguage = "preferred_language"
            case preferredCurrency = "preferred_currency"
        }
    }

    static func signUp(
        email: String,
        password: String,
        fullName: String,
        referralCode: String? = nil
    ) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: ["full_name": .string(fullName)]
        )

        if let referralCode, !referralCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let update = ReferralUpdate(referredBy: referralCode)
            try await client
                .from("profiles")
                .update(update)
                .eq("id", value: response.user.id.uuidString)
                .execute()
        }
    }

    static func signIn(email: String, password: String) async throws {
        _ = try await client.auth.signIn(email: email, password: password)
    }

    static func signInWithApple(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
    }

    static func signOut() async throws {
        try await client.auth.signOut()
    }

    static func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    static func currentSession() async -> Session? {
        try? await client.auth.session
    }

    static func currentUserEmail() async -> String? {
        let session = try? await client.auth.session
        return session?.user.email
    }

    static func fetchProfile() async throws -> UserProfile {
        let session = try await client.auth.session
        let response: PostgrestResponse<UserProfile> = try await client
            .from("profiles")
            .select()
            .eq("id", value: session.user.id.uuidString)
            .single()
            .execute()

        return response.value
    }

    static func updateProfile(
        fullName: String?,
        avatarUrl: String?,
        phone: String?,
        countryCode: String?,
        language: String?,
        currency: String?
    ) async throws {
        let session = try await client.auth.session

        if fullName == nil
            && avatarUrl == nil
            && phone == nil
            && countryCode == nil
            && language == nil
            && currency == nil {
            return
        }

        let updates = ProfileUpdate(
            fullName: fullName,
            avatarUrl: avatarUrl,
            phone: phone,
            countryCode: countryCode,
            preferredLanguage: language,
            preferredCurrency: currency
        )

        try await client
            .from("profiles")
            .update(updates)
            .eq("id", value: session.user.id.uuidString)
            .execute()
    }

    static func deleteAccount() async throws {
        let session = try await client.auth.session
        struct DeletedAtUpdate: Encodable {
            let deletedAt: Date

            enum CodingKeys: String, CodingKey {
                case deletedAt = "deleted_at"
            }
        }

        let updates = ProfileUpdate(
            fullName: String(localized: "Deleted User"),
            avatarUrl: nil,
            phone: nil,
            countryCode: nil,
            preferredLanguage: nil,
            preferredCurrency: nil
        )

        _ = try await client
            .from("profiles")
            .update(updates)
            .eq("id", value: session.user.id.uuidString)
            .execute()

        let deletedAtUpdate = DeletedAtUpdate(deletedAt: Date())
        _ = try await client
            .from("profiles")
            .update(deletedAtUpdate)
            .eq("id", value: session.user.id.uuidString)
            .execute()

        try await client.auth.signOut()
    }
}
