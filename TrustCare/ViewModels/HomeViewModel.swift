import Combine
import CoreLocation
import Foundation
import MapKit

@MainActor
final class HomeViewModel: ObservableObject {
    struct CityOption: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let latitude: Double
        let longitude: Double
    }

    static let majorTurkishCities: [CityOption] = [
        CityOption(name: "Adana", latitude: 37.0, longitude: 35.33),
        CityOption(name: "Ankara", latitude: 39.93, longitude: 32.86),
        CityOption(name: "Antalya", latitude: 36.88, longitude: 30.71),
        CityOption(name: "Bursa", latitude: 40.19, longitude: 29.06),
        CityOption(name: "Diyarbakır", latitude: 37.91, longitude: 40.24),
        CityOption(name: "Gaziantep", latitude: 37.06, longitude: 37.38),
        CityOption(name: "Istanbul - Anadolu", latitude: 41.0, longitude: 29.1),
        CityOption(name: "Istanbul - Avrupa", latitude: 41.01, longitude: 28.95),
        CityOption(name: "İzmir", latitude: 38.42, longitude: 27.14),
        CityOption(name: "Kayseri", latitude: 38.73, longitude: 35.49),
        CityOption(name: "Konya", latitude: 37.87, longitude: 32.49),
        CityOption(name: "Mersin", latitude: 36.80, longitude: 34.64),
        CityOption(name: "Samsun", latitude: 41.29, longitude: 36.33),
        CityOption(name: "Trabzon", latitude: 41.0, longitude: 39.72)
    ]

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
    @Published var selectedSpecialtyName: String? = nil
    @Published var selectedSurveyType: String? = nil
    @Published var providerSuggestions: [Provider] = []
    @Published var specialtySuggestions: [Specialty] = []
    @Published var viewMode: ViewMode = .list
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var hasMoreResults: Bool = true
    @Published var locationName: String = String(localized: "Tap to set location")
    @Published var selectedCity: String = "Adana"
    @Published var userLatitude: Double = 37.0
    @Published var userLongitude: Double = 35.33
    @Published var selectedRadiusKm: Int = 50
    @Published var selectedLocation: SelectedLocation
    @Published var recentLocations: [SelectedLocation] = []
    /// Incremented ONLY when the user explicitly picks a new location
    /// (city picker or "Use Current Location"). ProviderMapView watches
    /// this single token to fly the camera.
    @Published var flyToToken: Int = 0

    private(set) var hasLoadedInitially = false
    private let locationManager = LocationManager()
    private let specialtyTracker = SpecialtyTracker.shared
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
    private static let selectedCityKey = "home_selected_city"
    private static let userLatitudeKey = "home_user_latitude"
    private static let userLongitudeKey = "home_user_longitude"
    private static let selectedRadiusKmKey = "home_selected_radius_km"

    private func verboseLog(_ message: @autoclosure () -> String) {
        guard Self.verboseLogging else { return }
        print(message())
    }

    var locationManagerCoordinate: CLLocationCoordinate2D? {
        locationManager.userLocation
    }

    init() {
        selectedCity = UserDefaults.standard.string(forKey: Self.selectedCityKey) ?? "Adana"
        userLatitude = UserDefaults.standard.object(forKey: Self.userLatitudeKey) as? Double ?? 37.0
        userLongitude = UserDefaults.standard.object(forKey: Self.userLongitudeKey) as? Double ?? 35.33
        let savedRadius = UserDefaults.standard.integer(forKey: Self.selectedRadiusKmKey)
        selectedRadiusKm = [5, 10, 25, 50].contains(savedRadius) ? savedRadius : 50

        if let savedLocation = Self.loadSelectedLocation() {
            selectedLocation = savedLocation
            locationName = savedLocation.name
            selectedCity = savedLocation.name
            userLatitude = savedLocation.latitude
            userLongitude = savedLocation.longitude
        } else {
            let defaultCity = UserDefaults.standard.string(forKey: Self.selectedCityKey) ?? "Adana"
            let defaultLatitude = UserDefaults.standard.object(forKey: Self.userLatitudeKey) as? Double ?? 37.0
            let defaultLongitude = UserDefaults.standard.object(forKey: Self.userLongitudeKey) as? Double ?? 35.33
            selectedLocation = SelectedLocation(
                name: defaultCity,
                latitude: defaultLatitude,
                longitude: defaultLongitude,
                isCurrentLocation: false
            )
            locationName = defaultCity
            selectedCity = defaultCity
            userLatitude = defaultLatitude
            userLongitude = defaultLongitude
            persistCityAndCoordinates()
        }
        recentLocations = Self.loadRecentLocations()
        observeLocation()
        observeRehberSpecialtyRouting()
    }
    
    func onAppear() async {
        guard !hasLoadedInitially else { return }
        hasLoadedInitially = true
        await loadSpecialties(forceRefresh: false)
        
        // Prioritize user's current GPS location on initialization
        if let userLocation = locationManager.userLocation {
            let gpsLocation = SelectedLocation(
                name: locationName.isEmpty || locationName == String(localized: "Tap to set location") 
                    ? String(localized: "current_location") 
                    : locationName,
                latitude: userLocation.latitude,
                longitude: userLocation.longitude,
                isCurrentLocation: true
            )
            selectedLocation = gpsLocation
            userLatitude = gpsLocation.latitude
            userLongitude = gpsLocation.longitude
            saveSelectedLocation(gpsLocation)
        }
        
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
        selectedCity = location.name
        userLatitude = location.latitude
        userLongitude = location.longitude
        saveSelectedLocation(location)
        persistCityAndCoordinates()
        addRecentLocation(location)
        // Trigger map fly-to for explicit user action
        flyToToken += 1
        await refresh()
    }

    func useCurrentLocation() async {
        locationManager.requestPermission()
        locationManager.startUpdating()

        // Wait briefly for GPS fix
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        guard let coordinate = locationManager.userLocation else {
            verboseLog("❌ useCurrentLocation: No user location available")
            return
        }

        // CRITICAL: Reverse geocode to get city name
        let clLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let cityName: String
        if let placemark = try? await CLGeocoder().reverseGeocodeLocation(clLocation).first {
            cityName = placemark.locality
                ?? placemark.subAdministrativeArea
                ?? placemark.administrativeArea
                ?? String(localized: "current_location")
        } else {
            cityName = String(localized: "current_location")
        }

        // Update all location state
        let updated = SelectedLocation(
            name: cityName,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            isCurrentLocation: true
        )
        selectedLocation = updated
        locationName = cityName
        selectedCity = cityName
        userLatitude = coordinate.latitude
        userLongitude = coordinate.longitude
        saveSelectedLocation(updated)
        persistCityAndCoordinates()

        // Stop continuous updates (prevent map snap-back)
        locationManager.stopUpdating()

        // Trigger map fly-to for explicit user action
        flyToToken += 1

        // Refresh providers for new location
        currentOffset = 0
        hasMoreResults = true
        await searchProviders(reset: true)
    }

    func selectRadius(_ radiusKm: Int) async {
        guard [5, 10, 25, 50].contains(radiusKm) else { return }
        selectedRadiusKm = radiusKm
        UserDefaults.standard.set(radiusKm, forKey: Self.selectedRadiusKmKey)
        await refresh()
    }

    func fetchProviders() async {
        currentOffset = 0
        hasMoreResults = true
        await searchProviders(reset: true)
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
        // 1. Reverse geocode to update the label
        let location = CLLocation(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        if let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first {
            locationName = placemark.locality
                ?? placemark.subAdministrativeArea
                ?? placemark.administrativeArea
                ?? locationName
        }

        // 2. Update internal state WITHOUT triggering map recenter
        //    (no flyToToken increment — camera stays where user left it)
        selectedLocation = SelectedLocation(
            name: locationName,
            latitude: region.center.latitude,
            longitude: region.center.longitude,
            isCurrentLocation: false
        )
        saveSelectedLocation(selectedLocation)

        // 3. Search using the region's center
        currentOffset = 0
        hasMoreResults = true
        await searchProviders(reset: true)
    }

    // recenterMap removed — camera is now solely owned by ProviderMapView's
    // @State cameraPosition. The only way to fly the map is flyToToken += 1.

    func searchWithDebounce() async {
        verboseLog("🔵 HomeViewModel.searchWithDebounce called (searchText: '\(searchText)', surveyType: '\(selectedSurveyType ?? "all")')")
        do {
            try await Task.sleep(nanoseconds: 300_000_000)
        } catch {
            verboseLog("⚠️ searchWithDebounce cancelled")
            return
        }
        await loadSuggestions()
        await refresh()
    }

    func clearSuggestions() {
        providerSuggestions = []
        specialtySuggestions = []
    }

    func applySpecialtyFilter(_ specialty: Specialty?) async {
        selectedSpecialtyName = specialty?.name
        if let specialty {
            selectedSurveyType = specialty.surveyType
            // Record tap for personalization
            specialtyTracker.recordTap(specialtyName: specialty.name)
        } else {
            selectedSurveyType = nil
        }
        await refresh()
    }

    /// Called by the map legend when a category filter is tapped.
    /// Clears any specialty-level filter and applies the broad category.
    func applyLegendFilter(_ surveyType: String?) async {
        selectedSpecialtyName = nil
        selectedSurveyType = surveyType
        await refresh()
    }

    private func observeRehberSpecialtyRouting() {
        NotificationCenter.default.publisher(for: .trustCareApplySpecialtyFilter)
            .compactMap { $0.object as? String }
            .sink { [weak self] specialtyName in
                guard let self else { return }
                Task { @MainActor in
                    await self.applySpecialtyFilterByName(specialtyName)
                }
            }
            .store(in: &cancellables)
    }

    private func applySpecialtyFilterByName(_ specialtyName: String) async {
        if specialties.isEmpty {
            await loadSpecialties(forceRefresh: false)
        }

        let normalizedTarget = specialtyName
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))

        let match = specialties.first { specialty in
            [
                specialty.name,
                specialty.nameTr,
                specialty.nameDe,
                specialty.namePl,
                specialty.nameNl,
                specialty.nameDa,
            ]
            .compactMap { $0?.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR")) }
            .contains(normalizedTarget)
        }

        selectedSpecialtyName = match?.name ?? specialtyName
        selectedSurveyType = match?.surveyType
        await refresh()
    }

    private func loadSpecialties(forceRefresh: Bool) async {
        verboseLog("🔵 HomeViewModel.loadSpecialties started")
        do {
            let results = try await ProviderService.fetchSpecialtiesCached(forceRefresh: forceRefresh)
            specialties = results
            // Compute personalized top-5 pills
            let userTop = specialtyTracker.userTopSpecialties(count: 5)
            if userTop.isEmpty {
                // Default: use global popular
                popularSpecialties = results
                    .filter { $0.isPopular }
                    .sorted { $0.displayOrder < $1.displayOrder }
            } else {
                // Personalized: match user's top specialties
                let personalized = userTop.compactMap { name in
                    results.first { $0.name == name }
                }
                popularSpecialties = personalized.isEmpty
                    ? results.filter { $0.isPopular }.sorted { $0.displayOrder < $1.displayOrder }
                    : personalized
            }
            verboseLog("✅ Loaded \(results.count) specialties")
        } catch {
            let errorMsg = localizedErrorMessage(error)
            print("❌ loadSpecialties failed: \(errorMsg)")
            errorMessage = errorMsg
        }
    }

    private func searchProviders(reset: Bool) async {
        guard !isLoading || reset else {
            verboseLog("⚠️ searchProviders skipped - already loading")
            return
        }
        verboseLog("🔵 HomeViewModel.searchProviders started (reset: \(reset))")
        isLoading = true
        defer {
            isLoading = false
            verboseLog("🔵 HomeViewModel.searchProviders completed")
        }
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
                specialty: selectedSpecialtyName,
                country: nil,
                priceLevel: nil,
                minRating: nil,
                verifiedOnly: nil,
                radiusKm: selectedRadiusKm,
                lat: lat,
                lng: lng,
                limit: pageSize,
                offset: currentOffset
            )

            // Apply client-side category filtering
            let filteredResults = filterProvidersBySurveyType(results, selectedSurveyType)
                .filter { provider in
                    guard let providerDistance = provider.distanceKm else { return true }
                    return providerDistance <= Double(selectedRadiusKm)
                }
                .sorted {
                    ($0.distanceKm ?? .greatestFiniteMagnitude) < ($1.distanceKm ?? .greatestFiniteMagnitude)
                }
            
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
            print("  Full error: \(error)")
            print("  Error type: \(type(of: error))")
            if let decodingError = error as? DecodingError {
                print("  Decoding error detected!")
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("    Missing key: \(key.stringValue) in \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("    Type mismatch for \(type) at \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("    Value not found for \(type) at \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("    Data corrupted at \(context.codingPath)")
                @unknown default:
                    print("    Unknown decoding error")
                }
            }
            errorMessage = errorMsg
        }
    }

    private func filterProvidersBySurveyType(_ providers: [Provider], _ surveyType: String?) -> [Provider] {
        guard let surveyType else {
            return providers
        }

        return providers.filter { provider in
            SpecialtyService.shared.surveyType(for: provider.specialty) == surveyType
        }
    }

    private func loadSuggestions() async {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clearSuggestions()
            return
        }

        do {
            providerSuggestions = try await ProviderService.searchProvidersTable(query: trimmed, limit: 8)
        } catch {
            providerSuggestions = []
        }

        let query = trimmed.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
        specialtySuggestions = specialties
            .filter { specialty in
                specialty.matchesSearch(query)
            }
            .sorted { $0.displayOrder < $1.displayOrder }
            .prefix(8)
            .map { $0 }
    }

    private func observeLocation() {
        locationManager.requestPermission()
        // We only observe location for the INITIAL geocode on app launch.
        // After that, LocationManager stops itself (first fix only).
        // This does NOT trigger any map recentering.
        locationManager.$userLocation
            .compactMap { $0 }
            .first() // Only take the first emission
            .sink { [weak self] location in
                Task { @MainActor in
                    guard let self else { return }
                    let currentLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                    // Only reverse geocode if using current location, to update the label
                    if self.selectedLocation.isCurrentLocation {
                        await self.reverseGeocode(location: location)
                        self.lastGeocodedLocation = currentLocation
                        self.lastGeocodedAt = Date()
                    }
                    // Do NOT refresh providers or recenter map here
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
                let city = place.locality
                    ?? place.subAdministrativeArea
                    ?? place.administrativeArea
                    ?? String(localized: "current_location")
                if selectedLocation.isCurrentLocation {
                    locationName = city
                    let updated = SelectedLocation(
                        name: locationName,
                        latitude: location.latitude,
                        longitude: location.longitude,
                        isCurrentLocation: true
                    )
                    selectedLocation = updated
                    selectedCity = city
                    saveSelectedLocation(updated)
                }
            }
        } catch {
            if selectedLocation.isCurrentLocation {
                locationName = String(localized: "current_location")
                selectedCity = String(localized: "current_location")
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

    private func persistCityAndCoordinates() {
        let defaults = UserDefaults.standard
        defaults.set(selectedCity, forKey: Self.selectedCityKey)
        defaults.set(userLatitude, forKey: Self.userLatitudeKey)
        defaults.set(userLongitude, forKey: Self.userLongitudeKey)
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
