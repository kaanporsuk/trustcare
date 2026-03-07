import Foundation

struct Provider: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let specialty: String
    let clinicName: String?
    let facilityId: UUID?
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
    let ratingPainMgmt: Double? = nil
    let ratingAccuracy: Double? = nil
    let ratingKnowledge: Double? = nil
    let ratingCourtesy: Double? = nil
    let ratingCareQuality: Double? = nil
    let ratingAdmin: Double? = nil
    let ratingComfort: Double? = nil
    let ratingTurnaround: Double? = nil
    let ratingEmpathy: Double? = nil
    let ratingEnvironment: Double? = nil
    let ratingCommunication: Double? = nil
    let ratingEffectiveness: Double? = nil
    let ratingAttentiveness: Double? = nil
    let ratingEquipment: Double? = nil
    let ratingConsultation: Double? = nil
    let ratingResults: Double? = nil
    let ratingAftercare: Double? = nil
    let reviewCount: Int
    let verifiedReviewCount: Int
    let priceLevelAvg: Double
    let isClaimed: Bool
    let subscriptionTier: SubscriptionTier
    let isFeatured: Bool
    let isActive: Bool
    let createdAt: Date
    let distanceKm: Double?
    let dataSource: String?  // "system" or "apple_maps"
    let externalId: String?  // Apple Maps MKMapItem identifier
    let updatedAt: Date?
    let deletedAt: Date?
    let priceLevel: Int?

    var verifiedPercentage: Int {
        guard reviewCount > 0 else { return 0 }
        return Int((Double(verifiedReviewCount) / Double(reviewCount)) * 100)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, specialty, address, latitude, longitude, phone, email, website
        case clinicName = "clinic_name"
        case facilityId = "facility_id"
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
        case ratingPainMgmt = "rating_pain_mgmt"
        case ratingAccuracy = "rating_accuracy"
        case ratingKnowledge = "rating_knowledge"
        case ratingCourtesy = "rating_courtesy"
        case ratingCareQuality = "rating_care_quality"
        case ratingAdmin = "rating_admin"
        case ratingComfort = "rating_comfort"
        case ratingTurnaround = "rating_turnaround"
        case ratingEmpathy = "rating_empathy"
        case ratingEnvironment = "rating_environment"
        case ratingCommunication = "rating_communication"
        case ratingEffectiveness = "rating_effectiveness"
        case ratingAttentiveness = "rating_attentiveness"
        case ratingEquipment = "rating_equipment"
        case ratingConsultation = "rating_consultation"
        case ratingResults = "rating_results"
        case ratingAftercare = "rating_aftercare"
        case reviewCount = "review_count"
        case verifiedReviewCount = "verified_review_count"
        case priceLevelAvg = "price_level_avg"
        case isClaimed = "is_claimed"
        case subscriptionTier = "subscription_tier"
        case isFeatured = "is_featured"
        case isActive = "is_active"
        case createdAt = "created_at"
        case distanceKm = "distance_km"
        case dataSource = "data_source"
        case externalId = "external_id"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case priceLevel = "price_level"
    }
}

extension Provider {
    func aggregateRating(for dbColumn: String) -> Double? {
        switch dbColumn {
        case "rating_wait_time": return ratingWaitTime
        case "rating_bedside": return ratingBedside
        case "rating_efficacy": return ratingEfficacy
        case "rating_cleanliness": return ratingCleanliness
        case "rating_pain_mgmt": return ratingPainMgmt
        case "rating_accuracy": return ratingAccuracy
        case "rating_knowledge": return ratingKnowledge
        case "rating_courtesy": return ratingCourtesy
        case "rating_care_quality": return ratingCareQuality
        case "rating_admin": return ratingAdmin
        case "rating_comfort": return ratingComfort
        case "rating_turnaround": return ratingTurnaround
        case "rating_empathy": return ratingEmpathy
        case "rating_environment": return ratingEnvironment
        case "rating_communication": return ratingCommunication
        case "rating_effectiveness": return ratingEffectiveness
        case "rating_attentiveness": return ratingAttentiveness
        case "rating_equipment": return ratingEquipment
        case "rating_consultation": return ratingConsultation
        case "rating_results": return ratingResults
        case "rating_aftercare": return ratingAftercare
        default: return nil
        }
    }
}
