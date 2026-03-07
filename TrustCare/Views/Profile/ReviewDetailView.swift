import SwiftUI

struct ReviewDetailView: View {
    let review: Review

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(reviewDisplayName)
                    .font(AppFont.title2)

                StarRatingInput(readOnlyRating: Int(round(review.ratingOverall)), starSize: 14)
                PriceLevelView(level: Double(review.priceLevel))

                if let title = review.title {
                    Text(title)
                        .font(AppFont.headline)
                }

                Text(review.comment)
                    .font(AppFont.body)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(tcString("tab_review", fallback: "Review"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

private extension ReviewDetailView {
    var reviewDisplayName: String {
        if review.reviewTargetType == .facility {
            return review.facilityName ?? tcString("unknown_facility", fallback: "Unknown Facility")
        }
        return review.providerName ?? tcString("unknown_provider", fallback: "Unknown Provider")
    }
}
