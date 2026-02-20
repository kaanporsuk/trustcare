import SwiftUI

/// A chip view for displaying and selecting a provider category
struct CategoryChipView: View {
    let category: ProviderCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.iconName)
                    .font(.caption)
                Text(category.displayName)
                    .font(AppFont.caption)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(isSelected ? category.backgroundColor : AppColor.cardBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : AppColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
            ForEach(ProviderCategory.allCases) { category in
                CategoryChipView(
                    category: category,
                    isSelected: category == .pharmacy
                ) {
                    print("Tapped \(category.displayName)")
                }
            }
        }
        .padding()
    }
}
