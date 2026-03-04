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
    @State private var showRefreshErrorBanner: Bool = false
    @State private var mapSheetHeight: CGFloat = 188
    @State private var mapSheetDragOffset: CGFloat = 0
    private let verboseLogging = false
    private var mapSheetMinHeight: CGFloat {
        UIScreen.main.bounds.height < 760 ? 116 : 132
    }

    private var mapSheetMaxHeight: CGFloat {
        UIScreen.main.bounds.height < 760 ? 248 : 300
    }

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
                DiscoverSearchSurfaceView(
                    locationName: homeVM.locationName,
                    isLocationUnset: homeVM.locationName.isEmpty || homeVM.locationName == String(localized: "Tap to set location"),
                    searchText: $homeVM.searchText,
                    taxonomySuggestions: homeVM.taxonomySuggestions,
                    smartPills: homeVM.smartPills,
                    selectedSmartPillEntityID: homeVM.selectedSmartPillEntityID,
                    viewMode: $homeVM.viewMode,
                    onTapLocation: {
                        showLocationSearch = true
                    },
                    onClearSearch: {
                        homeVM.searchText = ""
                        homeVM.clearSuggestions()
                    },
                    onSelectSuggestion: { suggestion in
                        selectedSpecialty = nil
                        Task { await homeVM.applyTaxonomySuggestion(suggestion) }
                    },
                    onSelectSmartPill: { entityID in
                        selectedSpecialty = nil
                        Task { await homeVM.applySmartPill(entityID: entityID) }
                    },
                    onTapMore: {
                        showSpecialtyBrowser = true
                    }
                )
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.xs)
                .padding(.bottom, 16)
                .zIndex(2)

                // Content Section
                ZStack {
                    contentSection
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(1)
                .safeAreaInset(edge: .bottom) {
                    if let loadError = homeVM.providerLoadError,
                       !homeVM.providers.isEmpty,
                       showRefreshErrorBanner {
                        refreshErrorBanner(loadError)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.bottom, 12)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
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
            .onChange(of: homeVM.providerLoadError) { _, newError in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showRefreshErrorBanner = newError != nil && !homeVM.providers.isEmpty
                }
            }
            .onChange(of: homeVM.viewMode) { _, newMode in
                guard newMode == .map else { return }
                let clamped = min(max(mapSheetHeight, mapSheetMinHeight), mapSheetMaxHeight)
                if clamped != mapSheetHeight {
                    mapSheetHeight = clamped
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
        if let loadError = homeVM.providerLoadError {
            providerLoadErrorCard(loadError)
        } else if homeVM.hasActiveCanonicalFilter {
            filteredEmptyStateCard
        } else {
            mapEmptyStateCard
        }
    }

    private func providerLoadErrorCard(_ loadError: HomeViewModel.LoadErrorState) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.title3)
                    .foregroundStyle(AppColor.trustBlue)
                Text(LocalizedStringKey(loadError.errorKey))
                    .font(AppFont.callout.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Text(LocalizedStringKey(loadError.bodyKey))
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: AppSpacing.md) {
                Button("action_retry") {
                    Task { await homeVM.retryLoadProviders() }
                }
                .buttonStyle(.plain)
                .font(AppFont.callout.weight(.semibold))
                .foregroundStyle(AppColor.trustBlue)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColor.trustBlue.opacity(0.14))
                .clipShape(Capsule())

                Button(homeVM.viewMode == .map ? "action_switch_to_list" : "action_switch_to_map") {
                    homeVM.viewMode = homeVM.viewMode == .map ? .list : .map
                }
                .buttonStyle(.plain)
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
    }

    private func refreshErrorBanner(_ loadError: HomeViewModel.LoadErrorState) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(LocalizedStringKey(loadError.errorKey))
                .font(AppFont.callout)
                .fontWeight(.semibold)

            Text(LocalizedStringKey(loadError.bodyKey))
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: AppSpacing.md) {
                Button("action_retry") {
                    Task { await homeVM.retryLoadProviders() }
                }
                .buttonStyle(.plain)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.trustBlue)

                Button(homeVM.viewMode == .map ? "action_switch_to_list" : "action_switch_to_map") {
                    homeVM.viewMode = homeVM.viewMode == .map ? .list : .map
                }
                .buttonStyle(.plain)
                .font(AppFont.callout)
                .foregroundStyle(.secondary)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
        .allowsHitTesting(true)
    }

    private func localizedText(for key: String) -> String {
        let languageCode = locale.language.languageCode?.identifier
        let localeCode = locale.identifier
        let candidates = [localeCode, languageCode].compactMap { $0 }

        for candidate in candidates {
            if let path = Bundle.main.path(forResource: candidate, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                let value = NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
                if value != key {
                    return value
                }
            }
        }

        return NSLocalizedString(key, comment: "")
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

