import SwiftUI

struct TCFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .font(.system(.subheadline, design: .default).weight(.medium))
                .foregroundStyle(isSelected ? Color.tcOcean : Color.tcTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
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
