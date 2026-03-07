import Foundation
import Supabase
import MapKit
import CoreLocation

enum ProviderService {
    private static var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private static let verboseLogging = false

    private static func verboseLog(_ message: @autoclosure () -> String) {
        guard verboseLogging else { return }
        print(message())
    }

    private static let specialtiesCacheKey = "specialtiesCache"
    private static let specialtiesCacheDateKey = "specialtiesCacheDate"
    private static var cachedSpecialties: [Specialty]?
    private static var cachedSpecialtiesDate: Date?

    static func searchProvidersTable(query: String, limit: Int = 20) async throws -> [Provider] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let filter = "name.ilike.%\(trimmed)%,specialty.ilike.%\(trimmed)%,clinic_name.ilike.%\(trimmed)%,address.ilike.%\(trimmed)%"

        let response: PostgrestResponse<[Provider]> = try await client
            .from("providers")
            .select()
            .or(filter)
            .order("name", ascending: true)
            .limit(limit)
            .execute()

        return response.value
    }

    static func searchProviders(
        text: String?,
        specialty: String?,
        specialtyIDs: [String]? = nil,
        country: String? = nil,
        priceLevel: Int? = nil,
        minRating: Double? = nil,
        verifiedOnly: Bool? = nil,
        radiusKm: Int = 50,
        lat: Double?,
        lng: Double?,
        limit: Int = 20,
        offset: Int = 0,
        enableAppleMaps: Bool = true  // Enable Apple Maps fallback
    ) async throws -> [Provider] {
        verboseLog("🔵 ProviderService.searchProviders called")
        verboseLog("  Text: '\(text ?? "nil")'")
        verboseLog("  Specialty: '\(specialty ?? "nil")'")
        verboseLog("  Location: \(lat != nil && lng != nil ? "(\(lat!), \(lng!))" : "nil")")
        verboseLog("  Limit: \(limit), Offset: \(offset)")
        verboseLog("  Apple Maps fallback enabled: \(enableAppleMaps)")
        
        var params: [String: AnyJSON] = [
            "limit_val": .double(Double(limit)),
            "offset_val": .double(Double(offset)),
            "min_rating": .double(minRating ?? 0),
            "verified_only": .bool(verifiedOnly ?? false),
            "max_distance_km": .double(Double(radiusKm))
        ]

        if let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            params["search_query"] = .string(text)
        }
        if let specialty {
            params["specialty_filter"] = .string(specialty)
        }
        if let specialtyIDs, !specialtyIDs.isEmpty {
            params["specialty_ids"] = .array(specialtyIDs.map { .string($0) })
        }
        if let country {
            params["country_filter"] = .string(country)
        }
        if let priceLevel {
            params["price_level_filter"] = .double(Double(priceLevel))
        }
        if let lat {
            params["user_lat"] = .double(lat)
        }
        if let lng {
            params["user_lng"] = .double(lng)
        }

        verboseLog("  Calling search_providers RPC with params: \(params)")
        
        var supabaseProviders: [Provider] = []
        
        do {
            let response: PostgrestResponse<[Provider]> = try await client
                .rpc("search_providers", params: params)
                .execute()
            
            verboseLog("✅ search_providers RPC returned \(response.value.count) providers")
            supabaseProviders = response.value

            guard let lat, let lng else {
                return supabaseProviders
            }

            supabaseProviders = supabaseProviders.map { provider in
                let distance = haversineDistanceKm(
                    lat1: lat,
                    lon1: lng,
                    lat2: provider.latitude,
                    lon2: provider.longitude
                )
                return withDistance(provider, distanceKm: distance)
            }
        } catch {
            print("❌ search_providers RPC failed")
            print("  Error: \(error)")
            print("  Error type: \(type(of: error))")
            print("  Localized: \(error.localizedDescription)")
            throw error
        }
        
        // TIER 2: Apple Maps fallback if results are insufficient and enableAppleMaps is true
        if enableAppleMaps && supabaseProviders.count < 5, let searchText = text, !searchText.isEmpty {
            verboseLog("📍 Triggering Apple Maps fallback (Supabase only found \(supabaseProviders.count) results)")
            
            let userCoordinate: CLLocationCoordinate2D? = if let lat, let lng {
                CLLocationCoordinate2D(latitude: lat, longitude: lng)
            } else {
                nil
            }
            
            do {
                let appleMapsResults = try await AppleMapsService.searchHealthcareProviders(
                    query: searchText,
                    coordinate: userCoordinate,
                    radiusMeters: CLLocationDistance(radiusKm * 1000)
                )
                
                verboseLog("📍 Apple Maps returned \(appleMapsResults.count) results")
                
                // Convert to temporary providers and deduplicate
                var appleMapsProviders = appleMapsResults.map { $0.toTemporaryProvider() }
                
                // Add distance if location available
                if let lat, let lng {
                    appleMapsProviders = appleMapsProviders.map { provider in
                        let distance = haversineDistanceKm(
                            lat1: lat,
                            lon1: lng,
                            lat2: provider.latitude,
                            lon2: provider.longitude
                        )
                        return withDistance(provider, distanceKm: distance)
                    }
                }
                
                // Deduplicate by name and address
                let deduplicatedApple = appleMapsProviders.filter { appleProvider in
                    !supabaseProviders.contains { supabaseProvider in
                        supabaseProvider.name.lowercased() == appleProvider.name.lowercased() &&
                        supabaseProvider.address.lowercased() == appleProvider.address.lowercased()
                    }
                }
                
                verboseLog("📍 Adding \(deduplicatedApple.count) unique Apple Maps results")
                supabaseProviders.append(contentsOf: deduplicatedApple)
                
            } catch {
                print("⚠️ Apple Maps fallback failed: \(error.localizedDescription)")
                // Continue with Supabase results only
            }
        }
        
        return supabaseProviders
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
            let providerId: UUID?
            let facilityId: UUID?
            let reviewTargetType: ReviewTargetType?
            let visitDate: Date
            let visitType: VisitType
            let surveyType: String?
            let ratingWaitTime: Int?
            let ratingBedside: Int?
            let ratingEfficacy: Int?
            let ratingCleanliness: Int?
            let ratingStaff: Int?
            let ratingValue: Int?
            let ratingPainMgmt: Int?
            let ratingAccuracy: Int?
            let ratingKnowledge: Int?
            let ratingCourtesy: Int?
            let ratingCareQuality: Int?
            let ratingAdmin: Int?
            let ratingComfort: Int?
            let ratingTurnaround: Int?
            let ratingEmpathy: Int?
            let ratingEnvironment: Int?
            let ratingCommunication: Int?
            let ratingEffectiveness: Int?
            let ratingAttentiveness: Int?
            let ratingEquipment: Int?
            let ratingConsultation: Int?
            let ratingResults: Int?
            let ratingAftercare: Int?
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
            let waitingTime: Int?
            let facilityCleanliness: Int?
            let doctorCommunication: Int?
            let treatmentOutcome: Int?
            let proceduralComfort: Int?
            let clearExplanations: Int?
            let checkoutSpeed: Int?
            let stockAvailability: Int?
            let pharmacistAdvice: Int?
            let staffCourtesy: Int?
            let responseTime: Int?
            let nursingCare: Int?
            let checkInProcess: Int?
            let testComfort: Int?
            let resultTurnaround: Int?
            let sessionPunctuality: Int?
            let empathyListening: Int?
            let sessionPrivacy: Int?
            let actionableAdvice: Int?
            let therapyProgress: Int?
            let activeSupervision: Int?
            let facilityGear: Int?
            let consultationQuality: Int?
            let resultSatisfaction: Int?
            let aftercareSupport: Int?

            enum CodingKeys: String, CodingKey {
                case id, title, comment, status
                case userId = "user_id"
                case providerId = "provider_id"
                case facilityId = "facility_id"
                case reviewTargetType = "review_target_type"
                case visitDate = "visit_date"
                case visitType = "visit_type"
                case surveyType = "survey_type"
                case ratingWaitTime = "rating_wait_time"
                case ratingBedside = "rating_bedside"
                case ratingEfficacy = "rating_efficacy"
                case ratingCleanliness = "rating_cleanliness"
                case ratingStaff = "rating_staff"
                case ratingValue = "rating_value"
                case ratingPainMgmt = "rating_pain_mgmt"
                case ratingAccuracy = "rating_accuracy"
                case ratingKnowledge = "rating_knowledge"
                case ratingCourtesy = "rating_courtesy"
                case ratingCareQuality = "rating_care_quality"
                case ratingAdmin = "rating_admin"
                case ratingComfort = "rating_comfort"
                case ratingTurnaround = "rating_turnaround"
                case ratingEmpathy = "rating_empathy"
                case ratingEnvironment = "rating_environment"
                case ratingCommunication = "rating_communication"
                case ratingEffectiveness = "rating_effectiveness"
                case ratingAttentiveness = "rating_attentiveness"
                case ratingEquipment = "rating_equipment"
                case ratingConsultation = "rating_consultation"
                case ratingResults = "rating_results"
                case ratingAftercare = "rating_aftercare"
                case ratingOverall = "rating_overall"
                case priceLevel = "price_level"
                case wouldRecommend = "would_recommend"
                case proofImageUrl = "proof_image_url"
                case isVerified = "is_verified"
                case verificationConfidence = "verification_confidence"
                case helpfulCount = "helpful_count"
                case createdAt = "created_at"
                case waitingTime = "waiting_time"
                case facilityCleanliness = "facility_cleanliness"
                case doctorCommunication = "doctor_communication"
                case treatmentOutcome = "treatment_outcome"
                case proceduralComfort = "procedural_comfort"
                case clearExplanations = "clear_explanations"
                case checkoutSpeed = "checkout_speed"
                case stockAvailability = "stock_availability"
                case pharmacistAdvice = "pharmacist_advice"
                case staffCourtesy = "staff_courtesy"
                case responseTime = "response_time"
                case nursingCare = "nursing_care"
                case checkInProcess = "check_in_process"
                case testComfort = "test_comfort"
                case resultTurnaround = "result_turnaround"
                case sessionPunctuality = "session_punctuality"
                case empathyListening = "empathy_listening"
                case sessionPrivacy = "session_privacy"
                case actionableAdvice = "actionable_advice"
                case therapyProgress = "therapy_progress"
                case activeSupervision = "active_supervision"
                case facilityGear = "facility_gear"
                case consultationQuality = "consultation_quality"
                case resultSatisfaction = "result_satisfaction"
                case aftercareSupport = "aftercare_support"
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
            .from("reviews_public")
            .select("*, profiles(full_name, avatar_url)")
            .eq("review_target_type", value: ReviewTargetType.provider.rawValue)
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
                facilityId: review.facilityId,
                reviewTargetType: review.reviewTargetType,
                visitDate: review.visitDate,
                visitType: review.visitType,
                surveyType: review.surveyType,
                ratingWaitTime: review.ratingWaitTime,
                ratingBedside: review.ratingBedside,
                ratingEfficacy: review.ratingEfficacy,
                ratingCleanliness: review.ratingCleanliness,
                ratingStaff: review.ratingStaff,
                ratingValue: review.ratingValue,
                ratingPainMgmt: review.ratingPainMgmt,
                ratingAccuracy: review.ratingAccuracy,
                ratingKnowledge: review.ratingKnowledge,
                ratingCourtesy: review.ratingCourtesy,
                ratingCareQuality: review.ratingCareQuality,
                ratingAdmin: review.ratingAdmin,
                ratingComfort: review.ratingComfort,
                ratingTurnaround: review.ratingTurnaround,
                ratingEmpathy: review.ratingEmpathy,
                ratingEnvironment: review.ratingEnvironment,
                ratingCommunication: review.ratingCommunication,
                ratingEffectiveness: review.ratingEffectiveness,
                ratingAttentiveness: review.ratingAttentiveness,
                ratingEquipment: review.ratingEquipment,
                ratingConsultation: review.ratingConsultation,
                ratingResults: review.ratingResults,
                ratingAftercare: review.ratingAftercare,
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
                waitingTime: review.waitingTime,
                facilityCleanliness: review.facilityCleanliness,
                doctorCommunication: review.doctorCommunication,
                treatmentOutcome: review.treatmentOutcome,
                proceduralComfort: review.proceduralComfort,
                clearExplanations: review.clearExplanations,
                checkoutSpeed: review.checkoutSpeed,
                stockAvailability: review.stockAvailability,
                pharmacistAdvice: review.pharmacistAdvice,
                staffCourtesy: review.staffCourtesy,
                responseTime: review.responseTime,
                nursingCare: review.nursingCare,
                checkInProcess: review.checkInProcess,
                testComfort: review.testComfort,
                resultTurnaround: review.resultTurnaround,
                sessionPunctuality: review.sessionPunctuality,
                empathyListening: review.empathyListening,
                sessionPrivacy: review.sessionPrivacy,
                actionableAdvice: review.actionableAdvice,
                therapyProgress: review.therapyProgress,
                activeSupervision: review.activeSupervision,
                facilityGear: review.facilityGear,
                consultationQuality: review.consultationQuality,
                resultSatisfaction: review.resultSatisfaction,
                aftercareSupport: review.aftercareSupport,
                reviewerName: row.profile?.fullName,
                reviewerAvatar: row.profile?.avatarUrl,
                media: reviewMedia,
                providerName: nil,
                providerSpecialty: nil,
                facilityName: nil
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
                tcString("Please sign in to add a healthcare provider.", fallback: "Please sign in to add a healthcare provider.")
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
            let dataSource: String

            enum CodingKeys: String, CodingKey {
                case name, specialty, address, city, latitude, longitude, phone
                case clinicName = "clinic_name"
                case countryCode = "country_code"
                case createdBy = "created_by"
                case dataSource = "data_source"
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
            createdBy: session.user.id.uuidString,
            dataSource: "user"
        )

        let response: PostgrestResponse<Provider> = try await client
            .from("providers")
            .insert(payload)
            .select()
            .single()
            .execute()

        return response.value
    }

    static func fetchSpecialtiesCached(forceRefresh: Bool = false) async throws -> [Specialty] {
        if !forceRefresh, let cached = cachedSpecialties,
           let cachedDate = cachedSpecialtiesDate,
           !isSpecialtiesCacheStale(cachedDate) {
            return cached
        }

        if !forceRefresh,
           let stored = loadSpecialtiesFromDefaults(),
           let storedDate = loadSpecialtiesCacheDate(),
           !isSpecialtiesCacheStale(storedDate) {
            cachedSpecialties = stored
            cachedSpecialtiesDate = storedDate
            return stored
        }

        do {
            let fresh = try await fetchSpecialtiesRemote()
            cachedSpecialties = fresh
            let now = Date()
            cachedSpecialtiesDate = now
            saveSpecialtiesToDefaults(fresh, date: now)
            return fresh
        } catch {
            if let cached = cachedSpecialties {
                return cached
            }
            if let stored = loadSpecialtiesFromDefaults() {
                return stored
            }
            throw error
        }
    }

    private static func fetchSpecialtiesRemote() async throws -> [Specialty] {
        verboseLog("🔵 ProviderService.fetchSpecialtiesRemote called")

        do {
            let response: PostgrestResponse<[Specialty]> = try await client
                .from("specialties")
                .select("id, name, name_tr, name_de, name_pl, name_nl, name_da, category, subcategory, icon_name, survey_type, color_hex, display_order, is_popular, is_active")
                .eq("is_active", value: true)
                .order("display_order", ascending: true)
                .execute()

            verboseLog("✅ fetchSpecialtiesRemote returned \(response.value.count) specialties")
            return response.value
        } catch {
            print("❌ fetchSpecialtiesRemote failed")
            print("  Error: \(error)")
            print("  Error type: \(type(of: error))")
            print("  Localized: \(error.localizedDescription)")
            throw error
        }
    }

    private static func isSpecialtiesCacheStale(_ date: Date) -> Bool {
        let maxAge: TimeInterval = 24 * 60 * 60
        return Date().timeIntervalSince(date) > maxAge
    }

    private static func saveSpecialtiesToDefaults(_ specialties: [Specialty], date: Date) {
        if let data = try? JSONEncoder().encode(specialties) {
            UserDefaults.standard.set(data, forKey: specialtiesCacheKey)
            UserDefaults.standard.set(date, forKey: specialtiesCacheDateKey)
        }
    }

    private static func loadSpecialtiesFromDefaults() -> [Specialty]? {
        guard let data = UserDefaults.standard.data(forKey: specialtiesCacheKey) else {
            return nil
        }
        return try? JSONDecoder().decode([Specialty].self, from: data)
    }

    private static func loadSpecialtiesCacheDate() -> Date? {
        UserDefaults.standard.object(forKey: specialtiesCacheDateKey) as? Date
    }

    static func fetchReviewMedia(_ reviewIds: [UUID]) async throws -> [UUID: [ReviewMedia]] {
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
            facilityId: provider.facilityId,
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
            distanceKm: distanceKm,
            dataSource: provider.dataSource,
            externalId: provider.externalId,
            updatedAt: provider.updatedAt,
            deletedAt: provider.deletedAt,
            priceLevel: provider.priceLevel
        )
    }

    // MARK: - Apple Maps Capture
    
    /// Capture an Apple Maps provider and save it to Supabase
    /// This creates a new provider in the database from Apple Maps data
    static func captureAndSaveProvider(
        from appleMapsProvider: AppleMapsService.AppleMapsProvider
    ) async throws -> Provider {
        verboseLog("🔵 ProviderService.captureAndSaveProvider called")
        verboseLog("  Name: \(appleMapsProvider.name)")
        verboseLog("  Address: \(appleMapsProvider.address)")
        let externalId = "\(appleMapsProvider.mapItem.name ?? "unknown")_\(appleMapsProvider.coordinate.latitude)_\(appleMapsProvider.coordinate.longitude)"
        verboseLog("  External ID: \(externalId)")
        
        // Check if provider already exists by external_id
        if let existingId = try await AppleMapsService.existsWithExternalId(externalId) {
            verboseLog("ℹ️ Provider already exists with ID: \(existingId)")
            return try await fetchProviderById(existingId)
        }
        
        // Create new provider record
        let newProviderId = UUID()
        
        struct ProviderInsert: Encodable {
            let id: String
            let name: String
            let specialty: String
            let clinic_name: String?
            let address: String
            let city: String?
            let country_code: String
            let latitude: Double
            let longitude: Double
            let phone: String?
            let email: String?
            let website: String?
            let data_source: String
            let external_id: String
            let is_active: Bool
            let is_claimed: Bool
            let is_featured: Bool
        }
        
        let insert = ProviderInsert(
            id: newProviderId.uuidString,
            name: appleMapsProvider.name,
            specialty: "General",
            clinic_name: nil,
            address: appleMapsProvider.address,
            city: appleMapsProvider.mapItem.placemark.locality,
            country_code: appleMapsProvider.mapItem.placemark.country ?? "GB",
            latitude: appleMapsProvider.coordinate.latitude,
            longitude: appleMapsProvider.coordinate.longitude,
            phone: appleMapsProvider.phone,
            email: nil,
            website: appleMapsProvider.mapItem.url?.absoluteString,
            data_source: "apple_maps",
            external_id: externalId,
            is_active: true,
            is_claimed: false,
            is_featured: false
        )
        
        verboseLog("  Inserting provider with ID: \(newProviderId)")
        
        do {
            let _ = try await client
                .from("providers")
                .insert([insert])
                .execute()
            
            verboseLog("✅ Provider inserted successfully: \(newProviderId)")
            
            // Fetch and return the newly created provider
            return try await fetchProviderById(newProviderId)
        } catch {
            print("❌ Failed to insert provider")
            print("  Error: \(error)")
            print("  Error type: \(type(of: error))")
            print("  Localized: \(error.localizedDescription)")
            throw error
        }
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
