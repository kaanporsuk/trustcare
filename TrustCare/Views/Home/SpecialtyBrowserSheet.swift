import SwiftUI

struct SpecialtyBrowserSheet: View {
    @Environment(\.locale) private var locale
    let onSelect: (TaxonomySuggestion) -> Void
    let onClear: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var selectedEntityType: TaxonomyEntityType = .specialty
    @State private var suggestions: [TaxonomySuggestion] = []
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.md) {
                HStack {
                    Button("clear_filter") {
                        onClear()
                    }
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.trustBlue)

                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)

                Picker("", selection: $selectedEntityType) {
                    ForEach(TaxonomyEntityType.allCases) { entityType in
                        Text(LocalizedStringKey(entityType.segmentTitleKey))
                            .tag(entityType)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.lg)

                SearchField(
                    text: $searchText,
                    placeholderKey: selectedEntityType.searchPlaceholderKey
                )
                    .padding(.horizontal, AppSpacing.lg)

                ScrollView {
                    VStack(spacing: AppSpacing.sm) {
                        if isLoading {
                            ProgressView()
                                .padding(.top, AppSpacing.md)
                        } else if suggestions.isEmpty,
                                  !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("empty_search")
                                .font(AppFont.body)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, AppSpacing.md)
                        } else {
                            ForEach(suggestions) { suggestion in
                                TaxonomySuggestionRow(label: suggestion.label) {
                                    onSelect(suggestion)
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .navigationTitle("specialties_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close_button") {
                        dismiss()
                    }
                }
            }
            .task(id: selectedEntityType) {
                await runSearch()
            }
            .task(id: searchText) {
                await runSearch()
            }
        }
    }

    private func runSearch() async {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            return
        }

        do {
            try await Task.sleep(nanoseconds: 250_000_000)
        } catch {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let localeCode = currentLocaleCode()
            suggestions = try await TaxonomyService.searchTaxonomy(
                query: trimmed,
                locale: localeCode,
                entityTypeFilter: selectedEntityType,
                limit: 50
            )
        } catch {
            suggestions = []
        }
    }

    private func currentLocaleCode() -> String {
        if let languageCode = locale.language.languageCode?.identifier, !languageCode.isEmpty {
            return languageCode
        }
        return locale.identifier
            .components(separatedBy: ["-", "_"])
            .first?
            .lowercased() ?? "en"
    }
}

private struct TaxonomySuggestionRow: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "cross.case")
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(AppFont.body)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(AppColor.cardBackground)
            .cornerRadius(AppRadius.card)
        }
        .buttonStyle(.plain)
    }
}

private struct SearchField: View {
    @Binding var text: String
    let placeholderKey: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(LocalizedStringKey(placeholderKey), text: $text)
                .font(AppFont.body)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
    }
}

private struct LegacySpecialtyRow: View {
    let specialty: Specialty
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: safeIconName(specialty.iconName))
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
