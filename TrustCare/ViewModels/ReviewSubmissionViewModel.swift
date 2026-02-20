import Combine
import Foundation
import UIKit

@MainActor
final class ReviewSubmissionViewModel: ObservableObject {
    let provider: Provider

    @Published var visitDate: Date = Date()
    @Published var visitType: VisitType = .consultation

    @Published var overallRating: Int = 0
    @Published var ratingWaitTime: Int = 0
    @Published var ratingBedside: Int = 0
    @Published var ratingEfficacy: Int = 0
    @Published var ratingCleanliness: Int = 0
    @Published var ratingStaff: Int = 0
    @Published var ratingValue: Int = 0

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
        self.provider = provider
    }

    var commentCharCount: Int {
        comment.count
    }

    var isCommentValid: Bool {
        comment.trimmingCharacters(in: .whitespacesAndNewlines).count >= 50
    }

    var canSubmit: Bool {
        overallRating > 0 && isCommentValid
    }

    func setOverallRating(_ value: Int) {
        overallRating = value
        hasSetOverall = true
    }

    func updateOverallIfNeeded() {
        guard !hasSetOverall else { return }
        let ratings = [ratingWaitTime, ratingBedside, ratingEfficacy, ratingCleanliness, ratingStaff, ratingValue]
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
        if [ratingWaitTime, ratingBedside, ratingEfficacy, ratingCleanliness, ratingStaff, ratingValue].contains(where: { $0 < 1 }) {
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

        let priceLevel = max(1, min(4, Int(round(Double(ratingValue) / 1.25))))

        do {
            _ = try await ReviewService.submitReview(
                providerId: provider.id,
                visitDate: visitDate,
                visitType: visitType,
                ratings: (
                    wait: ratingWaitTime,
                    bedside: ratingBedside,
                    efficacy: ratingEfficacy,
                    cleanliness: ratingCleanliness,
                    staff: ratingStaff,
                    value: ratingValue
                ),
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
