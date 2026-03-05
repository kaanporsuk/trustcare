import SwiftUI
import Supabase
import Auth

struct ReviewItemView: View {
    let review: Review
    var onHelpful: ((Bool) -> Void)?
    @State private var isExpanded: Bool = false
    @State private var hasVoted: Bool = false
    @State private var helpfulCount: Int = 0
    @State private var isVoting: Bool = false
    @State private var showingReportSheet: Bool = false
    @State private var hasReported: Bool = false
    @State private var currentUserId: UUID?

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: review.createdAt)
    }
    
    private var isOwnReview: Bool {
        guard let currentUserId else { return false }
        return currentUserId == review.userId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                avatarView

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.reviewerName ?? "Anonymous")
                        .font(AppFont.headline)
                    HStack(spacing: AppSpacing.sm) {
                        if review.isVerified {
                            VerifiedBadge()
                        } else if review.status == .pendingVerification {
                            Text("Pending")
                                .font(AppFont.footnote)
                                .foregroundStyle(Color.tcCoral)
                        }
                    }
                }
                Spacer()
            }

            HStack(spacing: AppSpacing.sm) {
                StarRatingInput(readOnlyRating: Int(round(review.ratingOverall)), starSize: 12)
                Text(formattedDate)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                PriceLevelView(level: Double(review.priceLevel))
            }

            reviewMetricsView

            Text(review.comment)
                .font(AppFont.body)
                .lineLimit(isExpanded ? nil : 3)

            if review.comment.count > 120 {
                Button {
                    isExpanded.toggle()
                } label: {
                    Text(isExpanded ? "Show less" : "Read more")
                        .font(AppFont.caption)
                        .foregroundStyle(Color.tcOcean)
                }
                .buttonStyle(.plain)
            }

            if let media = review.media, !media.isEmpty {
                MediaStripView(media: media)
            }
            
            HStack(spacing: AppSpacing.lg) {
                Button {
                    toggleVote()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: hasVoted ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .foregroundStyle(hasVoted ? Color.tcOcean : .secondary)
                        Text("review_helpful_count_\(helpfulCount)")
                            .font(AppFont.caption)
                            .foregroundStyle(hasVoted ? Color.tcOcean : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isVoting)
                
                Spacer()
                
                if !isOwnReview {
                    Button {
                        if !hasReported {
                            showingReportSheet = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "flag")
                            Text(hasReported ? "report_reported" : "report_button")
                        }
                        .font(AppFont.footnote)
                        .foregroundStyle(hasReported ? .secondary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(hasReported)
                }
            }
        }
        .task {
            await loadVoteData()
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportReviewSheet(reviewId: review.id) {
                hasReported = true
            }
        }
    }
    
    private func loadVoteData() async {
        // Get current user ID
        if let session = try? await SupabaseManager.shared.client.auth.session {
            currentUserId = session.user.id
        }
        
        // Load existing vote
        if let vote = try? await ReviewService.getMyVote(reviewId: review.id) {
            hasVoted = vote
        }
        
        // Load helpful count
        if let count = try? await ReviewService.getHelpfulCount(reviewId: review.id) {
            helpfulCount = count
        } else {
            helpfulCount = review.helpfulCount
        }
        
        // Check if already reported
        if let reported = try? await ReviewService.hasReported(reviewId: review.id) {
            hasReported = reported
        }
    }
    
    private func toggleVote() {
        guard !isVoting else { return }
        isVoting = true
        
        let previousVoteState = hasVoted
        let previousCount = helpfulCount
        
        // Optimistic UI update
        if hasVoted {
            hasVoted = false
            helpfulCount = max(0, helpfulCount - 1)
        } else {
            hasVoted = true
            helpfulCount += 1
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        Task {
            do {
                if previousVoteState {
                    // Remove vote
                    try await ReviewService.removeVote(reviewId: review.id)
                } else {
                    // Add vote
                    try await ReviewService.voteReview(reviewId: review.id, isHelpful: true)
                }
                
                // Refresh count from server
                if let count = try? await ReviewService.getHelpfulCount(reviewId: review.id) {
                    await MainActor.run {
                        helpfulCount = count
                    }
                }
                
                await MainActor.run {
                    isVoting = false
                }
            } catch {
                // Revert on error
                await MainActor.run {
                    hasVoted = previousVoteState
                    helpfulCount = previousCount
                    isVoting = false
                }
                print("⚠️ Failed to vote: \(error.localizedDescription)")
            }
        }
    }

    private var avatarView: some View {
        Group {
            if let urlString = review.reviewerAvatar, let url = URL(string: urlString) {
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
                                print("⚠️ ReviewItemView reviewer avatar failed to load from: \(urlString)")
                                print("   Error: \(error.localizedDescription)")
                            }
                    @unknown default:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }

    @ViewBuilder
    private var reviewMetricsView: some View {
        let config = SurveyConfigurations.config(for: review.surveyType ?? "general_clinic")
        VStack(alignment: .leading, spacing: 4) {
            ForEach(config.metrics) { metric in
                if let ratingValue = review.ratingValue(for: metric.dbColumn), ratingValue > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: metric.icon)
                            .frame(width: 16)
                            .foregroundStyle(.secondary)
                        Text(LocalizedStringKey(metric.labelKey))
                            .font(AppFont.footnote)
                        Spacer()
                        StarRatingInput(readOnlyRating: ratingValue, starSize: 12)
                    }
                }
            }
        }
    }
}
