#!/usr/bin/env swift
import Foundation

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let catalogURL = repoRoot.appendingPathComponent("TrustCare/Localizable.xcstrings")
let viewURL = repoRoot.appendingPathComponent("TrustCare/Views/Profile/MyReviewsView.swift")

let requiredLocales = ["en", "de", "fr", "es", "pt", "ro", "sv", "cs", "da", "uk", "ru"]
let expectedEnglishSubtitle = "Share your experience by posting your first review."

struct CheckFailure: Error {
    let message: String
}

func loadJSON(_ url: URL) throws -> [String: Any] {
    let data = try Data(contentsOf: url)
    let raw = try JSONSerialization.jsonObject(with: data)
    guard let dict = raw as? [String: Any] else {
        throw CheckFailure(message: "Catalog is not a JSON object: \(url.path)")
    }
    return dict
}

func loadText(_ url: URL) throws -> String {
    try String(contentsOf: url, encoding: .utf8)
}

func localizationValue(catalog: [String: Any], key: String, locale: String) -> String? {
    guard
        let strings = catalog["strings"] as? [String: Any],
        let keyEntry = strings[key] as? [String: Any],
        let localizations = keyEntry["localizations"] as? [String: Any],
        let localeEntry = localizations[locale] as? [String: Any],
        let stringUnit = localeEntry["stringUnit"] as? [String: Any],
        let value = stringUnit["value"] as? String
    else {
        return nil
    }
    return value
}

func assertCondition(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw CheckFailure(message: message)
    }
}

do {
    let catalog = try loadJSON(catalogURL)
    let viewSource = try loadText(viewURL)

    try assertCondition(viewSource.contains("my_reviews_empty_title"), "MyReviewsView must use my_reviews_empty_title")
    try assertCondition(viewSource.contains("my_reviews_empty_message"), "MyReviewsView must use my_reviews_empty_message")
    try assertCondition(viewSource.contains("my_reviews_empty_action"), "MyReviewsView must use my_reviews_empty_action")

    let auditKeys = [
        "menu_my_reviews",
        "filter_all",
        "status_verified",
        "status_pending",
        "status_unverified",
        "my_reviews_empty_title",
        "my_reviews_empty_message",
        "my_reviews_empty_action"
    ]

    for key in auditKeys {
        for locale in requiredLocales {
            let value = localizationValue(catalog: catalog, key: key, locale: locale) ?? ""
            try assertCondition(!value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                                "Missing value for key=\(key) locale=\(locale)")
        }
    }

    let enSubtitle = localizationValue(catalog: catalog, key: "my_reviews_empty_message", locale: "en") ?? ""
    try assertCondition(enSubtitle == expectedEnglishSubtitle,
                        "Unexpected EN subtitle value for my_reviews_empty_message: '\(enSubtitle)'")

    // Lightweight non-English guard: EN subtitle should stay plain ASCII and should not equal the PL translation.
    let plSubtitle = localizationValue(catalog: catalog, key: "my_reviews_empty_message", locale: "pl") ?? ""
    try assertCondition(enSubtitle.unicodeScalars.allSatisfy { $0.value < 128 },
                        "EN subtitle for my_reviews_empty_message should remain ASCII-only")
    try assertCondition(enSubtitle != plSubtitle,
                        "EN subtitle for my_reviews_empty_message must not match PL translation")

    print("PASS: My Reviews empty-state localization regression checks succeeded")
    print("- audited locales: \(requiredLocales.joined(separator: ", "))")
    print("- subtitle key: my_reviews_empty_message")
    print("- en subtitle: \(enSubtitle)")
} catch let failure as CheckFailure {
    fputs("FAIL: \(failure.message)\n", stderr)
    exit(1)
} catch {
    fputs("FAIL: \(error.localizedDescription)\n", stderr)
    exit(1)
}
