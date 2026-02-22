import MapKit
import SDWebImageSwiftUI
import SwiftUI
import UIKit

struct ProviderDetailView: View {
    let providerId: UUID
    @StateObject private var detailVM = ProviderDetailViewModel()
    @State private var showClaimSheet: Bool = false
    @State private var showAuthRequiredAlert: Bool = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        ScrollView {
            if detailVM.isLoading && detailVM.provider == nil {
                VStack {
                    Spacer(minLength: AppSpacing.xxl)
                    ProgressView()
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if detailVM.provider == nil {
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(String(localized: "Provider unavailable"))
                        .font(AppFont.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, AppSpacing.xxl)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: AppSpacing.lg) {
                    heroSection
                    claimBanner
                    infoSection
                    quickActions
                    statsGrid
                    servicesSection
                    reviewsSection
                }
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            await detailVM.loadDetails(id: providerId)
        }
        .task {
            await detailVM.loadDetails(id: providerId)
        }
        .onChange(of: detailVM.provider?.id) { _, _ in
            if let provider = detailVM.provider {
                RecentProvidersStore.add(provider)
            }
        }
        .sheet(isPresented: $showClaimSheet) {
            if let provider = detailVM.provider {
                ClaimProviderView(providerId: provider.id, providerName: provider.name)
            }
        }
        .alert(String(localized: "Error"), isPresented: Binding(
            get: { detailVM.errorMessage != nil },
            set: { if !$0 { detailVM.errorMessage = nil } }
        )) {
            Button(String(localized: "Done")) {
                detailVM.errorMessage = nil
            }
        } message: {
            Text(detailVM.errorMessage ?? "")
        }
        .alert(String(localized: "Sign In Required"), isPresented: $showAuthRequiredAlert) {
            Button(String(localized: "Login / Sign Up")) {
                NotificationCenter.default.post(name: .trustCareRouteToAuth, object: nil)
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "You must be signed in to leave a review."))
        }
        .toolbar(.hidden, for: .tabBar)
        .overlay(alignment: .bottom) {
            if let provider = detailVM.provider {
                if authVM.isAuthenticated {
                    NavigationLink {
                        ReviewFormView(provider: provider)
                    } label: {
                        reviewButtonLabel
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, AppSpacing.lg)
                } else {
                    Button {
                        showAuthRequiredAlert = true
                    } label: {
                        reviewButtonLabel
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, AppSpacing.lg)
                }
            }
        }
    }

