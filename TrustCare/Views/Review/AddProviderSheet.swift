import CoreLocation
import MapKit
import SwiftUI

struct AddProviderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var specialtyService = SpecialtyService.shared

    let onComplete: (Provider) -> Void

    @State private var name: String = ""
    @State private var address: String = ""
    @State private var phone: String = ""
    @State private var selectedSpecialty: Specialty?
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var placeSuggestions: [PlaceSuggestion] = []

    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?
    @State private var showSpecialtyPicker: Bool = false
    @State private var showMapPicker: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Sağlayıcı") {
                    TextField("Ad", text: $name)

                    if !placeSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            ForEach(placeSuggestions) { suggestion in
                                Button {
                                    applySuggestion(suggestion)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Bu mu? \(suggestion.name)")
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
                            Text("Uzmanlık")
                            Spacer()
                            Text(selectedSpecialty?.name ?? "Seç")
                                .foregroundStyle(.secondary)
                        }
                    }

                    TextField("Adres", text: $address)
                    TextField("Telefon (opsiyonel)", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section("Konum") {
                    Button("Haritada İşaretle") {
                        showMapPicker = true
                    }

                    if let selectedCoordinate {
                        Text(String(format: "%.5f, %.5f", selectedCoordinate.latitude, selectedCoordinate.longitude))
                            .font(AppFont.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Yeni Sağlayıcı")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ekle") {
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
            .alert("Hata", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Tamam") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showSpecialtyPicker) {
                SpecialtyPickerSheet(selected: selectedSpecialty) { specialty in
                    selectedSpecialty = specialty
                    showSpecialtyPicker = false
                }
            }
            .sheet(isPresented: $showMapPicker) {
                MapPinSelectorSheet(selectedCoordinate: $selectedCoordinate)
            }
            .task {
                if specialtyService.specialties.isEmpty {
                    await specialtyService.loadSpecialties()
                }
            }
            .task(id: name) {
                await searchMapSuggestions()
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedSpecialty != nil
    }

    private func submit() async {
        guard let selectedSpecialty else {
            errorMessage = "Uzmanlık seçiniz."
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
                specialty: selectedSpecialty.name,
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
        throw AppError.validationError("Adres konumu bulunamadı.")
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
        return placemark.title ?? "Adres bilgisi yok"
    }
}

private struct PlaceSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

private struct SpecialtyPickerSheet: View {
    @ObservedObject private var specialtyService = SpecialtyService.shared
    @Environment(\.dismiss) private var dismiss

    let selected: Specialty?
    let onSelect: (Specialty) -> Void

    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredGroups, id: \.category) { group in
                    Section(group.category) {
                        ForEach(group.items) { specialty in
                            Button {
                                onSelect(specialty)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: specialty.iconName)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(specialty.name)
                                        if let nameTr = specialty.nameTr, !nameTr.isEmpty {
                                            Text(nameTr)
                                                .font(AppFont.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if specialty.id == selected?.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Uzmanlık Seç")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private var filteredGroups: [(category: String, items: [Specialty])] {
        let groups = specialtyService.specialtiesByCategory()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return groups }

        let normalized = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
        return groups.compactMap { group in
            let filtered = group.items.filter { item in
                let n1 = item.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
                let n2 = item.nameTr?.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
                return n1.contains(normalized) || (n2?.contains(normalized) ?? false)
            }
            return filtered.isEmpty ? nil : (category: group.category, items: filtered)
        }
    }
}

private struct MapPinSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCoordinate: CLLocationCoordinate2D?

    var body: some View {
        NavigationStack {
            CoordinatePickerMap(selectedCoordinate: $selectedCoordinate)
                .navigationTitle("Haritada İşaretle")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Tamam") { dismiss() }
                    }
                }
        }
    }
}

private struct CoordinatePickerMap: UIViewRepresentable {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tap)

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.0000, longitude: 35.3213),
            span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
        )
        mapView.setRegion(region, animated: false)
        context.coordinator.mapView = mapView
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        guard let selectedCoordinate else { return }
        uiView.removeAnnotations(uiView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = selectedCoordinate
        uiView.addAnnotation(annotation)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedCoordinate: $selectedCoordinate)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        @Binding var selectedCoordinate: CLLocationCoordinate2D?
        weak var mapView: MKMapView?

        init(selectedCoordinate: Binding<CLLocationCoordinate2D?>) {
            _selectedCoordinate = selectedCoordinate
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let mapView else { return }
            let point = recognizer.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            selectedCoordinate = coordinate

            mapView.removeAnnotations(mapView.annotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
    }
}
