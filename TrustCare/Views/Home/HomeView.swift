import SwiftUI
import Supabase
import CoreLocation

struct HomeView: View {
    @StateObject private var homeVM = HomeViewModel()
    @ObservedObject private var specialtyService = SpecialtyService.shared
    @State private var displayName: String = String(localized: "Anonymous")
    @State private var avatarDisplayUrl: String?
    @State private var showLocationSearch: Bool = false
    @State private var showSpecialtyBrowser: Bool = false
    @State private var selectedSpecialty: Specialty?
    @State private var selectedProviderFromSearch: Provider?
    @State private var selectedProviderFromMap: Provider?
    private let verboseLogging = false

    private func verboseLog(_ message: @autoclosure () -> String) {
        guard verboseLogging else { return }
        print(message())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection

                VStack(spacing: AppSpacing.lg) {
                    searchSection
                        .padding(.horizontal, AppSpacing.lg)

                    specialtyScroll

                    Picker("", selection: $homeVM.viewMode) {
                        Text("Harita").tag(HomeViewModel.ViewMode.map)
                        Text("Liste").tag(HomeViewModel.ViewMode.list)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AppSpacing.lg)
                }
                .padding(.bottom, AppSpacing.md)

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
            .alert(String(localized: "Error"), isPresented: Binding(
                get: { homeVM.errorMessage != nil },
                set: { if !$0 { homeVM.errorMessage = nil } }
            )) {
                Button(String(localized: "Done")) {
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

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Keşfet")
                .font(AppFont.largeTitle)

            Button {
                showLocationSearch = true
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.secondary)
                    Text(homeVM.locationName.isEmpty || homeVM.locationName == String(localized: "Tap to set location")
                         ? "Adana, Türkiye"
                         : homeVM.locationName)
                        .font(AppFont.body)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Doktor, klinik veya uzmanlık ara...", text: $homeVM.searchText)
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

            if !homeVM.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               (!homeVM.providerSuggestions.isEmpty || !homeVM.specialtySuggestions.isEmpty) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    if !homeVM.specialtySuggestions.isEmpty {
                        Text("Uzmanlıklar")
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, AppSpacing.xs)
                        ForEach(homeVM.specialtySuggestions.prefix(4)) { specialty in
                            Button {
                                selectedSpecialty = specialty
                                homeVM.searchText = specialty.name
                                homeVM.clearSuggestions()
                                Task { await homeVM.applySpecialtyFilter(specialty) }
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: specialty.iconName)
                                    Text(specialty.name)
                                        .font(AppFont.body)
                                    Spacer()
                                }
                                .foregroundStyle(.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !homeVM.providerSuggestions.isEmpty {
                        Text("Sağlayıcılar")
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
            }
        }
    }

    private var specialtyScroll: some View {
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                specialtyChip(title: "Tümü", isSelected: selectedSpecialty == nil) {
                    selectedSpecialty = nil
                    Task { await homeVM.applySpecialtyFilter(nil) }
                }

                ForEach(Array(specialtyService.popularSpecialties().prefix(20))) { specialty in
                    specialtyChip(title: specialty.name, isSelected: selectedSpecialty?.id == specialty.id) {
                        selectedSpecialty = specialty
                        Task { await homeVM.applySpecialtyFilter(specialty) }
                    }
                }

                specialtyChip(title: "Daha Fazla ▾", isSelected: false) {
                    showSpecialtyBrowser = true
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    private func specialtyChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
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
            ProviderMapView(
                viewModel: homeVM,
                providers: homeVM.providers,
                isLoading: homeVM.isLoading,
                centerCoordinate: homeVM.selectedLocation.isCurrentLocation
                    ? homeVM.locationManagerCoordinate
                    : CLLocationCoordinate2D(
                        latitude: homeVM.selectedLocation.latitude,
                        longitude: homeVM.selectedLocation.longitude
                    ),
                onOpenProvider: { provider in
                    selectedProviderFromMap = provider
                }
            )
        } else if homeVM.providers.isEmpty {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(homeVM.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     ? "Bu bölgede henüz sağlayıcı yok. İlk ekleyen siz olun!"
                     : "Sonuç bulunamadı")
                    .font(AppFont.body)
                    .foregroundStyle(.secondary)
                Button("Sağlayıcı Ekle") {
                    NotificationCenter.default.post(name: .trustCareSwitchTab, object: 2)
                }
                .font(AppFont.callout)
                .foregroundStyle(AppColor.trustBlue)
            }
            .padding(.top, AppSpacing.xxl)
        } else {
            ScrollView {
                LazyVStack(spacing: AppSpacing.md) {
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
