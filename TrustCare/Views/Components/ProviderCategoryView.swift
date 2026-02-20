import SwiftUI

/// Represents a provider category for filtering and display
enum ProviderCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case pharmacy = "Pharmacies"
    case hospital = "Hospitals"
    case clinic = "Clinics"
    case dentist = "Dentists"

    var id: String { rawValue }
    var displayName: String { rawValue }

    /// Returns the SF Symbol name for this category
    var iconName: String {
        switch self {
        case .all:
            return "stethoscope"
        case .pharmacy:
            return "pills.fill"
        case .hospital:
            return "building.2.fill"
        case .clinic:
            return "stethoscope"
        case .dentist:
            return "tooth.fill"
        }
    }

    /// Returns the background color for this category's avatar
    var backgroundColor: Color {
        switch self {
        case .all:
            return Color.blue
        case .pharmacy:
            return Color.green
        case .hospital:
            return Color.red
        case .clinic:
            return Color.blue
        case .dentist:
            return Color.orange
        }
    }

    /// Returns the relevant specialty names for this category
    var specialtyNames: [String] {
        switch self {
        case .all:
            return [] // No filtering for "All"
        case .pharmacy:
            return ["Pharmacy", "Pharmacist"]
        case .hospital:
            return ["Hospital", "General Hospital", "Specialty Hospital"]
        case .clinic:
            return ["Clinic", "General Practitioner", "Family Medicine", "Primary Care"]
        case .dentist:
            return ["Dentist", "Dental", "Dentistry", "Orthodontist"]
        }
    }
}

/// Helper function to determine provider category from specialty name
/// Returns nil if the specialty doesn't clearly map to a category
func getProviderCategory(from specialty: String) -> ProviderCategory? {
    let lowerSpecialty = specialty.lowercased()

    // Check pharmacy keywords
    if lowerSpecialty.contains("pharmacy") || lowerSpecialty.contains("pharmacist") {
        return .pharmacy
    }

    // Check hospital keywords
    if lowerSpecialty.contains("hospital") {
        return .hospital
    }

    // Check dentist keywords
    if lowerSpecialty.contains("dentist") || lowerSpecialty.contains("dental") || lowerSpecialty.contains("orthodont") {
        return .dentist
    }

    // Check clinic/doctor keywords
    if lowerSpecialty.contains("clinic") || lowerSpecialty.contains("doctor") || 
       lowerSpecialty.contains("practitioner") || lowerSpecialty.contains("family medicine") ||
       lowerSpecialty.contains("gp") || lowerSpecialty.contains("general practice") {
        return .clinic
    }

    return nil
}

/// View for displaying a provider avatar with dynamic icon and color based on category
struct DynamicProviderAvatarView: View {
    let provider: Provider
    let size: CGFloat = 64

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let urlString = provider.photoUrl, let url = URL(string: urlString) {
                // Display provider photo if available
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        categoryPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        categoryPlaceholder
                    @unknown default:
                        categoryPlaceholder
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                // Display category-based icon if no photo
                categoryPlaceholder
            }
        }
    }

    @ViewBuilder
    private var categoryPlaceholder: some View {
        ZStack {
            Circle()
                .fill(categoryColor)

            Image(systemName: categoryIcon)
                .resizable()
                .scaledToFit()
                .padding(14)
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    private var categoryIcon: String {
        if let category = getProviderCategory(from: provider.specialty) {
            return category.iconName
        }
        return "stethoscope"
    }

    private var categoryColor: Color {
        if let category = getProviderCategory(from: provider.specialty) {
            return category.backgroundColor
        }
        return Color.blue
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            DynamicProviderAvatarView(
                provider: Provider(
                    id: UUID(),
                    name: "Test Pharmacy",
                    specialty: "Pharmacy",
                    clinicName: nil,
                    address: "123 Main St",
                    city: "London",
                    countryCode: "GB",
                    latitude: 0,
                    longitude: 0,
                    phone: nil,
                    email: nil,
                    website: nil,
                    photoUrl: nil,
                    coverUrl: nil,
                    languagesSpoken: nil,
                    ratingOverall: 4.5,
                    ratingWaitTime: 4.0,
                    ratingBedside: 4.5,
                    ratingEfficacy: 4.5,
                    ratingCleanliness: 4.5,
                    reviewCount: 10,
                    verifiedReviewCount: 8,
                    priceLevelAvg: 2.0,
                    isClaimed: false,
                    subscriptionTier: .free,
                    isFeatured: false,
                    isActive: true,
                    createdAt: Date(),
                    distanceKm: nil,
                    dataSource: nil,
                    externalId: nil,
                    updatedAt: nil,
                    deletedAt: nil,
                    priceLevel: nil
                )
            )

            DynamicProviderAvatarView(
                provider: Provider(
                    id: UUID(),
                    name: "Test Hospital",
                    specialty: "Hospital",
                    clinicName: nil,
                    address: "456 High St",
                    city: "London",
                    countryCode: "GB",
                    latitude: 0,
                    longitude: 0,
                    phone: nil,
                    email: nil,
                    website: nil,
                    photoUrl: nil,
                    coverUrl: nil,
                    languagesSpoken: nil,
                    ratingOverall: 4.5,
                    ratingWaitTime: 4.0,
                    ratingBedside: 4.5,
                    ratingEfficacy: 4.5,
                    ratingCleanliness: 4.5,
                    reviewCount: 10,
                    verifiedReviewCount: 8,
                    priceLevelAvg: 2.0,
                    isClaimed: false,
                    subscriptionTier: .free,
                    isFeatured: false,
                    isActive: true,
                    createdAt: Date(),
                    distanceKm: nil,
                    dataSource: nil,
                    externalId: nil,
                    updatedAt: nil,
                    deletedAt: nil,
                    priceLevel: nil
                )
            )
        }

        Text("Categories: Pharmacy (Green), Hospital (Red), Clinic (Blue), Dentist (Orange)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}
