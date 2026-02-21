import SwiftUI

struct MyReviewsView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    @State private var pendingDeleteReviewId: UUID?
    @State private var showDeleteConfirm: Bool = false

    init(selectedTab: Binding<Int> = .constant(2)) {
        _selectedTab = selectedTab
    }

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
                ScrollView {
                    VStack(spacing: AppSpacing.md) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonReviewCard()
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            } else if profileVM.myReviews.isEmpty {
                EmptyStateView(
                    icon: "pencil.and.list.clipboard",
                    title: String(localized: "No reviews yet"),
                    message: String(localized: "Share your healthcare experience to help others"),
                    actionTitle: String(localized: "Write a Review")
                ) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    selectedTab = 1
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.md) {
                        ForEach(profileVM.myReviews) { review in
                            NavigationLink {
                                ReviewDetailView(review: review)
                            } label: {
                                reviewCard(review)
                            }
                            .buttonStyle(.plain)
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
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxl)
                }
                .refreshable {
                    await profileVM.loadReviews()
                }
            }
        }
        .navigationTitle(String(localized: "My Reviews"))
        .toolbar(.hidden, for: .tabBar)
        .task {
            if profileVM.myReviews.isEmpty {
                await profileVM.loadReviews()
            }
        }
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

    private func reviewCard(_ review: Review) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.providerName ?? String(localized: "Unknown Provider"))
                        .font(AppFont.headline)
                    if let specialty = review.providerSpecialty {
                        Text(specialty)
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                verificationBadge(review)
            }

            StarRatingDisplay(rating: Int(round(review.ratingOverall)), starSize: 14)

            Text(reviewSnippet(review.comment))
                .font(AppFont.body)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(formattedDate(review.createdAt))
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func reviewSnippet(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 100 {
            return trimmed
        }
        return String(trimmed.prefix(100)) + "..."
    }

    @ViewBuilder
    private func verificationBadge(_ review: Review) -> some View {
        if review.isVerified {
            Text(String(localized: "Verified"))
                .font(AppFont.footnote)
                .foregroundStyle(AppColor.success)
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
}
