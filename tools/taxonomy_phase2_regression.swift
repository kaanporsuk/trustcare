#!/usr/bin/env swift
import Foundation

struct RegressionFailure: Error {
    let message: String
}

func fail(_ message: String) throws {
    throw RegressionFailure(message: message)
}

func loadJSON(_ url: URL) throws -> [String: Any] {
    let data = try Data(contentsOf: url)
    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw RegressionFailure(message: "Invalid JSON object at \(url.path)")
    }
    return object
}

func loadLabels(repoRoot: URL, locale: String) throws -> [String: String] {
    let labelsURL = repoRoot
        .appendingPathComponent("TrustCare")
        .appendingPathComponent("Resources")
        .appendingPathComponent("TaxonomyV21")
        .appendingPathComponent("labels")
        .appendingPathComponent("taxonomy_v21_locale_labels_\(locale).json")

    let payload = try loadJSON(labelsURL)
    guard let labels = payload["labels"] as? [String: String] else {
        throw RegressionFailure(message: "Missing labels map in \(labelsURL.path)")
    }

    return labels
}

func checkLocalizedRows(repoRoot: URL) throws {
    let english = try loadLabels(repoRoot: repoRoot, locale: "en")
    let turkish = try loadLabels(repoRoot: repoRoot, locale: "tr")
    let polish = try loadLabels(repoRoot: repoRoot, locale: "pl")

    let ids = [
        "SPEC_AESTHETIC_MEDICINE",
        "SERV_ACUPUNCTURE",
        "FAC_DIALYSIS_CENTER",
    ]

    for id in ids {
        guard let en = english[id], !en.isEmpty else {
            throw RegressionFailure(message: "Missing English label for \(id)")
        }
        guard let tr = turkish[id], !tr.isEmpty else {
            throw RegressionFailure(message: "Missing Turkish label for \(id)")
        }
        guard let pl = polish[id], !pl.isEmpty else {
            throw RegressionFailure(message: "Missing Polish label for \(id)")
        }
        if tr == en {
            try fail("Turkish label did not localize for \(id)")
        }
        if pl == en {
            try fail("Polish label did not localize for \(id)")
        }
    }
}

func checkLanguageRefreshHook(repoRoot: URL) throws {
    let homeViewURL = repoRoot
        .appendingPathComponent("TrustCare")
        .appendingPathComponent("Views")
        .appendingPathComponent("Home")
        .appendingPathComponent("HomeView.swift")

    let contents = try String(contentsOf: homeViewURL, encoding: .utf8)
    if !contents.contains(".task(id: languageCode)") {
        try fail("Taxonomy filter sheet does not reload on language changes (.task(id: languageCode) missing)")
    }
}

func checkUnifiedResolverUsage(repoRoot: URL) throws {
    let targets = [
        "TrustCare/Views/Home/HomeView.swift",
        "TrustCare/Views/Components/TaxonomyPickerView.swift",
        "TrustCare/Views/Home/DiscoverSearchSurfaceView.swift",
    ]

    for relativePath in targets {
        let url = repoRoot.appendingPathComponent(relativePath)
        let contents = try String(contentsOf: url, encoding: .utf8)
        if !contents.contains("TaxonomyService.localizedLabel") {
            try fail("Unified taxonomy label resolver is not used in \(relativePath)")
        }
    }
}

func run() throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    try checkLocalizedRows(repoRoot: cwd)
    try checkLanguageRefreshHook(repoRoot: cwd)
    try checkUnifiedResolverUsage(repoRoot: cwd)

    print("PASS: taxonomy phase2 regression checks")
    print("- tr/pl taxonomy rows are localized for specialty/treatment/facility")
    print("- taxonomy sheet reload hook uses .task(id: languageCode)")
    print("- key taxonomy UI surfaces use TaxonomyService.localizedLabel")
}

do {
    try run()
} catch let error as RegressionFailure {
    fputs("FAIL: \(error.message)\n", stderr)
    exit(1)
} catch {
    fputs("FAIL: \(error)\n", stderr)
    exit(2)
}
