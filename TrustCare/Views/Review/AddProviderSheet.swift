import CoreLocation
import SwiftUI

struct AddProviderSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onComplete: (Provider) -> Void

    @State private var name: String = ""
    @State private var clinicName: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var countryCode: String = Locale.current.region?.identifier ?? "US"
    @State private var phone: String = ""
    @State private var specialties: [Specialty] = []
    @State private var selectedSpecialtyId: Int?
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "Full Name"), text: $name)
                    Picker(String(localized: "Specialty"), selection: $selectedSpecialtyId) {
                        if specialties.isEmpty {
                            Text(String(localized: "Loading...")).tag(Optional<Int>.none)
                        } else {
                            ForEach(specialties) { specialty in
                                Text(specialty.nameEn).tag(Optional(specialty.id))
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(specialties.isEmpty)
                    TextField(String(localized: "Clinic / Hospital"), text: $clinicName)
                    TextField(String(localized: "Address"), text: $address)
                    TextField(String(localized: "City"), text: $city)
                    TextField(String(localized: "Country"), text: $countryCode)
                    TextField(String(localized: "Phone"), text: $phone)
                }

            }
            .navigationTitle(String(localized: "Add a Healthcare Provider"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Add Provider")) {
                        Task { await submit() }
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                }
            }
            .task {
                await loadSpecialties()
            }
            .alert(String(localized: "Error"), isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(String(localized: "Done")) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedSpecialtyId != nil
            && !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadSpecialties() async {
        do {
            specialties = try await ProviderService.fetchSpecialties()
            if selectedSpecialtyId == nil {
                selectedSpecialtyId = specialties.first?.id
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func submit() async {
          guard let selectedId = selectedSpecialtyId,
              let specialty = specialties.first(where: { $0.id == selectedId }) else { return }
        isSubmitting = true
        errorMessage = nil

        do {
            let coordinate = try await geocodeAddress()
            let provider = try await ProviderService.addProvider(
                name: name,
                specialty: specialty.nameEn,
                clinicName: clinicName.isEmpty ? nil : clinicName,
                address: address,
                city: city.isEmpty ? nil : city,
                countryCode: countryCode.isEmpty ? "US" : countryCode,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                phone: phone.isEmpty ? nil : phone
            )
            onComplete(provider)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    private func geocodeAddress() async throws -> CLLocationCoordinate2D {
        let geocoder = CLGeocoder()
        let composed = [address, city, countryCode]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: ", ")

        let placemarks = try await geocoder.geocodeAddressString(composed)
        if let coordinate = placemarks.first?.location?.coordinate {
            return coordinate
        }

        throw AppError.validationError(String(localized: "Unable to locate address."))
    }
}
