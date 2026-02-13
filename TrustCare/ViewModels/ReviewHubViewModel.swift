import Combine
import CoreLocation
import Foundation

@MainActor
final class ReviewHubViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchResults: [Provider] = []
    @Published var isSearching: Bool = false
    @Published var searchErrorMessage: String?

    @Published var nearbyProviders: [Provider] = []
    @Published var isLoadingNearby: Bool = false

    @Published var recentlyViewed: [Provider] = []

    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?

    init() {
        observeLocation()
    }

    func onAppear() {
        recentlyViewed = RecentProvidersStore.load()
        startLocationUpdates()
        Task { await loadNearbyProviders() }
    }

    func startLocationUpdates() {
        locationManager.requestPermission()
        locationManager.startUpdating()
    }

    func searchProviders() {
        searchTask?.cancel()
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearching = false
            searchErrorMessage = nil
            return
        }

        isSearching = true
        searchTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
            } catch {
                self?.isSearching = false
                return
            }
            guard !Task.isCancelled, let self else { return }
            do {
                let results = try await ProviderService.searchProvidersTable(query: trimmed)
                self.searchResults = results
                self.searchErrorMessage = nil
                self.isSearching = false
            } catch {
                self.searchErrorMessage = self.localizedErrorMessage(error)
                self.isSearching = false
            }
        }
    }

    func refreshRecents() {
        recentlyViewed = RecentProvidersStore.load()
    }

    private func loadNearbyProviders() async {
        guard !isLoadingNearby else { return }
        isLoadingNearby = true
        defer { isLoadingNearby = false }

        let coordinate = locationManager.userLocation
        do {
            let results = try await ProviderService.searchProviders(
                text: nil,
                specialty: nil,
                country: nil,
                priceLevel: nil,
                minRating: nil,
                verifiedOnly: nil,
                radiusKm: 50,
                lat: coordinate?.latitude,
                lng: coordinate?.longitude,
                limit: 5,
                offset: 0
            )
            nearbyProviders = results
        } catch {
            nearbyProviders = []
        }
    }

    private func observeLocation() {
        locationManager.$userLocation
            .compactMap { $0 }
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadNearbyProviders()
                }
            }
            .store(in: &cancellables)
    }

    private func localizedErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }

        let message = error.localizedDescription.lowercased()
        if message.contains("network") || message.contains("offline") {
            return String(localized: "Network error. Please check your connection.")
        }
        return String(localized: "Unable to load providers. Please try again.")
    }
}
