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

    @State private var document = ParsedLegalDocument.empty

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                if !document.title.isEmpty {
                    Text(document.title)
                        .font(AppFont.title2)
                        .foregroundStyle(Color.tcTextPrimary)
                        .accessibilityAddTraits(.isHeader)
                }

                if let lastUpdated = document.lastUpdated, !lastUpdated.isEmpty {
                    Text(lastUpdated)
                        .font(AppFont.caption)
                        .foregroundStyle(Color.tcTextSecondary)
                }

                Text(tcKey: "legal_translation_disclaimer", fallback: "Translation is provided for convenience; the English version prevails.")
                    .font(AppFont.caption)
                    .foregroundStyle(Color.tcTextSecondary)
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.tcSurface)
                    .cornerRadius(AppRadius.card)

                ForEach(document.sections) { section in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(section.title)
                            .font(AppFont.headline)
                            .foregroundStyle(Color.tcTextPrimary)
                            .accessibilityAddTraits(.isHeader)

                        Text(section.body)
                            .font(AppFont.body)
                            .foregroundStyle(Color.tcTextSecondary)
                            .lineSpacing(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.tcSurface)
                    .cornerRadius(AppRadius.card)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: localizationManager.effectiveLanguage) {
            document = loadLegalDocument(kind: kind, languageCode: localizationManager.effectiveLanguage)
        }
    }

    private func loadLegalDocument(kind: LegalDocumentKind, languageCode: String) -> ParsedLegalDocument {
        let normalized = languageCode
            .split(separator: "-")
            .first
            .map(String.init)
            ?? "en"

        let candidates = [normalized, "en"]

        for code in candidates {
            if let markdown = loadMarkdown(fileName: kind.fileName, languageCode: code) {
                return parseLegalMarkdown(markdown)
            }
        }

        return .empty
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

    private func parseLegalMarkdown(_ markdown: String) -> ParsedLegalDocument {
        let normalized = normalizeMarkdown(markdown)
        let lines = normalized.components(separatedBy: "\n")

        var documentTitle = ""
        var lastUpdated: String?
        var sections: [ParsedLegalSection] = []

        var currentSectionTitle = ""
        var currentSectionLines: [String] = []

        func flushSection() {
            let trimmedTitle = currentSectionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let joinedBody = currentSectionLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty, !joinedBody.isEmpty else {
                currentSectionLines = []
                return
            }

            let body = (try? AttributedString(markdown: joinedBody)) ?? AttributedString(joinedBody)
            sections.append(ParsedLegalSection(title: trimmedTitle, body: body))
            currentSectionLines = []
        }

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                if !currentSectionLines.isEmpty {
                    currentSectionLines.append("")
                }
                continue
            }

            if line.hasPrefix("# ") {
                if documentTitle.isEmpty {
                    documentTitle = String(line.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                continue
            }

            if line.hasPrefix("## ") {
                flushSection()
                currentSectionTitle = String(line.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                continue
            }

            if line.hasPrefix("_") && line.hasSuffix("_") {
                let candidate = line.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !candidate.isEmpty {
                    lastUpdated = candidate
                }
                continue
            }

            currentSectionLines.append(line)
        }

        flushSection()

        if sections.isEmpty {
            let fallbackBody = (try? AttributedString(markdown: normalized)) ?? AttributedString(normalized)
            sections = [
                ParsedLegalSection(
                    title: tcString("legal_content", fallback: "Legal content"),
                    body: fallbackBody
                )
            ]
        }

        return ParsedLegalDocument(
            title: documentTitle,
            lastUpdated: lastUpdated,
            sections: sections
        )
    }

    private func normalizeMarkdown(_ markdown: String) -> String {
        let unixNewlines = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\\n", with: "\n")

        let trimmedLineEndings = unixNewlines
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")

        return trimmedLineEndings.replacingOccurrences(
            of: "\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )
    }
}

private struct ParsedLegalSection: Identifiable {
    let id = UUID()
    let title: String
    let body: AttributedString
}

private struct ParsedLegalDocument {
    let title: String
    let lastUpdated: String?
    let sections: [ParsedLegalSection]

    static let empty = ParsedLegalDocument(title: "", lastUpdated: nil, sections: [])
}
