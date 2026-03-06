import SwiftUI
import CoreLocation

struct HomeView: View {
    @StateObject private var homeVM = HomeViewModel()
    @ObservedObject private var specialtyService = SpecialtyService.shared
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var localizationManager: LocalizationManager

    @State private var showLocationSearch = false
    @State private var resultsDetent: ResultsSheetDetent = .medium
    @State private var showSearchOverlay = false
    @State private var selectedProviderID: UUID?

    @State private var activeFilterSheet: ActiveFilterSheet?
    @State private var selectedSpecialtyIDs = Set<String>()
    @State private var selectedServiceIDs = Set<String>()
    @State private var selectedFacilityIDs = Set<String>()
    @State private var selectedDistanceKm = 50
    @State private var selectedLanguages = Set<String>()
    @State private var verifiedOnly = false

    @State private var recentSearches = [String]()

    private let recentSearchesKey = "discover_recent_searches_v1"

    private enum ActiveFilterSheet: String, Identifiable {
        case specialty
        case treatment
        case facility
        case distance
        case language
        case verified

        var id: String { rawValue }
    }

    private var displayedProviders: [Provider] {
        homeVM.providers.filter { provider in
            if selectedDistanceKm < 50, let distance = provider.distanceKm, distance > Double(selectedDistanceKm) {
                return false
            }

            if verifiedOnly && provider.verifiedReviewCount == 0 {
                return false
            }

            if !selectedLanguages.isEmpty {
                let spoken = Set((provider.languagesSpoken ?? []).map { $0.lowercased() })
                if spoken.isDisjoint(with: Set(selectedLanguages.map { $0.lowercased() })) {
                    return false
                }
            }

            return true
        }
    }

    private var hasAnyActiveFilter: Bool {
        !selectedSpecialtyIDs.isEmpty
            || !selectedServiceIDs.isEmpty
            || !selectedFacilityIDs.isEmpty
            || selectedDistanceKm != 50
            || !selectedLanguages.isEmpty
            || verifiedOnly
            || homeVM.hasActiveCanonicalFilter
    }

    private var selectedCityName: String {
        homeVM.selectedLocation.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isRegionLikelyNew: Bool {
        let majorCityNames = Set(HomeViewModel.majorTurkishCities.map { $0.name.lowercased() })
        return !selectedCityName.isEmpty && !majorCityNames.contains(selectedCityName.lowercased())
    }

    private var cityCoverage: [(name: String, count: Int)] {
        let grouped = Dictionary(grouping: homeVM.providers) { provider in
            provider.city?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? provider.city!.trimmingCharacters(in: .whitespacesAndNewlines)
                : "Unknown"
        }
        return grouped
            .map { ($0.key, $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.name < rhs.name
                }
                return lhs.count > rhs.count
            }
    }

    private var languageOptions: [String] {
        let langs = homeVM.providers.flatMap { $0.languagesSpoken ?? [] }
        return Array(Set(langs.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }))
            .filter { !$0.isEmpty }
            .sorted()
    }

