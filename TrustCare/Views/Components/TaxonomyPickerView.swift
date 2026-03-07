import SwiftUI
import Combine

@MainActor
final class TaxonomyPickerViewModel: ObservableObject {
    @Published var selectedEntityType: TaxonomyEntityType
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var suggestions: [TaxonomySuggestion] = []
    @Published var allItems: [TaxonomySuggestion] = []
    @Published var recentItems: [TaxonomySuggestion] = []
    @Published var topPickItems: [TaxonomySuggestion] = []
    @Published var showEnglishFallbackHint: Bool = false

    private var searchTask: Task<Void, Never>?

    private static let searchCache = TaxonomySearchCache()
    private static let recentStorageKey = "taxonomy_picker_recents_v1"
    private static let maxRecentCount = 8
    private static let maxCacheEntries = 120

    init(initialEntityType: TaxonomyEntityType = .specialty) {
        self.selectedEntityType = initialEntityType
    }

    func refreshForCurrentType(localeCode: String) async {
        await loadCuratedContent(localeCode: localeCode)
        await runSearchIfNeeded(localeCode: localeCode)
    }

    func handleEntityTypeChanged(localeCode: String) async {
        showEnglishFallbackHint = false
        await loadCuratedContent(localeCode: localeCode)
        await runSearchIfNeeded(localeCode: localeCode)
    }

