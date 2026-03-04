import SwiftUI
import Supabase
import CoreLocation
import UIKit

struct HomeView: View {
    @StateObject private var homeVM = HomeViewModel()
    @ObservedObject private var specialtyService = SpecialtyService.shared
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.locale) private var locale
    @State private var displayName: String = String(localized: "Anonymous")
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
                                if homeVM.locationName.isEmpty || homeVM.locationName == String(localized: "Tap to set location") {
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
                       !homeVM.taxonomySuggestions.isEmpty {
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
                            smartPill(titleKey: "filter_all", isSelected: homeVM.selectedSmartPillEntityID == nil) {
                                selectedSpecialty = nil
                                Task { await homeVM.applySmartPill(entityID: nil) }
                            }

                            ForEach(homeVM.smartPills) { pill in
                                smartPill(title: pill.label, isSelected: homeVM.selectedSmartPillEntityID == pill.entityID) {
                                    selectedSpecialty = nil
                                    Task { await homeVM.applySmartPill(entityID: pill.entityID) }
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
            .task(id: localizationManager.effectiveLanguage) {
                await homeVM.reloadSmartPillsForCurrentLocale()
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
                appRouter.registerHomeViewModel(homeVM)
                homeVM.startLocationUpdates()
                await homeVM.onAppear()
                await loadDisplayName()
            }
            .onDisappear {
                appRouter.unregisterHomeViewModel(homeVM)
            }
            .sheet(isPresented: $showSpecialtyBrowser) {
                SpecialtyBrowserSheet(
                    onSelect: { suggestion in
                        selectedSpecialty = nil
                        Task { await homeVM.applyTaxonomySuggestion(suggestion) }
                    },
                    onClear: {
                        selectedSpecialty = nil
                        Task { await homeVM.applySmartPill(entityID: nil) }
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
                    highlightedProviderID: $homeVM.highlightedProviderID,
                    onOpenProvider: { provider in
                        homeVM.highlightedProviderID = provider.id
                    }
                )

                if homeVM.providers.isEmpty {
                    if !homeVM.isLoading {
                        activeEmptyStateCard
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
            activeEmptyStateCard
                .padding(.top, AppSpacing.xxl)
        } else if homeVM.providers.isEmpty {
            ProgressView()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(homeVM.providers) { provider in
                        ProviderCardView(provider: provider)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.card)
                                    .stroke(
                                        homeVM.highlightedProviderID == provider.id ? AppColor.trustBlue : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .onTapGesture {
                                homeVM.highlightedProviderID = provider.id
                            }
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
        PremiumEmptyStateCard(
            iconName: usesCrescentHealthIcon ? "moon.fill" : "cross.case.fill",
            title: String(localized: "empty_home_title"),
            bulletKeys: ["widen_map_area", "try_nearby_city", "switch_to_list"],
            primaryActionTitleKey: "switch_to_list",
            primaryAction: {
                homeVM.switchToListView()
            },
            secondaryActionTitleKey: "try_nearby_city",
            secondaryAction: {
                Task { await homeVM.widenSearchAreaOrShowNearby() }
            }
        )
        .padding(.horizontal, AppSpacing.lg)
    }

    private var mapEmptyStateCard: some View {
        premiumEmptyState
    }

    @ViewBuilder
    private var localizedMedicalIcon: some View {
        if usesCrescentHealthIcon {
            crescentMedicalIcon
        } else {
            Image(systemName: "cross.case.fill")
        }
    }

    @ViewBuilder
    private var crescentMedicalIcon: some View {
        if UIImage(named: "medical_bag_crescent") != nil {
            Image("medical_bag_crescent")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
        } else {
            ZStack {
                Image(systemName: "bag.fill")
                    .font(.system(size: 22, weight: .semibold))
                Image(systemName: "moon.fill")
                    .font(.system(size: 10, weight: .bold))
                    .offset(x: 7, y: -7)
            }
        }
    }

    private var usesCrescentHealthIcon: Bool {
        let languageCode = locale.language.languageCode?.identifier
            ?? locale.identifier
        let normalizedCode = languageCode
            .components(separatedBy: ["-", "_"])
            .first?
            .lowercased() ?? ""
        return normalizedCode == "tr" || normalizedCode == "ar"
    }

    @ViewBuilder
    private var activeEmptyStateCard: some View {
        if homeVM.hasActiveCanonicalFilter {
            filteredEmptyStateCard
        } else {
            mapEmptyStateCard
        }
    }

    private var filteredEmptyStateCard: some View {
        let selectedLabel = homeVM.activeCanonicalFilterLabel ?? String(localized: "specialties_label")
        let title = "\(selectedLabel): \(String(localized: "empty_search"))"

        return PremiumEmptyStateCard(
            iconName: "line.3.horizontal.decrease.circle",
            title: title,
            bulletKeys: ["widen_map_area", "try_nearby_city", "switch_to_list"],
            primaryActionTitleKey: "filter_all",
            primaryAction: {
                Task { await homeVM.clearCanonicalFilter() }
            },
            secondaryActionTitleKey: "try_nearby_city",
            secondaryAction: {
                Task { await homeVM.widenSearchAreaOrShowNearby() }
            },
            tertiaryActionTitleKey: "switch_to_list",
            tertiaryAction: {
                homeVM.switchToListView()
            }
        )
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
                            homeVM.highlightedProviderID = provider.id
                            selectedProviderFromMap = provider
                        } label: {
                            CompactProviderCardForSheet(
                                provider: provider,
                                isHighlighted: homeVM.highlightedProviderID == provider.id
                            )
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
            displayName = String(localized: "Anonymous")
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
    let isHighlighted: Bool
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
                .stroke(isHighlighted ? AppColor.trustBlue : AppColor.border, lineWidth: isHighlighted ? 2 : 1)
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

