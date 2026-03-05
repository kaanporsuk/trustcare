import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    termsSection(
                        title: "tos_service_title",
                        bullets: [
                            "tos_service_1",
                            "tos_service_2"
                        ]
                    )

                    termsSection(
                        title: "tos_user_title",
                        bullets: [
                            "tos_user_1",
                            "tos_user_2",
                            "tos_user_3"
                        ]
                    )

                    termsSection(
                        title: "tos_review_title",
                        bullets: [
                            "tos_review_1",
                            "tos_review_2",
                            "tos_review_3"
                        ]
                    )

                    termsSection(
                        title: "tos_rehber_title",
                        bullets: [
                            "tos_rehber_1",
                            "tos_rehber_2",
                            "tos_rehber_3"
                        ]
                    )

                    termsSection(
                        title: "tos_ip_title",
                        bullets: [
                            "tos_ip_1",
                            "tos_ip_2"
                        ]
                    )

                    termsSection(
                        title: "tos_account_title",
                        bullets: [
                            "tos_account_1",
                            "tos_account_2"
                        ]
                    )

                    termsSection(
                        title: "tos_dispute_title",
                        bullets: [
                            "tos_dispute_1",
                            "tos_dispute_2"
                        ]
                    )

                    termsSection(
                        title: "tos_contact_title",
                        bullets: [
                            "tos_contact_1",
                            "tos_contact_2"
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
            Text(LocalizedStringKey(title))
                .font(AppFont.title3)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(bullets, id: \.self) { line in
                    HStack(alignment: .top, spacing: AppSpacing.xs) {
                        Text("•")
                            .foregroundStyle(Color.tcOcean)
                        Text(LocalizedStringKey(line))
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
