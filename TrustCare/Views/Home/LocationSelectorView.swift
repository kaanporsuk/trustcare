import SwiftUI

struct LocationSelectorView: View {
    let selectedLocation: HomeViewModel.SelectedLocation
    let onUseCurrentLocation: () async -> Void
    let onSelectCity: (HomeViewModel.CityOption) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("search_placeholder", text: $searchText)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 44)
                .background(Color.tcSurface)
                .cornerRadius(AppRadius.button)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.button)
                        .stroke(Color.tcBorder, lineWidth: 1)
                )
                .padding(.horizontal, AppSpacing.lg)

                List {
                    Button {
                        Task {
                            await onUseCurrentLocation()
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "location.fill")
                                .foregroundStyle(Color.tcOcean)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("current_location")
                                    .font(AppFont.body)
                                    .foregroundStyle(.primary)
                                Text("use_device_location")
                                    .font(AppFont.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedLocation.isCurrentLocation {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.tcOcean)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    ForEach(filteredCities) { city in
                        Button {
                            Task {
                                await onSelectCity(city)
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "building.2")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(city.name)
                                        .font(AppFont.body)
                                        .foregroundStyle(.primary)
                                    Text(String(format: "%.2f, %.2f", city.latitude, city.longitude))
                                        .font(AppFont.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if !selectedLocation.isCurrentLocation,
                                   selectedLocation.name == city.name {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.tcOcean)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
            .background(Color.tcBackground)
            .navigationTitle("location_select_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close_button") { dismiss() }
                }
            }
        }
    }

    private var filteredCities: [HomeViewModel.CityOption] {
        let query = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))

        guard !query.isEmpty else {
            return HomeViewModel.majorTurkishCities
        }

        return HomeViewModel.majorTurkishCities.filter { city in
            city.name
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
                .contains(query)
        }
    }
}
