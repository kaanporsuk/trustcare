import MapKit
import SwiftUI

struct ProviderMapView: View {
    let providers: [Provider]
    let isLoading: Bool
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedProvider: Provider?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Map(position: $position, selection: $selectedProvider) {
                UserAnnotation()
                ForEach(providers) { provider in
                    Annotation(
                        provider.name,
                        coordinate: CLLocationCoordinate2D(
                            latitude: provider.latitude,
                            longitude: provider.longitude
                        ),
                        anchor: .bottom
                    ) {
                        VStack(spacing: 0) {
                            Image(systemName: "cross.case.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(provider.verifiedPercentage > 50 ? AppColor.success : AppColor.trustBlue)
                                .clipShape(Circle())
                            Image(systemName: "triangle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(provider.verifiedPercentage > 50 ? AppColor.success : AppColor.trustBlue)
                                .offset(y: -3)
                        }
                    }
                    .tag(provider)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }

            if providers.isEmpty && isLoading {
                ProgressView()
            }
        }
        .sheet(item: $selectedProvider) { provider in
            NavigationStack {
                ProviderDetailView(providerId: provider.id)
            }
            .presentationDetents([.medium, .large])
        }
        .alert(String(localized: "Error"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(String(localized: "OK")) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}