    private var currentSelectionCountForActiveTaxonomyFilter: Int {
        selectedSpecialtyIDs.count + selectedServiceIDs.count + selectedFacilityIDs.count
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack(alignment: .top) {
                    ProviderMapView(
                        viewModel: homeVM,
                        providers: displayedProviders,
                        selectedProviderID: $selectedProviderID,
                        allowsMapInteraction: resultsDetent != .large,
                        onOpenProvider: { provider in
                            selectedProviderID = provider.id
                        }
                    )

                    VStack(spacing: AppSpacing.sm) {
                        headerBar
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.top, AppSpacing.sm)
                    }
                    .zIndex(3)

                    if showSearchOverlay {
                        searchOverlay
                            .padding(.top, 84)
                            .padding(.horizontal, AppSpacing.md)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .zIndex(4)
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    ResultsBottomSheet(
                        detent: $resultsDetent,
                        availableHeight: proxy.size.height
                    ) {
                        mapResultsSheet
                    }
                }
            }
            .navigationBarHidden(true)
            .dismissKeyboardOnTap()
            .keyboardDoneToolbar()
            .task(id: homeVM.searchText) {
                guard homeVM.hasLoadedInitially else { return }
                await homeVM.searchWithDebounce()
            }
            .task(id: localizationManager.effectiveLanguage) {
                await homeVM.reloadSmartPillsForCurrentLocale()
            }
            .task {
                appRouter.registerHomeViewModel(homeVM)
                homeVM.startLocationUpdates()
                await homeVM.onAppear()
                loadRecentSearches()
                selectedDistanceKm = homeVM.selectedRadiusKm
            }
            .onDisappear {
                appRouter.unregisterHomeViewModel(homeVM)
            }
            .onChange(of: homeVM.providers) { _, newProviders in
                if let selectedProviderID,
                   !newProviders.contains(where: { $0.id == selectedProviderID }) {
                    self.selectedProviderID = nil
                }
            }
            .sheet(isPresented: $showLocationSearch) {
                LocationSelectorView(
                    selectedLocation: homeVM.selectedLocation,
                    onUseCurrentLocation: {
                        await homeVM.useCurrentLocation()
                    },
                    onSelectCity: { city in
                        let location = HomeViewModel.SelectedLocation(
                            name: city.name,
                            latitude: city.latitude,
                            longitude: city.longitude,
                            isCurrentLocation: false
                        )
                        await homeVM.selectLocation(location)
                    }
                )
            }
            .sheet(item: $activeFilterSheet) { sheet in
                switch sheet {
                case .specialty:
                    taxonomyFilterSheet(titleKey: "filter_specialty_title", titleFallback: "Specialty", entityType: .specialty, selectedIDs: $selectedSpecialtyIDs)
                case .treatment:
                    taxonomyFilterSheet(titleKey: "filter_treatment_title", titleFallback: "Treatment", entityType: .service, selectedIDs: $selectedServiceIDs)
                case .facility:
                    taxonomyFilterSheet(titleKey: "filter_facility_title", titleFallback: "Facility", entityType: .facility, selectedIDs: $selectedFacilityIDs)
                case .distance:
                    distanceFilterSheet
                case .language:
                    languageFilterSheet
                case .verified:
                    verifiedFilterSheet
                }
            }
        }
    }

    private var headerBar: some View {
        VStack(spacing: AppSpacing.sm) {
            TCSearchBar(
                text: $homeVM.searchText,
                placeholderKey: "search_placeholder",
                placeholderFallback: "Search specialties, treatments, clinics"
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showSearchOverlay = true
                }
            }

            HStack(spacing: AppSpacing.xs) {
                Button {
                    showSearchOverlay = false
                    showLocationSearch = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                        Text(selectedCityName.isEmpty ? tcString("find_set_location", fallback: "Set location") : selectedCityName)
                            .lineLimit(1)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.tcTextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.tcSurface.opacity(0.92))
                    .clipShape(Capsule())
                    .overlay {
                        Capsule().stroke(Color.tcBorder, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                if currentSelectionCountForActiveTaxonomyFilter > 0 {
                    Text(String(format: tcString("filters_count_format", fallback: "%lld filters"), currentSelectionCountForActiveTaxonomyFilter))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.tcOcean)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    TCFilterChip(title: tcString("chip_specialty", fallback: "Specialty"), isSelected: !selectedSpecialtyIDs.isEmpty) {
                        showSearchOverlay = false
                        activeFilterSheet = .specialty
                    }
                    TCFilterChip(title: tcString("chip_treatment", fallback: "Treatment"), isSelected: !selectedServiceIDs.isEmpty) {
                        showSearchOverlay = false
                        activeFilterSheet = .treatment
                    }
                    TCFilterChip(title: tcString("chip_facility", fallback: "Facility"), isSelected: !selectedFacilityIDs.isEmpty) {
                        showSearchOverlay = false
                        activeFilterSheet = .facility
                    }
                    TCFilterChip(title: tcString("chip_distance", fallback: "Distance"), isSelected: selectedDistanceKm != 50) {
                        showSearchOverlay = false
                        activeFilterSheet = .distance
                    }
                    TCFilterChip(title: tcString("chip_language", fallback: "Language"), isSelected: !selectedLanguages.isEmpty) {
                        showSearchOverlay = false
                        activeFilterSheet = .language
                    }
                    TCFilterChip(title: tcString("filter_verified", fallback: "Verified"), isSelected: verifiedOnly) {
                        showSearchOverlay = false
                        activeFilterSheet = .verified
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .tcGlassBackground()
    }

    private var mapResultsSheet: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(tcKey: "providers_title", fallback: "Providers")
                    .font(.headline)
                Spacer()
                Text("\(displayedProviders.count)")
                    .font(.subheadline)
                    .foregroundStyle(Color.tcTextSecondary)
            }
            .padding(.horizontal, AppSpacing.md)

            if displayedProviders.isEmpty {
                sheetEmptyState
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.sm) {
                        ForEach(displayedProviders, id: \.id) { provider in
                            TCProviderCard(
                                provider: provider,
                                localizedSpecialty: localizedProviderSpecialty(provider)
                            ) {
                                ProviderDetailView(providerId: provider.id)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.card)
                                    .stroke(
                                        selectedProviderID == provider.id ? Color.tcOcean : Color.clear,
                                        lineWidth: 2
                                    )
                            }
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    selectedProviderID = provider.id
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
        }
        .padding(.top, AppSpacing.sm)
        .background(Color.tcBackground)
    }

    @ViewBuilder
    private var sheetEmptyState: some View {
        if hasAnyActiveFilter {
            TCEmptyState(
                variant: .noResults,
                primaryTitle: tcString("find_empty_clear_filters", fallback: "Clear filters"),
                secondaryTitle: tcString("find_empty_search_another_area", fallback: "Search another area"),
                onPrimary: {
                    Task { await clearAllFilters() }
                },
                onSecondary: {
                    showLocationSearch = true
                }
            )
        } else if isRegionLikelyNew {
            TCEmptyState(
                variant: .noProviders,
                customTitle: tcString("empty_no_providers_title", fallback: "No providers available"),
                customBody: tcString("empty_no_providers_body", fallback: "Try searching another area or changing city."),
                primaryTitle: tcString("cta_change_city", fallback: "Change city"),
                secondaryTitle: tcString("cta_suggest_provider", fallback: "Suggest a provider"),
                onPrimary: {
                    showLocationSearch = true
                },
                onSecondary: {
                    openSuggestProviderFlow()
                }
            )
            .overlay(alignment: .topLeading) {
                Text(tcKey: "bul_growing_here_label", fallback: "TrustCare is growing here")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.tcSage)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.tcSage.opacity(0.14))
                    .clipShape(Capsule())
                    .offset(y: -10)
            }
        } else {
            TCEmptyState(
                variant: .noProviders,
                customTitle: tcString("empty_no_providers_title", fallback: "No providers available"),
                customBody: tcString("empty_no_providers_body", fallback: "Try searching another area or changing city."),
                primaryTitle: tcString("cta_change_city", fallback: "Change city"),
                secondaryTitle: tcString("cta_suggest_provider", fallback: "Suggest a provider"),
                onPrimary: {
                    showLocationSearch = true
                },
                onSecondary: {
                    openSuggestProviderFlow()
                }
            )
        }
    }

    private var mapEmptyStateCard: some View {
        Group {
            if hasAnyActiveFilter {
                stateBCard
            } else if isRegionLikelyNew {
                stateCCard
            } else {
                stateACard
            }
        }
    }

    private var stateACard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tcKey: "find_state_no_providers_visible", fallback: "No providers visible in this map area")
                .font(.headline)
            Text(tcKey: "empty_no_providers_body", fallback: "Try searching another area or changing city.")
                .font(.subheadline)
                .foregroundStyle(Color.tcTextSecondary)
            HStack(spacing: AppSpacing.sm) {
                TCPrimaryButton(title: tcString("cta_change_city", fallback: "Change city"), fullWidth: false) {
                    showLocationSearch = true
                }
                Button(tcString("cta_suggest_provider", fallback: "Suggest a provider")) {
                    openSuggestProviderFlow()
                }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.tcOcean)
            }
        }
        .padding(AppSpacing.md)
        .background(Color.tcSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var stateBCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tcKey: "find_state_clear_filters_title", fallback: "No results match these filters")
                .font(.headline)
            Text(tcKey: "find_state_clear_filters_body", fallback: "Clear one or more filters, or move the map to expand results.")
                .font(.subheadline)
                .foregroundStyle(Color.tcTextSecondary)
            HStack(spacing: AppSpacing.sm) {
                TCPrimaryButton(title: tcString("find_empty_clear_filters", fallback: "Clear filters"), fullWidth: false) {
                    Task { await clearAllFilters() }
                }
                Button(tcString("find_state_search_another_area", fallback: "Search another area")) {
                    showLocationSearch = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tcOcean)
            }
        }
        .padding(AppSpacing.md)
        .background(Color.tcSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var stateCCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tcKey: "find_state_growing_title", fallback: "TrustCare is growing here")
                .font(.headline)
                .foregroundStyle(Color.tcSage)
            Text(tcKey: "empty_no_providers_body", fallback: "Try searching another area or changing city.")
                .font(.subheadline)
                .foregroundStyle(Color.tcTextSecondary)
            HStack(spacing: AppSpacing.sm) {
                TCPrimaryButton(title: tcString("cta_change_city", fallback: "Change city"), fullWidth: false) {
                    showLocationSearch = true
                }
                Button(tcString("cta_suggest_provider", fallback: "Suggest a provider")) {
                    openSuggestProviderFlow()
                }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.tcOcean)
            }
        }
        .padding(AppSpacing.md)
        .background(Color.tcSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var searchOverlay: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if homeVM.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                popularNearYouSection

                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Recent searches")
                            .font(.caption)
                            .foregroundStyle(Color.tcTextSecondary)
                        ForEach(recentSearches, id: \.self) { query in
                            Button {
                                homeVM.searchText = query
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                    Text(query)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .foregroundStyle(Color.tcTextPrimary)
                                .font(.subheadline)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Browse by city")
                        .font(.caption)
                        .foregroundStyle(Color.tcTextSecondary)

                    ForEach(cityCoverage.prefix(6), id: \.name) { item in
                        Button {
                            if let city = HomeViewModel.majorTurkishCities.first(where: { $0.name == item.name }) {
                                Task {
                                    await homeVM.selectLocation(
                                        HomeViewModel.SelectedLocation(
                                            name: city.name,
                                            latitude: city.latitude,
                                            longitude: city.longitude,
                                            isCurrentLocation: false
                                        )
                                    )
                                    showSearchOverlay = false
                                }
                            } else {
                                showLocationSearch = true
                            }
                        } label: {
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text("\(item.count)")
                                    .foregroundStyle(Color.tcTextSecondary)
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.tcTextPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    ForEach(homeVM.taxonomySuggestions, id: \.id) { suggestion in
                        Button {
                            Task {
                                await homeVM.applyTaxonomySuggestion(suggestion)
                                saveRecentSearch(homeVM.searchText)
                                showSearchOverlay = false
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.label)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.tcTextPrimary)
                                    Text(typeLabel(for: suggestion.entityType))
                                        .font(.caption)
                                        .foregroundStyle(Color.tcTextSecondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tcSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.tcBorder, lineWidth: 1)
        }
    }

    private var popularNearYouSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Popular near you")
                .font(.caption)
                .foregroundStyle(Color.tcTextSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(homeVM.smartPills.prefix(8)) { pill in
                        Button {
                            Task {
                                await homeVM.applySmartPill(entityID: pill.entityID)
                                saveRecentSearch(pill.label)
                                showSearchOverlay = false
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: iconName(for: pill.entityID))
                                Text(pill.label)
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.tcTextPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.tcBackground)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func taxonomyFilterSheet(
        titleKey: String,
        titleFallback: String,
        entityType: TaxonomyEntityType,
        selectedIDs: Binding<Set<String>>
    ) -> some View {
        TaxonomyMultiSelectFilterSheet(
            titleKey: titleKey,
            titleFallback: titleFallback,
            entityType: entityType,
            selectedIDs: selectedIDs,
            onApply: {
                Task { await applyCombinedTaxonomyFilters() }
            },
            onReset: {
                selectedIDs.wrappedValue = []
                Task { await applyCombinedTaxonomyFilters() }
            }
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var distanceFilterSheet: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(tcKey: "filter_distance", fallback: "Distance")
                .font(.headline)

            Picker("Distance", selection: $selectedDistanceKm) {
                Text("5 km").tag(5)
                Text("10 km").tag(10)
                Text("25 km").tag(25)
                Text("50 km").tag(50)
            }
            .pickerStyle(.segmented)

            HStack(spacing: AppSpacing.sm) {
                TCPrimaryButton(title: tcString("filter_apply", fallback: "Apply"), fullWidth: true) {
                    Task { await homeVM.selectRadius(selectedDistanceKm) }
                    activeFilterSheet = nil
                }
                Button(tcString("filter_reset", fallback: "Reset")) {
                    selectedDistanceKm = 50
                    Task { await homeVM.selectRadius(50) }
                    activeFilterSheet = nil
                }
                .foregroundStyle(Color.tcOcean)
            }

            Spacer()
        }
        .padding(AppSpacing.lg)
        .presentationDetents([.medium])
    }

    private var languageFilterSheet: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(tcKey: "filter_language_title", fallback: "Language")
                .font(.headline)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.xs) {
                    ForEach(languageOptions, id: \.self) { language in
                        Button {
                            if selectedLanguages.contains(language) {
                                selectedLanguages.remove(language)
                            } else {
                                selectedLanguages.insert(language)
                            }
                        } label: {
                            HStack {
                                Text(language)
                                Spacer()
                                if selectedLanguages.contains(language) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.tcOcean)
                                }
                            }
                            .padding(.vertical, 6)
                            .foregroundStyle(Color.tcTextPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack(spacing: AppSpacing.sm) {
                TCPrimaryButton(title: tcString("filter_apply", fallback: "Apply"), fullWidth: true) {
                    activeFilterSheet = nil
                }
                Button(tcString("filter_reset", fallback: "Reset")) {
                    selectedLanguages = []
                    activeFilterSheet = nil
                }
                .foregroundStyle(Color.tcOcean)
            }
        }
        .padding(AppSpacing.lg)
        .presentationDetents([.medium, .large])
    }

    private var verifiedFilterSheet: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(tcKey: "filter_verified_title", fallback: "Verified")
                .font(.headline)

            Toggle(isOn: $verifiedOnly) {
                Text(tcKey: "filter_verified_only_label", fallback: "Show only providers with verified reviews")
            }
            .toggleStyle(.switch)

            if verifiedOnly && displayedProviders.isEmpty {
                Text("No verified providers match this area yet.")
                    .font(.caption)
                    .foregroundStyle(Color.tcCoral)
                    .padding(.top, 6)
            }

            HStack(spacing: AppSpacing.sm) {
                TCPrimaryButton(title: tcString("filter_apply", fallback: "Apply"), fullWidth: true) {
                    activeFilterSheet = nil
                }
                Button(tcString("filter_reset", fallback: "Reset")) {
                    verifiedOnly = false
                    activeFilterSheet = nil
                }
                .foregroundStyle(Color.tcOcean)
            }

            Spacer()
        }
        .padding(AppSpacing.lg)
        .presentationDetents([.medium])
    }

    private func applyCombinedTaxonomyFilters() async {
        let merged = Array(selectedSpecialtyIDs.union(selectedServiceIDs).union(selectedFacilityIDs))
        if merged.isEmpty {
            await homeVM.clearCanonicalFilter()
        } else {
            await homeVM.applyTaxonomyEntityIDs(merged)
        }
    }

    private func clearAllFilters() async {
        selectedSpecialtyIDs = []
        selectedServiceIDs = []
        selectedFacilityIDs = []
        selectedLanguages = []
        verifiedOnly = false
        selectedDistanceKm = 50
        await homeVM.selectRadius(50)
        await homeVM.clearCanonicalFilter()
    }

    private func openSuggestProviderFlow() {
        showSearchOverlay = false
        NotificationCenter.default.post(name: .trustCareSwitchTab, object: 2)
    }

    private func localizedProviderSpecialty(_ provider: Provider) -> String {
        guard let specialty = specialtyService.specialties.first(where: {
            [$0.name, $0.nameTr, $0.nameDe, $0.namePl, $0.nameNl, $0.nameDa]
                .compactMap { $0 }
                .contains { $0.caseInsensitiveCompare(provider.specialty) == .orderedSame }
        }) else {
            return provider.specialty
        }
        return specialty.resolvedName(using: localizationManager)
    }

    private func iconName(for entityID: String) -> String {
        if let specialty = specialtyService.specialties.first(where: {
            ($0.canonicalEntityId ?? $0.canonicalId) == entityID
        }) {
            return specialty.iconName
        }
        return "cross.case"
    }

    private func typeLabel(for entityType: String) -> String {
        switch entityType.lowercased() {
        case "specialty":
            return tcString("filter_specialty", fallback: "Specialty")
        case "service":
            return tcString("filter_treatment", fallback: "Treatment")
        case "facility":
            return tcString("filter_facility", fallback: "Facility")
        default:
            return tcString("filter_specialty", fallback: "Specialty")
        }
    }

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }

    private func saveRecentSearch(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var updated = recentSearches.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        updated.insert(trimmed, at: 0)
        if updated.count > 8 {
            updated = Array(updated.prefix(8))
        }
        recentSearches = updated
        UserDefaults.standard.set(updated, forKey: recentSearchesKey)
    }
}

private enum ResultsSheetDetent: CGFloat, CaseIterable {
    case peek = 0.15
    case medium = 0.5
    case large = 0.9
}

private struct ResultsBottomSheet<Content: View>: View {
    @Binding var detent: ResultsSheetDetent
    let availableHeight: CGFloat
    @ViewBuilder let content: () -> Content

    @GestureState private var dragOffset: CGFloat = 0

    private var allDetents: [ResultsSheetDetent] {
        ResultsSheetDetent.allCases
    }

    private var minHeight: CGFloat {
        availableHeight * ResultsSheetDetent.peek.rawValue
    }

    private var maxHeight: CGFloat {
        availableHeight * ResultsSheetDetent.large.rawValue
    }

    private var liveHeight: CGFloat {
        let base = availableHeight * detent.rawValue
        return clamp(base - dragOffset)
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.tcBorder)
                .frame(width: 44, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 10)

            content()
        }
        .frame(maxWidth: .infinity)
        .frame(height: liveHeight, alignment: .top)
        .background(Color.tcBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.tcBorder, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: -2)
        .gesture(dragGesture)
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: detent)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($dragOffset) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                let base = availableHeight * detent.rawValue
                let projectedHeight = clamp(base - value.predictedEndTranslation.height)
                let target = allDetents.min {
                    abs((availableHeight * $0.rawValue) - projectedHeight)
                        < abs((availableHeight * $1.rawValue) - projectedHeight)
                } ?? detent
                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                    detent = target
                }
            }
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, minHeight), maxHeight)
    }
}

