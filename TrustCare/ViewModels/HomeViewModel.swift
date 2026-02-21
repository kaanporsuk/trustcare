import Combine
import CoreLocation
import Foundation
import MapKit

@MainActor
final class HomeViewModel: ObservableObject {
    struct SelectedLocation: Codable, Equatable, Hashable {
        let name: String
        let latitude: Double
        let longitude: Double
        let isCurrentLocation: Bool
    }

    enum ViewMode: String, CaseIterable, Identifiable {
        case list = "List"
        case map = "Map"
        var id: String { rawValue }
    }

    @Published var providers: [Provider] = []
    @Published var specialties: [Specialty] = []
    @Published var popularSpecialties: [Specialty] = []
    @Published var searchText: String = ""
    @Published var selectedSurveyType: String? = nil
    @Published var viewMode: ViewMode = .list
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasMoreResults: Bool = true
    @Published var locationName: String = String(localized: "Tap to set location")
    @Published var selectedLocation: SelectedLocation
    @Published var recentLocations: [SelectedLocation] = []

    private(set) var hasLoadedInitially = false
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var currentOffset: Int = 0
    private let pageSize: Int = 20
    private var lastSearchLocation: CLLocation?
    private var lastSearchAt: Date?
    private var lastGeocodedLocation: CLLocation?
    private var lastGeocodedAt: Date?
    private let minSearchDistanceMeters: CLLocationDistance = 200
    private let minSearchInterval: TimeInterval = 8
    private let minGeocodeDistanceMeters: CLLocationDistance = 120
    private let minGeocodeInterval: TimeInterval = 20
    private static let verboseLogging = false
    private static let selectedLocationKey = "selectedLocation"
    private static let recentLocationsKey = "recentLocations"

    private func verboseLog(_ message: @autoclosure () -> String) {
        guard Self.verboseLogging else { return }
        print(message())
    }

    var locationManagerCoordinate: CLLocationCoordinate2D? {
        locationManager.userLocation
    }

    init() {
        if let savedLocation = Self.loadSelectedLocation() {
            selectedLocation = savedLocation
            locationName = savedLocation.name
        } else {
            selectedLocation = SelectedLocation(
                name: String(localized: "Tap to set location"),
                latitude: 0,
                longitude: 0,
                isCurrentLocation: true
            )
        }
        recentLocations = Self.loadRecentLocations()
        observeLocation()
    }
    
    func onAppear() async {
        guard !hasLoadedInitially else { return }
        hasLoadedInitially = true
        await loadSpecialties(forceRefresh: false)
        await searchProviders(reset: true)  // Load initial providers
    }

    func refresh(forceSpecialtiesRefresh: Bool = false) async {
        if forceSpecialtiesRefresh {
            await loadSpecialties(forceRefresh: true)
        }
        currentOffset = 0
        hasMoreResults = true
        await searchProviders(reset: true)
    }

    func selectLocation(_ location: SelectedLocation) async {
        selectedLocation = location
        locationName = location.name
        saveSelectedLocation(location)
        addRecentLocation(location)
        await refresh()
    }

    func useCurrentLocation() async {
        startLocationUpdates()
        let name = locationName.isEmpty ? String(localized: "Tap to set location") : locationName
        let coordinate = locationManager.userLocation
        let updated = SelectedLocation(
            name: name,
            latitude: coordinate?.latitude ?? 0,
            longitude: coordinate?.longitude ?? 0,
            isCurrentLocation: true
        )
        selectedLocation = updated
        saveSelectedLocation(updated)
        await refresh()
    }

    func clearRecentLocations() {
        recentLocations = []
        saveRecentLocations([])
    }

    func startLocationUpdates() {
        locationManager.requestPermission()
        locationManager.startUpdating()
    }

    func loadMore() async {
        guard !isLoading, hasMoreResults else { return }
        currentOffset += pageSize
        await searchProviders(reset: false)
    }

    func fetchProviders(in region: MKCoordinateRegion) async {
        let updatedLocation = SelectedLocation(
            name: locationName,
            latitude: region.center.latitude,
            longitude: region.center.longitude,
            isCurrentLocation: false
        )
        selectedLocation = updatedLocation
        saveSelectedLocation(updatedLocation)
        currentOffset = 0
        hasMoreResults = true
        await searchProviders(reset: true)
    }

    func searchWithDebounce() async {
        verboseLog("🔵 HomeViewModel.searchWithDebounce called (searchText: '\(searchText)', surveyType: '\(selectedSurveyType ?? "all")')")
        do {
            try await Task.sleep(nanoseconds: 300_000_000)
        } catch {
            verboseLog("⚠️ searchWithDebounce cancelled")
            return
        }
        await refresh()
    }

    private func loadSpecialties(forceRefresh: Bool) async {
        verboseLog("🔵 HomeViewModel.loadSpecialties started")
        do {
            let results = try await ProviderService.fetchSpecialtiesCached(forceRefresh: forceRefresh)
            specialties = results
            popularSpecialties = results
                .filter { $0.isPopular }
                .sorted { $0.displayOrder < $1.displayOrder }
            verboseLog("✅ Loaded \(results.count) specialties")
        } catch {
            let errorMsg = localizedErrorMessage(error)
            print("❌ loadSpecialties failed: \(errorMsg)")
            errorMessage = errorMsg
        }
    }

