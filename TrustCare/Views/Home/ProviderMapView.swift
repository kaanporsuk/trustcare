import MapKit
import SwiftUI

struct ProviderMapView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    let onOpenProvider: (Provider) -> Void
    @Binding var showSpecialtyBrowser: Bool

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
            // ═══════════════════════════════════════════════════════════
            // THE ONLY .onChange that touches cameraPosition.
            // Fires ONLY when user explicitly picks a new location
            // (city picker or "Use Current Location").
            // ═══════════════════════════════════════════════════════════
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

            // Overlay buttons
            VStack {
                HStack {
                    // Search this area button
                    if showSearchButton, let region = visibleRegion {
                        Button {
                            showSearchButton = false
                            Task {
                                await viewModel.fetchProviders(in: region)
                            }
                            // Do NOT recenter the camera — just loads data
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                Text(String(localized: "search_this_area"))
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(AppColor.trustBlue)
                            .cornerRadius(20)
                            .shadow(radius: 4)
                        }
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .scale))
                    }

                    Spacer()

                    // Filter button — TOP RIGHT only (the SOLE filter button)
                    Button {
                        showSpecialtyBrowser = true
                    } label: {
                        Label(String(localized: "filter_button"), systemImage: "line.3.horizontal.decrease")
                            .font(AppFont.callout)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                    .padding(.trailing, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                }

                Spacer()

                // Map legend
                HStack {
                    Spacer()
                    MapLegendView(viewModel: viewModel)
                        .padding(.trailing, 12)
                        .padding(.bottom, 12)
                }
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
        Image(systemName: ProviderMapColor.markerIcon(for: surveyType))
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(ProviderMapColor.color(for: surveyType))
            .clipShape(Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .shadow(radius: 2)
    }
}