private struct TaxonomyMultiSelectFilterSheet: View {
    let titleKey: String
    let titleFallback: String
    let entityType: TaxonomyEntityType
    @Binding var selectedIDs: Set<String>
    let onApply: () -> Void
    let onReset: () -> Void

    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var items: [TaxonomySuggestion] = []
    @State private var loading = false

    private var filteredItems: [TaxonomySuggestion] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        return items.filter {
            $0.label.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
                .contains(trimmed.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR")))
        }
    }

    private var groupedItems: [(String, [TaxonomySuggestion])] {
        let grouped = Dictionary(grouping: filteredItems) { suggestion in
            String(suggestion.label.prefix(1)).uppercased()
        }
        return grouped
            .map { ($0.key, $0.value.sorted { $0.label < $1.label }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(tcKey: titleKey, fallback: titleFallback)
                .font(.headline)

            TCSearchBar(
                text: $searchText,
                placeholderKey: "search_placeholder",
                placeholderFallback: "Search"
            )

            if loading {
                ProgressView()
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(groupedItems, id: \.0) { groupTitle, suggestions in
                        Text(groupTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.tcTextSecondary)
                            .padding(.top, AppSpacing.xs)

                        ForEach(suggestions, id: \.id) { suggestion in
                            Button {
                                if selectedIDs.contains(suggestion.entityId) {
                                    selectedIDs.remove(suggestion.entityId)
                                } else {
                                    selectedIDs.insert(suggestion.entityId)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: iconName(for: suggestion))
                                        .foregroundStyle(Color.tcTextSecondary)
                                    Text(suggestion.label)
                                        .foregroundStyle(Color.tcTextPrimary)
                                    Spacer()
                                    if selectedIDs.contains(suggestion.entityId) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.tcOcean)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack(spacing: AppSpacing.sm) {
                TCPrimaryButton(title: tcString("filter_apply", fallback: "Apply"), fullWidth: true) {
                    onApply()
                    dismiss()
                }

                Button(tcString("filter_reset", fallback: "Reset")) {
                    onReset()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tcOcean)
            }
        }
        .padding(AppSpacing.lg)
        .task {
            await loadItems()
        }
    }

    private func loadItems() async {
        loading = true
        defer { loading = false }
        do {
            let localeCode = locale.language.languageCode?.identifier ?? "en"
            items = try await TaxonomyService.browseTaxonomy(entityType: entityType, locale: localeCode, limit: 200)
        } catch {
            items = []
        }
    }

    private func iconName(for suggestion: TaxonomySuggestion) -> String {
        switch suggestion.entityType.lowercased() {
        case "service":
            return "wand.and.stars"
        case "facility":
            return "building.2"
        default:
            return "cross.case"
        }
    }
}
