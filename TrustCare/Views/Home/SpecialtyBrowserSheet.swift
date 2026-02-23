import SwiftUI

struct SpecialtyBrowserSheet: View {
    @ObservedObject private var specialtyService = SpecialtyService.shared
    @EnvironmentObject private var localizationManager: LocalizationManager
    let selectedSpecialty: Specialty?
    let onSelect: (Specialty) -> Void
    let onClear: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var expandedCategories: Set<String> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.md) {
                HStack {
                    Button(String(localized: "Clear Filter")) {
                        onClear()
                    }
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.trustBlue)

                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)

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
                                            isSelected: specialty == selectedSpecialty
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
                                    Text(localizationManager.localizedCategory(group.category))
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
            .navigationTitle(String(localized: "specialties_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "close_button")) {
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
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))

        let filtered = specialtyService.specialties.filter { specialty in
            guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }
            return specialty.matchesSearch(query)
        }

        let grouped = Dictionary(grouping: filtered, by: { $0.category })
        let sortedCategories = grouped.keys.sorted {
            let left = grouped[$0]?.map { $0.displayOrder }.min() ?? 0
            let right = grouped[$1]?.map { $0.displayOrder }.min() ?? 0
            if left == right {
                return $0 < $1
            }
            return left < right
        }

        return sortedCategories.compactMap { category in
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
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: specialty.iconName)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(specialty.resolvedName(using: localizationManager))
                        .font(AppFont.body)
                        .foregroundStyle(.primary)
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
