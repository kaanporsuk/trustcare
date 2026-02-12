import AVFoundation
import Combine
import Foundation
import UIKit

@MainActor
final class ReviewSubmissionViewModel: ObservableObject {
    @Published var currentStep: Int = 1
    @Published var selectedProvider: Provider?
    @Published var searchText: String = ""
    @Published var searchResults: [Provider] = []
    @Published var visitDate: Date = Date()
    @Published var visitType: VisitType = .consultation
    @Published var ratingWaitTime: Double = 5
    @Published var ratingBedside: Double = 5
    @Published var ratingEfficacy: Double = 5
    @Published var ratingCleanliness: Double = 5
    @Published var priceLevel: PriceLevel = .moderate
    @Published var title: String = ""
    @Published var comment: String = ""
    @Published var wouldRecommend: Bool = true
    @Published var selectedImages: [UIImage] = []
    @Published var selectedVideo: URL?
    @Published var selectedVideoDuration: Double?
    @Published var proofImage: UIImage?
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var isComplete: Bool = false
    @Published var mediaUploadProgress: Double = 0

    private var searchTask: Task<Void, Never>?

    var canAdvance: Bool {
        switch currentStep {
        case 1:
            return selectedProvider != nil
        case 2:
            return visitDate <= Date()
        case 3:
            return true
        case 4:
            return true
        case 5:
            return comment.count >= 50
        case 6:
            guard selectedImages.count <= 5 else { return false }
            if let duration = selectedVideoDuration {
                return duration <= 30
            }
            return true
        case 7:
            return true
        default:
            return false
        }
    }

    var overallRating: Double {
        let total = ratingWaitTime + ratingBedside + ratingEfficacy + ratingCleanliness
        return (total / 4.0) / 2.0
    }

    var commentCharCount: String {
        "\(comment.count) / 1000"
    }

    func searchProviders() {
        searchTask?.cancel()
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled, let self else { return }
            do {
                let results = try await ProviderService.searchProviders(
                    text: trimmed,
                    specialty: nil,
                    country: nil,
                    priceLevel: nil,
                    minRating: nil,
                    verifiedOnly: nil,
                    lat: nil,
                    lng: nil
                )
                self.searchResults = results
            } catch {
                self.errorMessage = self.localizedErrorMessage(error)
            }
        }
    }

    func nextStep() {
        guard canAdvance else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        currentStep = min(7, currentStep + 1)
    }

    func previousStep() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        currentStep = max(1, currentStep - 1)
    }

    func submit() async {
        guard let provider = selectedProvider else { return }
        isSubmitting = true
        errorMessage = nil
        mediaUploadProgress = 0

        do {
            let review = try await ReviewService.submitReview(
                providerId: provider.id,
                visitDate: visitDate,
                visitType: visitType,
                ratings: (
                    wait: Int(ratingWaitTime),
                    bedside: Int(ratingBedside),
                    efficacy: Int(ratingEfficacy),
                    cleanliness: Int(ratingCleanliness)
                ),
                priceLevel: priceLevel.rawValue,
                title: title.isEmpty ? nil : title,
                comment: comment,
                wouldRecommend: wouldRecommend,
                proofImage: proofImage,
                images: selectedImages,
                videoURL: selectedVideo
            )
            _ = review
            mediaUploadProgress = 1
            isComplete = true
        } catch {
            errorMessage = localizedErrorMessage(error)
        }

        isSubmitting = false
    }

    private func videoDurationSeconds(for url: URL) -> Double? {
        nil
    }

    private func localizedErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }

        let message = error.localizedDescription.lowercased()
        if message.contains("network") || message.contains("offline") {
            return String(localized: "Network error. Please check your connection.")
        }
        if message.contains("upload") {
            return String(localized: "Unable to upload media. Please try again.")
        }
        return String(localized: "Unable to submit review. Please try again.")
    }
}
