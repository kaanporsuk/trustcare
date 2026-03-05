import SwiftUI

struct TCEmptyState: View {
    enum Variant {
        case noResults
        case noProviders
        case noReviews

        var titleKey: String {
            switch self {
            case .noResults:
                return "empty_state_no_results_title"
            case .noProviders:
                return "empty_state_no_providers_title"
            case .noReviews:
                return "empty_state_no_reviews_title"
            }
        }

        var titleFallback: String {
            switch self {
            case .noResults:
                return "No results found"
            case .noProviders:
                return "No providers available"
            case .noReviews:
                return "No reviews yet"
            }
        }

        var bodyKey: String {
            switch self {
            case .noResults:
                return "empty_state_no_results_body"
            case .noProviders:
                return "empty_state_no_providers_body"
            case .noReviews:
                return "empty_state_no_reviews_body"
            }
        }

        var bodyFallback: String {
            switch self {
            case .noResults:
                return "Try changing your filters or search query."
            case .noProviders:
                return "Coverage can be limited in some areas. Try another city or specialty."
            case .noReviews:
                return "Be the first to share an experience and help others."
            }
        }
    }

    let variant: Variant
    let customTitle: String?
    let customBody: String?
    let primaryTitle: String
    let secondaryTitle: String?
    let onPrimary: () -> Void
    let onSecondary: (() -> Void)?

    init(
        variant: Variant,
        customTitle: String? = nil,
        customBody: String? = nil,
        primaryTitle: String,
        secondaryTitle: String? = nil,
        onPrimary: @escaping () -> Void,
        onSecondary: (() -> Void)? = nil
    ) {
        self.variant = variant
        self.customTitle = customTitle
        self.customBody = customBody
        self.primaryTitle = primaryTitle
        self.secondaryTitle = secondaryTitle
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.tcOcean)

            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.tcTextSecondary)

            Text(customTitle ?? tcString(variant.titleKey, fallback: variant.titleFallback))
                .font(.system(.title3, design: .default).weight(.semibold))
                .foregroundStyle(Color.tcTextPrimary)

            Text(customBody ?? tcString(variant.bodyKey, fallback: variant.bodyFallback))
                .font(.system(.body, design: .default))
                .foregroundStyle(Color.tcTextSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                TCPrimaryButton(title: primaryTitle, fullWidth: true, action: onPrimary)

                if let secondaryTitle, let onSecondary {
                    Button(action: onSecondary) {
                        Text(secondaryTitle)
                            .font(.system(.headline, design: .default).weight(.semibold))
                            .foregroundStyle(Color.tcOcean)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.tcSurface)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.tcBorder, lineWidth: 1)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.tcSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.tcBorder, lineWidth: 1)
        }
    }
}
