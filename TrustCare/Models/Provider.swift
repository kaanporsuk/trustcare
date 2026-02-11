import Foundation

struct Provider: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let specialty: String
    let clinicName: String?
    let address: String
    let city: String?
    let countryCode: String
    let latitude: Double
    let longitude: Double
    let phone: String?
    let email: String?
    let website: String?
    let photoUrl: String?
    let coverUrl: String?
    let languagesSpoken: [String]?
    let ratingOverall: Double
    let ratingWaitTime: Double
    let ratingBedside: Double
    let ratingEfficacy: Double
    let ratingCleanliness: Double
    let reviewCount: Int
    let verifiedReviewCount: Int
    let priceLevelAvg: Double
    let isClaimed: Bool
    let subscriptionTier: SubscriptionTier
    let isFeatured: Bool
    let isActive: Bool
    let createdAt: Date
    let distanceKm: Double?

    var verifiedPercentage: Int {
        guard reviewCount > 0 else { return 0 }
        return Int((Double(verifiedReviewCount) / Double(reviewCount)) * 100)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, specialty, address, latitude, longitude, phone, email, website
        case clinicName = "clinic_name"
        case city
        case countryCode = "country_code"
        case photoUrl = "photo_url"
        case coverUrl = "cover_url"
        case languagesSpoken = "languages_spoken"
        case ratingOverall = "rating_overall"
        case ratingWaitTime = "rating_wait_time"
        case ratingBedside = "rating_bedside"
        case ratingEfficacy = "rating_efficacy"
        case ratingCleanliness = "rating_cleanliness"
        case reviewCount = "review_count"
        case verifiedReviewCount = "verified_review_count"
        case priceLevelAvg = "price_level_avg"
        case isClaimed = "is_claimed"
        case subscriptionTier = "subscription_tier"
        case isFeatured = "is_featured"
        case isActive = "is_active"
        case createdAt = "created_at"
        case distanceKm = "distance_km"
    }
}
