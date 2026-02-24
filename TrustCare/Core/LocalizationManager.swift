import SwiftUI
import Combine

final class LocalizationManager: ObservableObject {

    struct AppLanguage: Identifiable, Hashable {
        let code: String
        let name: String
        let flag: String
        var id: String { code }
    }

    static let supportedLanguages: [AppLanguage] = [
        AppLanguage(code: "en", name: "English",    flag: "🇬🇧"),
        AppLanguage(code: "tr", name: "Türkçe",     flag: "🇹🇷"),
        AppLanguage(code: "de", name: "Deutsch",     flag: "🇩🇪"),
        AppLanguage(code: "pl", name: "Polski",      flag: "🇵🇱"),
        AppLanguage(code: "nl", name: "Nederlands",  flag: "🇳🇱"),
        AppLanguage(code: "da", name: "Dansk",       flag: "🇩🇰"),
    ]

    static let supportedCodes = Set(supportedLanguages.map(\.code))

    /// The actively chosen language. On first launch this is empty (""),
    /// and the app uses whatever iOS chose from its system prefs.
    @AppStorage("appLanguage") var currentLanguage: String = "" {
        didSet {
            guard !currentLanguage.isEmpty else { return }
            applyLanguage(currentLanguage)
            objectWillChange.send()
        }
    }

    /// Whether the user has manually chosen a language in Settings.
    var hasUserSelectedLanguage: Bool {
        !currentLanguage.isEmpty
    }

    /// The effective language code the app is running in right now.
    var effectiveLanguage: String {
        if hasUserSelectedLanguage { return currentLanguage }
        return Self.detectSystemLanguage()
    }

    init() {
        // On first launch, currentLanguage is "".
        // The app uses system language (iOS selects from project localizations).
        // If the user has previously set a language, apply it.
        if hasUserSelectedLanguage {
            applyLanguage(currentLanguage)
        }
    }

    /// Detect the best system language from iOS preferences.
    static func detectSystemLanguage() -> String {
        for preferred in Locale.preferredLanguages {
            let code = Locale(identifier: preferred).language.languageCode?.identifier ?? ""
            if supportedCodes.contains(code) { return code }
        }
        return "en"
    }

    /// Apply language by setting AppleLanguages UserDefaults.
    /// This takes effect on NEXT app launch for String(localized:).
    /// For CURRENT session, we also swizzle Bundle.
    func applyLanguage(_ code: String) {
        // Set for next launch:
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        // Set for current session (best-effort swizzle):
        Bundle.setLanguage(code)
    }

    /// Call this when user changes language in Settings.
    /// Posts a notification so the root view rebuilds with the new language.
    func changeLanguage(to code: String) {
        currentLanguage = code
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }

    /// The specialty name column to fetch from Supabase.
    var specialtyNameColumn: String {
        let lang = effectiveLanguage
        switch lang {
        case "tr": return "name_tr"
        case "de": return "name_de"
        case "pl": return "name_pl"
        case "nl": return "name_nl"
        case "da": return "name_da"
        default:   return "name"
        }
    }

    /// Resolves the best available specialty name for the current language.
    func resolvedSpecialtyName(
        canonical: String,
        tr: String? = nil, de: String? = nil,
        pl: String? = nil, nl: String? = nil,
        da: String? = nil
    ) -> String {
        let lang = effectiveLanguage
        switch lang {
        case "tr": return tr ?? canonical
        case "de": return de ?? canonical
        case "pl": return pl ?? canonical
        case "nl": return nl ?? canonical
        case "da": return da ?? canonical
        default:   return canonical
        }
    }

