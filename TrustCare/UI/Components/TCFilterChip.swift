import SwiftUI

struct TCFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .font(.system(.subheadline, design: .default).weight(.medium))
                .foregroundStyle(isSelected ? Color.tcOcean : Color.tcTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .frame(minHeight: 34)
                .background(isSelected ? Color.tcOcean.opacity(0.15) : Color.tcSurface)
                .overlay {
                    Capsule()
                        .stroke(isSelected ? Color.tcOcean : Color.tcBorder, lineWidth: 1)
                }
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
