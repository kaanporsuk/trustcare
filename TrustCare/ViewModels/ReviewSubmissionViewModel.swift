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
    @Published var submissionErrorMessage: String?
    @Published var searchErrorMessage: String?
    @Published var showSkipVerificationNote: Bool = false
    @Published var isComplete: Bool = false
    @Published var mediaUploadProgress: Double = 0
    @Published var isLoading: Bool = false

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
            isLoading = false
            searchErrorMessage = nil
            return
        }

        isLoading = true
        searchTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
            } catch {
                self?.isLoading = false
                return
            }
            guard !Task.isCancelled, let self else { return }
            do {
                let results = try await ProviderService.searchProvidersTable(query: trimmed)
                self.searchResults = results
                self.searchErrorMessage = nil
                self.isLoading = false
            } catch {
                self.searchErrorMessage = self.localizedSearchErrorMessage(error)
                self.isLoading = false
            }
        }
    }

    func selectProvider(_ provider: Provider, advanceToStep2: Bool = false) {
        selectedProvider = provider
        searchText = provider.name
        searchResults = []
        searchErrorMessage = nil
        submissionErrorMessage = nil
        if advanceToStep2 {
            currentStep = 2
        }
    }

    func nextStep() {
        guard canAdvance else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        submissionErrorMessage = nil
        showSkipVerificationNote = false
        currentStep = min(7, currentStep + 1)
    }

    func previousStep() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        submissionErrorMessage = nil
        showSkipVerificationNote = false
        currentStep = max(1, currentStep - 1)
    }

    func skipPhotos() {
        selectedImages = []
        selectedVideo = nil
        selectedVideoDuration = nil
        nextStep()
    }

    func skipVerification() async {
        proofImage = nil
        showSkipVerificationNote = true
        submissionErrorMessage = nil
        try? await Task.sleep(nanoseconds: 700_000_000)
        await submit(statusOverride: "pending_verification")
    }

    func resetFlow() {
        currentStep = 1
        selectedProvider = nil
        searchText = ""
        searchResults = []
        visitDate = Date()
        visitType = .consultation
        ratingWaitTime = 5
        ratingBedside = 5
        ratingEfficacy = 5
        ratingCleanliness = 5
        priceLevel = .moderate
        title = ""
        comment = ""
        wouldRecommend = true
        selectedImages = []
        selectedVideo = nil
        selectedVideoDuration = nil
        proofImage = nil
        submissionErrorMessage = nil
        searchErrorMessage = nil
        showSkipVerificationNote = false
        isComplete = false
        mediaUploadProgress = 0
        isLoading = false
    }

    func submit(statusOverride: String? = nil) async {
        guard let provider = selectedProvider else {
            submissionErrorMessage = String(localized: "Please select a provider before submitting.")
            return
        }
        if comment.trimmingCharacters(in: .whitespacesAndNewlines).count < 50 {
            submissionErrorMessage = String(localized: "Please enter at least 50 characters in your review.")
            return
        }
        if ratingWaitTime < 1 || ratingBedside < 1 || ratingEfficacy < 1 || ratingCleanliness < 1 {
            submissionErrorMessage = String(localized: "Please complete all ratings before submitting.")
            return
        }
        if selectedImages.count > 5 {
            submissionErrorMessage = String(localized: "You can upload up to 5 photos.")
            return
        }
        if let duration = selectedVideoDuration, duration > 30 {
            submissionErrorMessage = String(localized: "Videos must be 30 seconds or less.")
            return
        }
        isSubmitting = true
        submissionErrorMessage = nil
        mediaUploadProgress = 0

        let waitRating = max(1, min(5, Int(round(ratingWaitTime / 2.0))))
        let bedsideRating = max(1, min(5, Int(round(ratingBedside / 2.0))))
        let efficacyRating = max(1, min(5, Int(round(ratingEfficacy / 2.0))))
        let cleanlinessRating = max(1, min(5, Int(round(ratingCleanliness / 2.0))))

        do {
            print("🔵 ReviewSubmissionViewModel.submit started")
            print("  Provider ID: \(provider.id)")
            print("  Visit date: \(visitDate)")
            print("  Visit type: \(visitType.rawValue)")
            print("  Ratings (1-5): wait=\(waitRating), bedside=\(bedsideRating), efficacy=\(efficacyRating), cleanliness=\(cleanlinessRating)")
            print("  Comment length: \(comment.count)")
            print("  Proof image selected: \(proofImage != nil)")
            print("  Media images: \(selectedImages.count), video: \(selectedVideo != nil)")
            if let statusOverride {
                print("  Status override: \(statusOverride)")
            }
            let review = try await ReviewService.submitReview(
                providerId: provider.id,
                visitDate: visitDate,
                visitType: visitType,
                ratings: (
                    wait: waitRating,
                    bedside: bedsideRating,
                    efficacy: efficacyRating,
                    cleanliness: cleanlinessRating
                ),
                priceLevel: priceLevel.rawValue,
                title: title.isEmpty ? nil : title,
                comment: comment,
                wouldRecommend: wouldRecommend,
                proofImage: proofImage,
                images: selectedImages,
                videoURL: selectedVideo,
                statusOverride: statusOverride,
                progressHandler: { [weak self] progress in
                    Task { @MainActor in
                        self?.mediaUploadProgress = progress
                    }
                }
            )
            _ = review
            mediaUploadProgress = 1
            isComplete = true
            showSkipVerificationNote = false
        } catch {
            let message = localizedErrorMessage(error)
            print("❌ ReviewSubmissionViewModel.submit failed: \(message)")
            submissionErrorMessage = message
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
        return error.localizedDescription
    }

    private func localizedSearchErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }

        let message = error.localizedDescription.lowercased()
        if message.contains("network") || message.contains("offline") {
            return String(localized: "Network error. Please check your connection.")
        }
        return String(localized: "Unable to load providers. Please try again.")
    }
}
