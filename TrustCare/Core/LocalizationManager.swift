import Combine
import SwiftUI

class LocalizationManager: ObservableObject {
    @AppStorage("appLanguage") var appLanguage: String = "en"

    static let supportedLanguages: [(code: String, name: String, flag: String, isRTL: Bool)] = [
        ("en", String(localized: "English"), "GB", false),
        ("de", String(localized: "German"), "DE", false),
        ("nl", String(localized: "Dutch"), "NL", false),
        ("pl", String(localized: "Polish"), "PL", false),
        ("tr", String(localized: "Turkish"), "TR", false),
        ("ar", String(localized: "Arabic"), "SA", true)
    ]

    var layoutDirection: LayoutDirection {
        appLanguage == "ar" ? .rightToLeft : .leftToRight
    }
}
