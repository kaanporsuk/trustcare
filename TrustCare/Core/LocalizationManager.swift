import Combine
import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case en
    case tr
    case de
    case pl
    case nl

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .en: return "English"
        case .tr: return "Türkçe"
        case .de: return "Deutsch"
        case .pl: return "Polski"
        case .nl: return "Nederlands"
        }
    }
}

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published private(set) var currentLanguage: AppLanguage

    private let languageDefaultsKey = "AppLanguage"

    private init() {
        let defaults = UserDefaults.standard

        if let savedCode = defaults.string(forKey: languageDefaultsKey),
           let savedLanguage = AppLanguage(rawValue: savedCode) {
            currentLanguage = savedLanguage
        } else {
            let detected = Self.detectSystemLanguage()
            currentLanguage = detected
            defaults.set(detected.rawValue, forKey: languageDefaultsKey)
        }
    }

    func setLanguage(_ lang: AppLanguage) {
        guard currentLanguage != lang else { return }
        currentLanguage = lang
        UserDefaults.standard.set(lang.rawValue, forKey: languageDefaultsKey)
    }

    var layoutDirection: LayoutDirection {
        .leftToRight
    }

    private static func detectSystemLanguage() -> AppLanguage {
        guard let preferredLanguage = Locale.preferredLanguages.first?.lowercased() else {
            return .en
        }

        let prefix = String(preferredLanguage.prefix(2))
        return AppLanguage(rawValue: prefix) ?? .en
    }
}
