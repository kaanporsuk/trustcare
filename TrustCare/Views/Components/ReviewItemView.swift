import SwiftUI

struct ReviewItemView: View {
    let review: Review
    var onHelpful: ((Bool) -> Void)?
    @State private var isExpanded: Bool = false

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: review.createdAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                avatarView

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.reviewerName ?? String(localized: "Anonymous"))
                        .font(AppFont.headline)
                    HStack(spacing: AppSpacing.sm) {
                        if review.isVerified {
                            VerifiedBadge()
                        } else if review.status == .pendingVerification {
                            Text(String(localized: "Pending"))
                                .font(AppFont.footnote)
                                .foregroundStyle(AppColor.pending)
                        }
                    }
                }
                Spacer()
            }

            HStack(spacing: AppSpacing.sm) {
                StarRatingView(rating: review.ratingOverall)
                Text(formattedDate)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                PriceLevelView(level: Double(review.priceLevel))
            }

            Text(review.comment)
                .font(AppFont.body)
                .lineLimit(isExpanded ? nil : 3)

            if review.comment.count > 120 {
                Button {
                    isExpanded.toggle()
                } label: {
                    Text(isExpanded ? String(localized: "Show less") : String(localized: "Read more"))
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.trustBlue)
                }
                .buttonStyle(.plain)
            }

            if let media = review.media, !media.isEmpty {
                MediaStripView(media: media)
            }

            Button {
                onHelpful?(true)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "hand.thumbsup")
                    Text("\(review.helpfulCount)")
                }
            }
            .font(AppFont.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var avatarView: some View {
        Group {
            if let urlString = review.reviewerAvatar, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
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
}
