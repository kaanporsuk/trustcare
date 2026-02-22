import SwiftUI

enum AppColor {
    static let trustBlue = Color(hex: "#0055FF")
    static let trustBlueLight = Color(hex: "#4D88FF")
    static let trustBlueDark = Color(hex: "#003ACC")

    static let background = Color(.systemBackground)
    static let cardBackground = Color(.secondarySystemBackground)
    static let border = Color(.separator)

    static let success = Color(hex: "#34C759")
    static let warning = Color(hex: "#FF9500")
    static let error = Color(hex: "#FF3B30")
    static let info = Color(hex: "#007AFF")
    static let premium = Color(hex: "#AF52DE")

    static let verified = Color(hex: "#34C759")
    static let pending = Color(hex: "#FF9500")
    static let unverified = Color(.secondaryLabel)

    static let starFilled = Color(hex: "#FFCC00")
    static let starEmpty = Color(.systemGray4)

    static let mapClinic = Color(hex: "#0055FF")
    static let mapHospital = Color(hex: "#5856D6")
    static let mapDental = Color(hex: "#007AFF")
    static let mapPharmacy = Color(hex: "#34C759")
    static let mapDiagnostic = Color(hex: "#FF9500")
    static let mapMentalHealth = Color(hex: "#AF52DE")
    static let mapRehab = Color(hex: "#00C7BE")
    static let mapAesthetics = Color(hex: "#FF2D55")

    static let priceActive = Color(hex: "#34C759")
    static let priceInactive = Color(.systemGray4)
    static let featuredBorder = Color(hex: "#0055FF").opacity(0.3)
}

enum AppFont {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let callout = Font.system(size: 16, weight: .regular)
    static let caption = Font.system(size: 15, weight: .regular)
    static let footnote = Font.system(size: 13, weight: .regular)
}

enum AppSpacing {
    static let xs: CGFloat = DesignSpacing.scale[0]
    static let sm: CGFloat = DesignSpacing.scale[1]
    static let md: CGFloat = DesignSpacing.scale[2]
    static let lg: CGFloat = DesignSpacing.scale[3]
    static let xl: CGFloat = DesignSpacing.scale[4]
    static let xxl: CGFloat = DesignSpacing.scale[5]
    static let xxxl: CGFloat = DesignSpacing.scale[6]
    static let xxxxl: CGFloat = DesignSpacing.scale[7]
}

enum AppRadius {
    static let standard: CGFloat = DesignCornerRadius.standard
    static let card: CGFloat = DesignCornerRadius.card
    static let button: CGFloat = DesignCornerRadius.button
}
