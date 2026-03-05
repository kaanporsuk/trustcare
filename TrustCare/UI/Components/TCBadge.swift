import SwiftUI

struct TCBadge: View {
    enum Style {
        case verified
        case neutral
    }

    let text: String
    let style: Style

    init(_ text: String, style: Style = .neutral) {
        self.text = text
        self.style = style
    }

    var body: some View {
        HStack(spacing: 6) {
            if style == .verified {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 11, weight: .semibold))
            }

            Text(text)
                .font(.system(.caption, design: .default).weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    private var foregroundColor: Color {
        switch style {
        case .verified:
            return Color.tcSage
        case .neutral:
            return Color.tcTextSecondary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .verified:
            return Color.tcSage.opacity(0.15)
        case .neutral:
            return Color.tcBorder.opacity(0.45)
        }
    }
}