    private var reviewButtonLabel: some View {
        Label(String(localized: "Write a Review"), systemImage: "star.bubble")
            .font(AppFont.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, AppSpacing.lg)
            .background(AppColor.trustBlue)
            .cornerRadius(999)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let urlString = detailVM.provider?.coverUrl, let url = URL(string: urlString) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 250)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [AppColor.trustBlueLight, AppColor.trustBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 250)
            }

            HStack(spacing: AppSpacing.md) {
                if let urlString = detailVM.provider?.photoUrl, let url = URL(string: urlString) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.white)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                }

                Spacer()
            }
            .padding(.leading, AppSpacing.lg)
            .offset(y: 50)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }
                .accessibilityLabel(String(localized: "Back"))

                Spacer()

                if let provider = detailVM.provider {
                    ShareLink(item: shareItem(provider: provider)) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(String(localized: "Share"))
                }
            }
            .padding([.top, .horizontal], AppSpacing.lg)
        }
        .padding(.bottom, AppSpacing.xxl)
    }

    private var claimBanner: some View {
        Group {
            if detailVM.provider?.isClaimed == false {
                Button {
                    showClaimSheet = true
                } label: {
                    HStack {
                        Text(String(localized: "Is this your practice? Claim it ->"))
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(AppFont.caption)
                    .foregroundStyle(.white)
                    .padding(AppSpacing.md)
                    .background(AppColor.trustBlue)
                    .cornerRadius(AppRadius.button)
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Text(detailVM.provider?.name ?? "")
                    .font(AppFont.title1)
                if detailVM.provider?.isClaimed == true {
                    ClaimedBadge()
                }
            }

            Text(detailVM.provider?.specialty ?? "")
                .font(AppFont.body)
                .foregroundStyle(.secondary)

            if let clinic = detailVM.provider?.clinicName {
                Text(clinic)
                    .font(AppFont.body)
            }

            HStack(spacing: AppSpacing.sm) {
                StarRatingDisplay(rating: Int(round(detailVM.provider?.ratingOverall ?? 0)), starSize: 16)
                Text(String(format: String(localized: "reviews_count"), detailVM.provider?.reviewCount ?? 0))
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                Text("\(detailVM.provider?.verifiedPercentage ?? 0)% \(String(localized: "Verified"))")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.success)
            }

            HStack(spacing: AppSpacing.sm) {
                PriceLevelView(level: detailVM.provider?.priceLevelAvg ?? 0)
                Text(String(localized: "Price"))
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }

            if let address = detailVM.provider?.address {
                Button {
                    openMaps(address: address)
                } label: {
                    Text(address)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.trustBlue)
                }
                .buttonStyle(.plain)
            }

            if let phone = detailVM.provider?.phone {
                Button {
                    openPhone(phone)
                } label: {
                    Text(phone)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.trustBlue)
                }
                .buttonStyle(.plain)
            }

            if let website = detailVM.provider?.website, let url = URL(string: website) {
                Link(website, destination: url)
                    .font(AppFont.body)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickActions: some View {
        let provider = detailVM.provider
        let hasPhone = provider?.phone != nil && !(provider?.phone?.isEmpty ?? true)

        return HStack(spacing: AppSpacing.md) {
            Button {
                if hasPhone {
                    callProvider(phone: provider?.phone)
                } else {
                    print("Add phone number tapped")
                }
            } label: {
                VStack {
                    Image(systemName: hasPhone ? "phone.fill" : "phone.badge.plus")
                        .font(.system(size: 20))
                    Text(hasPhone ? "Call" : "Add Number")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(hasPhone ? .white : Color(hex: "#0055FF"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(hasPhone ? Color(hex: "#0055FF") : Color(hex: "#0055FF").opacity(0.1))
                .cornerRadius(12)
            }

            Button {
                if let address = detailVM.provider?.address {
                    openMaps(address: address)
                }
            } label: {
                Label(String(localized: "Directions"), systemImage: "map.fill")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button)
                            .stroke(AppColor.trustBlue, lineWidth: 1)
                    )
                    .foregroundStyle(AppColor.trustBlue)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private func callProvider(phone: String?) {
        guard let phone = phone, !phone.isEmpty else { return }
        let cleanedPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(cleanedPhone)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private var statsGrid: some View {
        guard let provider = detailVM.provider else {
            return AnyView(EmptyView())
        }

        let config = SpecialtyService.shared.surveyConfig(for: provider.specialty)

        return AnyView(
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(String(localized: "Ratings Breakdown"))
                    .font(AppFont.title3)

                ForEach(config.metrics) { metric in
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: metric.icon)
                            .foregroundStyle(.secondary)
                        Text(metric.label)
                            .font(AppFont.body)
                        Spacer()
                        if let value = provider.aggregateRating(for: metric.dbColumn), value > 0 {
                            Text(String(format: "%.1f/5", value))
                                .font(AppFont.headline)
                        } else {
                            Text(String(localized: "N/A"))
                                .font(AppFont.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        )
    }

    private var servicesSection: some View {
        Group {
            if detailVM.provider?.isClaimed == true && !detailVM.services.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text(String(localized: "Services & Prices"))
                            .font(AppFont.title3)
                        Spacer()
                        NavigationLink {
                            ServicesCatalogView(providerName: detailVM.provider?.name ?? "", services: detailVM.services)
                        } label: {
                            Text(String(localized: "View All"))
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.trustBlue)
                        }
                    }

                    ForEach(detailVM.services.prefix(3)) { item in
                        ServiceItemRow(item: item)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text(String(localized: "Reviews"))
                    .font(AppFont.title3)
                Spacer()
                Picker(String(localized: "Sort"), selection: .constant(0)) {
                    Text(String(localized: "Newest")).tag(0)
                    Text(String(localized: "Highest Rated")).tag(1)
                }
                .pickerStyle(.menu)
            }

            if detailVM.reviews.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "text.bubble")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(String(localized: "No reviews yet"))
                        .font(AppFont.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, AppSpacing.md)
            } else {
                ForEach(detailVM.reviews.prefix(5)) { review in
                    ReviewItemView(review: review) { isHelpful in
                        Task { await detailVM.voteHelpful(reviewId: review.id, isHelpful: isHelpful) }
                    }
                }
            }

            NavigationLink {
                ReviewListView(providerId: providerId)
            } label: {
                Text(String(localized: "See All Reviews"))
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.trustBlue)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.xxl)
    }

    private func openMaps(address: String) {
        let query = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
            UIApplication.shared.open(url)
        }
    }

    private func openPhone(_ phone: String) {
        let sanitized = phone.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel://\(sanitized)") {
            UIApplication.shared.open(url)
        }
    }

    private func shareItem(provider: Provider) -> String {
        if let website = provider.website, !website.isEmpty {
            return website
        }
        return provider.name
    }
}

private struct ServiceItemRow: View {
    let item: ProviderServiceItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(AppFont.body)
                if let description = item.description {
                    Text(description)
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let priceMin = item.priceMin {
                if let priceMax = item.priceMax {
                    Text("\(item.currency)\(String(format: "%.0f", priceMin)) - \(item.currency)\(String(format: "%.0f", priceMax))")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.trustBlue)
                } else {
                    Text("\(item.currency)\(String(format: "%.0f", priceMin))")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.trustBlue)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
