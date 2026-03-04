import SwiftUI

struct PremiumEmptyStateCard: View {
    let iconName: String
    let title: String
    let bulletKeys: [LocalizedStringKey]
    let primaryActionTitleKey: LocalizedStringKey
    let primaryAction: () -> Void
    let secondaryActionTitleKey: LocalizedStringKey
    let secondaryAction: () -> Void
    let tertiaryActionTitleKey: LocalizedStringKey?
    let tertiaryAction: (() -> Void)?

    init(
        iconName: String = "sparkles",
        title: String,
        bulletKeys: [LocalizedStringKey],
        primaryActionTitleKey: LocalizedStringKey,
        primaryAction: @escaping () -> Void,
        secondaryActionTitleKey: LocalizedStringKey,
        secondaryAction: @escaping () -> Void,
        tertiaryActionTitleKey: LocalizedStringKey? = nil,
        tertiaryAction: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.bulletKeys = bulletKeys
        self.primaryActionTitleKey = primaryActionTitleKey
        self.primaryAction = primaryAction
        self.secondaryActionTitleKey = secondaryActionTitleKey
        self.secondaryAction = secondaryAction
        self.tertiaryActionTitleKey = tertiaryActionTitleKey
        self.tertiaryAction = tertiaryAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColor.trustBlue)
                Text(title)
                    .font(AppFont.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(Array(bulletKeys.enumerated()), id: \.offset) { _, key in
                    HStack(alignment: .top, spacing: AppSpacing.xs) {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(key)
                            .font(AppFont.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: AppSpacing.sm) {
                Button(action: primaryAction) {
                    Text(primaryActionTitleKey)
                        .font(AppFont.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColor.trustBlue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button(action: secondaryAction) {
                    Text(secondaryActionTitleKey)
                        .font(AppFont.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.trustBlue)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColor.cardBackground)
                        .overlay(
                            Capsule().stroke(AppColor.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                if let tertiaryActionTitleKey, let tertiaryAction {
                    Button(action: tertiaryAction) {
                        Text(tertiaryActionTitleKey)
                            .font(AppFont.callout)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(AppRadius.card)
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }
}
