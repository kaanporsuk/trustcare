import SwiftUI
import Supabase
import CoreLocation

struct HomeView: View {
    @StateObject private var homeVM = HomeViewModel()
    @State private var displayName: String = String(localized: "Anonymous")
    @State private var avatarDisplayUrl: String?
    @State private var showLocationSearch: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                headerSection
                SearchBarView(text: $homeVM.searchText)
                    .padding(.horizontal, AppSpacing.lg)

                specialtyScroll

                Picker("", selection: $homeVM.viewMode) {
                    Text(String(localized: "List")).tag(HomeViewModel.ViewMode.list)
                    Text(String(localized: "Map")).tag(HomeViewModel.ViewMode.map)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.lg)

                contentSection
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
            .task {
                homeVM.startLocationUpdates()
                await homeVM.onAppear()
                await loadDisplayName()
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
            .fullScreenCover(isPresented: $showLocationSearch) {
                LocationSearchSheet(
                    currentLocationName: homeVM.locationName,
                    selectedLocation: homeVM.selectedLocation,
                    recentLocations: homeVM.recentLocations,
                    onSelectLocation: { location in
                        await homeVM.selectLocation(location)
                        showLocationSearch = false
                    },
                    onUseCurrentLocation: {
                        await homeVM.useCurrentLocation()
                        showLocationSearch = false
                    },
                    onClearRecents: {
                        homeVM.clearRecentLocations()
                    }
                )
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.sm) {
                Text(greetingText)
                    .font(AppFont.title2)
                if let urlString = avatarDisplayUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.secondary)
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure(let error):
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.secondary)
                                .onAppear {
                                    print("⚠️ HomeView avatar failed to load from: \(urlString)")
                                    print("   Error: \(error.localizedDescription)")
                                }
                        @unknown default:
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                }
                Spacer()
            }
            Button {
                showLocationSearch = true
            } label: {
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(.secondary)
                        Text(homeVM.locationName)
                            .font(AppFont.body)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(localized: "Change"))
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.trustBlue)
                }
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: homeVM.locationName)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var specialtyScroll: some View {
        let categories: [(type: String?, label: String, icon: String)] = [
            (nil, "All", "line.3.horizontal.decrease.circle"),
            ("general_clinic", "Clinic", ProviderMapColor.icon(for: "general_clinic")),
            ("pharmacy", "Pharmacy", ProviderMapColor.icon(for: "pharmacy")),
            ("hospital", "Hospital", ProviderMapColor.icon(for: "hospital")),
            ("dental", "Dental", ProviderMapColor.icon(for: "dental")),
            ("aesthetics", "Aesthetics", ProviderMapColor.icon(for: "aesthetics")),
            ("diagnostic", "Lab", ProviderMapColor.icon(for: "diagnostic")),
            ("mental_health", "Mental Health", ProviderMapColor.icon(for: "mental_health")),
            ("rehabilitation", "Rehab", ProviderMapColor.icon(for: "rehabilitation"))
        ]

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(categories, id: \.label) { category in
                    CategoryChipView(
                        title: category.label,
                        iconName: category.icon,
                        isSelected: homeVM.selectedSurveyType == category.type,
                        tint: category.type.map { ProviderMapColor.color(for: $0) } ?? AppColor.trustBlue
                    ) {
                        homeVM.selectedSurveyType = category.type
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        if homeVM.isLoading && homeVM.providers.isEmpty {
            VStack {
                Spacer()
                ProgressView()
                Spacer()
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
                    )
            )
        } else if homeVM.providers.isEmpty {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(String(localized: "No providers found"))
                    .font(AppFont.body)
                    .foregroundStyle(.secondary)
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

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        if hour < 12 {
            greeting = String(localized: "Good Morning")
        } else if hour < 18 {
            greeting = String(localized: "Good Afternoon")
        } else {
            greeting = String(localized: "Good Evening")
        }
        return "\(greeting), \(displayName)!"
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
            }
        } catch {
            displayName = String(localized: "there")
        }
    }

    private func storagePath(from urlString: String) -> String? {
        guard let range = urlString.range(of: "/user-avatars/") else {
            return nil
        }
        return String(urlString[range.upperBound...])
    }

    private func cacheBustedUrl(_ url: String) -> String {
        let separator = url.contains("?") ? "&" : "?"
        return "\(url)\(separator)v=\(Int(Date().timeIntervalSince1970))"
    }
}
