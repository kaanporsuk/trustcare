import SwiftUI

struct ReviewDetailView: View {
    let review: Review

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(review.providerName ?? String(localized: "Unknown Provider"))
                    .font(AppFont.title2)

                StarRatingDisplay(rating: Int(round(review.ratingOverall)), starSize: 14)
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
        .navigationTitle(String(localized: "Review"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
