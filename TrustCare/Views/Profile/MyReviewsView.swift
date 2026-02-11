import SwiftUI

struct MyReviewsView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel
    @State private var pendingDeleteReviewId: UUID?
    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Picker(String(localized: "Filter"), selection: $profileVM.reviewFilter) {
                Text(String(localized: "All")).tag("all")
                Text(String(localized: "Verified")).tag("verified")
                Text(String(localized: "Pending")).tag("pending")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppSpacing.lg)

            if profileVM.isLoading && profileVM.myReviews.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if profileVM.myReviews.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(profileVM.myReviews) { review in
                        NavigationLink {
                            ReviewDetailView(review: review)
                        } label: {
                            reviewRow(review)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                pendingDeleteReviewId = review.id
                                showDeleteConfirm = true
                            } label: {
                                Text(String(localized: "Delete"))
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await profileVM.loadReviews()
                }
            }
        }
        .navigationTitle(String(localized: "My Reviews"))
        .confirmationDialog(String(localized: "Delete Review"), isPresented: $showDeleteConfirm) {
            Button(String(localized: "Delete"), role: .destructive) {
                if let id = pendingDeleteReviewId {
                    Task { await profileVM.deleteReview(id: id) }
                }
                pendingDeleteReviewId = nil
            }
            Button(String(localized: "Cancel"), role: .cancel) {
                pendingDeleteReviewId = nil
            }
        } message: {
            Text(String(localized: "Are you sure you want to delete this review?"))
        }
        .onChange(of: profileVM.reviewFilter) { _, newValue in
            Task { await profileVM.loadReviews(filter: newValue) }
        }
        .alert(String(localized: "Error"), isPresented: Binding(
            get: { profileVM.errorMessage != nil },
            set: { if !$0 { profileVM.errorMessage = nil } }
        )) {
            Button(String(localized: "Done")) {
                profileVM.errorMessage = nil
            }
        } message: {
            Text(profileVM.errorMessage ?? "")
        }
    }

    private func reviewRow(_ review: Review) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(review.providerName ?? String(localized: "Unknown Provider"))
                .font(AppFont.headline)
            Text(formattedDate(review.createdAt))
                .font(AppFont.caption)
                .foregroundStyle(.secondary)

            StarRatingView(rating: review.ratingOverall)
            PriceLevelView(level: Double(review.priceLevel))

            if review.isVerified {
                VerifiedBadge()
            } else if review.status == .pendingVerification {
                Text(String(localized: "Pending"))
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.pending)
            } else {
                Text(String(localized: "Unverified"))
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.unverified)
            }
        }
        .padding(.vertical, 6)
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(String(localized: "No reviews yet"))
                .font(AppFont.headline)
            Text(String(localized: "Share your first experience!"))
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, AppSpacing.xxl)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
