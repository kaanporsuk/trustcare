import SwiftUI

struct PrivacyPolicyView: View {
    private typealias LocalizedLine = (key: String, fallback: String)

    private let sections: [(title: LocalizedLine, bullets: [LocalizedLine])] = [
        (
            title: ("pp_data_collection_title", "Data we collect"),
            bullets: [
                ("pp_data_collection_1", "We collect account details you provide during sign-up."),
                ("pp_data_collection_2", "We store profile data such as name, language, and preferences."),
                ("pp_data_collection_3", "We may process provider interactions and saved items."),
                ("pp_data_collection_4", "Technical logs may be used to improve reliability and security.")
            ]
        ),
        (
            title: ("pp_data_usage_title", "How we use data"),
            bullets: [
                ("pp_data_usage_1", "Data is used to deliver core TrustCare features."),
                ("pp_data_usage_2", "We use information to personalize language and content."),
                ("pp_data_usage_3", "Usage insights help us improve product quality.")
            ]
        ),
        (
            title: ("pp_data_sharing_title", "Data sharing"),
            bullets: [
                ("pp_data_sharing_1", "We do not sell your personal data."),
                ("pp_data_sharing_2", "Data may be shared with service providers needed to run the app."),
                ("pp_data_sharing_3", "We may disclose data when required by law.")
            ]
        ),
        (
            title: ("pp_rights_title", "Your rights"),
            bullets: [
                ("pp_rights_1", "You can request access to your personal data."),
                ("pp_rights_2", "You can request corrections to inaccurate profile information."),
                ("pp_rights_3", "You can request deletion of your account and related data."),
                ("pp_rights_4", "You can contact support for privacy-related requests.")
            ]
        ),
        (
            title: ("pp_cookies_title", "Cookies and similar technologies"),
            bullets: [
                ("pp_cookies_1", "We may use local storage for settings and session continuity."),
                ("pp_cookies_2", "These technologies help maintain secure authentication."),
                ("pp_cookies_3", "You can clear app data by signing out and removing app data locally.")
            ]
        ),
        (
            title: ("pp_security_title", "Security"),
            bullets: [
                ("pp_security_1", "We use safeguards to protect personal data."),
                ("pp_security_2", "No system is perfect, but we continuously improve security practices."),
                ("pp_security_3", "Report suspected security issues to support promptly.")
            ]
        ),
        (
            title: ("pp_contact_title", "Contact"),
            bullets: [
                ("pp_contact_1", "Reach out to support for any privacy questions."),
                ("pp_contact_2", "Policy updates may be reflected in this section.")
            ]
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    policySection(title: section.title, bullets: section.bullets)
                }

                Text(tcKey: "pp_last_updated", fallback: "Last updated")
                    .font(AppFont.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, AppSpacing.sm)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .navigationTitle(Text(tcKey: "menu_privacy", fallback: "Privacy Policy"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private func policySection(title: LocalizedLine, bullets: [LocalizedLine]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tcKey: title.key, fallback: title.fallback)
                .font(AppFont.title3)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(Array(bullets.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .top, spacing: AppSpacing.xs) {
                        Text("•")
                            .foregroundStyle(Color.tcOcean)
                        Text(tcKey: line.key, fallback: line.fallback)
                            .font(AppFont.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.tcSurface)
        .cornerRadius(AppRadius.card)
    }
}
