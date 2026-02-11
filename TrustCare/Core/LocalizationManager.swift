import Combine
import SwiftUI

class LocalizationManager: ObservableObject {
    @AppStorage("appLanguage") var appLanguage: String = "en"

    static let supportedLanguages: [(code: String, name: String, flag: String, isRTL: Bool)] = [
        ("en", "English", "GB", false),
        ("de", "German", "DE", false),
        ("nl", "Dutch", "NL", false),
        ("pl", "Polish", "PL", false),
        ("tr", "Turkish", "TR", false),
        ("ar", "Arabic", "SA", true)
    ]

    var layoutDirection: LayoutDirection {
        appLanguage == "ar" ? .rightToLeft : .leftToRight
    }
}
