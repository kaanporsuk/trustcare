import SwiftUI
import Combine

/// Central language state manager.
/// Publishes changes that trigger instant UI updates via SwiftUI environment.
final class LocalizationManager: ObservableObject {

    // MARK: - Types

    struct AppLanguage: Identifiable, Hashable {
        let code: String
        let nativeName: String
        let englishName: String
        let flag: String
        var id: String { code }

        var locale: Locale { Locale(identifier: code) }

        var name: String { nativeName }

        var hasEnglishSubtitle: Bool {
            nativeName.caseInsensitiveCompare(englishName) != .orderedSame
        }
    }

    // MARK: - Supported Languages

    static let supportedLanguages: [AppLanguage] = [
        AppLanguage(code: "en", nativeName: "English", englishName: "English", flag: "🇬🇧"),
        AppLanguage(code: "tr", nativeName: "Türkçe", englishName: "Turkish", flag: "🇹🇷"),
        AppLanguage(code: "de", nativeName: "Deutsch", englishName: "German", flag: "🇩🇪"),
        AppLanguage(code: "pl", nativeName: "Polski", englishName: "Polish", flag: "🇵🇱"),
        AppLanguage(code: "nl", nativeName: "Nederlands", englishName: "Dutch", flag: "🇳🇱"),
        AppLanguage(code: "da", nativeName: "Dansk", englishName: "Danish", flag: "🇩🇰"),
        AppLanguage(code: "es", nativeName: "Español", englishName: "Spanish", flag: "🇪🇸"),
        AppLanguage(code: "fr", nativeName: "Français", englishName: "French", flag: "🇫🇷"),
        AppLanguage(code: "it", nativeName: "Italiano", englishName: "Italian", flag: "🇮🇹"),
        AppLanguage(code: "ro", nativeName: "Română", englishName: "Romanian", flag: "🇷🇴"),
        AppLanguage(code: "pt", nativeName: "Português", englishName: "Portuguese", flag: "🇵🇹"),
        AppLanguage(code: "uk", nativeName: "Українська", englishName: "Ukrainian", flag: "🇺🇦"),
        AppLanguage(code: "ru", nativeName: "Русский", englishName: "Russian", flag: "🇷🇺"),
        AppLanguage(code: "sv", nativeName: "Svenska", englishName: "Swedish", flag: "🇸🇪"),
        AppLanguage(code: "cs", nativeName: "Čeština", englishName: "Czech", flag: "🇨🇿"),
        AppLanguage(code: "hu", nativeName: "Magyar", englishName: "Hungarian", flag: "🇭🇺"),
    ]

    static let orderedLanguages: [AppLanguage] = {
        guard let english = supportedLanguages.first(where: { $0.code == "en" }),
              let turkish = supportedLanguages.first(where: { $0.code == "tr" }) else {
            return supportedLanguages
        }

        let remainder = supportedLanguages
            .filter { $0.code != "en" && $0.code != "tr" }
            .sorted {
                $0.nativeName.localizedCaseInsensitiveCompare($1.nativeName) == .orderedAscending
            }

        return [english, turkish] + remainder
    }()

    static let supportedCodes = Set(supportedLanguages.map(\.code))

    // MARK: - Published State

