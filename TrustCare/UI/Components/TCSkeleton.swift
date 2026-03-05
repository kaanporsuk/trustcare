import SwiftUI

enum TCSkeletonState {
    case idle
    case loading
    case pending
}

struct TCSkeleton: View {
    var lineCount: Int = 3
    var lineHeight: CGFloat = 14
    var cornerRadius: CGFloat = 8
    var state: TCSkeletonState = .loading

    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<lineCount, id: \.self) { _ in
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.tcBorder.opacity(0.35))
                    .frame(height: lineHeight)
                    .modifier(TCSkeletonShimmerModifier(isActive: state == .loading || state == .pending))
            }
        }
        .opacity(state == .idle ? 0 : 1)
        .animation(.easeInOut(duration: 0.18), value: state == .idle)
        .accessibilityHidden(true)
    }
}

private struct TCSkeletonShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var move = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        LinearGradient(
                            colors: [Color.clear, Color.white.opacity(0.28), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: width * 0.7)
                        .offset(x: move ? width : -width)
                        .onAppear {
                            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                                move = true
                            }
                        }
                    }
                    .clipped()
                    .blendMode(.plusLighter)
                }
            }
    }
}
