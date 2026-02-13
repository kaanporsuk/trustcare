import SDWebImageSwiftUI
import SwiftUI

struct ProviderCardView: View {
    let provider: Provider
    let iconName: String?

    var body: some View {
        NavigationLink {
            ProviderDetailView(providerId: provider.id)
        } label: {
            HStack(spacing: AppSpacing.md) {
                if let urlString = provider.photoUrl, let url = URL(string: urlString) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(provider.name)
                            .font(AppFont.headline)
                            .foregroundStyle(.primary)
                        if provider.isClaimed {
                            ClaimedBadge()
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 6) {
                        if let iconName {
                            Image(systemName: iconName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("\(provider.specialty)" + (provider.clinicName != nil ? " • \(provider.clinicName ?? "")" : ""))
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 6) {
                        StarRatingView(rating: provider.ratingOverall)
                        Text(String(format: "%.1f", provider.ratingOverall))
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: String(localized: "reviews_count"), provider.reviewCount))
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 6) {
                        if provider.reviewCount > 0 {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(AppColor.success)
                            Text(String(format: String(localized: "verified_percentage"), provider.verifiedPercentage))
                                .font(AppFont.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("·")
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                        PriceLevelView(level: provider.priceLevelAvg)
                    }

                    if let distance = provider.distanceKm {
                        Text(String(format: String(localized: "km_away"), distance))
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                    }

                    if provider.isFeatured {
                        Text(String(localized: "Sponsored"))
                            .font(AppFont.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.lg)
            .background(AppColor.cardBackground)
            .cornerRadius(AppRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(provider.isFeatured ? AppColor.featuredBorder : Color.clear, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
