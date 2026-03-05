import SwiftUI

private struct TCCardStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Color.tcSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.tcBorder : Color.clear, lineWidth: colorScheme == .dark ? 1 : 0)
            }
            .shadow(
                color: colorScheme == .dark ? .clear : Color.black.opacity(0.08),
                radius: colorScheme == .dark ? 0 : 12,
                x: 0,
                y: colorScheme == .dark ? 0 : 4
            )
    }
}

private struct TCGlassBackgroundModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background {
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.tcSurface.opacity(0.92))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.tcBorder, lineWidth: 1)
                        }
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            }
    }
}

extension View {
    func tcCardStyle() -> some View {
        modifier(TCCardStyleModifier())
    }

    func tcGlassBackground() -> some View {
        modifier(TCGlassBackgroundModifier())
    }
}