    func handleSearchTextChanged(localeCode: String, debounceNanoseconds: UInt64 = 300_000_000) {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: debounceNanoseconds)
            } catch {
                return
            }
            guard let self else { return }
            await self.runSearchIfNeeded(localeCode: localeCode)
        }
    }

    func registerSelection(_ suggestion: TaxonomySuggestion, localeCode: String) async {
        saveRecentEntityID(suggestion.entityId, for: selectedEntityType)
        await loadCuratedContent(localeCode: localeCode)
    }

    private func runSearchIfNeeded(localeCode: String) async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            suggestions = []
            showEnglishFallbackHint = false
            return
        }

        let cacheKey = "\(localeCode)|\(selectedEntityType.rawValue)|\(query.lowercased())"
        if let cached = await Self.searchCache.value(for: cacheKey) {
            suggestions = cached.suggestions
            showEnglishFallbackHint = cached.usedEnglishFallback
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await TaxonomyService.searchTaxonomyWithLocaleFallback(
                query: query,
                locale: localeCode,
                entityTypeFilter: selectedEntityType,
                limit: 50
            )
            suggestions = dedupeSuggestions(result.suggestions)
            showEnglishFallbackHint = result.usedEnglishFallback
            await Self.searchCache.set(
                key: cacheKey,
                value: CachedSearchResult(
                    suggestions: dedupeSuggestions(result.suggestions),
                    usedEnglishFallback: result.usedEnglishFallback
                ),
                maxEntries: Self.maxCacheEntries
            )
        } catch {
            suggestions = []
            showEnglishFallbackHint = false
        }
    }

    private func loadCuratedContent(localeCode: String) async {
        async let recents = resolveRecents(localeCode: localeCode)
        async let topPicks = resolveTopPicks(localeCode: localeCode)
        async let all = resolveAll(localeCode: localeCode)

        let recentsValue = dedupeSuggestions(await recents)
        var seen = Set(recentsValue.map(\.entityId))

        let topPicksValue = dedupeSuggestions(await topPicks).filter { suggestion in
            seen.insert(suggestion.entityId).inserted
        }

        let allValue = dedupeSuggestions(await all).filter { suggestion in
            seen.insert(suggestion.entityId).inserted
        }

        recentItems = recentsValue
        topPickItems = topPicksValue
        allItems = allValue
    }

    private func dedupeSuggestions(_ items: [TaxonomySuggestion]) -> [TaxonomySuggestion] {
        var seenEntityIDs = Set<String>()
        var seenDisplayKeys = Set<String>()
        var ordered: [TaxonomySuggestion] = []

        for item in items {
            if !seenEntityIDs.insert(item.entityId).inserted { continue }

            let displayKey = "\(item.entityType.lowercased())|\(normalizedDisplayLabel(item.label))"
            if !seenDisplayKeys.insert(displayKey).inserted { continue }

            ordered.append(item)
        }

        return ordered
    }

    private func normalizedDisplayLabel(_ label: String) -> String {
        label
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    private func resolveRecents(localeCode: String) async -> [TaxonomySuggestion] {
        let ids = recentEntityIDs(for: selectedEntityType)
        guard !ids.isEmpty else { return [] }

        do {
            let labels = try await TaxonomyService.labelsByEntityID(entityIDs: ids, locale: localeCode)
            return ids.map { entityID in
                TaxonomySuggestion(
                    entityId: entityID,
                    entityType: selectedEntityType.rawValue,
                    label: labels[entityID] ?? entityID,
                    score: nil
                )
            }
        } catch {
            return ids.map {
                TaxonomySuggestion(entityId: $0, entityType: selectedEntityType.rawValue, label: $0, score: nil)
            }
        }
    }

    private func resolveTopPicks(localeCode: String) async -> [TaxonomySuggestion] {
        let ids = topPickIDs(for: selectedEntityType)
        guard !ids.isEmpty else { return [] }

        do {
            let labels = try await TaxonomyService.labelsByEntityID(entityIDs: ids, locale: localeCode)
            return ids.map { entityID in
                TaxonomySuggestion(
                    entityId: entityID,
                    entityType: selectedEntityType.rawValue,
                    label: labels[entityID] ?? entityID,
                    score: nil
                )
            }
        } catch {
            return ids.map {
                TaxonomySuggestion(entityId: $0, entityType: selectedEntityType.rawValue, label: $0, score: nil)
            }
        }
    }

    private func resolveAll(localeCode: String) async -> [TaxonomySuggestion] {
        do {
            return try await TaxonomyService.browseTaxonomy(entityType: selectedEntityType, locale: localeCode, limit: 120)
        } catch {
            return []
        }
    }

    private func topPickIDs(for type: TaxonomyEntityType) -> [String] {
        switch type {
        case .specialty:
            return [
                "SPEC_GENERAL_PRACTICE",
                "SPEC_DERMATOLOGY",
                "SPEC_ENT",
                "SPEC_CARDIOLOGY",
                "SPEC_OBGYN",
                "SPEC_DENTISTRY_GENERAL",
                "SPEC_ORTHOPEDIC_SURGERY",
                "SPEC_PSYCHIATRY"
            ]
        case .treatmentProcedure:
            return [
                "SERV_BOTOX_FILLERS",
                "SERV_LASIK_REFRACTIVE",
                "SERV_HAIR_TRANSPLANT",
                "SERV_PRP_SKIN_REJUVENATION",
                "SERV_LASER_TREATMENTS"
            ]
        case .facilityType:
            return [
                "FAC_HOSPITAL_GENERAL",
                "FAC_URGENT_CARE",
                "FAC_LABORATORY",
                "FAC_PHARMACY"
            ]
        case .symptomConcern:
            return []
        }
    }

    private func recentEntityIDs(for type: TaxonomyEntityType) -> [String] {
        let storage = loadRecentStorage()
        return storage[type.storageKey] ?? []
    }

    private func saveRecentEntityID(_ entityID: String, for type: TaxonomyEntityType) {
        var storage = loadRecentStorage()
        var current = storage[type.storageKey] ?? []
        current.removeAll { $0 == entityID }
        current.insert(entityID, at: 0)
        if current.count > Self.maxRecentCount {
            current = Array(current.prefix(Self.maxRecentCount))
        }
        storage[type.storageKey] = current

        if let data = try? JSONEncoder().encode(storage) {
            UserDefaults.standard.set(data, forKey: Self.recentStorageKey)
        }
    }

    private func loadRecentStorage() -> [String: [String]] {
        guard let data = UserDefaults.standard.data(forKey: Self.recentStorageKey),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }
        return decoded
    }
}

private struct CachedSearchResult {
    let suggestions: [TaxonomySuggestion]
    let usedEnglishFallback: Bool
}

private actor TaxonomySearchCache {
    private var storage: [String: CachedSearchResult] = [:]
    private var insertionOrder: [String] = []

    func value(for key: String) -> CachedSearchResult? {
        storage[key]
    }

    func set(key: String, value: CachedSearchResult, maxEntries: Int) {
        if storage[key] == nil {
            insertionOrder.append(key)
        }
        storage[key] = value

        while insertionOrder.count > maxEntries {
            let oldest = insertionOrder.removeFirst()
            storage.removeValue(forKey: oldest)
        }
    }
}

