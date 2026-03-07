#!/usr/bin/env swift
import Foundation

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let catalogURL = repoRoot.appendingPathComponent("TrustCare/Localizable.xcstrings")
let requiredLocales = ["en", "pl", "de", "fr", "es", "it", "pt", "ro", "cs", "uk", "ru", "sv", "da", "tr"]

struct KeyRule {
    let key: String
    let component: String
    let warningLimit: Int
    let failLimit: Int
}

let keyRules: [KeyRule] = [
    KeyRule(key: "filter_all", component: "segmented", warningLimit: 12, failLimit: 18),
    KeyRule(key: "status_verified", component: "segmented", warningLimit: 14, failLimit: 20),
    KeyRule(key: "status_pending", component: "segmented", warningLimit: 14, failLimit: 20),
    KeyRule(key: "status_unverified", component: "segmented", warningLimit: 16, failLimit: 24),
    KeyRule(key: "claim_provider_label", component: "segmented", warningLimit: 14, failLimit: 22),
    KeyRule(key: "chip_facility", component: "segmented", warningLimit: 14, failLimit: 22),
    KeyRule(key: "review_visit_type", component: "segmented", warningLimit: 16, failLimit: 24),

    KeyRule(key: "my_reviews_empty_title", component: "empty_state", warningLimit: 30, failLimit: 42),
    KeyRule(key: "my_reviews_empty_message", component: "empty_state", warningLimit: 80, failLimit: 120),
    KeyRule(key: "my_reviews_empty_action", component: "cta", warningLimit: 18, failLimit: 28),

    KeyRule(key: "chip_specialty", component: "filter_chip", warningLimit: 14, failLimit: 22),
    KeyRule(key: "chip_treatment", component: "filter_chip", warningLimit: 14, failLimit: 22),
    KeyRule(key: "chip_distance", component: "filter_chip", warningLimit: 14, failLimit: 22),
    KeyRule(key: "chip_language", component: "filter_chip", warningLimit: 14, failLimit: 22),
    KeyRule(key: "filter_verified", component: "filter_chip", warningLimit: 14, failLimit: 22),

    KeyRule(key: "button_ok", component: "cta", warningLimit: 12, failLimit: 18),
    KeyRule(key: "button_done", component: "cta", warningLimit: 12, failLimit: 18),
    KeyRule(key: "button_cancel", component: "cta", warningLimit: 14, failLimit: 20),
    KeyRule(key: "button_delete", component: "cta", warningLimit: 14, failLimit: 20),
]

struct CheckFailure: Error {
    let message: String
}

func loadCatalog() throws -> [String: Any] {
    let data = try Data(contentsOf: catalogURL)
    let json = try JSONSerialization.jsonObject(with: data)
    guard let dict = json as? [String: Any] else {
        throw CheckFailure(message: "Invalid JSON root in Localizable.xcstrings")
    }
    return dict
}

func value(for key: String, locale: String, in catalog: [String: Any]) -> String? {
    guard
        let strings = catalog["strings"] as? [String: Any],
        let keyEntry = strings[key] as? [String: Any],
        let localizations = keyEntry["localizations"] as? [String: Any],
        let localeEntry = localizations[locale] as? [String: Any],
        let stringUnit = localeEntry["stringUnit"] as? [String: Any],
        let text = stringUnit["value"] as? String
    else {
        return nil
    }
    return text
}

func visibleLength(_ text: String) -> Int {
    text.trimmingCharacters(in: .whitespacesAndNewlines).count
}

do {
    let catalog = try loadCatalog()
    var warningRows: [String] = []
    var failureRows: [String] = []

    for rule in keyRules {
        for locale in requiredLocales {
            guard let localized = value(for: rule.key, locale: locale, in: catalog) else {
                failureRows.append("missing value key=\(rule.key) locale=\(locale)")
                continue
            }
            let len = visibleLength(localized)
            if len >= rule.failLimit {
                failureRows.append("high risk key=\(rule.key) locale=\(locale) len=\(len) limit=\(rule.failLimit) component=\(rule.component)")
            } else if len >= rule.warningLimit {
                warningRows.append("warn key=\(rule.key) locale=\(locale) len=\(len) component=\(rule.component)")
            }
        }
    }

    print("UI fit audit locales: \(requiredLocales.joined(separator: ", "))")
    print("Checked keys: \(keyRules.count)")

    if !warningRows.isEmpty {
        print("Warnings (truncation risk):")
        for row in warningRows.prefix(60) {
            print("- \(row)")
        }
        if warningRows.count > 60 {
            print("- ... and \(warningRows.count - 60) more")
        }
    } else {
        print("Warnings: none")
    }

    if !failureRows.isEmpty {
        fputs("FAIL: High-risk localization fit issues found\n", stderr)
        for row in failureRows {
            fputs("- \(row)\n", stderr)
        }
        exit(1)
    }

    print("PASS: No high-risk localization fit issues detected")
} catch let failure as CheckFailure {
    fputs("FAIL: \(failure.message)\n", stderr)
    exit(1)
} catch {
    fputs("FAIL: \(error.localizedDescription)\n", stderr)
    exit(1)
}
