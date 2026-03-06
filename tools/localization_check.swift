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

    // Scoped guard for shared SwiftUI pieces used across provider/profile/review/help/legal/add-provider flows.
    static let guardedSwiftFiles = [
        "TrustCare/Views/MainTabView.swift",
        "TrustCare/UI/Components/TCProviderCard.swift",
        "TrustCare/UI/Components/TCClaimBanner.swift",
        "TrustCare/UI/Components/TCSearchBar.swift",
        "TrustCare/Views/Components/ClaimedBadge.swift",
        "TrustCare/Views/Components/VerifiedBadge.swift",
        "TrustCare/Views/Components/SearchBarView.swift",
    ]

    static let guardedCallPatterns = [
        #"\bText\s*\(\s*\"([^\"]+)\""#,
        #"\bButton\s*\(\s*\"([^\"]+)\""#,
        #"\bLabel\s*\(\s*\"([^\"]+)\""#,
        #"\.navigationTitle\s*\(\s*\"([^\"]+)\""#,
        #"\.alert\s*\(\s*\"([^\"]+)\""#,
        #"\.accessibilityLabel\s*\(\s*\"([^\"]+)\""#,
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

            let hardcodedLiteralFailures = try runHardcodedLiteralGuard()
            failures.append(contentsOf: hardcodedLiteralFailures)

            if failures.isEmpty {
                print("PASS localization completeness (\(requiredKeys.count) keys × \(requiredLocales.count) locales)")
                print("PASS hardcoded-string guard (\(guardedSwiftFiles.count) scoped SwiftUI files)")
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

    static func runHardcodedLiteralGuard() throws -> [String] {
        var failures: [String] = []
        let regexes = try guardedCallPatterns.map { pattern in
            try NSRegularExpression(pattern: pattern, options: [])
        }

        for path in guardedSwiftFiles {
            let fileURL = URL(fileURLWithPath: path)
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)

            for (index, line) in lines.enumerated() {
                // Keep this lightweight: skip comment-only and preview lines.
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("//") || trimmed.hasPrefix("#Preview") {
                    continue
                }

                let range = NSRange(location: 0, length: line.utf16.count)
                for regex in regexes {
                    let matches = regex.matches(in: line, options: [], range: range)
                    for match in matches where match.numberOfRanges > 1 {
                        guard let literalRange = Range(match.range(at: 1), in: line) else { continue }
                        let literal = String(line[literalRange])
                        if isLikelyHardcodedUserFacingEnglish(literal) {
                            failures.append("Hardcoded literal in \(path):\(index + 1) -> \"\(literal)\"")
                        }
                    }
                }
            }
        }

        return failures
    }

    static func isLikelyHardcodedUserFacingEnglish(_ literal: String) -> Bool {
        let trimmed = literal.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }
        if trimmed.contains("\\(") { return false }

        // Localization keys typically use snake_case / dot.notation and should be allowed.
        let keyPattern = #"^[a-z0-9]+([._-][a-z0-9]+)*$"#
        if trimmed.range(of: keyPattern, options: .regularExpression) != nil {
            return false
        }

        let hasLetters = trimmed.range(of: #"[A-Za-z]"#, options: .regularExpression) != nil
        if !hasLetters { return false }

        // Human-readable English often has spaces or sentence punctuation.
        let likelySentence = trimmed.contains(" ") || trimmed.contains("?") || trimmed.contains("!") || trimmed.contains(":")
        return likelySentence || CharacterSet.uppercaseLetters.contains(trimmed.unicodeScalars.first!)
    }
}

LocalizationCheck.main()
