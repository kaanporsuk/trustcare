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

    var body: some View {
        ZStack {
            ProviderMapRepresentable(
                providers: filteredProviders,
                centerCoordinate: centerCoordinate,
                centerUpdateToken: centerUpdateToken,
                onOpenProvider: onOpenProvider,
                onMapCameraChange: { region in
                    currentMapRegion = region
                    showSearchAreaButton = true
                }
            )

            if filteredProviders.isEmpty && isLoading {
                ProgressView()
            }

            VStack {
                // Search This Area Button at top center
                if showSearchAreaButton && currentMapRegion != nil {
                    Button {
                        if let region = currentMapRegion {
                            Task {
                                showSearchAreaButton = false
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
                
                // Map legend at top right
                HStack {
                    Spacer()
                    MapLegendView(viewModel: viewModel)
                        .padding(.top, 12)
                        .padding(.trailing, 12)
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
    let onOpenProvider: (Provider) -> Void
    let onMapCameraChange: (MKCoordinateRegion) -> Void

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

        if let centerCoordinate {
            let currentCenter = mapView.region.center
            let latitudeDistance = abs(currentCenter.latitude - centerCoordinate.latitude)
            let longitudeDistance = abs(currentCenter.longitude - centerCoordinate.longitude)
            let centerThreshold = 0.0001
            let centerChangedSignificantly = latitudeDistance > centerThreshold || longitudeDistance > centerThreshold
            let shouldForceUpdate = context.coordinator.lastCenterUpdateToken != centerUpdateToken

            guard centerChangedSignificantly || shouldForceUpdate else {
                context.coordinator.onMapCameraChange = onMapCameraChange
                return
            }

            let region = MKCoordinateRegion(
                center: centerCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
            )
            context.coordinator.isSettingRegionProgrammatically = true
            context.coordinator.lastCenterUpdateToken = centerUpdateToken
            mapView.setRegion(region, animated: true)
        }
        
        context.coordinator.onMapCameraChange = onMapCameraChange
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onOpenProvider: onOpenProvider, onMapCameraChange: onMapCameraChange)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        let onOpenProvider: (Provider) -> Void
        var onMapCameraChange: ((MKCoordinateRegion) -> Void)?
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
