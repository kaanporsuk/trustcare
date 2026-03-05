import SwiftUI
import UIKit

extension Color {
    static var tcOcean: Color { dynamicColor(lightHex: "#1B6B93", darkHex: "#4A9ABF") }
    static var tcCoral: Color { dynamicColor(lightHex: "#E8725A", darkHex: "#ED8E7A") }
    static var tcSage: Color { dynamicColor(lightHex: "#5B8C6E", darkHex: "#7AB38D") }

    static var tcBackground: Color { dynamicColor(lightHex: "#F5F0EB", darkHex: "#121110") }
    static var tcSurface: Color { dynamicColor(lightHex: "#FFFFFF", darkHex: "#1C1A18") }
    static var tcTextPrimary: Color { dynamicColor(lightHex: "#1A1814", darkHex: "#F5F0EB") }
    static var tcTextSecondary: Color { dynamicColor(lightHex: "#6B6560", darkHex: "#C4BEB8") }
    static var tcBorder: Color { dynamicColor(lightHex: "#D9D4CF", darkHex: "#2A2724") }

    private static func dynamicColor(lightHex: String, darkHex: String) -> Color {
        Color(
            UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(Color(hex: darkHex))
                    : UIColor(Color(hex: lightHex))
            }
        )
    }
}
