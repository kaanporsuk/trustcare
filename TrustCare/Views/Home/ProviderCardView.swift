import SDWebImageSwiftUI
import SwiftUI

struct ProviderCardView: View {
    let provider: Provider
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        NavigationLink {
            ProviderDetailView(providerId: provider.id)
        } label: {
            HStack(spacing: AppSpacing.md) {
                DynamicProviderAvatarView(provider: provider)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AppSpacing.sm) {
                        Text(provider.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                    }

                    Text(localizedProviderSpecialty)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(AppColor.starFilled)
                        Text(String(format: "%.1f", provider.ratingOverall))
                            .font(.subheadline)
                        Text("(\(provider.reviewCount))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if provider.verifiedReviewCount > 0 {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(AppColor.success)
                            Text("Doğrulanmış")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let distance = provider.distanceKm {
                        Text(String(format: "%.1f km", distance))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(AppColor.cardBackground)
            .cornerRadius(AppRadius.card)
            .shadow(color: DesignShadow.color, radius: DesignShadow.radius, x: DesignShadow.x, y: DesignShadow.y)
        }
        .buttonStyle(.plain)
    }

    private var localizedProviderSpecialty: String {
        guard let specialty = SpecialtyService.shared.specialties.first(where: {
            [
                $0.name,
                $0.nameTr,
                $0.nameDe,
                $0.namePl,
                $0.nameNl,
                $0.nameDa,
            ]
            .compactMap { $0 }
            .contains { $0.caseInsensitiveCompare(provider.specialty) == .orderedSame }
        }) else {
            return provider.specialty
        }

        return specialty.resolvedName(using: localizationManager)
    }
}
