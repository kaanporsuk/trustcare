import SwiftUI

enum LegalDocumentKind {
    case terms
    case privacy

    var fileName: String {
        switch self {
        case .terms: return "terms"
        case .privacy: return "privacy"
        }
    }
}

struct LegalMarkdownContentView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager

    let kind: LegalDocumentKind

    @State private var renderedText = AttributedString("")

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(tcKey: "legal_translation_disclaimer", fallback: "Translation is provided for convenience; the English version prevails.")
                .font(AppFont.caption)
                .foregroundStyle(.secondary)

            Text(renderedText)
                .font(AppFont.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: localizationManager.effectiveLanguage) {
            renderedText = loadLegalMarkdown(kind: kind, languageCode: localizationManager.effectiveLanguage)
        }
    }

    private func loadLegalMarkdown(kind: LegalDocumentKind, languageCode: String) -> AttributedString {
        let normalized = languageCode
            .split(separator: "-")
            .first
            .map(String.init)
            ?? "en"

        let candidates = [normalized, "en"]

        for code in candidates {
            if let markdown = loadMarkdown(fileName: kind.fileName, languageCode: code) {
                if let attributed = try? AttributedString(markdown: markdown) {
                    return attributed
                }
                return AttributedString(markdown)
            }
        }

        return AttributedString("")
    }

    private func loadMarkdown(fileName: String, languageCode: String) -> String? {
        let localizedResourceName = "\(fileName)_\(languageCode)"

        if let directURL = Bundle.main.url(forResource: localizedResourceName, withExtension: "md"),
           let directContent = try? String(contentsOf: directURL, encoding: .utf8) {
            return directContent
        }

        let subdirs = [
            "Resources/Legal/\(languageCode)",
            "Legal/\(languageCode)",
        ]

        for subdir in subdirs {
            if let url = Bundle.main.url(forResource: localizedResourceName, withExtension: "md", subdirectory: subdir),
               let content = try? String(contentsOf: url, encoding: .utf8) {
                return content
            }
        }

        return nil
    }
}
