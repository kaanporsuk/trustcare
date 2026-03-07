import SwiftUI

struct FacilityDetailView: View {
    let facilityId: UUID

    @StateObject private var detailVM = FacilityDetailViewModel()
    @EnvironmentObject private var authVM: AuthViewModel

    private var hasReviews: Bool { detailVM.reviewCount > 0 }

    var body: some View {
        ScrollView {
            if detailVM.isLoading && detailVM.facility == nil {
                VStack {
                    Spacer(minLength: AppSpacing.xxl)
                    ProgressView()
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if let facility = detailVM.facility {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    header(facility)
                    statsSection
                    providersSection
                    reviewsSection
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.lg)
            } else {
                TCEmptyState(
                    variant: .noProviders,
                    customTitle: tcString("facility_unavailable_title", fallback: "Facility unavailable"),
                    customBody: tcString("facility_unavailable_body", fallback: "This facility could not be loaded right now."),
                    primaryTitle: tcString("button_done", fallback: "Done")
                ) {
                    // Intentionally no-op; this keeps the shared empty state contract satisfied.
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
        .navigationTitle(tcString("facility_details_title", fallback: "Facility"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await detailVM.loadDetails(id: facilityId)
        }
        .refreshable {
            await detailVM.loadDetails(id: facilityId)
        }
        .alert(tcString("error_generic", fallback: "Error"), isPresented: Binding(
            get: { detailVM.errorMessage != nil },
            set: { if !$0 { detailVM.errorMessage = nil } }
        )) {
            Button(tcString("button_done", fallback: "Done")) { detailVM.errorMessage = nil }
        } message: {
            Text(detailVM.errorMessage ?? "")
        }
    }

    private func header(_ facility: Facility) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(facility.name)
                .font(AppFont.title1)
                .foregroundStyle(Color.tcTextPrimary)

            Text(detailVM.facilityTypeLabel)
                .font(AppFont.body)
                .foregroundStyle(Color.tcTextSecondary)

            if let city = facility.city, !city.isEmpty {
                Text(city)
                    .font(AppFont.caption)
                    .foregroundStyle(Color.tcTextSecondary)
            }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tcString("facility_ratings_title", fallback: "Facility ratings"))
                .font(AppFont.title3)

            if hasReviews {
                HStack(spacing: AppSpacing.sm) {
                    StarRatingInput(readOnlyRating: Int(round(detailVM.ratingOverall)), starSize: 16)
                    Text(String(format: "%.1f", detailVM.ratingOverall))
                        .font(AppFont.headline)
                    Text(reviewsCountLabel(detailVM.reviewCount))
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                    if detailVM.verifiedReviewCount > 0 {
                        Text("\(detailVM.verifiedReviewCount) \(tcString("status_verified", fallback: "Verified"))")
                            .font(AppFont.caption)
                            .foregroundStyle(Color.tcSage)
                    }
                }
            } else {
                Text(tcString("facility_reviews_empty", fallback: "No facility reviews yet"))
                    .font(AppFont.caption)
                    .foregroundStyle(Color.tcTextSecondary)
            }
        }
    }

    private var providersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tcString("facility_linked_providers_title", fallback: "Providers at this facility"))
                .font(AppFont.title3)

            if detailVM.providers.isEmpty {
                Text(tcString("facility_linked_providers_empty", fallback: "No linked providers yet."))
                    .font(AppFont.caption)
                    .foregroundStyle(Color.tcTextSecondary)
            } else {
                ForEach(detailVM.providers.prefix(8)) { provider in
                    NavigationLink {
                        ProviderDetailView(providerId: provider.id)
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            DynamicProviderAvatarView(provider: provider)
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(provider.name)
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.tcTextPrimary)
                                Text(provider.specialty)
                                    .font(AppFont.caption)
                                    .foregroundStyle(Color.tcTextSecondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tcString("reviews_title", fallback: "Reviews"))
                .font(AppFont.title3)

            if detailVM.reviews.isEmpty {
                Text(tcString("facility_reviews_feed_empty", fallback: "There are no facility reviews to display yet."))
                    .font(AppFont.body)
                    .foregroundStyle(Color.tcTextSecondary)
            } else {
                ForEach(detailVM.reviews) { review in
                    ReviewItemView(review: review)
                    Divider()
                }
            }

            if authVM.isAuthenticated, let facility = detailVM.facility {
                NavigationLink {
                    ReviewHubView(initialFacility: facility)
                } label: {
                    Text(tcString("review_write_for_facility", fallback: "Write a facility review"))
                        .font(AppFont.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(Color.tcOcean)
                        .cornerRadius(AppRadius.button)
                }
                .buttonStyle(.plain)
                .padding(.top, AppSpacing.sm)
            }
        }
    }

    private func reviewsCountLabel(_ count: Int) -> String {
        String(format: tcString("reviews_count_format", fallback: "%lld reviews"), count)
    }
}
