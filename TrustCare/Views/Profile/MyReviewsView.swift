import SwiftUI

struct MyReviewsView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.locale) private var locale
    @Binding var selectedTab: Int

    @State private var pendingDeleteReviewId: UUID?
    @State private var showDeleteConfirm: Bool = false
    @State private var editingReview: Review?

    init(selectedTab: Binding<Int> = .constant(3)) {
        _selectedTab = selectedTab
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Picker("filter_button", selection: $profileVM.reviewFilter) {
                Text("filter_all").tag("all")
                Text("status_verified").tag("verified")
                Text("status_pending").tag("pending")
                Text("status_unverified").tag("unverified")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppSpacing.lg)

            if profileVM.isLoadingReviews {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if profileVM.myReviews.isEmpty {
                TCEmptyState(
                    variant: .noReviews,
                    customTitle: tcString("reviews_empty_title", fallback: "No reviews yet"),
                    customBody: tcString("my_reviews_empty_body", fallback: "Your reviews help build trust. Share your experience."),
                    primaryTitle: tcString("review_write_cta", fallback: "Write a review")
                ) {
                    selectedTab = 2
                }
                .padding(.horizontal, AppSpacing.lg)
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
                                Label("button_delete", systemImage: "trash")
                            }

                            if canEdit(review) {
                                Button {
                                    editingReview = review
                                } label: {
                                    Label("button_edit", systemImage: "pencil")
                                }
                                .tint(Color.tcOcean)
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
        .navigationTitle(tcString("menu_my_reviews", fallback: "My reviews"))
        .toolbar(.hidden, for: .tabBar)
        .task {
            if profileVM.myReviews.isEmpty {
                await profileVM.loadReviews(filter: profileVM.reviewFilter)
            }
        }
        .onChange(of: profileVM.reviewFilter) { _, newValue in
            Task { await profileVM.loadReviews(filter: newValue) }
        }
        .confirmationDialog("my_reviews_delete_title", isPresented: $showDeleteConfirm) {
            Button("button_delete", role: .destructive) {
                if let id = pendingDeleteReviewId {
                    Task { await profileVM.deleteReview(id: id) }
                }
                pendingDeleteReviewId = nil
            }
            Button("button_cancel", role: .cancel) {
                pendingDeleteReviewId = nil
            }
        } message: {
            Text("my_reviews_delete_message")
        }
        .sheet(item: $editingReview) { review in
            EditReviewSheet(review: review) { title, comment in
                await profileVM.updateReview(id: review.id, title: title, comment: comment)
                editingReview = nil
            }
        }
        .alert(tcString("error_generic", fallback: "Error"), isPresented: Binding(
            get: { profileVM.errorMessage != nil },
            set: { if !$0 { profileVM.errorMessage = nil } }
        )) {
            Button(tcString("button_ok", fallback: "OK")) { profileVM.errorMessage = nil }
        } message: {
            Text(profileVM.errorMessage ?? "")
        }
    }

    private func reviewRow(_ review: Review) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.providerName ?? "unknown_provider")
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
                Text(localizedSurveyTypeKey(review.surveyType ?? "general_clinic"))
                    .font(AppFont.footnote)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.tcOcean.opacity(0.12))
                    .foregroundStyle(Color.tcOcean)
                    .cornerRadius(AppRadius.button)

                if canEdit(review) {
                    Text("review_editable_24h")
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
        formatter.locale = Locale(identifier: locale.identifier)
        return formatter.string(from: date)
    }

    private func canEdit(_ review: Review) -> Bool {
        Date().timeIntervalSince(review.createdAt) <= 24 * 60 * 60
    }

    private func localizedSurveyTypeKey(_ slug: String) -> LocalizedStringKey {
        LocalizedStringKey("survey_\(slug)")
    }

    @ViewBuilder
    private func statusBadge(_ review: Review) -> some View {
        if review.isVerified {
            badge("status_verified", color: Color.tcSage)
        } else if review.status == .pendingVerification {
            badge("status_pending", color: Color.tcCoral)
        } else {
            badge("status_unverified", color: Color.tcTextSecondary)
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
                Section("edit_review_title_section") {
                    TextField("edit_review_title_placeholder", text: $title)
                }

                Section("edit_review_comment_section") {
                    TextEditor(text: $comment)
                        .frame(minHeight: 140)
                }
            }
            .navigationTitle("edit_review_title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button_cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("button_save") {
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
