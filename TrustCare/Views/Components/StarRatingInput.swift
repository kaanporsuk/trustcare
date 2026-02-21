import SwiftUI
import UIKit

struct StarRatingInput: View {
    @Binding var rating: Int
    var starSize: CGFloat = 28
    var spacing: CGFloat = 6
    var filledColor: Color = Color(hex: "#FFCC00")
    var emptyColor: Color = Color(hex: "#E5E5EA")

    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    @State private var isDragging = false

    init(
        rating: Binding<Int>,
        starSize: CGFloat = 28,
        spacing: CGFloat = 6,
        filledColor: Color = Color(hex: "#FFCC00"),
        emptyColor: Color = Color(hex: "#E5E5EA")
    ) {
        _rating = rating
        self.starSize = starSize
        self.spacing = spacing
        self.filledColor = filledColor
        self.emptyColor = emptyColor
    }

    init(rating: Binding<Int>, size: CGFloat = 28, showsValue: Bool = true) {
        _rating = rating
        self.starSize = size
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .resizable()
                    .scaledToFit()
                    .frame(width: starSize, height: starSize)
                    .foregroundStyle(star <= rating ? filledColor : emptyColor)
                    .scaleEffect(isDragging && star == rating ? 1.15 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: rating)
            }
            Spacer()
            Text("\(rating)/5")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(rating > 0 ? .primary : .secondary)
                .frame(width: 35)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    updateRating(from: value.location.x)
                }
                .onEnded { _ in
                    isDragging = false
                    impactGenerator.impactOccurred()
                }
        )
        .onAppear {
            selectionGenerator.prepare()
            impactGenerator.prepare()
        }
        .accessibilityValue("\(rating) out of 5 stars")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                if rating < 5 { rating += 1 }
            case .decrement:
                if rating > 1 { rating -= 1 }
            @unknown default:
                break
            }
        }
        .accessibilityHint("Swipe up or down to adjust rating")
    }

    private func updateRating(from xPosition: CGFloat) {
        let totalWidth = (starSize + spacing) * 5
        let clampedX = max(0, min(xPosition, totalWidth))
        let newRating = max(1, min(5, Int(clampedX / (starSize + spacing)) + 1))
        if newRating != rating {
            rating = newRating
            selectionGenerator.selectionChanged()
            selectionGenerator.prepare()
        }
    }
}

struct StarRatingDisplay: View {
    let rating: Int
    var starSize: CGFloat = 12
    var filledColor: Color = Color(hex: "#FFCC00")
    var emptyColor: Color = Color(hex: "#E5E5EA")

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .resizable()
                    .scaledToFit()
                    .frame(width: starSize, height: starSize)
                    .foregroundStyle(star <= rating ? filledColor : emptyColor)
            }
        }
    }
}
