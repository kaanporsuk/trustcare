import MapKit
import SwiftUI

struct ProviderMapView: View {
    @ObservedObject var viewModel: HomeViewModel
    let providers: [Provider]
    let isLoading: Bool
    let centerCoordinate: CLLocationCoordinate2D?
    let centerUpdateToken: Int
    let onOpenProvider: (Provider) -> Void
    
    @State private var showSearchAreaButton = false
    @State private var currentMapRegion: MKCoordinateRegion?
    @State private var userIsInteracting = false

    var body: some View {
        ZStack {
            ProviderMapRepresentable(
                providers: filteredProviders,
                centerCoordinate: userIsInteracting ? nil : centerCoordinate,
                centerUpdateToken: centerUpdateToken,
                didUserSelectNewLocation: viewModel.didUserSelectNewLocation,
                onOpenProvider: onOpenProvider,
                onMapCameraChange: { region in
                    currentMapRegion = region
                    showSearchAreaButton = true
                },
                userIsInteracting: $userIsInteracting,
                didUserSelectNewLocationChanged: {
                    viewModel.didUserSelectNewLocation = false
                }
            )

            if filteredProviders.isEmpty && isLoading {
                ProgressView()
            }

            VStack {
                HStack {
                    // Search This Area Button at top-left center
                    if showSearchAreaButton && currentMapRegion != nil {
                        Button {
                            if let region = currentMapRegion {
                                Task {
                                    showSearchAreaButton = false
                                    userIsInteracting = false
                                    await viewModel.fetchProviders(in: region)
                                }
                            }
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
                        }
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .scale))
                    }
                    
                    Spacer()
                    
                    // Filter button at top-right
                    Button {
                        // Filter button action
                    } label: {
                        Label(String(localized: "Filter"), systemImage: "line.3.horizontal.decrease")
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
            return providers
        }
        return providers.filter { provider in
            SpecialtyService.shared.surveyType(for: provider.specialty) == filterType
        }
    }
}

final class ProviderAnnotation: NSObject, MKAnnotation {
    let provider: Provider
    let surveyType: String
    dynamic var coordinate: CLLocationCoordinate2D
    var title: String? { provider.name }
    var subtitle: String? {
        "\(provider.specialty) • \(String(format: "%.1f", provider.ratingOverall))"
    }

    init(provider: Provider) {
        self.provider = provider
        self.surveyType = SpecialtyService.shared.surveyType(for: provider.specialty)
        self.coordinate = CLLocationCoordinate2D(latitude: provider.latitude, longitude: provider.longitude)
    }
}

private struct ProviderMapRepresentable: UIViewRepresentable {
    let providers: [Provider]
    let centerCoordinate: CLLocationCoordinate2D?
    let centerUpdateToken: Int
    let didUserSelectNewLocation: Bool
    let onOpenProvider: (Provider) -> Void
    let onMapCameraChange: (MKCoordinateRegion) -> Void
    @Binding var userIsInteracting: Bool
    let didUserSelectNewLocationChanged: () -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "provider")
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "cluster")
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let existing = mapView.annotations.compactMap { $0 as? ProviderAnnotation }
        mapView.removeAnnotations(existing)
        mapView.addAnnotations(providers.map { ProviderAnnotation(provider: $0) })

        // CRITICAL FIX: Only snap the map if user explicitly selected a new location
        // This prevents the snap-back loop that occurs on every view redraw
        if let centerCoordinate, !userIsInteracting, didUserSelectNewLocation {
            let region = MKCoordinateRegion(
                center: centerCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
            )
            context.coordinator.isSettingRegionProgrammatically = true
            context.coordinator.lastCenterUpdateToken = centerUpdateToken
            mapView.setRegion(region, animated: true)
            
            // Immediately reset the flag to prevent re-snapping on subsequent redraws
            didUserSelectNewLocationChanged()
        }
        
        context.coordinator.onMapCameraChange = onMapCameraChange
        context.coordinator.userIsInteracting = $userIsInteracting
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onOpenProvider: onOpenProvider, onMapCameraChange: onMapCameraChange)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        let onOpenProvider: (Provider) -> Void
        var onMapCameraChange: ((MKCoordinateRegion) -> Void)?
        var userIsInteracting: Binding<Bool>?
        var isSettingRegionProgrammatically = false
        var lastCenterUpdateToken: Int = -1

        init(onOpenProvider: @escaping (Provider) -> Void, onMapCameraChange: @escaping (MKCoordinateRegion) -> Void) {
            self.onOpenProvider = onOpenProvider
            self.onMapCameraChange = onMapCameraChange
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let providerAnnotation = annotation as? ProviderAnnotation else {
                return nil
            }

            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "provider", for: providerAnnotation) as! MKMarkerAnnotationView
            view.canShowCallout = true
            view.clusteringIdentifier = "provider"
            view.markerTintColor = UIColor(ProviderMapColor.color(for: providerAnnotation.surveyType))
            view.glyphTintColor = .white
            view.glyphImage = UIImage(systemName: ProviderMapColor.markerIcon(for: providerAnnotation.surveyType))
            let button = UIButton(type: .detailDisclosure)
            button.tag = providerAnnotation.provider.id.hashValue
            view.rightCalloutAccessoryView = button
            return view
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let annotation = view.annotation as? ProviderAnnotation else { return }
            onOpenProvider(annotation.provider)
        }
        
        func mapViewWillStartUserInteraction(_ mapView: MKMapView) {
            userIsInteracting?.wrappedValue = true
        }
        
        func mapViewDidEndUserInteraction(_ mapView: MKMapView) {
            userIsInteracting?.wrappedValue = false
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if isSettingRegionProgrammatically {
                isSettingRegionProgrammatically = false
                return
            }
            let region = mapView.region
            onMapCameraChange?(region)
        }
    }
}
