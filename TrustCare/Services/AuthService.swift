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
		let preferredLanguage: String?
		let preferredCurrency: String?

		enum CodingKeys: String, CodingKey {
			case fullName = "full_name"
			case avatarUrl = "avatar_url"
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
			data: ["full_name": fullName]
		)

		if let referralCode, !referralCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
		   let userId = response.user?.id {
			let update = ReferralUpdate(referredBy: referralCode)
			try await client
				.from("profiles")
				.update(update)
				.eq("id", value: userId.uuidString)
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

	static func currentSession() async -> Session? {
		try? await client.auth.session
	}

	static func fetchProfile() async throws -> UserProfile {
		guard let session = try await client.auth.session else {
			throw AppError.authError(String(localized: "Not authenticated."))
		}

		let response = try await client
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
		language: String?,
		currency: String?
	) async throws {
		guard let session = try await client.auth.session else {
			throw AppError.authError(String(localized: "Not authenticated."))
		}

		if fullName == nil && avatarUrl == nil && language == nil && currency == nil {
			return
		}

		let updates = ProfileUpdate(
			fullName: fullName,
			avatarUrl: avatarUrl,
			preferredLanguage: language,
			preferredCurrency: currency
		)
		try await client
			.from("profiles")
			.update(updates)
			.eq("id", value: session.user.id.uuidString)
			.execute()
	}
}
