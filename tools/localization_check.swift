#!/usr/bin/env swift
import Foundation

enum LocalizationCheckError: Error, CustomStringConvertible {
    case invalidFormat(String)

    var description: String {
        switch self {
        case .invalidFormat(let message):
            return message
        }
    }
}

struct LocalizationCheck {
    static let requiredLocales = ["en", "tr", "de", "pl", "nl", "da", "es", "fr", "it", "ro", "pt", "uk", "ru", "sv", "cs", "hu"]

    static let requiredKeys = [
        "specialties_title",
        "clear_filter",
        "taxonomy_segment_specialties",
        "taxonomy_segment_treatments",
        "taxonomy_segment_facilities",
        "search_specialties",
        "search_treatments",
        "search_facilities",
        "recents",
        "top_picks",
        "all_results",
        "showing_english_results",
        "no_results",
        "try_english_keywords",
        "switch_category_hint"
    ]

    static func main() {
        do {
            let fileURL = URL(fileURLWithPath: "TrustCare/Localizable.xcstrings")
            let data = try Data(contentsOf: fileURL)
            let root = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            guard let root,
                  let strings = root["strings"] as? [String: Any] else {
                throw LocalizationCheckError.invalidFormat("Localizable.xcstrings format is invalid")
            }

            var failures: [String] = []

            for key in requiredKeys {
                guard let keyNode = strings[key] as? [String: Any] else {
                    failures.append("Missing key: \(key)")
                    continue
                }

                let localizations = keyNode["localizations"] as? [String: Any] ?? [:]
                for locale in requiredLocales {
                    if localizations[locale] == nil {
                        failures.append("Missing locale '\(locale)' for key '\(key)'")
                    }
                }
            }

            if failures.isEmpty {
                print("PASS localization completeness (\(requiredKeys.count) keys × \(requiredLocales.count) locales)")
                exit(0)
            } else {
                print("FAIL localization completeness")
                for failure in failures {
                    print("- \(failure)")
                }
                exit(1)
            }
        } catch {
            fputs("Localization check failed to run: \(error)\n", stderr)
            exit(2)
        }
    }
}

LocalizationCheck.main()
