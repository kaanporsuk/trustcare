import SwiftUI

struct MyReviewsView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel
    @Binding var selectedTab: Int

    @State private var pendingDeleteReviewId: UUID?
    @State private var showDeleteConfirm: Bool = false
    @State private var editingReview: Review?

    init(selectedTab: Binding<Int> = .constant(3)) {
        _selectedTab = selectedTab
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Picker(String(localized: "filter_button"), selection: $profileVM.reviewFilter) {
                Text(String(localized: "filter_all")).tag("all")
                Text(String(localized: "status_verified")).tag("verified")
                Text(String(localized: "status_pending")).tag("pending")
                Text(String(localized: "status_unverified")).tag("unverified")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppSpacing.lg)

            if profileVM.isLoading && profileVM.myReviews.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if profileVM.myReviews.isEmpty {
                EmptyStateView(
                    icon: "pencil.and.list.clipboard",
                    title: String(localized: "my_reviews_empty_title"),
                    message: String(localized: "my_reviews_empty_message"),
                    actionTitle: String(localized: "my_reviews_empty_action")
                ) {
                    selectedTab = 2
                }
            } else {
                List {
                    ForEach(profileVM.myReviews) { review in
                        NavigationLink {
                            ReviewDetailView(review: review)
                        } label: {
                            reviewRow(review)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDeleteReviewId = review.id
                                showDeleteConfirm = true
                            } label: {
                                Label(String(localized: "button_delete"), systemImage: "trash")
                            }

                            if canEdit(review) {
                                Button {
                                    editingReview = review
                                } label: {
                                    Label(String(localized: "button_edit"), systemImage: "pencil")
                                }
                                .tint(AppColor.trustBlue)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await profileVM.loadReviews(filter: profileVM.reviewFilter)
                }
            }
        }
        .navigationTitle(String(localized: "menu_my_reviews"))
        .toolbar(.hidden, for: .tabBar)
        .task {
            if profileVM.myReviews.isEmpty {
                await profileVM.loadReviews(filter: profileVM.reviewFilter)
            }
        }
        .onChange(of: profileVM.reviewFilter) { _, newValue in
            Task { await profileVM.loadReviews(filter: newValue) }
        }
        .confirmationDialog(String(localized: "my_reviews_delete_title"), isPresented: $showDeleteConfirm) {
            Button(String(localized: "button_delete"), role: .destructive) {
                if let id = pendingDeleteReviewId {
                    Task { await profileVM.deleteReview(id: id) }
                }
                pendingDeleteReviewId = nil
            }
            Button(String(localized: "button_cancel"), role: .cancel) {
                pendingDeleteReviewId = nil
            }
        } message: {
            Text(String(localized: "my_reviews_delete_message"))
        }
        .sheet(item: $editingReview) { review in
            EditReviewSheet(review: review) { title, comment in
                await profileVM.updateReview(id: review.id, title: title, comment: comment)
                editingReview = nil
            }
        }
        .alert(String(localized: "error_generic"), isPresented: Binding(
            get: { profileVM.errorMessage != nil },
            set: { if !$0 { profileVM.errorMessage = nil } }
        )) {
            Button(String(localized: "button_ok")) { profileVM.errorMessage = nil }
        } message: {
            Text(profileVM.errorMessage ?? "")
        }
    }

    private func reviewRow(_ review: Review) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.providerName ?? String(localized: "unknown_provider"))
                        .font(AppFont.headline)
                    Text(formattedDate(review.createdAt))
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge(review)
            }

            StarRatingInput(readOnlyRating: Int(round(review.ratingOverall)), starSize: 14)

            HStack(spacing: AppSpacing.xs) {
                Text((review.surveyType ?? "general_clinic").replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(AppFont.footnote)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 4)
                    .background(AppColor.trustBlue.opacity(0.12))
                    .foregroundStyle(AppColor.trustBlue)
                    .cornerRadius(AppRadius.button)

                if canEdit(review) {
                    Text(String(localized: "review_editable_24h"))
                        .font(AppFont.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Text(review.comment)
                .font(AppFont.body)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func canEdit(_ review: Review) -> Bool {
        Date().timeIntervalSince(review.createdAt) <= 24 * 60 * 60
    }

    @ViewBuilder
    private func statusBadge(_ review: Review) -> some View {
        if review.isVerified {
            badge(String(localized: "status_verified"), color: AppColor.success)
        } else if review.status == .pendingVerification {
            badge(String(localized: "status_pending"), color: AppColor.pending)
        } else {
            badge(String(localized: "status_unverified"), color: AppColor.unverified)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppFont.footnote)
            .foregroundStyle(color)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(AppRadius.button)
    }
}

private struct EditReviewSheet: View {
    let review: Review
    let onSave: (_ title: String, _ comment: String) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var comment: String
    @State private var isSaving: Bool = false

    init(review: Review, onSave: @escaping (_ title: String, _ comment: String) async -> Void) {
        self.review = review
        self.onSave = onSave
        _title = State(initialValue: review.title ?? "")
        _comment = State(initialValue: review.comment)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "edit_review_title_section")) {
                    TextField(String(localized: "edit_review_title_placeholder"), text: $title)
                }

                Section(String(localized: "edit_review_comment_section")) {
                    TextEditor(text: $comment)
                        .frame(minHeight: 140)
                }
            }
            .navigationTitle(String(localized: "edit_review_title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button_cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button_save")) {
                        Task {
                            isSaving = true
                            await onSave(title, comment)
                            isSaving = false
                            dismiss()
                        }
                    }
                    .disabled(isSaving || comment.trimmingCharacters(in: .whitespacesAndNewlines).count < 10)
                }
            }
        }
    }
}
