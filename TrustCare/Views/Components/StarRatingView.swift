import SwiftUI

struct StarRatingView: View {
    let rating: Double
    var showValue: Bool = false

    private var roundedRating: Int {
        Int(rating.rounded())
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= roundedRating ? "star.fill" : "star")
                    .foregroundStyle(index <= roundedRating ? Color.tcCoral : Color.tcBorder)
            }
            if showValue {
                Text(String(format: "%.1f", rating))
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
