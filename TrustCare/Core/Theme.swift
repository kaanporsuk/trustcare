import SwiftUI

enum AppColor {
    static let trustBlue = Color(hex: "#0055FF")
    static let trustBlueLight = Color(hex: "#4D88FF")
    static let trustBlueDark = Color(hex: "#0044CC")
    static let background = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let border = Color(.separator)
    static let success = Color(hex: "#34C759")
    static let warning = Color(hex: "#FF9500")
    static let error = Color(hex: "#FF3B30")
    static let verified = Color(hex: "#34C759")
    static let pending = Color(hex: "#FF9500")
    static let unverified = Color(.secondaryLabel)
    static let starFilled = Color(hex: "#FFCC00")
    static let starEmpty = Color(.systemGray5)
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
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

enum AppRadius {
    static let standard: CGFloat = 12
    static let card: CGFloat = 16
    static let button: CGFloat = 12
}
