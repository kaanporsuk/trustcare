import Combine
import Foundation
import UIKit
import Supabase

@MainActor
final class ReviewSubmissionViewModel: ObservableObject {
    enum TargetMode: String, CaseIterable, Identifiable {
        case provider
        case facility
        case both

        var id: String { rawValue }
    }

    private static let hasSubmittedReviewKey = "has_submitted_review_v1"

    @Published var selectedProvider: Provider?
    @Published var selectedFacility: Facility?
    @Published var targetMode: TargetMode = .provider
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
    @Published var lastSubmittedFacilityID: UUID?

    static var shouldShowFirstReviewNudge: Bool {
        !UserDefaults.standard.bool(forKey: hasSubmittedReviewKey)
    }

    var canSubmit: Bool {
        hasValidTargetSelection
            && overallRating > 0
            && comment.trimmingCharacters(in: .whitespacesAndNewlines).count >= 50
    }

    var hasValidTargetSelection: Bool {
        switch targetMode {
        case .provider:
            return selectedProvider != nil
        case .facility:
            return selectedFacility != nil
        case .both:
            return selectedProvider != nil && selectedFacility != nil
        }
    }

    var activeTargetType: ReviewTargetType {
        targetMode == .facility ? .facility : .provider
    }

    var availableCriteria: [RatingCriterion] {
        switch targetMode {
        case .provider:
            return RatingCriterion.provider
        case .facility:
            return RatingCriterion.facility
        case .both:
            return RatingCriterion.provider + RatingCriterion.facility
        }
    }

    var commentCharCount: Int { comment.count }

    init(provider: Provider? = nil) {
        if let provider {
            selectProvider(provider)
        }
    }

    func selectProvider(_ provider: Provider) {
        selectedProvider = provider
        if targetMode == .provider {
            surveyConfig = SpecialtyService.shared.surveyConfig(for: provider.specialty)
            resetMetricRatings(for: .provider)
        }
    }

    func selectFacility(_ facility: Facility) {
        selectedFacility = facility
        if targetMode == .facility {
            surveyConfig = SurveyConfigurations.generalClinic
            resetMetricRatings(for: .facility)
        }
    }

    func setTargetMode(_ mode: TargetMode) {
        targetMode = mode
        switch mode {
        case .provider:
            if let provider = selectedProvider {
                surveyConfig = SpecialtyService.shared.surveyConfig(for: provider.specialty)
            }
            resetMetricRatings(for: .provider)
        case .facility:
            surveyConfig = SurveyConfigurations.generalClinic
            resetMetricRatings(for: .facility)
        case .both:
            if let provider = selectedProvider {
                surveyConfig = SpecialtyService.shared.surveyConfig(for: provider.specialty)
            }
            metricRatings = Dictionary(
                uniqueKeysWithValues: (RatingCriterion.provider + RatingCriterion.facility).map { ($0.dbColumn, 0) }
            )
        }
    }

    func removePhoto(at index: Int) {
        guard photos.indices.contains(index) else { return }
        photos.remove(at: index)
    }

    func submitReview() async {
        guard hasValidTargetSelection else {
            submissionErrorMessage = tcString("review_select_target_to_continue", fallback: "Select who you are reviewing to continue.")
            return
        }

        guard (try? await SupabaseManager.shared.client.auth.session) != nil else {
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
            let derivedPriceLevel = max(1, min(4, Int(round(Double(overallRating) / 1.25))))
            let generatedTitle = String(trimmedComment.prefix(60)).trimmingCharacters(in: .whitespacesAndNewlines)
            let visitTypeEnum = mappedVisitType(for: visitType)
            let surveyType = surveyConfig.type
            let title = generatedTitle.isEmpty ? nil : generatedTitle

            let targets = resolveSubmissionTargets()
            var submittedReviews: [Review] = []

            for (index, target) in targets.enumerated() {
                let review = try await retry(times: 3) {
                    try await ReviewService.submitReview(
                        target: target,
                        visitDate: self.visitDate,
                        visitType: visitTypeEnum,
                        surveyType: surveyType,
                        metricRatings: self.metricRatings,
                        overallRating: self.overallRating,
                        priceLevel: derivedPriceLevel,
                        title: title,
                        comment: trimmedComment,
                        wouldRecommend: self.overallRating >= 4,
                        proofImage: self.proofImage,
                        images: index == 0 ? self.photos : [],
                        videoURL: nil,
                        statusOverride: nil,
                        progressHandler: { progress in
                            let total = Double(max(targets.count, 1))
                            self.mediaUploadProgress = min(1.0, (Double(index) + progress) / total)
                        }
                    )
                }
                submittedReviews.append(review)
            }

            mediaUploadProgress = 1.0
            lastSubmittedReviewID = submittedReviews.last?.id
            lastSubmittedProviderID = submittedReviews.last(where: { $0.reviewTargetType == .provider })?.providerId
            lastSubmittedFacilityID = submittedReviews.last(where: { $0.reviewTargetType == .facility })?.facilityId
            didUploadProof = proofImage != nil
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
        if !keepProvider {
            selectedFacility = nil
        }
        if let provider {
            surveyConfig = SpecialtyService.shared.surveyConfig(for: provider.specialty)
            resetMetricRatings(for: .provider)
        } else {
            surveyConfig = SurveyConfigurations.generalClinic
            resetMetricRatings(for: .provider)
        }
        targetMode = keepProvider ? .provider : .provider
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
        lastSubmittedFacilityID = nil
    }

    private func markFirstSubmissionCompleted() {
        UserDefaults.standard.set(true, forKey: Self.hasSubmittedReviewKey)
        NotificationCenter.default.post(name: .trustCareReviewNudgeUpdated, object: nil)
    }

    private func mappedVisitType(for uiValue: String) -> VisitType {
        let mapping: [String: VisitType] = [
            "examination": .consultation,
            "procedure": .procedure,
            "checkup": .checkup,
            "emergency": .emergency,
        ]
        return mapping[uiValue] ?? .consultation
    }

    private func resetMetricRatings(for targetType: ReviewTargetType) {
        metricRatings = Dictionary(uniqueKeysWithValues: RatingCriterion.criteria(for: targetType).map { ($0.dbColumn, 0) })
    }

    private func resolveSubmissionTargets() -> [ReviewTarget] {
        switch targetMode {
        case .provider:
            if let provider = selectedProvider {
                return [.provider(provider.id)]
            }
        case .facility:
            if let facility = selectedFacility {
                return [.facility(facility.id)]
            }
        case .both:
            if let provider = selectedProvider, let facility = selectedFacility {
                return [.provider(provider.id), .facility(facility.id)]
            }
        }
        return []
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
