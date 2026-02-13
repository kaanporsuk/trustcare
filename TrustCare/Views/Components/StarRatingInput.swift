import SwiftUI
import UIKit

struct StarRatingInput: View {
    @Binding var rating: Int
    let size: CGFloat
    let showsValue: Bool

    @State private var lastHapticRating: Int = 0

    init(rating: Binding<Int>, size: CGFloat = 22, showsValue: Bool = true) {
        _rating = rating
        self.size = size
        self.showsValue = showsValue
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            GeometryReader { proxy in
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: rating >= index ? "star.fill" : "star")
                            .resizable()
                            .frame(width: size, height: size)
                            .foregroundStyle(rating >= index ? AppColor.starFilled : AppColor.starEmpty)
                            .animation(.easeInOut(duration: 0.15), value: rating)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newRating = ratingFromLocation(value.location.x, width: proxy.size.width)
                            if newRating != rating {
                                rating = newRating
                                triggerHaptic(for: newRating)
                            }
                        }
                )
            }
            .frame(height: size)

            if showsValue {
                Text("\(rating)/5")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func ratingFromLocation(_ x: CGFloat, width: CGFloat) -> Int {
        guard width > 0 else { return 0 }
        let raw = Int(ceil((x / width) * 5.0))
        return max(1, min(5, raw))
    }

    private func triggerHaptic(for newRating: Int) {
        guard newRating != lastHapticRating else { return }
        lastHapticRating = newRating
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
