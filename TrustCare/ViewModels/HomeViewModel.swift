import Combine
import CoreLocation
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    enum ViewMode: String, CaseIterable, Identifiable {
        case list = "List"
        case map = "Map"
        var id: String { rawValue }
    }

    @Published var providers: [Provider] = []
    @Published var specialties: [Specialty] = []
    @Published var searchText: String = ""
    @Published var selectedSpecialty: String?
    @Published var viewMode: ViewMode = .list
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasMoreResults: Bool = true
    @Published var locationName: String = String(localized: "Tap to set location")

    private(set) var hasLoadedInitially = false
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var currentOffset: Int = 0
    private let pageSize: Int = 20

    init() {
        observeLocation()
    }
    
    func onAppear() async {
        guard !hasLoadedInitially else { return }
        hasLoadedInitially = true
        await loadSpecialties()
        await searchProviders(reset: true)  // Load initial providers
    }

    func refresh() async {
        currentOffset = 0
        hasMoreResults = true
        await searchProviders(reset: true)
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

    func searchWithDebounce() async {
        print("🔵 HomeViewModel.searchWithDebounce called (searchText: '\(searchText)', specialty: '\(selectedSpecialty ?? "nil")')")
        do {
            try await Task.sleep(nanoseconds: 300_000_000)
        } catch {
            print("⚠️ searchWithDebounce cancelled")
            return
        }
        await refresh()
    }

    private func loadSpecialties() async {
        print("🔵 HomeViewModel.loadSpecialties started")
        do {
            let results = try await ProviderService.fetchSpecialties()
            specialties = results
            print("✅ Loaded \(results.count) specialties")
        } catch {
            let errorMsg = localizedErrorMessage(error)
            print("❌ loadSpecialties failed: \(errorMsg)")
            errorMessage = errorMsg
        }
    }

    private func searchProviders(reset: Bool) async {
        guard !isLoading else {
            print("⚠️ searchProviders skipped - already loading")
            return
        }
        print("🔵 HomeViewModel.searchProviders started (reset: \(reset))")
        isLoading = true
        errorMessage = nil
        let lat = locationManager.userLocation?.latitude
        let lng = locationManager.userLocation?.longitude

        do {
            let results = try await ProviderService.searchProviders(
                text: searchText,
                specialty: selectedSpecialty,
                country: nil,
                priceLevel: nil,
                minRating: nil,
                verifiedOnly: nil,
                lat: lat,
                lng: lng,
                limit: pageSize,
                offset: currentOffset
            )

            print("✅ searchProviders returned \(results.count) providers")
            if reset {
                providers = results
            } else {
                providers.append(contentsOf: results)
            }
            hasMoreResults = results.count == pageSize
        } catch {
            let errorMsg = localizedErrorMessage(error)
            print("❌ searchProviders failed: \(errorMsg)")
            errorMessage = errorMsg
        }
        isLoading = false
        print("🔵 HomeViewModel.searchProviders completed")
    }

    private func observeLocation() {
        locationManager.requestPermission()
        locationManager.$userLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                Task { @MainActor in
                    await self?.reverseGeocode(location: location)
                }
            }
            .store(in: &cancellables)
    }

    private func reverseGeocode(location: CLLocationCoordinate2D) async {
        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(clLocation)
            if let place = placemarks.first {
                let city = place.locality ?? place.administrativeArea
                locationName = city ?? String(localized: "Tap to set location")
            }
        } catch {
            locationName = String(localized: "Tap to set location")
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
        if message.contains("location") || message.contains("geocode") {
            return String(localized: "Unable to use your location right now.")
        }
        return String(localized: "Unable to load providers. Please try again.")
    }
}