    private func searchProviders(reset: Bool) async {
        guard !isLoading else {
            verboseLog("⚠️ searchProviders skipped - already loading")
            return
        }
        verboseLog("🔵 HomeViewModel.searchProviders started (reset: \(reset))")
        isLoading = true
        errorMessage = nil
        let activeCoordinate = selectedLocation.isCurrentLocation
            ? locationManager.userLocation
            : CLLocationCoordinate2D(
                latitude: selectedLocation.latitude,
                longitude: selectedLocation.longitude
            )
        let lat = activeCoordinate?.latitude
        let lng = activeCoordinate?.longitude

        do {
            let results = try await ProviderService.searchProviders(
                text: searchText,
                specialty: nil,  // Don't filter by specialty in RPC, we'll filter client-side
                country: nil,
                priceLevel: nil,
                minRating: nil,
                verifiedOnly: nil,
                lat: lat,
                lng: lng,
                limit: pageSize,
                offset: currentOffset
            )

            // Apply client-side category filtering
            let filteredResults = filterProvidersBySurveyType(results, selectedSurveyType)
            
            verboseLog("✅ searchProviders returned \(results.count) providers, \(filteredResults.count) after category filter")
            if reset {
                providers = filteredResults
            } else {
                providers.append(contentsOf: filteredResults)
            }
            hasMoreResults = results.count == pageSize
        } catch {
            let errorMsg = localizedErrorMessage(error)
            print("❌ searchProviders failed: \(errorMsg)")
            errorMessage = errorMsg
        }
        isLoading = false
        verboseLog("🔵 HomeViewModel.searchProviders completed")
    }

    private func filterProvidersBySurveyType(_ providers: [Provider], _ surveyType: String?) -> [Provider] {
        guard let surveyType else {
            return providers
        }

        return providers.filter { provider in
            SpecialtyService.shared.surveyType(for: provider.specialty) == surveyType
        }
    }

    private func observeLocation() {
        locationManager.requestPermission()
        locationManager.$userLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                Task { @MainActor in
                    guard let self else { return }
                    let currentLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)

                    if self.shouldReverseGeocode(for: currentLocation) {
                        await self.reverseGeocode(location: location)
                        self.lastGeocodedLocation = currentLocation
                        self.lastGeocodedAt = Date()
                    }

                    if self.selectedLocation.isCurrentLocation,
                       self.hasLoadedInitially,
                       self.shouldRefreshProviders(for: currentLocation),
                       !self.isLoading {
                        await self.refresh()
                        self.lastSearchLocation = currentLocation
                        self.lastSearchAt = Date()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func shouldRefreshProviders(for location: CLLocation) -> Bool {
        if let lastSearchAt,
           Date().timeIntervalSince(lastSearchAt) < minSearchInterval {
            return false
        }

        guard let lastSearchLocation else {
            return true
        }

        return location.distance(from: lastSearchLocation) >= minSearchDistanceMeters
    }

    private func shouldReverseGeocode(for location: CLLocation) -> Bool {
        if let lastGeocodedAt,
           Date().timeIntervalSince(lastGeocodedAt) < minGeocodeInterval {
            return false
        }

        guard let lastGeocodedLocation else {
            return true
        }

        return location.distance(from: lastGeocodedLocation) >= minGeocodeDistanceMeters
    }

    private func reverseGeocode(location: CLLocationCoordinate2D) async {
        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(clLocation)
            if let place = placemarks.first {
                let city = place.locality ?? place.administrativeArea
                if selectedLocation.isCurrentLocation {
                    locationName = city ?? String(localized: "Tap to set location")
                    let updated = SelectedLocation(
                        name: locationName,
                        latitude: location.latitude,
                        longitude: location.longitude,
                        isCurrentLocation: true
                    )
                    selectedLocation = updated
                    saveSelectedLocation(updated)
                }
            }
        } catch {
            if selectedLocation.isCurrentLocation {
                locationName = String(localized: "Tap to set location")
            }
        }
    }

    private func addRecentLocation(_ location: SelectedLocation) {
        guard !location.isCurrentLocation else { return }
        var updated = recentLocations.filter { $0 != location }
        updated.insert(location, at: 0)
        if updated.count > 5 {
            updated = Array(updated.prefix(5))
        }
        recentLocations = updated
        saveRecentLocations(updated)
    }

    private func saveSelectedLocation(_ location: SelectedLocation) {
        if let data = try? JSONEncoder().encode(location) {
            UserDefaults.standard.set(data, forKey: Self.selectedLocationKey)
        }
    }

    private static func loadSelectedLocation() -> SelectedLocation? {
        guard let data = UserDefaults.standard.data(forKey: Self.selectedLocationKey) else {
            return nil
        }
        return try? JSONDecoder().decode(SelectedLocation.self, from: data)
    }

    private func saveRecentLocations(_ locations: [SelectedLocation]) {
        if let data = try? JSONEncoder().encode(locations) {
            UserDefaults.standard.set(data, forKey: Self.recentLocationsKey)
        }
    }

    private static func loadRecentLocations() -> [SelectedLocation] {
        guard let data = UserDefaults.standard.data(forKey: Self.recentLocationsKey) else {
            return []
        }
        return (try? JSONDecoder().decode([SelectedLocation].self, from: data)) ?? []
    }

    private func localizedErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }

        let message = error.localizedDescription.lowercased()
        if message.contains("network") || message.contains("offline") {
            return String(localized: "Network error. Please check your connection.")
        }
        if message.contains("location") || message.contains("geocode") {
            return String(localized: "Unable to use your location right now.")
        }
        return String(localized: "Unable to load providers. Please try again.")
    }
}
