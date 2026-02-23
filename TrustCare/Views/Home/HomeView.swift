import SwiftUI
import Supabase
import CoreLocation

struct HomeView: View {
    @StateObject private var homeVM = HomeViewModel()
    @ObservedObject private var specialtyService = SpecialtyService.shared
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var displayName: String = String(localized: "Anonymous")
    @State private var avatarDisplayUrl: String?
    @State private var showLocationSearch: Bool = false
    @State private var showSpecialtyBrowser: Bool = false
    @State private var selectedSpecialty: Specialty?
    @State private var selectedProviderFromSearch: Provider?
    @State private var selectedProviderFromMap: Provider?
    @State private var showMapBottomSheet: Bool = false
    private let verboseLogging = false

    private func verboseLog(_ message: @autoclosure () -> String) {
        guard verboseLogging else { return }
        print(message())
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
                                Text(homeVM.locationName.isEmpty || homeVM.locationName == String(localized: "Tap to set location")
                                     ? "Adana"
                                     : homeVM.locationName)
                                    .font(AppFont.headline)
                                    .foregroundStyle(.primary)
                                Text("Türkiye")
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
                        TextField(String(localized: "search_placeholder"), text: $homeVM.searchText)
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
                    .background(AppColor.cardBackground)
                    .cornerRadius(AppRadius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button)
                            .stroke(AppColor.border, lineWidth: 1)
                    )
                    .padding(.horizontal, AppSpacing.lg)

                    // Search suggestions (if any)
                    if !homeVM.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       (!homeVM.providerSuggestions.isEmpty || !homeVM.specialtySuggestions.isEmpty) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            if !homeVM.specialtySuggestions.isEmpty {
                                Text(String(localized: "specialties_label"))
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
                                Text(String(localized: "providers_label"))
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
                                                Text(provider.specialty)
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
                            smartPill(title: String(localized: "filter_all"), isSelected: selectedSpecialty == nil) {
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

                            smartPill(title: String(localized: "filter_more"), isSelected: false) {
                                showSpecialtyBrowser = true
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }

                    // Map/List Toggle
                    Picker("", selection: $homeVM.viewMode) {
                        Text(String(localized: "map_toggle_map")).tag(HomeViewModel.ViewMode.map)
                        Text(String(localized: "map_toggle_list")).tag(HomeViewModel.ViewMode.list)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AppSpacing.lg)
                }
                .padding(.bottom, AppSpacing.md)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)

                // Content Section
                ZStack {
                    contentSection
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarHidden(true)
            .dismissKeyboardOnTap()
            .keyboardDoneToolbar()
            .task(id: homeVM.searchText) {
                guard homeVM.hasLoadedInitially else { return }
                await homeVM.searchWithDebounce()
            }
            .task(id: homeVM.selectedSurveyType) {
                guard homeVM.hasLoadedInitially else { return }
                await homeVM.searchWithDebounce()
            }
            .task(id: homeVM.selectedSpecialtyName) {
                guard homeVM.hasLoadedInitially else { return }
                await homeVM.refresh()
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
            .alert(String(localized: "error_generic"), isPresented: Binding(
                get: { homeVM.errorMessage != nil },
                set: { if !$0 { homeVM.errorMessage = nil } }
            )) {
                Button(String(localized: "button_ok")) {
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
            ZStack {
                ProviderMapView(
                    viewModel: homeVM,
                    providers: homeVM.providers,
                    isLoading: homeVM.isLoading,
                    centerCoordinate: homeVM.mapCenterCoordinate,
                    centerUpdateToken: homeVM.mapCenterUpdateToken,
                    onOpenProvider: { provider in
                        selectedProviderFromMap = provider
                    }
                )

                // Bottom Sheet with Provider Cards
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: AppSpacing.md) {
                        // Drag Handle
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(Color(.systemGray3))
                            .frame(width: 40, height: 5)
                            .padding(.top, AppSpacing.sm)

                        if homeVM.providers.isEmpty {
                            VStack(spacing: AppSpacing.sm) {
                                Image(systemName: "mappin.slash")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                Text(String(localized: "empty_search"))
                                    .font(AppFont.body)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.lg)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppSpacing.md) {
                                    ForEach(homeVM.providers) { provider in
                                        Button {
                                            selectedProviderFromMap = provider
                                        } label: {
                                            CompactProviderCardForSheet(provider: provider)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, AppSpacing.lg)
                            }
                            .frame(height: 160)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(16, corners: [.topLeft, .topRight])
                    .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        } else if homeVM.providers.isEmpty {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(homeVM.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     ? String(localized: "empty_home_title")
                     : String(localized: "empty_search"))
                    .font(AppFont.body)
                    .foregroundStyle(.secondary)
                Button(String(localized: "empty_home_cta")) {
                    NotificationCenter.default.post(name: .trustCareSwitchTab, object: 2)
                }
                .font(AppFont.callout)
                .foregroundStyle(AppColor.trustBlue)
            }
            .padding(.top, AppSpacing.xxl)
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
            displayName = String(localized: "there")
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
                Text(localizationManager.resolvedSpecialtyName(
                    canonical: provider.specialty,
                    tr: provider.specialtyTr ?? provider.specialty,
                    de: provider.specialtyDe ?? provider.specialty,
                    pl: provider.specialtyPl ?? provider.specialty,
                    nl: provider.specialtyNl ?? provider.specialty,
                    da: provider.specialtyDa ?? provider.specialty
                ))
                    .font(AppFont.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Verification Badge
                if provider.isVerified {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(AppFont.caption2)
                        Text(String(localized: "verified_badge"))
                            .font(AppFont.caption2)
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
}

