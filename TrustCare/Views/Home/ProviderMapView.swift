import MapKit
import SwiftUI

struct ProviderMapView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var highlightedProviderID: UUID?
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

    var body: some View {
        GeometryReader { proxy in
            let safeAreaTop = proxy.safeAreaInsets.top

            ZStack(alignment: .top) {
                Map(position: $cameraPosition) {
                    UserAnnotation()
                    ForEach(filteredProviders) { provider in
                        Annotation(
                            provider.name,
                            coordinate: CLLocationCoordinate2D(
                                latitude: provider.latitude,
                                longitude: provider.longitude
                            )
                        ) {
                            Button {
                                highlightedProviderID = provider.id
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
                    DispatchQueue.main.async {
                        visibleRegion = region
                        if hasSetInitialPosition {
                            showSearchButton = true
                        }
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
                .onChange(of: highlightedProviderID) { _, newValue in
                    guard let highlightedID = newValue,
                          let provider = filteredProviders.first(where: { $0.id == highlightedID }) else {
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

                if viewModel.isLoading && filteredProviders.isEmpty {
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
                            .background(AppColor.trustBlue, in: Capsule())
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

    private var filteredProviders: [Provider] {
        guard let filterType = viewModel.selectedSurveyType else {
            return viewModel.providers
        }
        return viewModel.providers.filter { provider in
            SpecialtyService.shared.surveyType(for: provider.specialty) == filterType
        }
    }

    @ViewBuilder
    private func mapPin(for provider: Provider) -> some View {
        let surveyType = SpecialtyService.shared.surveyType(for: provider.specialty)
        let isHighlighted = highlightedProviderID == provider.id
        Image(systemName: ProviderMapColor.markerIcon(for: surveyType))
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(ProviderMapColor.color(for: surveyType))
            .clipShape(Circle())
            .overlay(
                Circle().stroke(isHighlighted ? AppColor.trustBlue : .white, lineWidth: isHighlighted ? 3 : 2)
            )
            .scaleEffect(isHighlighted ? 1.12 : 1.0)
            .shadow(radius: isHighlighted ? 4 : 2)
    }
}
