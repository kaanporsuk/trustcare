import Foundation
import Supabase

enum FacilityService {
    private static var client: SupabaseClient { SupabaseManager.shared.client }

    struct FacilityReviewSummary {
        let reviewCount: Int
        let verifiedReviewCount: Int
        let ratingOverall: Double
    }

    static func searchFacilities(query: String, limit: Int = 12) async throws -> [Facility] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let response: PostgrestResponse<[Facility]> = try await client
            .from("facilities")
            .select()
            .ilike("name", pattern: "%\(trimmed)%")
            .order("name", ascending: true)
            .limit(limit)
            .execute()

        return response.value
    }

    static func fetchFacility(id: UUID) async throws -> Facility {
        let response: PostgrestResponse<Facility> = try await client
            .from("facilities")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()

        return response.value
    }

    static func searchFacilityByIdentity(name: String, city: String?, countryCode: String?) async throws -> Facility? {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else { return nil }

        var query = client
            .from("facilities")
            .select()
            .eq("name", value: normalizedName)

        if let city, !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            query = query.eq("city", value: city)
        }

        if let countryCode, !countryCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            query = query.eq("country_code", value: countryCode)
        }

        let response: PostgrestResponse<[Facility]> = try await query
            .limit(1)
            .execute()

        return response.value.first
    }

    static func fetchReviewSummary(for facilityId: UUID) async throws -> FacilityReviewSummary {
        struct FacilityReviewStatsRow: Decodable {
            let reviewCount: Int
            let verifiedReviewCount: Int
            let ratingOverall: Double

            enum CodingKeys: String, CodingKey {
                case reviewCount = "review_count"
                case verifiedReviewCount = "verified_review_count"
                case ratingOverall = "rating_overall"
            }
        }

        let response: PostgrestResponse<[FacilityReviewStatsRow]> = try await client
            .from("facility_review_stats")
            .select("review_count,verified_review_count,rating_overall")
            .eq("facility_id", value: facilityId.uuidString)
            .limit(1)
            .execute()

        if let row = response.value.first {
            return FacilityReviewSummary(
                reviewCount: row.reviewCount,
                verifiedReviewCount: row.verifiedReviewCount,
                ratingOverall: row.ratingOverall
            )
        }

        return FacilityReviewSummary(reviewCount: 0, verifiedReviewCount: 0, ratingOverall: 0)
    }

    static func fetchProvidersForFacility(_ facility: Facility, limit: Int = 30) async throws -> [Provider] {
        var providers: [Provider] = []

        let linkedResponse: PostgrestResponse<[Provider]> = try await client
            .from("providers")
            .select()
            .eq("facility_id", value: facility.id.uuidString)
            .eq("is_active", value: true)
            .is("deleted_at", value: nil)
            .order("rating_overall", ascending: false)
            .limit(limit)
            .execute()
        providers.append(contentsOf: linkedResponse.value)

        if providers.count >= limit {
            return providers
        }

        // Transitional fallback while providers are still being migrated to facility_id.
        let fallbackResponse: PostgrestResponse<[Provider]> = try await client
            .from("providers")
            .select()
            .eq("clinic_name", value: facility.name)
            .eq("is_active", value: true)
            .is("deleted_at", value: nil)
            .order("rating_overall", ascending: false)
            .limit(limit)
            .execute()

        for provider in fallbackResponse.value where !providers.contains(where: { $0.id == provider.id }) {
            providers.append(provider)
        }

        return Array(providers.prefix(limit))
    }

    static func fetchReviewsForFacility(
        _ id: UUID,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [Review] {
        struct ReviewPublicRow: Decodable {
            let review: Review
            let profile: ProfileRow?

            enum CodingKeys: String, CodingKey {
                case review
                case profile = "profiles"
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                review = try container.decode(Review.self)
                profile = try? container.decode(ProfileRow.self)
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

        let response: PostgrestResponse<[ReviewPublicRow]> = try await client
            .from("reviews_public")
            .select("*, profiles(full_name, avatar_url)")
            .eq("review_target_type", value: ReviewTargetType.facility.rawValue)
            .eq("facility_id", value: id.uuidString)
            .is("deleted_at", value: nil)
            .in("status", values: ["active", "pending_verification"])
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()

        let reviewIds = response.value.map { $0.review.id }
        let media = try await ProviderService.fetchReviewMedia(reviewIds)

        return response.value.map { row in
            let base = row.review
            return Review(
                id: base.id,
                userId: base.userId,
                providerId: base.providerId,
                facilityId: base.facilityId,
                reviewTargetType: base.reviewTargetType,
                visitDate: base.visitDate,
                visitType: base.visitType,
                surveyType: base.surveyType,
                ratingWaitTime: base.ratingWaitTime,
                ratingBedside: base.ratingBedside,
                ratingEfficacy: base.ratingEfficacy,
                ratingCleanliness: base.ratingCleanliness,
                ratingStaff: base.ratingStaff,
                ratingValue: base.ratingValue,
                ratingPainMgmt: base.ratingPainMgmt,
                ratingAccuracy: base.ratingAccuracy,
                ratingKnowledge: base.ratingKnowledge,
                ratingCourtesy: base.ratingCourtesy,
                ratingCareQuality: base.ratingCareQuality,
                ratingAdmin: base.ratingAdmin,
                ratingComfort: base.ratingComfort,
                ratingTurnaround: base.ratingTurnaround,
                ratingEmpathy: base.ratingEmpathy,
                ratingEnvironment: base.ratingEnvironment,
                ratingCommunication: base.ratingCommunication,
                ratingEffectiveness: base.ratingEffectiveness,
                ratingAttentiveness: base.ratingAttentiveness,
                ratingEquipment: base.ratingEquipment,
                ratingConsultation: base.ratingConsultation,
                ratingResults: base.ratingResults,
                ratingAftercare: base.ratingAftercare,
                ratingOverall: base.ratingOverall,
                priceLevel: base.priceLevel,
                title: base.title,
                comment: base.comment,
                wouldRecommend: base.wouldRecommend,
                proofImageUrl: base.proofImageUrl,
                isVerified: base.isVerified,
                verificationConfidence: base.verificationConfidence,
                status: base.status,
                helpfulCount: base.helpfulCount,
                createdAt: base.createdAt,
                waitingTime: base.waitingTime,
                facilityCleanliness: base.facilityCleanliness,
                doctorCommunication: base.doctorCommunication,
                treatmentOutcome: base.treatmentOutcome,
                proceduralComfort: base.proceduralComfort,
                clearExplanations: base.clearExplanations,
                checkoutSpeed: base.checkoutSpeed,
                stockAvailability: base.stockAvailability,
                pharmacistAdvice: base.pharmacistAdvice,
                staffCourtesy: base.staffCourtesy,
                responseTime: base.responseTime,
                nursingCare: base.nursingCare,
                checkInProcess: base.checkInProcess,
                testComfort: base.testComfort,
                resultTurnaround: base.resultTurnaround,
                sessionPunctuality: base.sessionPunctuality,
                empathyListening: base.empathyListening,
                sessionPrivacy: base.sessionPrivacy,
                actionableAdvice: base.actionableAdvice,
                therapyProgress: base.therapyProgress,
                activeSupervision: base.activeSupervision,
                facilityGear: base.facilityGear,
                consultationQuality: base.consultationQuality,
                resultSatisfaction: base.resultSatisfaction,
                aftercareSupport: base.aftercareSupport,
                reviewerName: row.profile?.fullName,
                reviewerAvatar: row.profile?.avatarUrl,
                media: media[base.id] ?? [],
                providerName: base.providerName,
                providerSpecialty: base.providerSpecialty,
                facilityName: base.facilityName
            )
        }
    }
}
