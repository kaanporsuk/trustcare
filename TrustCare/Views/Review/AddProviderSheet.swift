import CoreLocation
import SwiftUI

struct AddProviderSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onComplete: (Provider) -> Void

    @State private var name: String = ""
    @State private var clinicName: String = ""
    @State private var address: String = ""
    @State private var phone: String = ""
    @State private var selectedSpecialty: Specialty?
    @State private var specialties: [Specialty] = []
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?
    @State private var showSpecialtyPicker: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "Provider Name"), text: $name)
                    Button {
                        showSpecialtyPicker = true
                    } label: {
                        HStack {
                            Text(String(localized: "Specialty"))
                            Spacer()
                            Text(selectedSpecialty?.name ?? String(localized: "Select"))
                                .foregroundStyle(.secondary)
                        }
                    }
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
            .sheet(isPresented: $showSpecialtyPicker) {
                SpecialtyPickerSheet(
                    specialties: specialties,
                    selected: selectedSpecialty,
                    onSelect: { specialty in
                        selectedSpecialty = specialty
                        showSpecialtyPicker = false
                    }
                )
            }
            .task {
                if specialties.isEmpty {
                    do {
                        specialties = try await ProviderService.fetchSpecialtiesCached()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedSpecialty != nil
            && !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let selectedSpecialty else {
            errorMessage = String(localized: "Please select a specialty.")
            return
        }
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
                specialty: selectedSpecialty.name,
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

private struct SpecialtyPickerSheet: View {
    let specialties: [Specialty]
    let selected: Specialty?
    let onSelect: (Specialty) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var expandedCategories: Set<String> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.md) {
                SearchField(text: $searchText)
                    .padding(.horizontal, AppSpacing.lg)

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        ForEach(groupedCategories, id: \.category) { group in
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { expandedCategories.contains(group.category) },
                                    set: { isExpanded in
                                        if isExpanded {
                                            expandedCategories.insert(group.category)
                                        } else {
                                            expandedCategories.remove(group.category)
                                        }
                                    }
                                )
                            ) {
                                VStack(spacing: AppSpacing.sm) {
                                    ForEach(group.specialties) { specialty in
                                        SpecialtyRow(
                                            specialty: specialty,
                                            isSelected: specialty == selected
                                        ) {
                                            onSelect(specialty)
                                            dismiss()
                                        }
                                    }
                                }
                                .padding(.top, AppSpacing.sm)
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: group.iconName)
                                        .foregroundStyle(.secondary)
                                    Text(group.category)
                                        .font(AppFont.headline)
                                    Spacer()
                                }
                            }
                            .padding(AppSpacing.md)
                            .background(AppColor.cardBackground)
                            .cornerRadius(AppRadius.card)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .navigationTitle(String(localized: "Specialty"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Close")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                expandedCategories = Set(groupedCategories.map { $0.category })
            }
        }
    }

    private var groupedCategories: [(category: String, iconName: String, specialties: [Specialty])] {
        let filtered = specialties.filter { specialty in
            guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }
            let query = searchText.lowercased()
            return specialty.name.lowercased().contains(query)
                || specialty.category.lowercased().contains(query)
                || (specialty.subcategory?.lowercased().contains(query) ?? false)
        }

        let grouped = Dictionary(grouping: filtered, by: { $0.category })
        return grouped.keys.sorted().compactMap { category in
            guard let items = grouped[category] else { return nil }
            let sorted = items.sorted { $0.displayOrder < $1.displayOrder }
            let icon = sorted.first?.iconName ?? "stethoscope"
            return (category: category, iconName: icon, specialties: sorted)
        }
    }
}

private struct SpecialtyRow: View {
    let specialty: Specialty
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: specialty.iconName)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(specialty.name)
                        .font(AppFont.body)
                        .foregroundStyle(.primary)
                    if let subcategory = specialty.subcategory, !subcategory.isEmpty {
                        Text(subcategory)
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(AppColor.trustBlue)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColor.background)
            .cornerRadius(AppRadius.standard)
        }
        .buttonStyle(.plain)
    }
}

private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(String(localized: "Search specialties"), text: $text)
                .font(AppFont.body)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
    }
}
