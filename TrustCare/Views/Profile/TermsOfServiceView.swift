import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    termsSection(
                        title: String(localized: "tos_service_title"),
                        bullets: [
                            String(localized: "tos_service_1"),
                            String(localized: "tos_service_2")
                        ]
                    )

                    termsSection(
                        title: String(localized: "tos_user_title"),
                        bullets: [
                            String(localized: "tos_user_1"),
                            String(localized: "tos_user_2"),
                            String(localized: "tos_user_3")
                        ]
                    )

                    termsSection(
                        title: String(localized: "tos_review_title"),
                        bullets: [
                            String(localized: "tos_review_1"),
                            String(localized: "tos_review_2"),
                            String(localized: "tos_review_3")
                        ]
                    )

                    termsSection(
                        title: String(localized: "tos_rehber_title"),
                        bullets: [
                            String(localized: "tos_rehber_1"),
                            String(localized: "tos_rehber_2"),
                            String(localized: "tos_rehber_3")
                        ]
                    )

                    termsSection(
                        title: String(localized: "tos_ip_title"),
                        bullets: [
                            String(localized: "tos_ip_1"),
                            String(localized: "tos_ip_2")
                        ]
                    )

                    termsSection(
                        title: String(localized: "tos_account_title"),
                        bullets: [
                            String(localized: "tos_account_1"),
                            String(localized: "tos_account_2")
                        ]
                    )

                    termsSection(
                        title: String(localized: "tos_dispute_title"),
                        bullets: [
                            String(localized: "tos_dispute_1"),
                            String(localized: "tos_dispute_2")
                        ]
                    )

                    termsSection(
                        title: String(localized: "tos_contact_title"),
                        bullets: [
                            String(localized: "tos_contact_1"),
                            String(localized: "tos_contact_2")
                        ]
                    )
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.lg)
            }
            .navigationTitle("menu_terms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
        }
    }

    private func termsSection(title: String, bullets: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFont.title3)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(bullets, id: \.self) { line in
                    HStack(alignment: .top, spacing: AppSpacing.xs) {
                        Text("•")
                            .foregroundStyle(AppColor.trustBlue)
                        Text(line)
                            .font(AppFont.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
    }
}
