import SwiftUI

/// A slider view for displaying contextual review metrics with a 1-5 scale
struct ContextualMetricSliderView: View {
    let metric: ContextualReviewMetric
    let currentValue: Int
    let onValueChange: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.label)
                        .font(AppFont.caption)
                        .fontWeight(.semibold)
                    Text(metric.subtext)
                        .font(AppFont.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                if currentValue > 0 {
                    Text("\(currentValue)/5")
                        .font(AppFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(ratingColor)
                        .frame(width: 40)
                }
            }

            Slider(value: Binding(
                get: { Double(currentValue) },
                set: { newValue in
                    let rounded = Int(round(newValue))
                    if rounded != currentValue {
                        onValueChange(rounded)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            ), in: 0...5, step: 1)
            .tint(ratingColor)

            HStack(spacing: AppSpacing.sm) {
                Text("Poor")
                    .font(AppFont.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Excellent")
                    .font(AppFont.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.standard)
    }

    private var ratingColor: Color {
        switch currentValue {
        case 0:
            return Color.gray
        case 1:
            return Color.red
        case 2:
            return Color.orange
        case 3:
            return Color.yellow
        case 4:
            return Color.green
        case 5:
            return AppColor.trustBlue
        default:
            return Color.gray
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ContextualMetricSliderView(
            metric: ContextualReviewMetric(
                label: "Waiting Time",
                subtext: "How long did you wait past your appointment?"
            ),
            currentValue: 3,
            onValueChange: { _ in }
        )

        ContextualMetricSliderView(
            metric: ContextualReviewMetric(
                label: "Doctor Communication",
                subtext: "How carefully did the doctor listen and explain?"
            ),
            currentValue: 0,
            onValueChange: { _ in }
        )
    }
    .padding()
}