    /// The user's chosen language code. Empty = use system default.
    /// When this changes, SwiftUI rebuilds via .id() and .environment(\\.locale).
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "app_language")
            UserDefaults.standard.set([effectiveLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
    }

    /// The effective language code the app is running in right now.
    var effectiveLanguage: String {
        if !currentLanguage.isEmpty { return currentLanguage }
        return Self.detectSystemLanguage()
    }

    /// The Locale object to inject into SwiftUI's environment.
    var locale: Locale {
        Locale(identifier: effectiveLanguage)
    }

    // MARK: - Init

    init() {
        let saved = UserDefaults.standard.string(forKey: "app_language")
            ?? ""
        self.currentLanguage = saved
    }

    // MARK: - Public API

    /// Called when the user taps a language in Settings.
    /// NO restart needed — the @Published change triggers instant UI update.
    func changeLanguage(to newCode: String) {
        guard Self.supportedCodes.contains(newCode) else { return }
        currentLanguage = newCode
    }

    // MARK: - System Detection

    static func detectSystemLanguage() -> String {
        for preferred in Locale.preferredLanguages {
            let code = Locale(identifier: preferred)
                .identifier.components(separatedBy: "-").first?
                .components(separatedBy: "_").first ?? ""
            if supportedCodes.contains(code) { return code }
        }
        return "en"
    }

    // MARK: - Layer B Helpers (Database Content)

    /// The DB column suffix for the current language.
    var dbColumnSuffix: String {
        switch effectiveLanguage {
        case "tr": return "_tr"
        case "de": return "_de"
        case "pl": return "_pl"
        case "nl": return "_nl"
        case "da": return "_da"
        default:   return ""
        }
    }

    /// Returns the correct DB column name for a given base field.
    func dbColumn(_ base: String) -> String {
        let suffix = dbColumnSuffix
        return suffix.isEmpty ? base : base + suffix
    }

    /// The specialty name column to fetch from Supabase.
    var specialtyNameColumn: String {
        dbColumn("name")
    }

    /// Translate a specialty name using loaded data.
    func resolvedSpecialtyName(
        canonical: String,
        tr: String? = nil, de: String? = nil,
        pl: String? = nil, nl: String? = nil, da: String? = nil
    ) -> String {
        switch effectiveLanguage {
        case "tr": return tr ?? canonical
        case "de": return de ?? canonical
        case "pl": return pl ?? canonical
        case "nl": return nl ?? canonical
        case "da": return da ?? canonical
        default:   return canonical
        }
    }

    /// Translate a category name.
    func localizedCategory(_ english: String) -> String {
        let lang = effectiveLanguage
        if lang == "en" { return english }
        return Self.categoryMap[english]?[lang] ?? english
    }

    var layoutDirection: LayoutDirection { .leftToRight }

    // MARK: - Category Translations

    private static let categoryMap: [String: [String: String]] = [
        "Primary Care": ["tr": "Temel Sağlık", "de": "Hausärztliche Versorgung", "pl": "Podstawowa opieka zdrowotna", "nl": "Eerstelijnszorg", "da": "Almen praksis"],
        "Surgical": ["tr": "Cerrahi", "de": "Chirurgie", "pl": "Chirurgia", "nl": "Chirurgie", "da": "Kirurgi"],
        "Medical Specialties": ["tr": "Tıbbi Uzmanlıklar", "de": "Fachärztliche Medizin", "pl": "Specjalizacje medyczne", "nl": "Medische specialismen", "da": "Medicinske specialer"],
        "Women's Health": ["tr": "Kadın Sağlığı", "de": "Frauengesundheit", "pl": "Zdrowie kobiet", "nl": "Vrouwengezondheid", "da": "Kvinders sundhed"],
        "Dental": ["tr": "Diş Sağlığı", "de": "Zahnmedizin", "pl": "Stomatologia", "nl": "Tandheelkunde", "da": "Tandpleje"],
        "Eye Care": ["tr": "Göz Sağlığı", "de": "Augenheilkunde", "pl": "Okulistyka", "nl": "Oogzorg", "da": "Øjenpleje"],
        "ENT": ["tr": "Kulak Burun Boğaz", "de": "Hals-Nasen-Ohren", "pl": "Laryngologia", "nl": "Keel-neus-oor", "da": "Øre-næse-hals"],
        "Mental Health": ["tr": "Ruh Sağlığı", "de": "Psychische Gesundheit", "pl": "Zdrowie psychiczne", "nl": "Geestelijke gezondheid", "da": "Mental sundhed"],
        "Urology": ["tr": "Üroloji", "de": "Urologie", "pl": "Urologia", "nl": "Urologie", "da": "Urologi"],
        "Rehabilitation": ["tr": "Rehabilitasyon", "de": "Rehabilitation", "pl": "Rehabilitacja", "nl": "Revalidatie", "da": "Genoptræning"],
        "Aesthetic & Cosmetic": ["tr": "Estetik ve Kozmetik", "de": "Ästhetik und Kosmetik", "pl": "Medycyna estetyczna", "nl": "Esthetische geneeskunde", "da": "Æstetik og kosmetik"],
        "Diagnostic": ["tr": "Tanı ve Teşhis", "de": "Diagnostik", "pl": "Diagnostyka", "nl": "Diagnostiek", "da": "Diagnostik"],
        "Emergency": ["tr": "Acil", "de": "Notfall", "pl": "Ratunkowe", "nl": "Spoedeisend", "da": "Akut"],
        "Alternative": ["tr": "Alternatif Tıp", "de": "Alternativmedizin", "pl": "Medycyna alternatywna", "nl": "Alternatieve geneeskunde", "da": "Alternativ behandling"],
        "Pharmacy": ["tr": "Eczane", "de": "Apotheke", "pl": "Apteka", "nl": "Apotheek", "da": "Apotek"],
        "Hospital": ["tr": "Hastane", "de": "Krankenhaus", "pl": "Szpital", "nl": "Ziekenhuis", "da": "Hospital"],
        "Other": ["tr": "Diğer", "de": "Sonstiges", "pl": "Inne", "nl": "Overig", "da": "Øvrige"],
    ]
}
