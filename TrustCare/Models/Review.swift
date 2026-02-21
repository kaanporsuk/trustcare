import Foundation

struct Review: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let providerId: UUID
    let visitDate: Date
    let visitType: VisitType
    let ratingWaitTime: Int
    let ratingBedside: Int
    let ratingEfficacy: Int
    let ratingCleanliness: Int
    let ratingStaff: Int
    let ratingValue: Int
    let ratingOverall: Double
    let priceLevel: Int
    let title: String?
    let comment: String
    let wouldRecommend: Bool?
    let proofImageUrl: String?
    let isVerified: Bool
    let verificationConfidence: Int?
    let status: ReviewStatus
    let helpfulCount: Int
    let createdAt: Date
    
    // Contextual review metrics (1-5 scale, optional)
    let waitingTime: Int?
    let facilityCleanliness: Int?
    let doctorCommunication: Int?
    let treatmentOutcome: Int?
    let proceduralComfort: Int?
    let clearExplanations: Int?
    let checkoutSpeed: Int?
    let stockAvailability: Int?
    let pharmacistAdvice: Int?
    let staffCourtesy: Int?
    let responseTime: Int?
    let nursingCare: Int?
    let checkInProcess: Int?
    let testComfort: Int?
    let resultTurnaround: Int?
    let sessionPunctuality: Int?
    let empathyListening: Int?
    let sessionPrivacy: Int?
    let actionableAdvice: Int?
    let therapyProgress: Int?
    let activeSupervision: Int?
    let facilityGear: Int?
    let consultationQuality: Int?
    let resultSatisfaction: Int?
    let aftercareSupport: Int?

    let reviewerName: String?
    let reviewerAvatar: String?
    let media: [ReviewMedia]?
    let providerName: String?
    let providerSpecialty: String?

    enum CodingKeys: String, CodingKey {
        case id, title, comment, status, media
        case userId = "user_id"
        case providerId = "provider_id"
        case visitDate = "visit_date"
        case visitType = "visit_type"
        case ratingWaitTime = "rating_wait_time"
        case ratingBedside = "rating_bedside"
        case ratingEfficacy = "rating_efficacy"
        case ratingCleanliness = "rating_cleanliness"
        case ratingStaff = "rating_staff"
        case ratingValue = "rating_value"
        case ratingOverall = "rating_overall"
        case priceLevel = "price_level"
        case wouldRecommend = "would_recommend"
        case proofImageUrl = "proof_image_url"
        case isVerified = "is_verified"
        case verificationConfidence = "verification_confidence"
        case helpfulCount = "helpful_count"
        case createdAt = "created_at"
        case waitingTime = "waiting_time"
        case facilityCleanliness = "facility_cleanliness"
        case doctorCommunication = "doctor_communication"
        case treatmentOutcome = "treatment_outcome"
        case proceduralComfort = "procedural_comfort"
        case clearExplanations = "clear_explanations"
        case checkoutSpeed = "checkout_speed"
        case stockAvailability = "stock_availability"
        case pharmacistAdvice = "pharmacist_advice"
        case staffCourtesy = "staff_courtesy"
        case responseTime = "response_time"
        case nursingCare = "nursing_care"
        case checkInProcess = "check_in_process"
        case testComfort = "test_comfort"
        case resultTurnaround = "result_turnaround"
        case sessionPunctuality = "session_punctuality"
        case empathyListening = "empathy_listening"
        case sessionPrivacy = "session_privacy"
        case actionableAdvice = "actionable_advice"
        case therapyProgress = "therapy_progress"
        case activeSupervision = "active_supervision"
        case facilityGear = "facility_gear"
        case consultationQuality = "consultation_quality"
        case resultSatisfaction = "result_satisfaction"
        case aftercareSupport = "aftercare_support"
        case reviewerName = "reviewer_name"
        case reviewerAvatar = "reviewer_avatar"
        case providerName = "provider_name"
        case providerSpecialty = "provider_specialty"
    }
}
