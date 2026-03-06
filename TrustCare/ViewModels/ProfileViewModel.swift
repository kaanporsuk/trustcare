import Combine
import Foundation
import Supabase
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var myReviews: [Review] = []
    @Published var reviewFilter: String = "all"
    @Published var isLoading: Bool = false
    @Published var isLoadingReviews: Bool = false
    @Published var isUpdatingAvatar: Bool = false
    @Published var isSavingProfile: Bool = false
    @Published var errorMessage: String?
    @Published var unreadNotificationCount: Int = 0
    @Published var avatarDisplayUrl: String?
    private static let verboseLogging = false

    private func verboseLog(_ message: @autoclosure () -> String) {
        guard Self.verboseLogging else { return }
        print(message())
    }
    
    init() {
        verboseLog("🔵 ProfileViewModel initialized")
    }

    func loadProfile() async {
        verboseLog("🔵 ProfileViewModel.loadProfile called")
        isLoading = true
        errorMessage = nil
        do {
            profile = try await AuthService.fetchProfile()
            verboseLog("Avatar URL from profile: \(profile?.avatarUrl ?? "nil")")
            await resolveAvatarDisplayUrl(from: profile?.avatarUrl)
            verboseLog("✅ Profile loaded: \(profile?.displayName ?? "nil")")
        } catch {
            print("❌ loadProfile failed: \(error)")
            errorMessage = localizedErrorMessage(error)
        }
        isLoading = false
    }

    func loadReviews(filter: String? = nil) async {
        let selectedFilter = filter ?? reviewFilter
        reviewFilter = selectedFilter
        isLoadingReviews = true
        errorMessage = nil
        defer { isLoadingReviews = false }

        do {
            let session = try await SupabaseManager.shared.client.auth.session

            struct ProviderRow: Decodable {
                let name: String
                let specialty: String
            }

            struct ReviewProviderRow: Decodable {
                let id: UUID
                let userId: UUID
                let providerId: UUID
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
                let providers: ProviderRow?

                enum CodingKeys: String, CodingKey {
                    case id, title, comment, status, providers
                    case userId = "user_id"
                    case providerId = "provider_id"
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
                }
            }

            var query = SupabaseManager.shared.client
                .from("reviews")
                .select("*, providers(name, specialty)")
                .eq("user_id", value: session.user.id.uuidString)

            if selectedFilter == "verified" {
                query = query.eq("is_verified", value: true)
            } else if selectedFilter == "pending" {
                query = query.eq("status", value: ReviewStatus.pendingVerification.rawValue)
            } else if selectedFilter == "unverified" {
                query = query.eq("is_verified", value: false)
                    .neq("status", value: ReviewStatus.pendingVerification.rawValue)
            }

            let response: PostgrestResponse<[ReviewProviderRow]> = try await query
                .order("created_at", ascending: false)
                .execute()

            myReviews = response.value.map { row in
                return Review(
                    id: row.id,
                    userId: row.userId,
                    providerId: row.providerId,
                    visitDate: row.visitDate,
                    visitType: row.visitType,
                    surveyType: row.surveyType,
                    ratingWaitTime: row.ratingWaitTime,
                    ratingBedside: row.ratingBedside,
                    ratingEfficacy: row.ratingEfficacy,
                    ratingCleanliness: row.ratingCleanliness,
                    ratingStaff: row.ratingStaff,
                    ratingValue: row.ratingValue,
                    ratingPainMgmt: row.ratingPainMgmt,
                    ratingAccuracy: row.ratingAccuracy,
                    ratingKnowledge: row.ratingKnowledge,
                    ratingCourtesy: row.ratingCourtesy,
                    ratingCareQuality: row.ratingCareQuality,
                    ratingAdmin: row.ratingAdmin,
                    ratingComfort: row.ratingComfort,
                    ratingTurnaround: row.ratingTurnaround,
                    ratingEmpathy: row.ratingEmpathy,
                    ratingEnvironment: row.ratingEnvironment,
                    ratingCommunication: row.ratingCommunication,
                    ratingEffectiveness: row.ratingEffectiveness,
                    ratingAttentiveness: row.ratingAttentiveness,
                    ratingEquipment: row.ratingEquipment,
                    ratingConsultation: row.ratingConsultation,
                    ratingResults: row.ratingResults,
                    ratingAftercare: row.ratingAftercare,
                    ratingOverall: row.ratingOverall,
                    priceLevel: row.priceLevel,
                    title: row.title,
                    comment: row.comment,
                    wouldRecommend: row.wouldRecommend,
                    proofImageUrl: row.proofImageUrl,
                    isVerified: row.isVerified,
                    verificationConfidence: row.verificationConfidence,
                    status: row.status,
                    helpfulCount: row.helpfulCount,
                    createdAt: row.createdAt,
                    waitingTime: row.waitingTime,
                    facilityCleanliness: row.facilityCleanliness,
                    doctorCommunication: row.doctorCommunication,
                    treatmentOutcome: row.treatmentOutcome,
                    proceduralComfort: row.proceduralComfort,
                    clearExplanations: row.clearExplanations,
                    checkoutSpeed: row.checkoutSpeed,
                    stockAvailability: row.stockAvailability,
                    pharmacistAdvice: row.pharmacistAdvice,
                    staffCourtesy: row.staffCourtesy,
                    responseTime: row.responseTime,
                    nursingCare: row.nursingCare,
                    checkInProcess: row.checkInProcess,
                    testComfort: row.testComfort,
                    resultTurnaround: row.resultTurnaround,
                    sessionPunctuality: row.sessionPunctuality,
                    empathyListening: row.empathyListening,
                    sessionPrivacy: row.sessionPrivacy,
                    actionableAdvice: row.actionableAdvice,
                    therapyProgress: row.therapyProgress,
                    activeSupervision: row.activeSupervision,
                    facilityGear: row.facilityGear,
                    consultationQuality: row.consultationQuality,
                    resultSatisfaction: row.resultSatisfaction,
                    aftercareSupport: row.aftercareSupport,
                    reviewerName: nil,
                    reviewerAvatar: nil,
                    media: nil,
                    providerName: row.providers?.name,
                    providerSpecialty: row.providers?.specialty
                )
            }
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
    }

    func deleteReview(id: UUID) async {
        do {
            _ = try await SupabaseManager.shared.client
                .from("reviews")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
            myReviews.removeAll { $0.id == id }
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
    }

    func updateReview(id: UUID, title: String?, comment: String) async {
        struct ReviewUpdate: Encodable {
            let title: String?
            let comment: String
        }

        do {
            let payload = ReviewUpdate(
                title: title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : title?.trimmingCharacters(in: .whitespacesAndNewlines),
                comment: comment.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            _ = try await SupabaseManager.shared.client
                .from("reviews")
                .update(payload)
                .eq("id", value: id.uuidString)
                .execute()

            await loadReviews(filter: reviewFilter)
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
    }

    func updateAvatar(image: UIImage) async -> Bool {
        isUpdatingAvatar = true
        defer { isUpdatingAvatar = false }
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            guard let data = ImageService.prepareAvatarUploadData(image, maxDimension: 1600, compressionQuality: 0.7) else {
                throw NSError(
                    domain: "ProfileAvatarUpload",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: tcString("Avatar processing failed. Please use a different photo under 5 MB.", fallback: "Avatar processing failed. Please use a different photo under 5 MB.")]
                )
            }

            let userId = session.user.id.uuidString
            let path = "avatars/\(userId)/avatar_\(UUID().uuidString).jpg"
            let url = try await ImageService.uploadToStorage(
                bucket: "avatars",
                path: path,
                data: data,
                contentType: "image/jpeg"
            )
            verboseLog("✅ Avatar uploaded: \(url)")

            try await AuthService.updateProfile(
                fullName: nil,
                avatarUrl: url,
                bio: nil,
                phone: nil,
                countryCode: nil,
                language: nil,
                currency: nil
            )
            avatarDisplayUrl = cacheBustedUrl(url)
            await loadProfile()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func resolveAvatarDisplayUrl(from rawUrl: String?) async {
        guard let rawUrl, !rawUrl.isEmpty else {
            avatarDisplayUrl = nil
            return
        }

        // Try to extract path from the raw URL
        if let path = ImageService.extractStoragePath(from: rawUrl, bucket: "avatars") {
            if let publicUrl = ImageService.getPublicURL(bucket: "avatars", path: path) {
                avatarDisplayUrl = cacheBustedUrl(publicUrl.absoluteString)
                verboseLog("✅ Avatar public URL resolved: \(publicUrl.absoluteString)")
                return
            }
        }

        // Also try old user-avatars path for backward compatibility
        if let path = ImageService.extractStoragePath(from: rawUrl, bucket: "user-avatars") {
            if let publicUrl = ImageService.getPublicURL(bucket: "user-avatars", path: path) {
                avatarDisplayUrl = cacheBustedUrl(publicUrl.absoluteString)
                verboseLog("✅ Avatar public URL resolved from legacy path: \(publicUrl.absoluteString)")
                return
            }
        }

        // Fallback: use raw URL if extraction or URL generation fails
        verboseLog("📌 Using raw avatar URL as fallback: \(rawUrl)")
        avatarDisplayUrl = cacheBustedUrl(rawUrl)
    }

    private func storagePath(from urlString: String) -> String? {
        return ImageService.extractStoragePath(from: urlString, bucket: "avatars")
    }

    private func cacheBustedUrl(_ url: String) -> String {
        let separator = url.contains("?") ? "&" : "?"
        return "\(url)\(separator)v=\(Int(Date().timeIntervalSince1970))"
    }

    func updatePhone(_ phone: String?) async {
        do {
            try await AuthService.updateProfile(
                fullName: nil,
                avatarUrl: nil,
                bio: nil,
                phone: phone,
                countryCode: nil,
                language: nil,
                currency: nil
            )
            await loadProfile()
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
    }

    func updateLanguage(_ language: String) async {
        do {
            try await AuthService.updateProfile(
                fullName: nil,
                avatarUrl: nil,
                bio: nil,
                phone: nil,
                countryCode: nil,
                language: language,
                currency: nil
            )
            await loadProfile()
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
    }

    func updateRegion(countryCode: String, currency: String) async {
        do {
            try await AuthService.updateProfile(
                fullName: nil,
                avatarUrl: nil,
                bio: nil,
                phone: nil,
                countryCode: countryCode,
                language: nil,
                currency: currency
            )
            await loadProfile()
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
    }

    func updateProfile(fullName: String?, bio: String?, phone: String?) async {
        isSavingProfile = true
        defer { isSavingProfile = false }
        do {
            let trimmedName = fullName?.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedBio = bio?.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedPhone = phone?.trimmingCharacters(in: .whitespacesAndNewlines)
            try await AuthService.updateProfile(
                fullName: trimmedName?.isEmpty == true ? nil : trimmedName,
                avatarUrl: nil,
                bio: trimmedBio?.isEmpty == true ? nil : trimmedBio,
                phone: trimmedPhone?.isEmpty == true ? nil : trimmedPhone,
                countryCode: nil,
                language: nil,
                currency: nil
            )
            await loadProfile()
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
    }

    func loadNotificationCount() async {
        do {
            unreadNotificationCount = try await NotificationService.fetchUnreadCount()
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
    }

    func deleteAccount() async {
        do {
            try await AuthService.deleteAccount()
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
    }

    private func localizedErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }

        let localized = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !localized.isEmpty,
           localized != "The operation couldn’t be completed." {
            return localized
        }

        let debugDescription = String(describing: error).trimmingCharacters(in: .whitespacesAndNewlines)
        if !debugDescription.isEmpty {
            return debugDescription
        }

        return tcString("Unknown error", fallback: "Unknown error")
    }
}
