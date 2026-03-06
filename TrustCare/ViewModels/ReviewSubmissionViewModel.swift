import Combine
import Foundation
import UIKit
import Supabase

@MainActor
final class ReviewSubmissionViewModel: ObservableObject {
    private static let hasSubmittedReviewKey = "has_submitted_review_v1"

    @Published var selectedProvider: Provider?
    @Published var surveyConfig: SurveyConfig = SurveyConfigurations.generalClinic
    @Published var visitDate: Date = Date()
    @Published var visitType: String = "examination"
    @Published var overallRating: Int = 0
    @Published var metricRatings: [String: Int] = [:]
    @Published var comment: String = ""
    @Published var photos: [UIImage] = []
    @Published var proofImage: UIImage?
    @Published var isSubmitting: Bool = false
    @Published var submissionErrorMessage: String?
    @Published var isComplete: Bool = false
    @Published var mediaUploadProgress: Double = 0

    @Published var didUploadProof: Bool = false
    @Published var lastSubmittedReviewID: UUID?
    @Published var lastSubmittedProviderID: UUID?

    static var shouldShowFirstReviewNudge: Bool {
        !UserDefaults.standard.bool(forKey: hasSubmittedReviewKey)
    }

    var canSubmit: Bool {
        selectedProvider != nil
            && overallRating > 0
            && comment.trimmingCharacters(in: .whitespacesAndNewlines).count >= 50
    }

    var commentCharCount: Int { comment.count }

    init(provider: Provider? = nil) {
        if let provider {
            selectProvider(provider)
        }
    }

    func selectProvider(_ provider: Provider) {
        selectedProvider = provider
        surveyConfig = SpecialtyService.shared.surveyConfig(for: provider.specialty)
        metricRatings = [:]
        for criterion in RatingCriterion.all {
            metricRatings[criterion.dbColumn] = 0
        }
    }

    func removePhoto(at index: Int) {
        guard photos.indices.contains(index) else { return }
        photos.remove(at: index)
    }