struct TaxonomyPickerView: View {
    let titleKey: LocalizedStringKey
    let onSelect: (TaxonomySuggestion) -> Void
    let onClear: (() -> Void)?
    let initialEntityType: TaxonomyEntityType

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var viewModel: TaxonomyPickerViewModel

    init(
        titleKey: LocalizedStringKey,
        initialEntityType: TaxonomyEntityType = .specialty,
        onSelect: @escaping (TaxonomySuggestion) -> Void,
        onClear: (() -> Void)? = nil
    ) {
        self.titleKey = titleKey
        self.initialEntityType = initialEntityType
        self.onSelect = onSelect
        self.onClear = onClear
        _viewModel = StateObject(wrappedValue: TaxonomyPickerViewModel(initialEntityType: initialEntityType))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.md) {
                if let onClear {
                    HStack {
                        Button("clear_filter") {
                            onClear()
                            dismiss()
                        }
                        .font(AppFont.caption)
                        .foregroundStyle(Color.tcOcean)

                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }

                Picker("", selection: $viewModel.selectedEntityType) {
                    ForEach(TaxonomyEntityType.pickerCases) { entityType in
                        Text(LocalizedStringKey(entityType.segmentTitleKey))
                            .tag(entityType)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.lg)

                taxonomySearchField
                    .padding(.horizontal, AppSpacing.lg)

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, AppSpacing.md)
                        }

                        if viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            if !viewModel.recentItems.isEmpty {
                                section(titleKey: "recents", items: viewModel.recentItems)
                            }

                            if !viewModel.topPickItems.isEmpty {
                                section(titleKey: "top_picks", items: viewModel.topPickItems)
                            }

                            section(titleKey: "all", items: viewModel.allItems)
                        } else if viewModel.suggestions.isEmpty {
                            emptySearchGuidance
                        } else {
                            if viewModel.showEnglishFallbackHint {
                                Text("showing_english_results")
                                    .font(AppFont.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, AppSpacing.xs)
                            }
                            taxonomyRows(viewModel.suggestions)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .navigationTitle(LocalizedStringKey(viewModel.selectedEntityType.segmentTitleKey))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tcString("close_button", fallback: "Close")) { dismiss() }
                }
            }
            .task(id: localizationManager.effectiveLanguage) {
                await viewModel.refreshForCurrentType(localeCode: currentLocaleCode())
            }
            .onChange(of: viewModel.selectedEntityType) { _, _ in
                Task {
                    await viewModel.handleEntityTypeChanged(localeCode: currentLocaleCode())
                }
            }
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.handleSearchTextChanged(localeCode: currentLocaleCode())
            }
        }
    }

    private var taxonomySearchField: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(
                LocalizedStringKey(viewModel.selectedEntityType.searchPlaceholderKey),
                text: $viewModel.searchText
            )
            .font(AppFont.body)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
        }
        .padding(AppSpacing.md)
        .background(Color.tcSurface)
        .cornerRadius(AppRadius.card)
    }

    private func section(titleKey: LocalizedStringKey, items: [TaxonomySuggestion]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(titleKey)
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.xs)

            taxonomyRows(items)
        }
    }

    private func taxonomyRows(_ items: [TaxonomySuggestion]) -> some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(items) { suggestion in
                Button {
                    Task {
                        await viewModel.registerSelection(suggestion, localeCode: currentLocaleCode())
                        onSelect(suggestion)
                        dismiss()
                    }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "cross.case")
                            .foregroundStyle(.secondary)
                        Text(suggestion.label)
                            .font(AppFont.body)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(AppSpacing.md)
                    .background(Color.tcSurface)
                    .cornerRadius(AppRadius.card)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptySearchGuidance: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("no_results")
                .font(AppFont.body)
                .foregroundStyle(.primary)
            Text("try_english_keywords")
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)
            Text("switch_category_hint")
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(Color.tcSurface)
        .cornerRadius(AppRadius.card)
    }

    private func currentLocaleCode() -> String {
        return localizationManager.effectiveLanguage
            .components(separatedBy: ["-", "_"])
            .first?
            .lowercased() ?? "en"
    }
}
