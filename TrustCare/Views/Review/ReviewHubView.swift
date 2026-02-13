import SwiftUI

struct ReviewHubView: View {
    @StateObject private var viewModel = ReviewHubViewModel()
    @State private var showAddProviderSheet: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text(String(localized: "Write a Review"))
                        .font(AppFont.title2)

                    SearchBarView(
                        text: $viewModel.searchText,
                        placeholder: String(localized: "Search for a provider...")
                    )
                        .onChange(of: viewModel.searchText) { _, _ in
                            viewModel.searchProviders()
                        }

                    if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        searchResultsSection
                    } else {
                        recentlyViewedSection
                        nearbyProvidersSection
                    }

                    Button {
                        showAddProviderSheet = true
                    } label: {
                        Text(String(localized: "Can't find your provider?"))
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.trustBlue)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
            }
            .navigationBarHidden(true)
            .task {
                viewModel.onAppear()
            }
            .onAppear {
                viewModel.refreshRecents()
            }
            .sheet(isPresented: $showAddProviderSheet) {
                AddProviderSheet { _ in
                    showAddProviderSheet = false
                }
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if viewModel.isSearching {
                ProgressView()
            }
            if let message = viewModel.searchErrorMessage {
                Text(message)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.error)
            }
            if viewModel.searchResults.isEmpty && !viewModel.isSearching {
                Text(String(localized: "No providers found"))
                    .font(AppFont.body)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.searchResults) { provider in
                        ReviewProviderRow(provider: provider)
                    }
                }
            }
        }
    }

    private var recentlyViewedSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(String(localized: "Recently Viewed"))
                .font(AppFont.headline)

            if viewModel.recentlyViewed.isEmpty {
                Text(String(localized: "No providers found"))
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(viewModel.recentlyViewed) { provider in
                            ReviewProviderCard(provider: provider)
                        }
                    }
                }
            }
        }
    }

    private var nearbyProvidersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(String(localized: "Nearby Providers"))
                .font(AppFont.headline)

            if viewModel.isLoadingNearby {
                ProgressView()
            } else if viewModel.nearbyProviders.isEmpty {
                Text(String(localized: "No providers found"))
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.nearbyProviders) { provider in
                        ReviewProviderRow(provider: provider)
                    }
                }
            }
        }
    }
}

private struct ReviewProviderCard: View {
    let provider: Provider

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(provider.name)
                .font(AppFont.headline)
            Text(provider.specialty)
                .font(AppFont.caption)
                .foregroundStyle(.secondary)

            NavigationLink {
                ReviewFormView(provider: provider)
            } label: {
                Text(String(localized: "Review"))
                    .font(AppFont.caption)
                    .foregroundStyle(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, AppSpacing.md)
                    .background(AppColor.trustBlue)
                    .cornerRadius(AppRadius.button)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.md)
        .frame(width: 220, alignment: .leading)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
    }
}

private struct ReviewProviderRow: View {
    let provider: Provider

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text(provider.name)
                    .font(AppFont.headline)
                Text(provider.specialty)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                if let distance = provider.distanceKm {
                    Text(String(format: String(localized: "km_away"), distance))
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            NavigationLink {
                ReviewFormView(provider: provider)
            } label: {
                Text(String(localized: "Review"))
                    .font(AppFont.caption)
                    .foregroundStyle(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, AppSpacing.md)
                    .background(AppColor.trustBlue)
                    .cornerRadius(AppRadius.button)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
    }
}
