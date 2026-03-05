import SwiftUI

struct PriceLevelPicker: View {
    @Binding var selection: PriceLevel

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("How expensive was your visit?")
                .font(AppFont.title3)

            LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                ForEach(PriceLevel.allCases) { level in
                    Button {
                        selection = level
                    } label: {
                        VStack(spacing: 6) {
                            Text(level.symbol)
                                .font(AppFont.title2)
                            Text(LocalizedStringKey(level.labelKey))
                                .font(AppFont.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .foregroundStyle(selection == level ? Color.white : Color.primary)
                        .background(selection == level ? Color.tcOcean : Color.tcSurface)
                        .cornerRadius(AppRadius.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.card)
                                .stroke(selection == level ? Color.white : Color.tcBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
