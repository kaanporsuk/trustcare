import SwiftUI
import CoreLocation

struct TCProviderCard<Destination: View>: View {
    let provider: Provider
    let localizedSpecialty: String
    let destination: () -> Destination

    private var hasCoordinates: Bool {
        let coordinate = CLLocationCoordinate2D(latitude: provider.latitude, longitude: provider.longitude)
        return CLLocationCoordinate2DIsValid(coordinate) && !(provider.latitude == 0 && provider.longitude == 0)
    }

    private var locationLine: String {
        if let city = provider.city?.trimmingCharacters(in: .whitespacesAndNewlines), !city.isEmpty {
            return "Location: \(city)"
        }
        return "Approximate location"
    }

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: AppSpacing.md) {
                DynamicProviderAvatarView(provider: provider)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: AppSpacing.sm) {
                        Text(provider.name)
                            .font(.headline)
                            .foregroundStyle(Color.tcTextPrimary)
                        Spacer()
                    }

                    Text(localizedSpecialty)
                        .font(.subheadline)
                        .foregroundStyle(Color.tcTextSecondary)

                    if provider.reviewCount == 0 {
                        Text("Be the first to review")
                            .font(.footnote)
                            .foregroundStyle(Color.tcTextSecondary)

                        Text("New on TrustCare")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.tcCoral)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.tcCoral.opacity(0.12))
                            .clipShape(Capsule())
                    } else {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(Color.tcCoral)
                            Text(String(format: "%.1f", provider.ratingOverall))
                                .font(.subheadline)
                                .foregroundStyle(Color.tcTextPrimary)
                            Text("(\(provider.reviewCount))")
                                .font(.subheadline)
                                .foregroundStyle(Color.tcTextSecondary)
                        }

                        if provider.verifiedReviewCount > 0 {
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.tcSage)
                                Text("\(provider.verifiedPercentage)% verified")
                                    .font(.footnote)
                                    .foregroundStyle(Color.tcTextSecondary)
                            }
                        }
                    }

                    if hasCoordinates, let distance = provider.distanceKm {
                        Text(String(format: "%.1f km", distance))
                            .font(.footnote)
                            .foregroundStyle(Color.tcTextSecondary)
                    } else {
                        Text(locationLine)
                            .font(.footnote)
                            .foregroundStyle(Color.tcTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .tcCardStyle()
        }
        .buttonStyle(.plain)
    }
}
