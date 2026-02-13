import MapKit
import SwiftUI

struct ProviderMapView: View {
    let providers: [Provider]
    let isLoading: Bool
    let centerCoordinate: CLLocationCoordinate2D?
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
            .onAppear {
                recenterOnSelectedLocation(animated: false)
            }
            .onChange(of: centerCoordinateToken) { _, _ in
                recenterOnSelectedLocation(animated: true)
            }

            if providers.isEmpty && isLoading {
                ProgressView()
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                recenterOnSelectedLocation(animated: true)
            } label: {
                Image(systemName: "location.fill")
                    .font(.headline)
                    .foregroundStyle(AppColor.trustBlue)
                    .padding(12)
                    .background(AppColor.cardBackground)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
            }
            .padding(AppSpacing.lg)
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

    private func recenterOnSelectedLocation(animated: Bool) {
        guard let centerCoordinate else { return }
        let region = MKCoordinateRegion(
            center: centerCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
        )
        if animated {
            withAnimation(.easeInOut(duration: 0.25)) {
                position = .region(region)
            }
        } else {
            position = .region(region)
        }
    }

    private var centerCoordinateToken: String {
        guard let centerCoordinate else { return "nil" }
        return "\(centerCoordinate.latitude),\(centerCoordinate.longitude)"
    }
}
