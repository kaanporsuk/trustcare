import Combine
import SwiftUI

final class LocalizationManager: ObservableObject {

    // ── Supported languages ─────────────────────────────────
    struct AppLanguage: Identifiable, Hashable {
        let code: String
        let name: String          // Native name (shown in picker)
        let englishName: String   // English name (for accessibility)
        let flag: String          // Country code for flag emoji or image
        var id: String { code }
    }

    static let supportedLanguages: [AppLanguage] = [
        AppLanguage(code: "en", name: "English",    englishName: "English",  flag: "GB"),
        AppLanguage(code: "tr", name: "Türkçe",     englishName: "Turkish",  flag: "TR"),
        AppLanguage(code: "de", name: "Deutsch",     englishName: "German",   flag: "DE"),
        AppLanguage(code: "pl", name: "Polski",      englishName: "Polish",   flag: "PL"),
        AppLanguage(code: "nl", name: "Nederlands",  englishName: "Dutch",    flag: "NL"),
        AppLanguage(code: "da", name: "Dansk",       englishName: "Danish",   flag: "DK"),
    ]

    static let supportedCodes: Set<String> = Set(supportedLanguages.map(\.code))

    // ── Persisted language ──────────────────────────────────
    @AppStorage("appLanguage") var currentLanguage: String = LocalizationManager.detectSystemLanguage() {
        didSet {
            objectWillChange.send()
            Bundle.setLanguage(currentLanguage)
        }
    }

    // ── Detect system language on first launch ──────────────
    static func detectSystemLanguage() -> String {
        // Check the user's preferred languages from iOS Settings
        for preferred in Locale.preferredLanguages {
            // Extract the language code (e.g., "de-DE" → "de", "tr" → "tr")
            let code = Locale(identifier: preferred).language.languageCode?.identifier ?? ""
            if supportedCodes.contains(code) {
                return code
            }
        }
        // Fallback to English
        return "en"
    }

    // ── Convenience ─────────────────────────────────────────
    var layoutDirection: LayoutDirection {
        // All current languages are LTR
        .leftToRight
    }

    /// Returns the correct specialty name column for the active language.
    /// Usage: specialty[languageColumn] on the Supabase query.
    var specialtyNameColumn: String {
        switch currentLanguage {
        case "tr": return "name_tr"
        case "de": return "name_de"
        case "pl": return "name_pl"
        case "nl": return "name_nl"
        case "da": return "name_da"
        default:   return "name"    // English = canonical name column
        }
    }

    /// Resolves the best available translated name for a specialty.
    /// Pass in the full specialty object (with all name_xx fields).
    func resolvedSpecialtyName(
        canonical: String,
        tr: String? = nil,
        de: String? = nil,
        pl: String? = nil,
        nl: String? = nil,
        da: String? = nil
    ) -> String {
        switch currentLanguage {
        case "tr": return tr ?? canonical
        case "de": return de ?? canonical
        case "pl": return pl ?? canonical
        case "nl": return nl ?? canonical
        case "da": return da ?? canonical
        default:   return canonical
        }
    }
}
