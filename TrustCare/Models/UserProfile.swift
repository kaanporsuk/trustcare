import Foundation

struct UserProfile: Identifiable, Codable {
    let id: UUID
    var fullName: String?
    var avatarUrl: String?
    var bio: String?
    var phone: String?
    var countryCode: String
    var preferredLanguage: String
    var preferredCurrency: String
    let referralCode: String?
    var dateOfBirth: Date?
    let createdAt: Date

    var displayName: String {
        guard let name = fullName, !name.isEmpty else {
            return String(localized: "Anonymous")
        }
        return name
    }

    enum CodingKeys: String, CodingKey {
        case id, phone
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case bio
        case countryCode = "country_code"
        case preferredLanguage = "preferred_language"
        case preferredCurrency = "preferred_currency"
        case referralCode = "referral_code"
        case dateOfBirth = "date_of_birth"
        case createdAt = "created_at"
    }
}
