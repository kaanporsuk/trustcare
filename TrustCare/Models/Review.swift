import Foundation

struct Review: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let providerId: UUID?
    let facilityId: UUID?
    let reviewTargetType: ReviewTargetType?
    let visitDate: Date
    let visitType: VisitType
    let surveyType: String?
    let ratingWaitTime: Int?
    let ratingBedside: Int?
    let ratingEfficacy: Int?
    let ratingCleanliness: Int?
    let ratingStaff: Int?
    let ratingValue: Int?
    let ratingPainMgmt: Int?
    let ratingAccuracy: Int?
    let ratingKnowledge: Int?
    let ratingCourtesy: Int?
    let ratingCareQuality: Int?
    let ratingAdmin: Int?
    let ratingComfort: Int?
    let ratingTurnaround: Int?
    let ratingEmpathy: Int?
    let ratingEnvironment: Int?
    let ratingCommunication: Int?
    let ratingEffectiveness: Int?
    let ratingAttentiveness: Int?
    let ratingEquipment: Int?
    let ratingConsultation: Int?
    let ratingResults: Int?
    let ratingAftercare: Int?
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
    let facilityName: String?

    enum CodingKeys: String, CodingKey {
        case id, title, comment, status, media
        case userId = "user_id"
        case providerId = "provider_id"
        case facilityId = "facility_id"
        case reviewTargetType = "review_target_type"
        case visitDate = "visit_date"
        case visitType = "visit_type"
        case surveyType = "survey_type"
        case ratingWaitTime = "rating_wait_time"
        case ratingBedside = "rating_bedside"
        case ratingEfficacy = "rating_efficacy"
        case ratingCleanliness = "rating_cleanliness"
        case ratingStaff = "rating_staff"
        case ratingValue = "rating_value"
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
        case facilityName = "facility_name"
    }

    init(
        id: UUID,
        userId: UUID,
        providerId: UUID? = nil,
        facilityId: UUID? = nil,
        reviewTargetType: ReviewTargetType? = .provider,
        visitDate: Date,
        visitType: VisitType,
        surveyType: String? = nil,
        ratingWaitTime: Int? = nil,
        ratingBedside: Int? = nil,
        ratingEfficacy: Int? = nil,
        ratingCleanliness: Int? = nil,
        ratingStaff: Int? = nil,
        ratingValue: Int? = nil,
        ratingPainMgmt: Int? = nil,
        ratingAccuracy: Int? = nil,
        ratingKnowledge: Int? = nil,
        ratingCourtesy: Int? = nil,
        ratingCareQuality: Int? = nil,
        ratingAdmin: Int? = nil,
        ratingComfort: Int? = nil,
        ratingTurnaround: Int? = nil,
        ratingEmpathy: Int? = nil,
        ratingEnvironment: Int? = nil,
        ratingCommunication: Int? = nil,
        ratingEffectiveness: Int? = nil,
        ratingAttentiveness: Int? = nil,
        ratingEquipment: Int? = nil,
        ratingConsultation: Int? = nil,
        ratingResults: Int? = nil,
        ratingAftercare: Int? = nil,
        ratingOverall: Double,
        priceLevel: Int,
        title: String?,
        comment: String,
        wouldRecommend: Bool?,
        proofImageUrl: String?,
        isVerified: Bool,
        verificationConfidence: Int?,
        status: ReviewStatus,
        helpfulCount: Int,
        createdAt: Date,
        waitingTime: Int? = nil,
        facilityCleanliness: Int? = nil,
        doctorCommunication: Int? = nil,
        treatmentOutcome: Int? = nil,
        proceduralComfort: Int? = nil,
        clearExplanations: Int? = nil,
        checkoutSpeed: Int? = nil,
        stockAvailability: Int? = nil,
        pharmacistAdvice: Int? = nil,
        staffCourtesy: Int? = nil,
        responseTime: Int? = nil,
        nursingCare: Int? = nil,
        checkInProcess: Int? = nil,
        testComfort: Int? = nil,
        resultTurnaround: Int? = nil,
        sessionPunctuality: Int? = nil,
        empathyListening: Int? = nil,
        sessionPrivacy: Int? = nil,
        actionableAdvice: Int? = nil,
        therapyProgress: Int? = nil,
        activeSupervision: Int? = nil,
        facilityGear: Int? = nil,
        consultationQuality: Int? = nil,
        resultSatisfaction: Int? = nil,
        aftercareSupport: Int? = nil,
        reviewerName: String?,
        reviewerAvatar: String?,
        media: [ReviewMedia]?,
        providerName: String?,
        providerSpecialty: String?,
        facilityName: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.providerId = providerId
        self.facilityId = facilityId
        self.reviewTargetType = reviewTargetType
        self.visitDate = visitDate
        self.visitType = visitType
        self.surveyType = surveyType
        self.ratingWaitTime = ratingWaitTime
        self.ratingBedside = ratingBedside
        self.ratingEfficacy = ratingEfficacy
        self.ratingCleanliness = ratingCleanliness
        self.ratingStaff = ratingStaff
        self.ratingValue = ratingValue
        self.ratingPainMgmt = ratingPainMgmt
        self.ratingAccuracy = ratingAccuracy
        self.ratingKnowledge = ratingKnowledge
        self.ratingCourtesy = ratingCourtesy
        self.ratingCareQuality = ratingCareQuality
        self.ratingAdmin = ratingAdmin
        self.ratingComfort = ratingComfort
        self.ratingTurnaround = ratingTurnaround
        self.ratingEmpathy = ratingEmpathy
        self.ratingEnvironment = ratingEnvironment
        self.ratingCommunication = ratingCommunication
        self.ratingEffectiveness = ratingEffectiveness
        self.ratingAttentiveness = ratingAttentiveness
        self.ratingEquipment = ratingEquipment
        self.ratingConsultation = ratingConsultation
        self.ratingResults = ratingResults
        self.ratingAftercare = ratingAftercare
        self.ratingOverall = ratingOverall
        self.priceLevel = priceLevel
        self.title = title
        self.comment = comment
        self.wouldRecommend = wouldRecommend
        self.proofImageUrl = proofImageUrl
        self.isVerified = isVerified
        self.verificationConfidence = verificationConfidence
        self.status = status
        self.helpfulCount = helpfulCount
        self.createdAt = createdAt
        self.waitingTime = waitingTime
        self.facilityCleanliness = facilityCleanliness
        self.doctorCommunication = doctorCommunication
        self.treatmentOutcome = treatmentOutcome
        self.proceduralComfort = proceduralComfort
        self.clearExplanations = clearExplanations
        self.checkoutSpeed = checkoutSpeed
        self.stockAvailability = stockAvailability
        self.pharmacistAdvice = pharmacistAdvice
        self.staffCourtesy = staffCourtesy
        self.responseTime = responseTime
        self.nursingCare = nursingCare
        self.checkInProcess = checkInProcess
        self.testComfort = testComfort
        self.resultTurnaround = resultTurnaround
        self.sessionPunctuality = sessionPunctuality
        self.empathyListening = empathyListening
        self.sessionPrivacy = sessionPrivacy
        self.actionableAdvice = actionableAdvice
        self.therapyProgress = therapyProgress
        self.activeSupervision = activeSupervision
        self.facilityGear = facilityGear
        self.consultationQuality = consultationQuality
        self.resultSatisfaction = resultSatisfaction
        self.aftercareSupport = aftercareSupport
        self.reviewerName = reviewerName
        self.reviewerAvatar = reviewerAvatar
        self.media = media
        self.providerName = providerName
        self.providerSpecialty = providerSpecialty
        self.facilityName = facilityName
    }
}

extension Review {
    func ratingValue(for dbColumn: String) -> Int? {
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
