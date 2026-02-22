import SwiftUI

enum DesignCornerRadius {
    static let standard: CGFloat = 12
    static let card: CGFloat = 16
    static let button: CGFloat = 25
}

enum DesignShadow {
    static let color: Color = Color.black.opacity(0.08)
    static let radius: CGFloat = 8
    static let x: CGFloat = 0
    static let y: CGFloat = 2
}

enum DesignSpacing {
    static let scale: [CGFloat] = [4, 8, 12, 16, 20, 24, 32, 48]
}
