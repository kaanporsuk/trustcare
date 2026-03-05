import SwiftUI

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
