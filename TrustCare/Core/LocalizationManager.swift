import SwiftUI

class LocalizationManager: ObservableObject {
    @AppStorage("appLanguage") var appLanguage: String = "en"

    static let supportedLanguages: [(code: String, name: String, flag: String, isRTL: Bool)] = [
        ("en", "English", "🇬🇧", false),
        ("de", "Deutsch", "🇩🇪", false),
        ("nl", "Nederlands", "🇳🇱", false),
        ("pl", "Polski", "🇵🇱", false),
        ("tr", "Türkçe", "🇹🇷", false),
        ("ar", "العربية", "🇸🇦", true),
    ]

    var layoutDirection: LayoutDirection {
        appLanguage == "ar" ? .rightToLeft : .leftToRight
    }
}
