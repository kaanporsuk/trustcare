import SwiftUI

struct HomeView: View {
    @StateObject private var homeVM = HomeViewModel()
    @State private var displayName: String = String(localized: "Anonymous")

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
            .task(id: homeVM.searchText) {
                // Only trigger search if user actually typed something or cleared text
                // Skip the initial "" value on view load
                guard homeVM.hasLoadedInitially else { return }
                await homeVM.searchWithDebounce()
            }
            .task(id: homeVM.selectedSpecialty) {
                // Only trigger search after initial load
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
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(greetingText)
                .font(AppFont.title2)
            Button {
                homeVM.startLocationUpdates()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.secondary)
                    Text(homeVM.locationName)
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var specialtyScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                SpecialtyChipView(
                    title: String(localized: "All"),
                    isSelected: homeVM.selectedSpecialty == nil
                ) {
                    homeVM.selectedSpecialty = nil
                }

                ForEach(homeVM.specialties) { specialty in
                    SpecialtyChipView(
                        title: specialty.nameEn,
                        isSelected: homeVM.selectedSpecialty == specialty.nameEn
                    ) {
                        homeVM.selectedSpecialty = specialty.nameEn
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
            ProviderMapView(providers: homeVM.providers, isLoading: homeVM.isLoading)
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
                await homeVM.refresh()
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
        } catch {
            // Non-critical — just use default name, no alert needed
            displayName = String(localized: "there")
        }
    }
}
