import Combine
import CoreLocation
import MapKit
import SwiftUI

struct LocationSearchSheet: View {
    let currentLocationName: String
    let selectedLocation: HomeViewModel.SelectedLocation
    let recentLocations: [HomeViewModel.SelectedLocation]
    let onSelectLocation: (HomeViewModel.SelectedLocation) async -> Void
    let onUseCurrentLocation: () async -> Void
    let onClearRecents: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LocationSearchViewModel()

    private let popularCities: [String] = [
        "Istanbul",
        "Ankara",
        "Izmir",
        "Antalya",
        "Bursa",
        "Berlin",
        "Amsterdam",
        "Warsaw"
    ]

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Search Location")
                    .font(AppFont.title2)

                SearchField(
                    text: $viewModel.query,
                    isSearching: viewModel.isSearching
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            currentLocationSection

                            if !recentLocations.isEmpty {
                                recentLocationsSection
                            }

                            popularCitiesSection
                        } else if viewModel.results.isEmpty && !viewModel.isSearching {
                            noResultsSection
                        } else {
                            searchResultsSection
                        }
                    }
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .background(AppColor.background.ignoresSafeArea())
    }

    private var currentLocationSection: some View {
        Button {
            Task {
                await onUseCurrentLocation()
                dismiss()
            }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                PulsingDot()
                VStack(alignment: .leading, spacing: 4) {
                    Text("use_device_location")
                        .font(AppFont.body)
                        .foregroundStyle(.primary)
                    Text(currentLocationName)
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if selectedLocation.isCurrentLocation {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(AppColor.trustBlue)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColor.cardBackground)
            .cornerRadius(AppRadius.card)
        }
        .buttonStyle(.plain)
    }

    private var recentLocationsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Recent Locations")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear") {
                    onClearRecents()
                }
                .font(AppFont.caption)
                .foregroundStyle(AppColor.trustBlue)
            }

            VStack(spacing: AppSpacing.sm) {
                ForEach(recentLocations, id: \.self) { location in
                    LocationRow(
                        iconName: "mappin.and.ellipse",
                        title: location.name,
                        subtitle: nil,
                        isSelected: location == selectedLocation
                    ) {
                        Task {
                            await onSelectLocation(location)
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var popularCitiesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Popular Cities")
                .font(AppFont.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: AppSpacing.sm) {
                ForEach(popularCities, id: \.self) { city in
                    LocationRow(
                        iconName: "building.2.fill",
                        title: city,
                        subtitle: nil,
                        isSelected: selectedLocation.name == city && !selectedLocation.isCurrentLocation
                    ) {
                        Task {
                            if let location = try? await viewModel.resolveQuery(city) {
                                await onSelectLocation(location)
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(viewModel.results, id: \.self) { completion in
                LocationRow(
                    iconName: "mappin.and.ellipse",
                    title: completion.title,
                    subtitle: completion.subtitle.isEmpty ? nil : completion.subtitle,
                    isSelected: selectedLocation.name == completion.title && !selectedLocation.isCurrentLocation
                ) {
                    Task {
                        if let location = try? await viewModel.resolveCompletion(completion) {
                            await onSelectLocation(location)
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var noResultsSection: some View {
        Text("No locations found. Try a different search.")
            .font(AppFont.body)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AppSpacing.md)
    }
}

private struct SearchField: View {
    @Binding var text: String
    let isSearching: Bool

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search city or region...", text: $text)
                .font(AppFont.body)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
            if isSearching {
                ProgressView()
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
    }
}

private struct LocationRow: View {
    let iconName: String
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: iconName)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.body)
                        .foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(AppColor.trustBlue)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColor.cardBackground)
            .cornerRadius(AppRadius.card)
        }
        .buttonStyle(.plain)
    }
}

private struct PulsingDot: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColor.trustBlue.opacity(0.2))
                .frame(width: 18, height: 18)
                .scaleEffect(animate ? 1.4 : 0.8)
                .opacity(animate ? 0.0 : 1.0)
            Circle()
                .fill(AppColor.trustBlue)
                .frame(width: 8, height: 8)
        }
        .onAppear {
            withAnimation(
                .easeOut(duration: 1.2)
                    .repeatForever(autoreverses: false)
            ) {
                animate = true
            }
        }
    }
}

@MainActor
final class LocationSearchViewModel: NSObject, ObservableObject {
    @Published var query: String = ""
    @Published var results: [MKLocalSearchCompletion] = []
    @Published var isSearching: Bool = false

    private let completer = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address]

        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                guard let self else { return }
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                self.isSearching = !trimmed.isEmpty
                self.completer.queryFragment = trimmed
                if trimmed.isEmpty {
                    self.results = []
                }
            }
            .store(in: &cancellables)
    }

    func resolveCompletion(
        _ completion: MKLocalSearchCompletion
    ) async throws -> HomeViewModel.SelectedLocation? {
        let request = MKLocalSearch.Request(completion: completion)
        return try await resolveRequest(request, fallbackName: completion.title)
    }

    func resolveQuery(_ query: String) async throws -> HomeViewModel.SelectedLocation? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        return try await resolveRequest(request, fallbackName: query)
    }

    private func resolveRequest(
        _ request: MKLocalSearch.Request,
        fallbackName: String
    ) async throws -> HomeViewModel.SelectedLocation? {
        let search = MKLocalSearch(request: request)
        let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MKLocalSearch.Response, Error>) in
            search.start { response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let response else {
                    continuation.resume(throwing: NSError(domain: "LocationSearch", code: 1))
                    return
                }
                continuation.resume(returning: response)
            }
        }

        guard let item = response.mapItems.first else { return nil }
        let placemark = item.placemark
        let name = formatLocationName(placemark: placemark, fallback: fallbackName)
        return HomeViewModel.SelectedLocation(
            name: name,
            latitude: placemark.coordinate.latitude,
            longitude: placemark.coordinate.longitude,
            isCurrentLocation: false
        )
    }

    private func formatLocationName(placemark: MKPlacemark, fallback: String) -> String {
        if let locality = placemark.locality {
            return locality
        }
        if let admin = placemark.administrativeArea {
            return admin
        }
        return placemark.name ?? fallback
    }
}

extension LocationSearchViewModel: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.results = completer.results
            self.isSearching = false
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.results = []
            self.isSearching = false
        }
    }
}
