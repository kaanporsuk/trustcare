import SwiftUI

struct CategoryChipView: View {
    let title: String
    let iconName: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.caption)
                Text(title)
                    .font(AppFont.caption)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(isSelected ? tint : Color.tcSurface)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.tcBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
            CategoryChipView(title: "Pharmacy", iconName: "pills.circle.fill", isSelected: true, tint: .green) {}
            CategoryChipView(title: "Hospital", iconName: "cross.case.fill", isSelected: false, tint: .indigo) {}
        }
        .padding()
    }
}
