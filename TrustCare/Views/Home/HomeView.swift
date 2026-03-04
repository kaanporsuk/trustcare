import SwiftUI
import Supabase
import CoreLocation

struct HomeView: View {
    @StateObject private var homeVM = HomeViewModel()
    @ObservedObject private var specialtyService = SpecialtyService.shared
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.locale) private var locale
    @State private var displayName: String = "Anonymous"
    @State private var avatarDisplayUrl: String?
    @State private var showLocationSearch: Bool = false
    @State private var showSpecialtyBrowser: Bool = false
    @State private var selectedSpecialty: Specialty?
    @State private var selectedProviderFromSearch: Provider?
    @State private var selectedProviderFromMap: Provider?
    @State private var mapSheetHeight: CGFloat = 188
    @State private var mapSheetDragOffset: CGFloat = 0
    private let verboseLogging = false
    private let mapSheetMinHeight: CGFloat = 132
    private let mapSheetMaxHeight: CGFloat = 300

    private func verboseLog(_ message: @autoclosure () -> String) {
        guard verboseLogging else { return }
        print(message())
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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top sticky section with location, search, and smart pills
                VStack(spacing: AppSpacing.md) {
                    // Location Row
                    Button {
                        showLocationSearch = true
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title3)
                                .foregroundStyle(AppColor.trustBlue)
                            VStack(alignment: .leading, spacing: 2) {
                                if homeVM.locationName.isEmpty || homeVM.locationName == "Tap to set location" {
                                    Text("default_city_name")
                                        .font(AppFont.headline)
                                        .foregroundStyle(.primary)
                                } else {
                                    Text(homeVM.locationName)
                                        .font(AppFont.headline)
                                        .foregroundStyle(.primary)
                                }
                                Text("country_turkey")
                                    .font(AppFont.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColor.cardBackground)
                        .cornerRadius(AppRadius.button)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppSpacing.lg)

                    // Search Bar
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("search_placeholder", text: $homeVM.searchText)
                            .textFieldStyle(.plain)
                            .font(AppFont.body)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                        if !homeVM.searchText.isEmpty {
                            Button {
                                homeVM.searchText = ""
                                homeVM.clearSuggestions()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .frame(height: 44)
                    .background(Color(.systemGray6).opacity(0.95))
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(0.04), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                    .padding(.horizontal, AppSpacing.lg)

                    // Search suggestions (if any)
                    if !homeVM.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       (!homeVM.providerSuggestions.isEmpty || !homeVM.specialtySuggestions.isEmpty || !homeVM.taxonomySuggestions.isEmpty) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            if !homeVM.taxonomySuggestions.isEmpty {
                                Text("specialties_label")
                                    .font(AppFont.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, AppSpacing.xs)
                                ForEach(homeVM.taxonomySuggestions.prefix(4)) { suggestion in
                                    Button {
                                        selectedSpecialty = nil
                                        Task { await homeVM.applyTaxonomySuggestion(suggestion) }
                                    } label: {
                                        HStack(spacing: AppSpacing.sm) {
                                            Image(systemName: "cross.case")
                                            Text(suggestion.label)
                                                .font(AppFont.body)
                                            Spacer()
                                        }
                                        .foregroundStyle(.primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if !homeVM.specialtySuggestions.isEmpty {
                                Text("specialties_label")
                                    .font(AppFont.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, AppSpacing.xs)
                                ForEach(homeVM.specialtySuggestions.prefix(4)) { specialty in
                                    Button {
                                        selectedSpecialty = specialty
                                        homeVM.searchText = specialty.resolvedName(using: localizationManager)
                                        homeVM.clearSuggestions()
                                        Task { await homeVM.applySpecialtyFilter(specialty) }
                                    } label: {
                                        HStack(spacing: AppSpacing.sm) {
                                            Image(systemName: specialty.iconName)
                                            Text(specialty.resolvedName(using: localizationManager))
                                                .font(AppFont.body)
                                            Spacer()
                                        }
                                        .foregroundStyle(.primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if !homeVM.providerSuggestions.isEmpty {
                                Text("providers_label")
                                    .font(AppFont.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, AppSpacing.xs)
                                ForEach(homeVM.providerSuggestions.prefix(5)) { provider in
                                    Button {
                                        homeVM.clearSuggestions()
                                        selectedProviderFromSearch = provider
                                    } label: {
                                        HStack(spacing: AppSpacing.sm) {
                                            Image(systemName: "cross.case")
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(provider.name)
                                                    .font(AppFont.body)
                                                Text(localizedProviderSpecialty(provider))
                                                    .font(AppFont.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .foregroundStyle(.primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(AppSpacing.md)
                        .background(AppColor.cardBackground)
                        .cornerRadius(AppRadius.card)
                        .shadow(color: DesignShadow.color, radius: DesignShadow.radius, x: DesignShadow.x, y: DesignShadow.y)
                        .padding(.horizontal, AppSpacing.lg)
                    }

                    // Smart Pills (All + Top 5 Popular + More)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            smartPill(titleKey: "filter_all", isSelected: selectedSpecialty == nil) {
                                selectedSpecialty = nil
                                Task { await homeVM.applySpecialtyFilter(nil) }
                            }

                            ForEach(homeVM.popularSpecialties.prefix(5)) { specialty in
                                smartPill(title: localizationManager.resolvedSpecialtyName(
                                    canonical: specialty.name,
                                    tr: specialty.nameTr, de: specialty.nameDe,
                                    pl: specialty.namePl, nl: specialty.nameNl,
                                    da: specialty.nameDa
                                ), isSelected: selectedSpecialty?.id == specialty.id) {
                                    selectedSpecialty = specialty
                                    Task { await homeVM.applySpecialtyFilter(specialty) }
                                }
                            }

                            smartPill(titleKey: "filter_more", isSelected: false) {
                                showSpecialtyBrowser = true
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }

                    // Map/List Toggle
                    Picker("", selection: $homeVM.viewMode) {
                        Text("map_toggle_map").tag(HomeViewModel.ViewMode.map)
                        Text("map_toggle_list").tag(HomeViewModel.ViewMode.list)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AppSpacing.lg)
                }
                .padding(.bottom, AppSpacing.md)
                .background(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                .zIndex(2)

                // Content Section
                ZStack {
                    contentSection
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(1)
            }
            .navigationBarHidden(true)
            .dismissKeyboardOnTap()
            .keyboardDoneToolbar()
            .task(id: homeVM.searchText) {
                guard homeVM.hasLoadedInitially else { return }
                await homeVM.searchWithDebounce()
            }
            // Sync pill selection when the map legend changes surveyType.
            // When the legend calls applyLegendFilter(), it clears
            // selectedSpecialtyName; detect that and reset selectedSpecialty.
            .onChange(of: homeVM.selectedSurveyType) { _, newType in
                if let spec = selectedSpecialty {
                    let specSurvey = SpecialtyService.shared.surveyType(for: spec.name)
                    if specSurvey != newType {
                        selectedSpecialty = nil
                    }
                }
            }
            .task {
                homeVM.startLocationUpdates()
                await homeVM.onAppear()
                await loadDisplayName()
            }
            .sheet(isPresented: $showSpecialtyBrowser) {
                SpecialtyBrowserSheet(
                    selectedSpecialty: selectedSpecialty,
                    onSelect: { specialty in
                        selectedSpecialty = specialty
                        Task { await homeVM.applySpecialtyFilter(specialty) }
                    },
                    onClear: {
                        selectedSpecialty = nil
                        Task { await homeVM.applySpecialtyFilter(nil) }
                    }
                )
            }
            .navigationDestination(item: $selectedProviderFromSearch) { provider in
                ProviderDetailView(providerId: provider.id)
            }
            .navigationDestination(item: $selectedProviderFromMap) { provider in
                ProviderDetailView(providerId: provider.id)
            }
            .alert("error_generic", isPresented: Binding(
                get: { homeVM.errorMessage != nil },
                set: { if !$0 { homeVM.errorMessage = nil } }
            )) {
                Button("button_ok") {
                    homeVM.errorMessage = nil
                }
            } message: {
                Text(homeVM.errorMessage ?? "")
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
        }
    }

    private func smartPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(isSelected ? AppColor.trustBlue : AppColor.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.button)
                        .stroke(isSelected ? Color.clear : AppColor.border, lineWidth: 1)
                )
                .cornerRadius(AppRadius.button)
        }
        .buttonStyle(.plain)
    }

    private func smartPill(titleKey: LocalizedStringKey, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(titleKey)
                .font(AppFont.caption)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(isSelected ? AppColor.trustBlue : AppColor.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.button)
                        .stroke(isSelected ? Color.clear : AppColor.border, lineWidth: 1)
                )
                .cornerRadius(AppRadius.button)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var contentSection: some View {
        if homeVM.isLoading && homeVM.providers.isEmpty {
            ScrollView {
                LazyVStack(spacing: AppSpacing.md) {
                    ForEach(0..<6, id: \.self) { _ in
                        SkeletonProviderCard()
                            .redacted(reason: .placeholder)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
            }
        } else if homeVM.viewMode == .map {
            ZStack(alignment: .bottom) {
                ProviderMapView(
                    viewModel: homeVM,
                    onOpenProvider: { provider in
                        selectedProviderFromMap = provider
                    }
                )

                if homeVM.providers.isEmpty {
                    if !homeVM.isLoading {
                        mapEmptyStateCard
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.bottom, AppSpacing.xl)
                    } else {
                        ProgressView()
                            .padding(.bottom, AppSpacing.xxl)
                    }
                } else {
                    mapBottomSheet
                }
            }
        } else if !homeVM.isLoading && homeVM.providers.isEmpty {
            premiumEmptyState
                .padding(.top, AppSpacing.xxl)
        } else if homeVM.providers.isEmpty {
            ProgressView()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(homeVM.providers) { provider in
                        ProviderCardView(provider: provider)
                    }

                    if homeVM.hasMoreResults {
                        ProgressView()
                            .onAppear {
                                Task { await homeVM.loadMore() }
                            }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                await homeVM.refresh(forceSpecialtiesRefresh: true)
            }
        }
    }

    private var premiumEmptyState: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColor.trustBlue.opacity(0.12))
                    .frame(width: 120, height: 120)
                localizedMedicalIcon
                    .font(.system(size: 54))
                    .foregroundStyle(AppColor.trustBlue.opacity(0.85))
            }

            Text(homeVM.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                 ? LocalizedStringKey("empty_home_title")
                 : LocalizedStringKey("empty_search"))
                .font(AppFont.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            Button {
                NotificationCenter.default.post(name: .trustCareSwitchTab, object: 2)
            } label: {
                Text("empty_home_cta")
                    .font(AppFont.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColor.trustBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private var mapEmptyStateCard: some View {
        VStack(spacing: AppSpacing.sm) {
            localizedMedicalIcon
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColor.trustBlue)

            Text(homeVM.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                 ? LocalizedStringKey("empty_home_title")
                 : LocalizedStringKey("empty_search"))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            Button {
                NotificationCenter.default.post(name: .trustCareSwitchTab, object: 2)
            } label: {
                Text("empty_home_cta")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColor.trustBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
        .frame(maxWidth: 340)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }

    @ViewBuilder
    private var localizedMedicalIcon: some View {
        if usesCrescentHealthIcon {
            Image(systemName: "moon.fill")
                .rotationEffect(.degrees(-25))
        } else {
            Image(systemName: "cross.case.fill")
        }
    }

    private var usesCrescentHealthIcon: Bool {
        let languageCode = locale.language.languageCode?.identifier
            ?? (!localizationManager.currentLanguage.isEmpty
                ? localizationManager.currentLanguage
                : localizationManager.effectiveLanguage)
        let normalizedCode = languageCode
            .components(separatedBy: ["-", "_"])
            .first?
            .lowercased() ?? ""
        return normalizedCode == "tr" || normalizedCode == "ar"
    }

    private var mapBottomSheet: some View {
        let dynamicHeight = min(
            max(mapSheetHeight - mapSheetDragOffset, mapSheetMinHeight),
            mapSheetMaxHeight
        )

        return VStack(spacing: AppSpacing.sm) {
            Capsule()
                .fill(.secondary.opacity(0.35))
                .frame(width: 40, height: 5)
                .padding(.top, AppSpacing.sm)

            HStack {
                Text("providers_label")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(homeVM.providers.count)")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(homeVM.providers) { provider in
                        Button {
                            selectedProviderFromMap = provider
                        } label: {
                            CompactProviderCardForSheet(provider: provider)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
            .padding(.bottom, AppSpacing.md)
        }
        .frame(maxWidth: .infinity)
        .frame(height: dynamicHeight, alignment: .top)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 12, y: 3)
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.md)
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    mapSheetDragOffset = value.translation.height
                }
                .onEnded { value in
                    let proposed = mapSheetHeight - value.translation.height
                    let clamped = min(max(proposed, mapSheetMinHeight), mapSheetMaxHeight)
                    let midpoint = (mapSheetMinHeight + mapSheetMaxHeight) / 2
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        mapSheetHeight = clamped > midpoint ? mapSheetMaxHeight : mapSheetMinHeight
                        mapSheetDragOffset = 0
                    }
                }
        )
    }

    private func loadDisplayName() async {
        do {
            let profile = try await AuthService.fetchProfile()
            displayName = profile.displayName
            if let avatarUrl = profile.avatarUrl, let path = storagePath(from: avatarUrl) {
                let signed = try await SupabaseManager.shared.client
                    .storage
                    .from("user-avatars")
                    .createSignedURL(path: path, expiresIn: 3600)
                avatarDisplayUrl = cacheBustedUrl(signed.absoluteString)
            } else if let avatarUrl = profile.avatarUrl {
                avatarDisplayUrl = cacheBustedUrl(avatarUrl)
            } else {
                avatarDisplayUrl = nil
            }
        } catch {
            displayName = "there"
            avatarDisplayUrl = nil
        }
    }

    private func storagePath(from urlString: String) -> String? {
        guard let range = urlString.range(of: "/user-avatars/") else {
            return nil
        }
        return String(urlString[range.upperBound...])
    }

    private func cacheBustedUrl(_ url: String) -> String? {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let parsed = URL(string: trimmed),
              let scheme = parsed.scheme,
              scheme == "http" || scheme == "https" else {
            return nil
        }

        let separator = trimmed.contains("?") ? "&" : "?"
        return "\(trimmed)\(separator)v=\(Int(Date().timeIntervalSince1970))"
    }
}

private struct SkeletonProviderCard: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 180, height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 12)
            }
            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
    }
}

private struct CompactProviderCardForSheet: View {
    let provider: Provider
    @EnvironmentObject private var localizationManager: LocalizationManager
    @ObservedObject private var specialtyService = SpecialtyService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // Provider Avatar or Name initials
            ZStack {
                AppColor.trustBlue.opacity(0.1)
                    .frame(height: 80)

                Text(provider.name.prefix(2).uppercased())
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.trustBlue)
                    .frame(height: 80)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Provider Name
                Text(provider.name)
                    .font(AppFont.caption)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                // Specialty
                Text(localizedProviderSpecialty)
                    .font(AppFont.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Verification Badge
                if provider.verifiedReviewCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(AppFont.footnote)
                        Text("verified_badge")
                            .font(AppFont.footnote)
                    }
                    .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)

            Spacer()
        }
        .frame(width: 140)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }

    private var localizedProviderSpecialty: String {
        guard let specialty = specialtyService.specialties.first(where: {
            [
                $0.name,
                $0.nameTr,
                $0.nameDe,
                $0.namePl,
                $0.nameNl,
                $0.nameDa,
            ]
            .compactMap { $0 }
            .contains { $0.caseInsensitiveCompare(provider.specialty) == .orderedSame }
        }) else {
            return provider.specialty
        }

        return specialty.resolvedName(using: localizationManager)
    }
}

