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

    func loadDetails(id: UUID) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            async let providerTask = ProviderService.fetchProviderById(id)
            async let reviewsTask = ProviderService.fetchReviewsForProvider(id, limit: 20, offset: 0)
            async let servicesTask = ProviderService.fetchServicesForProvider(id)

            let (providerResult, reviewsResult, servicesResult) = try await (providerTask, reviewsTask, servicesTask)
            provider = providerResult
            reviews = reviewsResult
            services = servicesResult
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
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
                    reviewerName: current.reviewerName,
                    reviewerAvatar: current.reviewerAvatar,
                    media: current.media,
                    providerName: current.providerName
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
