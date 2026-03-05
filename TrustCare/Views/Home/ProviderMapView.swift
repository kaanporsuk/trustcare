import MapKit
import SwiftUI

struct ProviderMapView: View {
    @ObservedObject var viewModel: HomeViewModel
    let providers: [Provider]
    @Binding var selectedProviderID: UUID?
    @EnvironmentObject var localizationManager: LocalizationManager
    let onOpenProvider: (Provider) -> Void

    // ═══════════════════════════════════════════════════════════════
    // SOLE source of truth for the camera.
    // This is a LOCAL @State — NOT derived from ViewModel.
    // It is ONLY mutated by:
    //   1. .task on initial load
    
    //   2. .onChange(of: viewModel.flyToToken) when user picks a location
    //   3. The built-in MapUserLocationButton (MapKit internal)
    //   4. User gestures (MapKit internal)
    // ═══════════════════════════════════════════════════════════════
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasSetInitialPosition = false
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var showSearchButton = false
    @State private var searchAreaRevealTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            let safeAreaTop = proxy.safeAreaInsets.top

            ZStack(alignment: .top) {
                Map(position: $cameraPosition) {
                    UserAnnotation()
                    ForEach(providers) { provider in
                        Annotation(
                            provider.name,
                            coordinate: CLLocationCoordinate2D(
                                latitude: provider.latitude,
                                longitude: provider.longitude
                            )
                        ) {
                            Button {
                                selectedProviderID = provider.id
                                onOpenProvider(provider)
                            } label: {
                                mapPin(for: provider)
                            }
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    let region = context.region
                    searchAreaRevealTask?.cancel()
                    DispatchQueue.main.async {
                        visibleRegion = region
                    }
                    guard hasSetInitialPosition else { return }
                    searchAreaRevealTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 450_000_000)
                        guard !Task.isCancelled else { return }
                        showSearchButton = true
                    }
                }
                // Set initial position ONCE on appear
                .task {
                    if !hasSetInitialPosition {
                        let loc = viewModel.selectedLocation
                        if loc.latitude != 0, loc.longitude != 0 {
                            DispatchQueue.main.async {
                                cameraPosition = .region(MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(
                                        latitude: loc.latitude,
                                        longitude: loc.longitude
                                    ),
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                ))
                            }
                        }
                        DispatchQueue.main.async {
                            hasSetInitialPosition = true
                        }
                    }
                }
                .onChange(of: viewModel.flyToToken) { _, _ in
                    let loc = viewModel.selectedLocation
                    guard loc.latitude != 0, loc.longitude != 0 else { return }
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            cameraPosition = .region(MKCoordinateRegion(
                                center: CLLocationCoordinate2D(
                                    latitude: loc.latitude,
                                    longitude: loc.longitude
                                ),
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            ))
                        }
                        showSearchButton = false
                    }
                }
                                .onChange(of: selectedProviderID) { _, newValue in
                    guard let highlightedID = newValue,
                                                    let provider = providers.first(where: { $0.id == highlightedID }) else {
                        return
                    }

                    withAnimation(.easeInOut(duration: 0.35)) {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: CLLocationCoordinate2D(
                                    latitude: provider.latitude,
                                    longitude: provider.longitude
                                ),
                                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            )
                        )
                    }
                }

                if viewModel.isLoading && providers.isEmpty {
                    ProgressView()
                        .padding(.top, 24)
                }
            }
            .overlay(alignment: .topLeading) {
                if showSearchButton, let region = visibleRegion {
                    Button {
                        showSearchButton = false
                        Task {
                            await viewModel.fetchProviders(in: region)
                        }
                    } label: {
                        Label("search_this_area", systemImage: "magnifyingglass")
                            .font(.callout.weight(.medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.92)
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .background(Color.tcOcean, in: Capsule())
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, safeAreaTop + 16)
                    .padding(.leading, 16)
                    .zIndex(3)
                }
            }
            .overlay(alignment: .topTrailing) {
                MapLegendView(viewModel: viewModel)
                    .padding(.top, safeAreaTop + 16)
                    .padding(.trailing, 16)
                    .zIndex(3)
            }
        }
    }

    @ViewBuilder
    private func mapPin(for provider: Provider) -> some View {
        let surveyType = SpecialtyService.shared.surveyType(for: provider.specialty)
        let isHighlighted = selectedProviderID == provider.id
        Image(systemName: ProviderMapColor.markerIcon(for: surveyType))
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(ProviderMapColor.color(for: surveyType))
            .clipShape(Circle())
            .overlay(
                Circle().stroke(isHighlighted ? Color.tcOcean : .white, lineWidth: isHighlighted ? 3 : 2)
            )
            .scaleEffect(isHighlighted ? 1.12 : 1.0)
            .shadow(radius: isHighlighted ? 4 : 2)
    }
}
