import Foundation
import MapKit
import Supabase

/// Service for integrating Apple Maps (MKLocalSearch) with TrustCare's provider database
enum AppleMapsService {
    // MARK: - Models
    
    /// Represents a provider result from Apple Maps
    struct AppleMapsProvider {
        let name: String
        let address: String
        let coordinate: CLLocationCoordinate2D
        let phone: String?
        let mapItem: MKMapItem
        
        /// Convert to temporary Provider model for display
        func toTemporaryProvider() -> Provider {
            Provider(
                id: UUID(),
                name: name,
                specialty: "General",
                clinicName: nil,
                address: address,
                city: mapItem.placemark.locality,
                countryCode: mapItem.placemark.country ?? "GB",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                phone: phone,
                email: nil,
                website: mapItem.url?.absoluteString,
                photoUrl: nil,
                coverUrl: nil,
                languagesSpoken: nil,
                ratingOverall: 0,
                ratingWaitTime: 0,
                ratingBedside: 0,
                ratingEfficacy: 0,
                ratingCleanliness: 0,
                reviewCount: 0,
                verifiedReviewCount: 0,
                priceLevelAvg: 0,
                isClaimed: false,
                subscriptionTier: .free,
                isFeatured: false,
                isActive: true,
                createdAt: Date(),
                distanceKm: nil,
                dataSource: "apple_maps",
                externalId: "\(mapItem.name ?? "unknown")_\(mapItem.placemark.coordinate.latitude)_\(mapItem.placemark.coordinate.longitude)",
                updatedAt: Date(),
                deletedAt: nil,
                priceLevel: nil
            )
        }
    }
    
    // MARK: - Search
    
    /// Search for healthcare providers on Apple Maps
    /// Filters by hospital, pharmacy, and medical center categories
    static func searchHealthcareProviders(
        query: String,
        coordinate: CLLocationCoordinate2D? = nil,
        radiusMeters: CLLocationDistance = 50000  // Default 50km
    ) async throws -> [AppleMapsProvider] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        // Set search region - use user location if available
        if let coordinate {
            request.region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: radiusMeters / 111000,  // Rough conversion to degrees
                    longitudeDelta: radiusMeters / 111000
                )
            )
        }
        
        // Filter by healthcare category - using pointOfInterestFilter
        let healthcareCategories: [MKPointOfInterestCategory] = [
            .hospital,
            .pharmacy
        ]
        if #available(iOS 17.0, *) {
            // medicalCenter not available in earlier iOS versions
        }
        request.pointOfInterestFilter = MKPointOfInterestFilter(
            including: healthcareCategories
        )
        
        print("🔵 AppleMapsService: Searching Apple Maps for '\(query)'")
        print("  Coordinate: \(coordinate?.latitude ?? 0), \(coordinate?.longitude ?? 0)")
        print("  Healthcare categories: \(healthcareCategories.count)")
        
        let search = MKLocalSearch(request: request)
        let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MKLocalSearch.Response, Error>) in
            search.start { response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let response {
                    continuation.resume(returning: response)
                } else {
                    let noResultsError = NSError(domain: "AppleMapsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No results found"])
                    continuation.resume(throwing: noResultsError)
                }
            }
        }
        
        print("✅ Apple Maps returned \(response.mapItems.count) results")
        
        // Convert MKMapItem responses to AppleMapsProvider
        return response.mapItems.compactMap { mapItem in
            guard let name = mapItem.name else { return nil }
            
            let address = [
                mapItem.placemark.thoroughfare,
                mapItem.placemark.locality,
                mapItem.placemark.postalCode,
                mapItem.placemark.country
            ]
            .compactMap { $0 }
            .joined(separator: ", ")
            
            let phoneNumber = mapItem.phoneNumber
            
            return AppleMapsProvider(
                name: name,
                address: address.isEmpty ? "Unknown Address" : address,
                coordinate: mapItem.placemark.coordinate,
                phone: phoneNumber,
                mapItem: mapItem
            )
        }
    }
    
    // MARK: - Deduplication
    
    /// Check if a provider already exists by external_id for Apple Maps
    static func existsWithExternalId(_ externalId: String) async throws -> UUID? {
        let client = SupabaseManager.shared.client
        
        struct ExistingProvider: Decodable {
            let id: UUID
        }
        
        do {
            let response: PostgrestResponse<[ExistingProvider]> = try await client
                .from("providers")
                .select("id")
                .eq("external_id", value: externalId)
                .limit(1)
                .execute()
            
            return response.value.first?.id
        } catch {
            print("⚠️ AppleMapsService: Error checking for existing provider: \(error)")
            // Assume not duplicated on error to allow insertion
            return nil
        }
    }
}
