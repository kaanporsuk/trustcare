import SwiftUI
import UIKit

struct RatingSliderView: View {
    let icon: String
    let label: String
    @Binding var value: Double

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(AppColor.trustBlue)
                    .clipShape(Circle())
                Text(label)
                    .font(AppFont.headline)
                Spacer()
            }

            Slider(value: $value, in: 1...10, step: 1)
                .tint(AppColor.trustBlue)
                .onChange(of: value) { _, _ in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

            HStack {
                Text("Poor")
                    .font(AppFont.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value))/10")
                    .font(AppFont.headline)
                Spacer()
                Text("Excellent")
                    .font(AppFont.footnote)
                    .foregroundStyle(.secondary)
            }

            StarRatingInput(readOnlyRating: Int(round(value / 2.0)), starSize: 12)
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
    }
}
