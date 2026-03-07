import Foundation
import Combine

@MainActor
final class FacilityDetailViewModel: ObservableObject {
    @Published var facility: Facility?
    @Published var reviews: [Review] = []
    @Published var providers: [Provider] = []
    @Published var facilityTypeLabel: String = ""
    @Published var ratingOverall: Double = 0
    @Published var reviewCount: Int = 0
    @Published var verifiedReviewCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func loadDetails(id: UUID) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetchedFacility = try await FacilityService.fetchFacility(id: id)
            facility = fetchedFacility

            async let summaryTask = FacilityService.fetchReviewSummary(for: id)
            async let reviewsTask = FacilityService.fetchReviewsForFacility(id, limit: 30, offset: 0)
            async let providersTask = FacilityService.fetchProvidersForFacility(fetchedFacility, limit: 20)
            async let facilityTypeTask = resolveFacilityTypeLabel(fetchedFacility)

            let (summary, fetchedReviews, linkedProviders, typeLabel) = try await (
                summaryTask,
                reviewsTask,
                providersTask,
                facilityTypeTask
            )

            ratingOverall = summary.ratingOverall
            reviewCount = summary.reviewCount
            verifiedReviewCount = summary.verifiedReviewCount
            reviews = fetchedReviews
            providers = linkedProviders
            facilityTypeLabel = typeLabel
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
    }

    private func resolveFacilityTypeLabel(_ facility: Facility) async throws -> String {
        guard let canonicalId = facility.canonicalFacilityTypeId,
              !canonicalId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return tcString("facility_type_unknown", fallback: "Facility")
        }

        return try await TaxonomyService.displayLabel(for: canonicalId, locale: Locale.current.language.languageCode?.identifier ?? "en")
    }

    private func localizedErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }

        let message = error.localizedDescription.lowercased()
        if message.contains("network") || message.contains("offline") {
            return tcString("error_network", fallback: "Network error")
        }

        return tcString("facility_details_load_failed", fallback: "Unable to load facility details. Please try again.")
    }
}
