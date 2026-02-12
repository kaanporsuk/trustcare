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
    @Published var errorMessage: String?
    @Published var unreadNotificationCount: Int = 0

    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            profile = try await AuthService.fetchProfile()
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
        isLoading = false
    }

    func loadReviews(filter: String? = nil) async {
        let selectedFilter = filter ?? reviewFilter
        reviewFilter = selectedFilter
        isLoading = true
        errorMessage = nil

        do {
            let session = try await SupabaseManager.shared.client.auth.session

            struct ReviewRow: Decodable {
                let id: UUID
                let userId: UUID
                let providerId: UUID
                let visitDate: Date
                let visitType: VisitType
                let ratingWaitTime: Int
                let ratingBedside: Int
                let ratingEfficacy: Int
                let ratingCleanliness: Int
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

                enum CodingKeys: String, CodingKey {
                    case id, title, comment, status
                    case userId = "user_id"
                    case providerId = "provider_id"
                    case visitDate = "visit_date"
                    case visitType = "visit_type"
                    case ratingWaitTime = "rating_wait_time"
                    case ratingBedside = "rating_bedside"
                    case ratingEfficacy = "rating_efficacy"
                    case ratingCleanliness = "rating_cleanliness"
                    case ratingOverall = "rating_overall"
                    case priceLevel = "price_level"
                    case wouldRecommend = "would_recommend"
                    case proofImageUrl = "proof_image_url"
                    case isVerified = "is_verified"
                    case verificationConfidence = "verification_confidence"
                    case helpfulCount = "helpful_count"
                    case createdAt = "created_at"
                }
            }

            struct ProviderNameRow: Decodable {
                let id: UUID
                let name: String
            }

            var query = SupabaseManager.shared.client
                .from("reviews")
                .select()
                .eq("user_id", value: session.user.id.uuidString)

            if selectedFilter == "verified" {
                query = query.eq("is_verified", value: true)
            } else if selectedFilter == "pending" {
                query = query.eq("status", value: ReviewStatus.pendingVerification.rawValue)
            }

            let response: PostgrestResponse<[ReviewRow]> = try await query
                .order("created_at", ascending: false)
                .execute()

            let providerIds = Set(response.value.map { $0.providerId })
            var providerNames: [UUID: String] = [:]
            if !providerIds.isEmpty {
                let ids = providerIds.map { $0.uuidString }
                let providersResponse: PostgrestResponse<[ProviderNameRow]> = try await SupabaseManager.shared.client
                    .from("providers")
                    .select("id, name")
                    .in("id", values: ids)
                    .execute()
                providerNames = Dictionary(uniqueKeysWithValues: providersResponse.value.map { ($0.id, $0.name) })
            }

            myReviews = response.value.map { review in
                return Review(
                    id: review.id,
                    userId: review.userId,
                    providerId: review.providerId,
                    visitDate: review.visitDate,
                    visitType: review.visitType,
                    ratingWaitTime: review.ratingWaitTime,
                    ratingBedside: review.ratingBedside,
                    ratingEfficacy: review.ratingEfficacy,
                    ratingCleanliness: review.ratingCleanliness,
                    ratingOverall: review.ratingOverall,
                    priceLevel: review.priceLevel,
                    title: review.title,
                    comment: review.comment,
                    wouldRecommend: review.wouldRecommend,
                    proofImageUrl: review.proofImageUrl,
                    isVerified: review.isVerified,
                    verificationConfidence: review.verificationConfidence,
                    status: review.status,
                    helpfulCount: review.helpfulCount,
                    createdAt: review.createdAt,
                    reviewerName: nil,
                    reviewerAvatar: nil,
                    media: nil,
                    providerName: providerNames[review.providerId]
                )
            }
        } catch {
            errorMessage = localizedErrorMessage(error)
        }

        isLoading = false
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

    func updateAvatar(image: UIImage) async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            guard let data = ImageService.compressImage(image, maxSizeKB: 512) else {
                throw AppError.uploadFailed
            }

            let path = "\(session.user.id.uuidString)/\(UUID().uuidString).jpg"
            let url = try await ImageService.uploadToStorage(
                bucket: "avatars",
                path: path,
                data: data,
                contentType: "image/jpeg"
            )

            try await AuthService.updateProfile(
                fullName: nil,
                avatarUrl: url,
                phone: nil,
                countryCode: nil,
                language: nil,
                currency: nil
            )
            await loadProfile()
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
    }

    func updatePhone(_ phone: String?) async {
        do {
            try await AuthService.updateProfile(
                fullName: nil,
                avatarUrl: nil,
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

        let message = error.localizedDescription.lowercased()
        if message.contains("network") || message.contains("offline") {
            return String(localized: "Network error. Please check your connection.")
        }
        if message.contains("not found") {
            return String(localized: "We could not find that item.")
        }
        return String(localized: "Something went wrong. Please try again.")
    }
}
