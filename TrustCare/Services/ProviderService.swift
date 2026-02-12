import Foundation
import Supabase

enum ProviderService {
    private static var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    static func searchProviders(
        text: String?,
        specialty: String?,
        country: String? = nil,
        priceLevel: Int? = nil,
        minRating: Double? = nil,
        verifiedOnly: Bool? = nil,
        lat: Double?,
        lng: Double?,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [Provider] {
        var params: [String: AnyJSON] = [
            "limit_val": .double(Double(limit)),
            "offset_val": .double(Double(offset))
        ]

        if let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            params["search_query"] = .string(text)
        }
        if let specialty {
            params["specialty_filter"] = .string(specialty)
        }
        if let country {
            params["country_filter"] = .string(country)
        }
        if let priceLevel {
            params["price_level_filter"] = .double(Double(priceLevel))
        }
        if let minRating {
            params["min_rating"] = .double(minRating)
        }
        if let verifiedOnly {
            params["verified_only"] = .bool(verifiedOnly)
        }
        if let lat {
            params["user_lat"] = .double(lat)
        }
        if let lng {
            params["user_lng"] = .double(lng)
        }

        let response: PostgrestResponse<[Provider]> = try await client
            .rpc("search_providers", params: params)
            .execute()

        guard let lat, let lng else {
            return response.value
        }

        return response.value.map { provider in
            let distance = haversineDistanceKm(
                lat1: lat,
                lon1: lng,
                lat2: provider.latitude,
                lon2: provider.longitude
            )
            return withDistance(provider, distanceKm: distance)
        }
    }

    static func fetchProviderById(_ id: UUID) async throws -> Provider {
        let response: PostgrestResponse<Provider> = try await client
            .from("providers")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()

        return response.value
    }

    static func fetchReviewsForProvider(
        _ id: UUID,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [Review] {
        struct ReviewProfileRow: Decodable {
            let review: ReviewRow
            let profile: ProfileRow?

            enum CodingKeys: String, CodingKey {
                case review
                case profile = "profiles"
            }
        }

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

        struct ProfileRow: Decodable {
            let fullName: String?
            let avatarUrl: String?

            enum CodingKeys: String, CodingKey {
                case fullName = "full_name"
                case avatarUrl = "avatar_url"
            }
        }

        let response: PostgrestResponse<[ReviewProfileRow]> = try await client
            .from("reviews")
            .select("*, profiles(full_name, avatar_url)")
            .eq("provider_id", value: id.uuidString)
            .is("deleted_at", value: nil)
            .in("status", values: ["active", "pending_verification"])
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()

        let reviewIds = response.value.map { $0.review.id }
        let media = try await fetchReviewMedia(reviewIds)

        return response.value.map { row in
            let review = row.review
            let reviewMedia = media[review.id] ?? []
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
                reviewerName: row.profile?.fullName,
                reviewerAvatar: row.profile?.avatarUrl,
                media: reviewMedia,
                providerName: nil
            )
        }
    }

    static func fetchServicesForProvider(_ id: UUID) async throws -> [ProviderServiceItem] {
        let response: PostgrestResponse<[ProviderServiceItem]> = try await client
            .from("provider_services")
            .select()
            .eq("provider_id", value: id.uuidString)
            .eq("is_active", value: true)
            .order("display_order", ascending: true)
            .order("name", ascending: true)
            .execute()

        return response.value
    }

    static func addProvider(
        name: String,
        specialty: String,
        clinicName: String?,
        address: String,
        city: String?,
        countryCode: String,
        latitude: Double,
        longitude: Double,
        phone: String?
    ) async throws -> Provider {
        // Check if user is authenticated
        guard let session = try? await client.auth.session else {
            throw AppError.authError(
                String(localized: "Please sign in to add a healthcare provider.")
            )
        }

        struct InsertProvider: Encodable {
            let name: String
            let specialty: String
            let clinicName: String?
            let address: String
            let city: String?
            let countryCode: String
            let latitude: Double
            let longitude: Double
            let phone: String?
            let createdBy: String

            enum CodingKeys: String, CodingKey {
                case name, specialty, address, city, latitude, longitude, phone
                case clinicName = "clinic_name"
                case countryCode = "country_code"
                case createdBy = "created_by"
            }
        }

        let payload = InsertProvider(
            name: name,
            specialty: specialty,
            clinicName: clinicName,
            address: address,
            city: city,
            countryCode: countryCode,
            latitude: latitude,
            longitude: longitude,
            phone: phone,
            createdBy: session.user.id.uuidString
        )

        let response: PostgrestResponse<Provider> = try await client
            .from("providers")
            .insert(payload)
            .select()
            .single()
            .execute()

        return response.value
    }

    static func fetchSpecialties() async throws -> [Specialty] {
        let response: PostgrestResponse<[Specialty]> = try await client
            .from("specialties")
            .select("id, name_key, name_en, icon_name")
            .eq("is_active", value: true)
            .order("display_order", ascending: true)
            .execute()

        return response.value
    }

    private static func fetchReviewMedia(_ reviewIds: [UUID]) async throws -> [UUID: [ReviewMedia]] {
        guard !reviewIds.isEmpty else { return [:] }

        let ids = reviewIds.map { $0.uuidString }
        let response: PostgrestResponse<[ReviewMedia]> = try await client
            .from("review_media")
            .select()
            .in("review_id", values: ids)
            .order("display_order", ascending: true)
            .execute()

        return Dictionary(grouping: response.value, by: { $0.reviewId })
    }

    private static func withDistance(_ provider: Provider, distanceKm: Double?) -> Provider {
        Provider(
            id: provider.id,
            name: provider.name,
            specialty: provider.specialty,
            clinicName: provider.clinicName,
            address: provider.address,
            city: provider.city,
            countryCode: provider.countryCode,
            latitude: provider.latitude,
            longitude: provider.longitude,
            phone: provider.phone,
            email: provider.email,
            website: provider.website,
            photoUrl: provider.photoUrl,
            coverUrl: provider.coverUrl,
            languagesSpoken: provider.languagesSpoken,
            ratingOverall: provider.ratingOverall,
            ratingWaitTime: provider.ratingWaitTime,
            ratingBedside: provider.ratingBedside,
            ratingEfficacy: provider.ratingEfficacy,
            ratingCleanliness: provider.ratingCleanliness,
            reviewCount: provider.reviewCount,
            verifiedReviewCount: provider.verifiedReviewCount,
            priceLevelAvg: provider.priceLevelAvg,
            isClaimed: provider.isClaimed,
            subscriptionTier: provider.subscriptionTier,
            isFeatured: provider.isFeatured,
            isActive: provider.isActive,
            createdAt: provider.createdAt,
            distanceKm: distanceKm
        )
    }

    private static func haversineDistanceKm(
        lat1: Double,
        lon1: Double,
        lat2: Double,
        lon2: Double
    ) -> Double {
        let radius = 6371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a =
            sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180)
            * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return radius * c
    }
}
