import SwiftUI

struct TermsOfServiceView: View {
    private typealias LocalizedLine = (key: String, fallback: String)

    private let sections: [(title: LocalizedLine, bullets: [LocalizedLine])] = [
        (
            title: ("tos_service_title", "About this service"),
            bullets: [
                ("tos_service_1", "TrustCare helps users discover providers and share care experiences."),
                ("tos_service_2", "Information in the app is provided for general guidance purposes.")
            ]
        ),
        (
            title: ("tos_user_title", "User responsibilities"),
            bullets: [
                ("tos_user_1", "You are responsible for keeping your account information accurate."),
                ("tos_user_2", "Use the platform respectfully and avoid abusive or misleading content."),
                ("tos_user_3", "Do not submit unlawful material or impersonate other people.")
            ]
        ),
        (
            title: ("tos_review_title", "Reviews and contributions"),
            bullets: [
                ("tos_review_1", "Reviews should reflect genuine personal experiences."),
                ("tos_review_2", "TrustCare may moderate content that violates community rules."),
                ("tos_review_3", "False or harmful submissions may be removed.")
            ]
        ),
        (
            title: ("tos_rehber_title", "Rehber guidance"),
            bullets: [
                ("tos_rehber_1", "Rehber content is informational and not a medical diagnosis."),
                ("tos_rehber_2", "Seek professional medical help for urgent or serious concerns."),
                ("tos_rehber_3", "Emergency situations should be directed to local emergency services.")
            ]
        ),
        (
            title: ("tos_ip_title", "Intellectual property"),
            bullets: [
                ("tos_ip_1", "TrustCare branding, content, and software are protected by applicable laws."),
                ("tos_ip_2", "You may not copy or redistribute protected content without permission.")
            ]
        ),
        (
            title: ("tos_account_title", "Account and access"),
            bullets: [
                ("tos_account_1", "TrustCare may suspend accounts that violate these terms."),
                ("tos_account_2", "You may request account deletion from settings.")
            ]
        ),
        (
            title: ("tos_dispute_title", "Disputes and liability"),
            bullets: [
                ("tos_dispute_1", "TrustCare is provided as-is to the extent permitted by law."),
                ("tos_dispute_2", "Applicable laws govern dispute resolution and legal rights.")
            ]
        ),
        (
            title: ("tos_contact_title", "Contact"),
            bullets: [
                ("tos_contact_1", "Contact support if you have questions about these terms."),
                ("tos_contact_2", "Policy updates may be communicated within the app.")
            ]
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    termsSection(title: section.title, bullets: section.bullets)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .navigationTitle(Text(tcKey: "menu_terms", fallback: "Terms of Service"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private func termsSection(title: LocalizedLine, bullets: [LocalizedLine]) -> some View {
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
