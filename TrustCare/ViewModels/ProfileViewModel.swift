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
    @Published var isUpdatingAvatar: Bool = false
    @Published var isSavingProfile: Bool = false
    @Published var errorMessage: String?
    @Published var unreadNotificationCount: Int = 0
    
    init() {
        print("🔵 ProfileViewModel initialized")
    }

    func loadProfile() async {
        print("🔵 ProfileViewModel.loadProfile called")
        isLoading = true
        errorMessage = nil
        do {
            profile = try await AuthService.fetchProfile()
            print("✅ Profile loaded: \(profile?.displayName ?? "nil")")
        } catch {
            print("❌ loadProfile failed: \(error)")
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
                let providers: ProviderRow?

                enum CodingKeys: String, CodingKey {
                    case id, title, comment, status, providers
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

            var query = SupabaseManager.shared.client
                .from("reviews")
                .select("*, providers(name, specialty)")
                .eq("user_id", value: session.user.id.uuidString)

            if selectedFilter == "verified" {
                query = query.eq("is_verified", value: true)
            } else if selectedFilter == "pending" {
                query = query.eq("status", value: ReviewStatus.pendingVerification.rawValue)
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
                    ratingWaitTime: row.ratingWaitTime,
                    ratingBedside: row.ratingBedside,
                    ratingEfficacy: row.ratingEfficacy,
                    ratingCleanliness: row.ratingCleanliness,
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
        isUpdatingAvatar = true
        defer { isUpdatingAvatar = false }
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            guard let data = ImageService.compressImage(image, maxSizeKB: 500) else {
                throw AppError.uploadFailed
            }

            let path = "\(session.user.id.uuidString)/avatar.jpg"
            let url = try await ImageService.uploadToStorage(
                bucket: "user-avatars",
                path: path,
                data: data,
                contentType: "image/jpeg"
            )

            try await AuthService.updateProfile(
                fullName: nil,
                avatarUrl: url,
                bio: nil,
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