    func submitReview() async {
        guard let provider = selectedProvider else {
            submissionErrorMessage = tcString("Please select a provider.", fallback: "Please select a provider.")
            return
        }

        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            submissionErrorMessage = tcString("Please sign in to submit a review.", fallback: "Please sign in to submit a review.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if overallRating <= 0 {
            submissionErrorMessage = tcString("Overall rating is required.", fallback: "Overall rating is required.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        if trimmedComment.count < 50 {
            submissionErrorMessage = tcString("Your review must be at least 50 characters.", fallback: "Your review must be at least 50 characters.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        if photos.count > 5 {
            submissionErrorMessage = tcString("You can upload up to 5 photos.", fallback: "You can upload up to 5 photos.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        isSubmitting = true
        submissionErrorMessage = nil
        mediaUploadProgress = 0
        didUploadProof = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        do {
            let reviewId = UUID()
            var uploadedPhotoUrls: [String] = []
            let derivedPriceLevel = max(1, min(4, Int(round(Double(overallRating) / 1.25))))
            let generatedTitle = String(trimmedComment.prefix(60)).trimmingCharacters(in: .whitespacesAndNewlines)

            let photoCount = min(photos.count, 5)
            let totalSteps = Double(photoCount + (proofImage != nil ? 1 : 0) + 1)
            var completedSteps = 0.0

            func step() {
                completedSteps += 1
                mediaUploadProgress = min(1.0, completedSteps / max(totalSteps, 1))
            }

            for image in photos.prefix(5) {
                guard let data = ImageService.compressImage(image, maxSizeKB: 1024) else { continue }
                let path = "\(session.user.id.uuidString)/\(reviewId.uuidString)/\(UUID().uuidString).jpg"
                let url = try await ImageService.uploadToStorage(
                    bucket: "review-photos",
                    path: path,
                    data: data,
                    contentType: "image/jpeg"
                )
                uploadedPhotoUrls.append(url)
                step()
            }

            var proofURL: String?
            if let proofImage,
               let data = ImageService.compressImage(proofImage, maxSizeKB: 1024) {
                let path = "\(session.user.id.uuidString)/\(reviewId.uuidString)/proof_\(UUID().uuidString).jpg"
                proofURL = try await ImageService.uploadToStorage(
                    bucket: "verification-proofs",
                    path: path,
                    data: data,
                    contentType: "image/jpeg"
                )
                didUploadProof = true
                step()
            }

            struct ReviewInsert: Encodable {
                let id: String
                let userId: String
                let providerId: String
                let ratingOverall: Double
                let priceLevel: Int
                let title: String?
                let comment: String
                let wouldRecommend: Bool
                let visitDate: Date
                let visitType: String
                let surveyType: String
                let ratingWaitTime: Int?
                let ratingBedside: Int?
                let ratingEfficacy: Int?
                let ratingCleanliness: Int?
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
                let photoUrls: [String]
                let proofImageUrl: String?
                let status: String

                enum CodingKeys: String, CodingKey {
                    case id
                    case userId = "user_id"
                    case providerId = "provider_id"
                    case ratingOverall = "rating_overall"
                    case priceLevel = "price_level"
                    case title
                    case comment
                    case wouldRecommend = "would_recommend"
                    case visitDate = "visit_date"
                    case visitType = "visit_type"
                    case surveyType = "survey_type"
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
                    case photoUrls = "photo_urls"
                    case proofImageUrl = "proof_image_url"
                    case status
                }
            }

            func value(_ key: String) -> Int? {
                guard let value = metricRatings[key], value > 0 else { return nil }
                return value
            }

            let dbVisitType = mappedVisitType(for: visitType)
            let submissionStatus = proofURL != nil ? "pending_verification" : "active"

            let payload = ReviewInsert(
                id: reviewId.uuidString,
                userId: session.user.id.uuidString,
                providerId: provider.id.uuidString,
                ratingOverall: Double(overallRating),
                priceLevel: derivedPriceLevel,
                title: generatedTitle.isEmpty ? nil : generatedTitle,
                comment: trimmedComment,
                wouldRecommend: overallRating >= 4,
                visitDate: visitDate,
                visitType: dbVisitType,
                surveyType: surveyConfig.type,
                ratingWaitTime: value("rating_wait_time"),
                ratingBedside: value("rating_bedside"),
                ratingEfficacy: value("rating_efficacy"),
                ratingCleanliness: value("rating_cleanliness"),
                ratingPainMgmt: value("rating_pain_mgmt"),
                ratingAccuracy: value("rating_accuracy"),
                ratingKnowledge: value("rating_knowledge"),
                ratingCourtesy: value("rating_courtesy"),
                ratingCareQuality: value("rating_care_quality"),
                ratingAdmin: value("rating_admin"),
                ratingComfort: value("rating_comfort"),
                ratingTurnaround: value("rating_turnaround"),
                ratingEmpathy: value("rating_empathy"),
                ratingEnvironment: value("rating_environment"),
                ratingCommunication: value("rating_communication"),
                ratingEffectiveness: value("rating_effectiveness"),
                ratingAttentiveness: value("rating_attentiveness"),
                ratingEquipment: value("rating_equipment"),
                ratingConsultation: value("rating_consultation"),
                ratingResults: value("rating_results"),
                ratingAftercare: value("rating_aftercare"),
                photoUrls: uploadedPhotoUrls,
                proofImageUrl: proofURL,
                status: submissionStatus
            )

            _ = try await retry(times: 3) {
                try await SupabaseManager.shared.client
                    .from("reviews")
                    .insert(payload)
                    .select()
                    .single()
                    .execute()
            }

            step()
            mediaUploadProgress = 1.0
            lastSubmittedReviewID = reviewId
            lastSubmittedProviderID = provider.id
            markFirstSubmissionCompleted()
            isComplete = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            submissionErrorMessage = localizedErrorMessage(error)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        isSubmitting = false
    }

    func resetForm(keepProvider: Bool = false) {
        let provider = keepProvider ? selectedProvider : nil
        selectedProvider = provider
        if let provider {
            surveyConfig = SpecialtyService.shared.surveyConfig(for: provider.specialty)
            metricRatings = Dictionary(uniqueKeysWithValues: RatingCriterion.all.map { ($0.dbColumn, 0) })
        } else {
            surveyConfig = SurveyConfigurations.generalClinic
            metricRatings = [:]
        }
        visitDate = Date()
        visitType = "examination"
        overallRating = 0
        comment = ""
        photos = []
        proofImage = nil
        isSubmitting = false
        submissionErrorMessage = nil
        mediaUploadProgress = 0
        didUploadProof = false
        isComplete = false
        lastSubmittedReviewID = nil
        lastSubmittedProviderID = nil
    }

    private func markFirstSubmissionCompleted() {
        UserDefaults.standard.set(true, forKey: Self.hasSubmittedReviewKey)
        NotificationCenter.default.post(name: .trustCareReviewNudgeUpdated, object: nil)
    }

    private func mappedVisitType(for uiValue: String) -> String {
        // Tags are now canonical English keys that map directly to DB values
        let mapping: [String: String] = [
            "examination": "consultation",
            "procedure": "procedure",
            "checkup": "checkup",
            "emergency": "emergency"
        ]
        return mapping[uiValue] ?? "consultation"
    }

    private func localizedErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }
        let localized = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !localized.isEmpty {
            let lower = localized.lowercased()
            if lower.contains("network") || lower.contains("offline") || lower.contains("internet") {
                return tcString("error_network", fallback: "Network error")
            }
            if lower.contains("duplicate") || lower.contains("unique") {
                return tcString("error_duplicate_review", fallback: "Duplicate review")
            }
            return localized
        }
        return tcString("Unknown error", fallback: "Unknown error")
    }

    private func retry<T>(times: Int, operation: @escaping () async throws -> T) async throws -> T {
        var attempt = 0
        var lastError: Error?

        while attempt < times {
            do {
                return try await operation()
            } catch {
                lastError = error
                attempt += 1

                if attempt >= times || !isRetryable(error) {
                    throw error
                }

                let delayNanos = UInt64(pow(2.0, Double(attempt - 1)) * 400_000_000)
                try? await Task.sleep(nanoseconds: delayNanos)
            }
        }

        throw lastError ?? AppError.unknown
    }

    private func isRetryable(_ error: Error) -> Bool {
        let message = error.localizedDescription.lowercased()
        return message.contains("network")
            || message.contains("timeout")
            || message.contains("offline")
            || message.contains("temporarily unavailable")
    }
}
