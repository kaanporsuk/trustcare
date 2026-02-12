import CoreLocation
import SwiftUI

struct AddProviderSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onComplete: (Provider) -> Void

    @State private var name: String = ""
    @State private var clinicName: String = ""
    @State private var address: String = ""
    @State private var phone: String = ""
    @State private var selectedSpecialty: String = "General"
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?

    private let specialties = [
        "General",
        "Dentist",
        "Cardiologist",
        "Dermatologist",
        "Pediatrician",
        "Orthopedic",
        "Gynecology",
        "Psychiatry",
        "Ophthalmology",
        "ENT",
        "Urologist",
        "Neurologist",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "Provider Name"), text: $name)
                    Picker(String(localized: "Specialty"), selection: $selectedSpecialty) {
                        ForEach(specialties, id: \.self) { specialty in
                            Text(specialty).tag(specialty)
                        }
                    }
                    .pickerStyle(.menu)
                    TextField(String(localized: "Clinic / Hospital"), text: $clinicName)
                    TextField(String(localized: "Address"), text: $address)
                    TextField(String(localized: "Phone"), text: $phone)
                }

            }
            .navigationTitle(String(localized: "Add a Healthcare Provider"))
            .dismissKeyboardOnTap()
            .keyboardDoneToolbar()
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
            && !selectedSpecialty.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedAddress.isEmpty {
            errorMessage = String(localized: "Address is required to add a provider.")
            return
        }
        isSubmitting = true
        errorMessage = nil

        do {
            let coordinate = try await geocodeAddress(address: trimmedAddress)
            let provider = try await ProviderService.addProvider(
                name: trimmedName,
                specialty: selectedSpecialty,
                clinicName: clinicName.isEmpty ? nil : clinicName,
                address: trimmedAddress,
                city: nil,
                countryCode: Locale.current.region?.identifier ?? "US",
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

    private func geocodeAddress(address: String) async throws -> CLLocationCoordinate2D {
        let geocoder = CLGeocoder()
        let country = Locale.current.region?.identifier ?? "US"
        let composed = [address, country].joined(separator: ", ")

        let placemarks = try await geocoder.geocodeAddressString(composed)
        if let coordinate = placemarks.first?.location?.coordinate {
            return coordinate
        }

        throw AppError.validationError(String(localized: "Unable to locate address."))
    }
}
