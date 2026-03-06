import CoreLocation
import MapKit
import SwiftUI

struct AddProviderSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onComplete: (Provider) -> Void

    @State private var name: String = ""
    @State private var address: String = ""
    @State private var phone: String = ""
    @State private var selectedTaxonomy: TaxonomySuggestion?
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedCoordinateSummary: String?
    @State private var placeSuggestions: [PlaceSuggestion] = []

    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?
    @State private var showSpecialtyPicker: Bool = false
    @State private var showMapPicker: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("add_provider_name", text: $name)

                    if !placeSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            ForEach(placeSuggestions) { suggestion in
                                Button {
                                    applySuggestion(suggestion)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(tcString("add_provider_is_this", fallback: "Is this provider a...")) \(suggestion.name)")
                                            .font(AppFont.body)
                                            .foregroundStyle(.primary)
                                        Text(suggestion.address)
                                            .font(AppFont.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        showSpecialtyPicker = true
                    } label: {
                        HStack {
                            Text(tcKey: "add_provider_specialty", fallback: "Specialty")
                            Spacer()
                            Text(selectedTaxonomy?.label ?? tcString("add_provider_select", fallback: "Select"))
                                .foregroundStyle(.secondary)
                        }
                    }

                    TextField("add_provider_address", text: $address)
                    TextField("add_provider_phone_optional", text: $phone)
                        .keyboardType(.phonePad)
                }
                header: {
                    Text(tcKey: "add_provider_provider_information", fallback: "Provider information")
                }

                Section {
                    Button(tcString("add_provider_set_map_pin", fallback: "Set map pin")) {
                        showMapPicker = true
                    }

                    if let selectedCoordinate {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tcKey: "add_provider_pin_set", fallback: "Pin set")
                                .font(AppFont.body)
                                .foregroundStyle(Color.tcSage)

                            Text(selectedCoordinateSummary ?? fallbackLocationSummary())
                                .font(AppFont.footnote)
                                .foregroundStyle(.secondary)

                            Text(String(format: "%.5f, %.5f", selectedCoordinate.latitude, selectedCoordinate.longitude))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                header: {
                    Text(tcKey: "add_provider_location", fallback: "Location")
                }
            }
            .navigationTitle(Text(tcKey: "add_provider_title", fallback: "Add provider"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tcString("add_provider_cancel", fallback: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(tcString("add_provider_add", fallback: "Add")) {
                        Task { await submit() }
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView().tint(.white)
                }
            }
            .alert("error_generic", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(tcString("button_ok", fallback: "OK")) { errorMessage = nil }
            } message: {
                Text(localizedErrorMessage)
            }
            .sheet(isPresented: $showSpecialtyPicker) {
                TaxonomyPickerView(
                    titleKey: "add_provider_select_specialty",
                    initialEntityType: .specialty,
                    onSelect: { selected in
                        selectedTaxonomy = selected
                        showSpecialtyPicker = false
                    }
                )
            }
            .sheet(isPresented: $showMapPicker) {
                MapPinSelectorSheet(selectedCoordinate: $selectedCoordinate)
            }
            .task(id: coordinateTaskID) {
                await refreshCoordinateSummary(for: selectedCoordinate)
            }
            .task(id: name) {
                await searchMapSuggestions()
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedTaxonomy != nil
    }

    private var coordinateTaskID: String {
        guard let selectedCoordinate else { return "none" }
        return String(format: "%.6f,%.6f", selectedCoordinate.latitude, selectedCoordinate.longitude)
    }

    private var localizedErrorMessage: String {
        guard let message = errorMessage else { return "" }
        return tcString(message, fallback: message)
    }

    private func submit() async {
        guard let selectedTaxonomy else {
            errorMessage = "add_provider_select_specialty_error"
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let coordinate: CLLocationCoordinate2D
            if let selectedCoordinate {
                coordinate = selectedCoordinate
            } else {
                coordinate = try await geocodeAddress(address)
            }

            let provider = try await ProviderService.addProvider(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                specialty: selectedTaxonomy.label,
                clinicName: nil,
                address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                city: nil,
                countryCode: "TR",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phone
            )

            onComplete(provider)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString("\(address), Türkiye")
        if let coordinate = placemarks.first?.location?.coordinate {
            return coordinate
        }
        throw AppError.validationError("add_provider_geocode_error")
    }

    private func searchMapSuggestions() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            placeSuggestions = []
            return
        }

        do {
            try await Task.sleep(nanoseconds: 300_000_000)
        } catch {
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        let center = selectedCoordinate ?? CLLocationCoordinate2D(latitude: 37.0, longitude: 35.33)
        request.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )

        let search = MKLocalSearch(request: request)

        do {
            let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MKLocalSearch.Response, Error>) in
                search.start { response, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let response else {
                        continuation.resume(throwing: AppError.unknown)
                        return
                    }
                    continuation.resume(returning: response)
                }
            }

            placeSuggestions = response.mapItems.prefix(5).map { item in
                PlaceSuggestion(
                    name: item.name ?? trimmed,
                    address: formatAddress(item.placemark),
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude
                )
            }
        } catch {
            placeSuggestions = []
        }
    }

    private func applySuggestion(_ suggestion: PlaceSuggestion) {
        name = suggestion.name
        address = suggestion.address
        selectedCoordinate = CLLocationCoordinate2D(latitude: suggestion.latitude, longitude: suggestion.longitude)
        placeSuggestions = []
    }

    private func refreshCoordinateSummary(for coordinate: CLLocationCoordinate2D?) async {
        guard let coordinate else {
            selectedCoordinateSummary = nil
            return
        }

        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                selectedCoordinateSummary = fallbackLocationSummary()
                return
            }

            let parts = [
                placemark.subLocality,
                placemark.locality,
                placemark.administrativeArea,
            ]
            .compactMap { $0 }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

            selectedCoordinateSummary = parts.isEmpty ? fallbackLocationSummary() : parts.joined(separator: ", ")
        } catch {
            selectedCoordinateSummary = fallbackLocationSummary()
        }
    }

    private func fallbackLocationSummary() -> String {
        let chunks = address
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let cityLike = chunks.last {
            return cityLike
        }

        return tcString("add_provider_location_selected", fallback: "Location selected")
    }

    private func formatAddress(_ placemark: MKPlacemark) -> String {
        let chunks = [
            placemark.thoroughfare,
            placemark.subThoroughfare,
            placemark.locality,
            placemark.administrativeArea
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        if !chunks.isEmpty {
            return chunks.joined(separator: ", ")
        }
        return placemark.title ?? tcString("add_provider_no_address", fallback: "Address unavailable")
    }
}

private struct PlaceSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

private struct MapPinSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @State private var mapCenter: CLLocationCoordinate2D

    init(selectedCoordinate: Binding<CLLocationCoordinate2D?>) {
        _selectedCoordinate = selectedCoordinate
        _mapCenter = State(initialValue: selectedCoordinate.wrappedValue ?? CLLocationCoordinate2D(latitude: 37.0000, longitude: 35.3213))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoordinatePickerMap(centerCoordinate: $mapCenter)

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Color.tcCoral)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    .offset(y: -16)
                    .allowsHitTesting(false)
            }
            .navigationTitle(Text(tcKey: "add_provider_set_map_pin", fallback: "Set map pin"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("button_ok") {
                        selectedCoordinate = mapCenter
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct CoordinatePickerMap: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator

        let region = MKCoordinateRegion(
            center: centerCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
        )
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(centerCoordinate: $centerCoordinate)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        @Binding var centerCoordinate: CLLocationCoordinate2D

        init(centerCoordinate: Binding<CLLocationCoordinate2D>) {
            _centerCoordinate = centerCoordinate
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            centerCoordinate = mapView.centerCoordinate
        }
    }
}
