import SDWebImageSwiftUI
import SwiftUI

struct ProviderCardView: View {
    let provider: Provider

    var body: some View {
        NavigationLink {
            ProviderDetailView(providerId: provider.id)
        } label: {
            HStack(spacing: AppSpacing.md) {
                DynamicProviderAvatarView(provider: provider)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.sm) {
                        Text(provider.name)
                            .font(AppFont.title3)
                            .foregroundStyle(.primary)
                        Spacer()
                    }

                    Text(provider.specialty)
                        .font(AppFont.body)
                        .foregroundStyle(.secondary)

                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(AppColor.starFilled)
                        Text(String(format: "%.1f", provider.ratingOverall))
                            .font(AppFont.body)
                        Text("(\(provider.reviewCount))")
                            .font(AppFont.body)
                            .foregroundStyle(.secondary)
                    }

                    if provider.verifiedReviewCount > 0 {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(AppColor.success)
                            Text("Doğrulanmış")
                                .font(AppFont.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let distance = provider.distanceKm {
                        Text(String(format: "%.1f km", distance))
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.lg)
            .background(AppColor.cardBackground)
            .cornerRadius(AppRadius.card)
            .shadow(color: DesignShadow.color, radius: DesignShadow.radius, x: DesignShadow.x, y: DesignShadow.y)
        }
        .buttonStyle(.plain)
    }
}
