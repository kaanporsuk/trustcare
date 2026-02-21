import Combine
import Foundation
import UIKit

@MainActor
final class ReviewSubmissionViewModel: ObservableObject {
    @Published var selectedProvider: Provider

    @Published var visitDate: Date = Date()
    @Published var visitType: VisitType = .consultation

    @Published var overallRating: Int = 0
    @Published var surveyConfig: SurveyConfig = SurveyConfigurations.generalClinic
    @Published var metricRatings: [String: Int] = [:]

    @Published var title: String = ""
    @Published var comment: String = ""
    @Published var wouldRecommend: Bool = true
    @Published var selectedImages: [UIImage] = []
    @Published var proofImage: UIImage?

    @Published var isSubmitting: Bool = false
    @Published var submissionErrorMessage: String?
    @Published var isComplete: Bool = false
    @Published var mediaUploadProgress: Double = 0

    private var hasSetOverall: Bool = false

    init(provider: Provider) {
        self.selectedProvider = provider
        selectProvider(provider)
    }

    func selectProvider(_ provider: Provider) {
        selectedProvider = provider
        surveyConfig = SpecialtyService.shared.surveyConfig(for: provider.specialty)
        metricRatings = [:]
        for metric in surveyConfig.metrics {
            metricRatings[metric.dbColumn] = 0
        }
    }

    var commentCharCount: Int {
        comment.count
    }

    var isCommentValid: Bool {
        comment.trimmingCharacters(in: .whitespacesAndNewlines).count >= 50
    }

    var canSubmit: Bool {
        overallRating > 0 && isCommentValid && hasAllMetricRatings
    }

    private var hasAllMetricRatings: Bool {
        surveyConfig.metrics.allSatisfy { metric in
            (metricRatings[metric.dbColumn] ?? 0) >= 1
        }
    }

    func setOverallRating(_ value: Int) {
        overallRating = value
        hasSetOverall = true
    }

    func updateOverallIfNeeded() {
        guard !hasSetOverall else { return }
        let ratings = surveyConfig.metrics.map { metricRatings[$0.dbColumn] ?? 0 }
        guard ratings.allSatisfy({ $0 > 0 }) else {
            overallRating = 0
            return
        }
        let average = Double(ratings.reduce(0, +)) / Double(ratings.count)
        overallRating = Int(round(average))
    }

    func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)
    }

    func submit() async {
        guard await AuthService.currentSession() != nil else {
            submissionErrorMessage = String(localized: "Please sign in to submit a review.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if overallRating < 1 {
            submissionErrorMessage = String(localized: "Please complete all ratings before submitting.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        if trimmedComment.count < 50 {
            submissionErrorMessage = String(format: String(localized: "Your review must be at least 50 characters. Currently %lld / 50."), commentCharCount)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        if !hasAllMetricRatings {
            submissionErrorMessage = String(localized: "Please complete all ratings before submitting.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        if selectedImages.count > 5 {
            submissionErrorMessage = String(localized: "You can upload up to 5 photos.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        isSubmitting = true
        submissionErrorMessage = nil
        mediaUploadProgress = 0
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let validRatings = surveyConfig.metrics.compactMap { metric -> Int? in
            let value = metricRatings[metric.dbColumn] ?? 0
            return (1...5).contains(value) ? value : nil
        }
        let baseValue = validRatings.isEmpty ? overallRating : Int(round(Double(validRatings.reduce(0, +)) / Double(validRatings.count)))
        let priceLevel = max(1, min(4, Int(round(Double(baseValue) / 1.25))))

        do {
            _ = try await ReviewService.submitReview(
                providerId: selectedProvider.id,
                visitDate: visitDate,
                visitType: visitType,
                surveyType: surveyConfig.type,
                metricRatings: metricRatings,
                overallRating: overallRating,
                priceLevel: priceLevel,
                title: title.isEmpty ? nil : title,
                comment: comment,
                wouldRecommend: wouldRecommend,
                proofImage: proofImage,
                images: selectedImages,
                videoURL: nil,
                progressHandler: { [weak self] progress in
                    Task { @MainActor in
                        self?.mediaUploadProgress = progress
                    }
                }
            )
            mediaUploadProgress = 1
            isComplete = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            let message = localizedErrorMessage(error)
            submissionErrorMessage = message
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        isSubmitting = false
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

        return String(localized: "Unknown error")
    }
}
