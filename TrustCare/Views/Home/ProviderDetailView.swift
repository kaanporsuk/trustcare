import MapKit
import SDWebImageSwiftUI
import SwiftUI
import UIKit

struct ProviderDetailView: View {
    let providerId: UUID
    @StateObject private var detailVM = ProviderDetailViewModel()
    @State private var showClaimSheet: Bool = false
    @State private var showAuthRequiredAlert: Bool = false
    @State private var isSaved: Bool = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var localizationManager: LocalizationManager

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
                    Text("Provider unavailable")
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
        .alert("Error", isPresented: Binding(
            get: { detailVM.errorMessage != nil },
            set: { if !$0 { detailVM.errorMessage = nil } }
        )) {
            Button("Done") {
                detailVM.errorMessage = nil
            }
        } message: {
            Text(detailVM.errorMessage ?? "")
        }
        .alert("Sign In Required", isPresented: $showAuthRequiredAlert) {
            Button("Login / Sign Up") {
                NotificationCenter.default.post(name: .trustCareRouteToAuth, object: nil)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You must be signed in to leave a review.")
        }
        .toolbar(.hidden, for: .tabBar)
        .overlay(alignment: .bottom) {
            if let provider = detailVM.provider {
                if authVM.isAuthenticated {
                    NavigationLink {
                        ReviewHubView(initialProvider: provider)
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
        Label("button_review", systemImage: "star.bubble")
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
                .accessibilityLabel("Back")

                Spacer()

                if let provider = detailVM.provider {
                    ShareLink(item: shareItem(provider: provider)) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Share")
                }
            }
            .padding([.top, .horizontal], AppSpacing.lg)
        }
        .padding(.bottom, AppSpacing.xxl)
    }

    private var claimBanner: some View {
        Group {
            if detailVM.provider?.isClaimed == false {
                if let claim = detailVM.myClaimStatus {
                    // User has already submitted a claim
                    if claim.status == .pending {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("claim_pending")
                                    .font(AppFont.headline)
                                    .foregroundStyle(.primary)
                                Text("claim_pending_message")
                                    .font(AppFont.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(AppRadius.card)
                        .padding(.horizontal, AppSpacing.lg)
                    } else if claim.status == .rejected {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("claim_rejected")
                                        .font(AppFont.headline)
                                        .foregroundStyle(.primary)
                                    if let reason = claim.rejectionReason {
                                        Text(reason)
                                            .font(AppFont.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            Button {
                                showClaimSheet = true
                            } label: {
                                Text("claim_resubmit")
                                    .font(AppFont.footnote)
                                    .foregroundStyle(AppColor.trustBlue)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, AppSpacing.md)
                                    .background(AppColor.trustBlue.opacity(0.1))
                                    .cornerRadius(AppRadius.button)
                            }
                        }
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(AppRadius.card)
                        .padding(.horizontal, AppSpacing.lg)
                    }
                } else {
                    // No claim yet - show claim button
                    Button {
                        showClaimSheet = true
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "building.2.fill")
                                .foregroundStyle(AppColor.trustBlue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("is_this_your_practice")
                                    .font(AppFont.headline)
                                    .foregroundStyle(.primary)
                                Text("claim_description")
                                    .font(AppFont.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("claim_profile")
                                .font(AppFont.footnote)
                                .foregroundStyle(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, AppSpacing.md)
                                .background(AppColor.trustBlue)
                                .cornerRadius(AppRadius.button)
                        }
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColor.trustBlue.opacity(0.1))
                        .cornerRadius(AppRadius.card)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppSpacing.lg)
                }
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

            Text(localizedProviderSpecialty)
                .font(AppFont.body)
                .foregroundStyle(.secondary)

            if let clinic = detailVM.provider?.clinicName {
                Text(clinic)
                    .font(AppFont.body)
            }

            HStack(spacing: AppSpacing.sm) {
                StarRatingInput(readOnlyRating: Int(round(detailVM.provider?.ratingOverall ?? 0)), starSize: 16)
                Text(String(format: "reviews_count", detailVM.provider?.reviewCount ?? 0))
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                Text("\(detailVM.provider?.verifiedPercentage ?? 0)% \("Verified")")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.success)
            }

            HStack(spacing: AppSpacing.sm) {
                PriceLevelView(level: detailVM.provider?.priceLevelAvg ?? 0)
                Text("Price")
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

    private var localizedProviderSpecialty: String {
        guard let provider = detailVM.provider else { return "" }

        guard let specialty = SpecialtyService.shared.specialties.first(where: {
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

    private var quickActions: some View {
        let provider = detailVM.provider
        let hasPhone = provider?.phone != nil && !(provider?.phone?.isEmpty ?? true)

        return HStack(spacing: AppSpacing.sm) {
            Button {
                if hasPhone {
                    callProvider(phone: provider?.phone)
                } else {
                    print("Add phone number tapped")
                }
            } label: {
                VStack {
                    Image(systemName: hasPhone ? "phone.fill" : "phone.badge.plus")
                        .font(.system(size: 16))
                    Text("button_call")
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
                Label("button_directions", systemImage: "map.fill")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button)
                            .stroke(AppColor.trustBlue, lineWidth: 1)
                    )
                    .foregroundStyle(AppColor.trustBlue)
            }

            Button {
                isSaved.toggle()
            } label: {
                Label("button_save", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(isSaved ? AppColor.trustBlue.opacity(0.12) : Color.clear)
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
                Text("Ratings Breakdown")
                    .font(AppFont.title3)

                ForEach(config.metrics) { metric in
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: metric.icon)
                            .foregroundStyle(.secondary)
                        Text(LocalizedStringKey(metric.labelKey))
                            .font(AppFont.body)
                        Spacer()
                        if let value = provider.aggregateRating(for: metric.dbColumn), value > 0 {
                            Text(String(format: "%.1f/5", value))
                                .font(AppFont.headline)
                        } else {
                            Text("N/A")
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
                        Text("Services & Prices")
                            .font(AppFont.title3)
                        Spacer()
                        NavigationLink {
                            ServicesCatalogView(providerName: detailVM.provider?.name ?? "", services: detailVM.services)
                        } label: {
                            Text("View All")
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
                Text("Reviews")
                    .font(AppFont.title3)
                Spacer()
                Picker("Sort", selection: .constant(0)) {
                    Text("Newest").tag(0)
                    Text("Highest Rated").tag(1)
                }
                .pickerStyle(.menu)
            }

            if detailVM.reviews.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "text.bubble")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No reviews yet")
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
                Text("See All Reviews")
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
