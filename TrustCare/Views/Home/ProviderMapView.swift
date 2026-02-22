import MapKit
import SwiftUI

struct ProviderMapView: View {
    @ObservedObject var viewModel: HomeViewModel
    let providers: [Provider]
    let isLoading: Bool
    let centerCoordinate: CLLocationCoordinate2D?
    let onOpenProvider: (Provider) -> Void

    var body: some View {
        ZStack {
            ProviderMapRepresentable(
                providers: filteredProviders,
                centerCoordinate: centerCoordinate,
                onOpenProvider: onOpenProvider
            )

            if filteredProviders.isEmpty && isLoading {
                ProgressView()
            }

            VStack {
                HStack {
                    Spacer()
                    MapLegendView(viewModel: viewModel)
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                }
                Spacer()
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
    let onOpenProvider: (Provider) -> Void

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
            let region = MKCoordinateRegion(
                center: centerCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
            )
            mapView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onOpenProvider: onOpenProvider)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        let onOpenProvider: (Provider) -> Void

        init(onOpenProvider: @escaping (Provider) -> Void) {
            self.onOpenProvider = onOpenProvider
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
    }
}
