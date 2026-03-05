import Foundation
import SwiftUI

enum L10n {
    private static var warnedMissingKeys: Set<String> = []
    private static let warningLock = NSLock()

    private static var selectedLanguageCode: String {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? ""
        if !saved.isEmpty {
            return normalizedLanguageCode(saved)
        }
        return LocalizationManager.detectSystemLanguage()
    }

    private static func normalizedLanguageCode(_ rawCode: String) -> String {
        let normalized = rawCode
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .split(separator: "_")
            .first
            .map(String.init) ?? "en"

        return LocalizationManager.supportedCodes.contains(normalized) ? normalized : "en"
    }

    private static func bundle(for languageCode: String) -> Bundle? {
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }

    static func tcString(_ key: String, fallback: String) -> String {
        let selectedCode = selectedLanguageCode
        let candidateBundles: [Bundle] = [
            bundle(for: selectedCode),
            bundle(for: "en"),
            bundle(for: "Base"),
            .main,
        ]
        .compactMap { $0 }

        for bundle in candidateBundles {
            let localized = bundle.localizedString(forKey: key, value: key, table: nil)
            if localized != key {
                return localized
            }
        }

        // As a final safety net, attempt the default NSLocalizedString lookup.
        let defaultLookup = NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
        if defaultLookup == key {
            #if DEBUG
            warningLock.lock()
            let shouldWarn = warnedMissingKeys.insert(key).inserted
            warningLock.unlock()
            if shouldWarn {
                print("[L10n] Missing localization key: \(key)")
            }
            #endif
            return fallback
        }

        return defaultLookup
    }
}

func tcString(_ key: String, fallback: String) -> String {
    L10n.tcString(key, fallback: fallback)
}

extension Text {
    init(tcKey: String, fallback: String) {
        self.init(verbatim: L10n.tcString(tcKey, fallback: fallback))
    }
}
