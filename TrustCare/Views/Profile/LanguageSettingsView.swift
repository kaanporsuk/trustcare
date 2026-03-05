import SwiftUI

struct LanguageSettingsView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    let onLanguageSelected: (LocalizationManager.AppLanguage) -> Void

    @State private var searchText: String = ""

    var body: some View {
        List {
            ForEach(filteredLanguages) { language in
                Button {
                    if localizationManager.effectiveLanguage != language.code {
                        localizationManager.changeLanguage(to: language.code)
                        onLanguageSelected(language)
                    }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Text(language.flag)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(language.nativeName)
                                .font(AppFont.body)
                                .foregroundStyle(.primary)
                            if language.hasEnglishSubtitle {
                                Text(language.englishName)
                                    .font(AppFont.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if localizationManager.effectiveLanguage == language.code {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.tcOcean)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: Text("search_languages"))
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 16)
        }
        .navigationTitle("app_language")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings.languageScreen")
        .onAppear {
            #if DEBUG
            print("[LanguageSettingsView] Appeared")
            #endif
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("button_done") {
                    dismiss()
                }
            }
        }
    }

    private var filteredLanguages: [LocalizationManager.AppLanguage] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return LocalizationManager.orderedLanguages
        }

        let normalized = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US"))

        return LocalizationManager.orderedLanguages.filter { language in
            [language.nativeName, language.englishName, language.code]
                .map { $0.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US")) }
                .contains { $0.contains(normalized) }
        }
    }
}