    /// Category translation mapping for the 16 database categories.
    static let categoryTranslations: [String: [String: String]] = [
        "Primary Care": [
            "tr": "Temel Sağlık", "de": "Hausärztliche Versorgung",
            "pl": "Podstawowa opieka zdrowotna", "nl": "Eerstelijnszorg",
            "da": "Almen praksis", "en": "Primary Care"
        ],
        "Surgical": [
            "tr": "Cerrahi", "de": "Chirurgie",
            "pl": "Chirurgia", "nl": "Chirurgie", "da": "Kirurgi", "en": "Surgical"
        ],
        "Medical Specialties": [
            "tr": "Tıbbi Uzmanlıklar", "de": "Fachärztliche Medizin",
            "pl": "Specjalizacje medyczne", "nl": "Medische specialismen",
            "da": "Medicinske specialer", "en": "Medical Specialties"
        ],
        "Women's Health": [
            "tr": "Kadın Sağlığı", "de": "Frauengesundheit",
            "pl": "Zdrowie kobiet", "nl": "Vrouwengezondheid",
            "da": "Kvinders sundhed", "en": "Women's Health"
        ],
        "Dental": [
            "tr": "Diş Sağlığı", "de": "Zahnmedizin",
            "pl": "Stomatologia", "nl": "Tandheelkunde", "da": "Tandpleje", "en": "Dental"
        ],
        "Eye Care": [
            "tr": "Göz Sağlığı", "de": "Augenheilkunde",
            "pl": "Okulistyka", "nl": "Oogzorg", "da": "Øjenpleje", "en": "Eye Care"
        ],
        "ENT": [
            "tr": "Kulak Burun Boğaz", "de": "Hals-Nasen-Ohren",
            "pl": "Laryngologia", "nl": "Keel-neus-oor", "da": "Øre-næse-hals", "en": "ENT"
        ],
        "Mental Health": [
            "tr": "Ruh Sağlığı", "de": "Psychische Gesundheit",
            "pl": "Zdrowie psychiczne", "nl": "Geestelijke gezondheid",
            "da": "Mental sundhed", "en": "Mental Health"
        ],
        "Urology": [
            "tr": "Üroloji", "de": "Urologie",
            "pl": "Urologia", "nl": "Urologie", "da": "Urologi", "en": "Urology"
        ],
        "Rehabilitation": [
            "tr": "Rehabilitasyon", "de": "Rehabilitation",
            "pl": "Rehabilitacja", "nl": "Revalidatie", "da": "Genoptræning", "en": "Rehabilitation"
        ],
        "Aesthetic & Cosmetic": [
            "tr": "Estetik ve Kozmetik", "de": "Ästhetik und Kosmetik",
            "pl": "Medycyna estetyczna", "nl": "Esthetische geneeskunde",
            "da": "Æstetik og kosmetik", "en": "Aesthetic & Cosmetic"
        ],
        "Diagnostic": [
            "tr": "Tanı ve Teşhis", "de": "Diagnostik",
            "pl": "Diagnostyka", "nl": "Diagnostiek", "da": "Diagnostik", "en": "Diagnostic"
        ],
        "Emergency": [
            "tr": "Acil", "de": "Notfall",
            "pl": "Ratunkowe", "nl": "Spoedeisend", "da": "Akut", "en": "Emergency"
        ],
        "Alternative": [
            "tr": "Alternatif Tıp", "de": "Alternativmedizin",
            "pl": "Medycyna alternatywna", "nl": "Alternatieve geneeskunde",
            "da": "Alternativ behandling", "en": "Alternative"
        ],
        "Pharmacy": [
            "tr": "Eczane", "de": "Apotheke",
            "pl": "Apteka", "nl": "Apotheek", "da": "Apotek", "en": "Pharmacy"
        ],
        "Hospital": [
            "tr": "Hastane", "de": "Krankenhaus",
            "pl": "Szpital", "nl": "Ziekenhuis", "da": "Hospital", "en": "Hospital"
        ],
        "Other": [
            "tr": "Diğer", "de": "Sonstiges",
            "pl": "Inne", "nl": "Overig", "da": "Øvrige", "en": "Other"
        ],
    ]

    /// Translate a database category to the user's language.
    func localizedCategory(_ englishCategory: String) -> String {
        let lang = effectiveLanguage
        if lang == "en" { return englishCategory }
        return Self.categoryTranslations[englishCategory]?[lang] ?? englishCategory
    }

    var layoutDirection: LayoutDirection {
        .leftToRight
    }
}
