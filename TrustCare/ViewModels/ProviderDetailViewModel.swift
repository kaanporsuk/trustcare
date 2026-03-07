import Combine
import Foundation
import Supabase

@MainActor
final class ProviderDetailViewModel: ObservableObject {
    @Published var provider: Provider?
    @Published var reviews: [Review] = []
    @Published var services: [ProviderServiceItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var myClaimStatus: ProviderClaim?
    private var prioritizedReviewID: UUID?

    func loadDetails(id: UUID) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            async let providerTask = ProviderService.fetchProviderById(id)
            async let reviewsTask = ProviderService.fetchReviewsForProvider(id, limit: 20, offset: 0)
            async let servicesTask = ProviderService.fetchServicesForProvider(id)
            async let claimTask = ClaimService.getMyClaimStatus(providerId: id)

            let (providerResult, reviewsResult, servicesResult, claimResult) = try await (providerTask, reviewsTask, servicesTask, claimTask)
            provider = providerResult
            reviews = prioritizeReviews(reviewsResult)
            services = servicesResult
            myClaimStatus = claimResult
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
        isLoading = false
    }

    func prioritizeReview(id: UUID?) {
        prioritizedReviewID = id
        reviews = prioritizeReviews(reviews)
    }

    private func prioritizeReviews(_ items: [Review]) -> [Review] {
        guard let prioritizedReviewID,
              let index = items.firstIndex(where: { $0.id == prioritizedReviewID }) else {
            return items
        }

        var reordered = items
        let prioritized = reordered.remove(at: index)
        reordered.insert(prioritized, at: 0)
        return reordered
    }

    func voteHelpful(reviewId: UUID, isHelpful: Bool) async {
        do {
            let client = SupabaseManager.shared.client
            let session = try await client.auth.session

            struct VotePayload: Encodable {
                let reviewId: String
                let userId: String
                let isHelpful: Bool

                enum CodingKeys: String, CodingKey {
                    case reviewId = "review_id"
                    case userId = "user_id"
                    case isHelpful = "is_helpful"
                }
            }

            let payload = VotePayload(
                reviewId: reviewId.uuidString,
                userId: session.user.id.uuidString,
                isHelpful: isHelpful
            )

            _ = try await client
                .from("review_votes")
                .upsert(payload, onConflict: "review_id,user_id")
                .execute()

            let countResponse = try await client
                .from("review_votes")
                .select("id", count: .exact)
                .eq("review_id", value: reviewId.uuidString)
                .eq("is_helpful", value: true)
                .execute()

            let newCount = countResponse.count ?? 0

            _ = try await client
                .from("reviews")
                .update(["helpful_count": newCount])
                .eq("id", value: reviewId.uuidString)
                .execute()

            if let index = reviews.firstIndex(where: { $0.id == reviewId }) {
                let current = reviews[index]
                reviews[index] = Review(
                    id: current.id,
                    userId: current.userId,
                    providerId: current.providerId,
                    visitDate: current.visitDate,
                    visitType: current.visitType,
                    ratingWaitTime: current.ratingWaitTime,
                    ratingBedside: current.ratingBedside,
                    ratingEfficacy: current.ratingEfficacy,
                    ratingCleanliness: current.ratingCleanliness,
                    ratingStaff: current.ratingStaff,
                    ratingValue: current.ratingValue,
                    ratingOverall: current.ratingOverall,
                    priceLevel: current.priceLevel,
                    title: current.title,
                    comment: current.comment,
                    wouldRecommend: current.wouldRecommend,
                    proofImageUrl: current.proofImageUrl,
                    isVerified: current.isVerified,
                    verificationConfidence: current.verificationConfidence,
                    status: current.status,
                    helpfulCount: newCount,
                    createdAt: current.createdAt,
                    waitingTime: current.waitingTime,
                    facilityCleanliness: current.facilityCleanliness,
                    doctorCommunication: current.doctorCommunication,
                    treatmentOutcome: current.treatmentOutcome,
                    proceduralComfort: current.proceduralComfort,
                    clearExplanations: current.clearExplanations,
                    checkoutSpeed: current.checkoutSpeed,
                    stockAvailability: current.stockAvailability,
                    pharmacistAdvice: current.pharmacistAdvice,
                    staffCourtesy: current.staffCourtesy,
                    responseTime: current.responseTime,
                    nursingCare: current.nursingCare,
                    checkInProcess: current.checkInProcess,
                    testComfort: current.testComfort,
                    resultTurnaround: current.resultTurnaround,
                    sessionPunctuality: current.sessionPunctuality,
                    empathyListening: current.empathyListening,
                    sessionPrivacy: current.sessionPrivacy,
                    actionableAdvice: current.actionableAdvice,
                    therapyProgress: current.therapyProgress,
                    activeSupervision: current.activeSupervision,
                    facilityGear: current.facilityGear,
                    consultationQuality: current.consultationQuality,
                    resultSatisfaction: current.resultSatisfaction,
                    aftercareSupport: current.aftercareSupport,
                    reviewerName: current.reviewerName,
                    reviewerAvatar: current.reviewerAvatar,
                    media: current.media,
                    providerName: current.providerName,
                    providerSpecialty: current.providerSpecialty
                )
            }
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
    }

    private func localizedErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }

        let message = error.localizedDescription.lowercased()
        if message.contains("network") || message.contains("offline") {
            return tcString("error_network_check_connection", fallback: "Network error. Please check your connection.")
        }
        if message.contains("not found") {
            return tcString("error_provider_not_found", fallback: "Provider not found.")
        }
        return tcString("error_provider_details_load_failed", fallback: "Unable to load provider details. Please try again.")
    }
}
