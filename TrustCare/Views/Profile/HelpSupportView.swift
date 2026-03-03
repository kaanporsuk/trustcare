import SwiftUI

struct HelpSupportView: View {
    @Environment(\.openURL) private var openURL

    private var faqItems: [(question: String, answer: String)] {
        [
            (
                "help_faq_q1",
                "help_faq_a1"
            ),
            (
                "help_faq_q2",
                "help_faq_a2"
            ),
            (
                "help_faq_q3",
                "help_faq_a3"
            ),
            (
                "help_faq_q4",
                "help_faq_a4"
            ),
            (
                "help_faq_q5",
                "help_faq_a5"
            ),
            (
                "help_faq_q6",
                "help_faq_a6"
            )
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("help_faq_title")
                    .font(AppFont.title2)
                    .foregroundStyle(AppColor.trustBlue)

                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array(faqItems.enumerated()), id: \.offset) { _, item in
                        DisclosureGroup {
                            Text(LocalizedStringKey(item.answer))
                                .font(AppFont.body)
                                .foregroundStyle(.secondary)
                                .padding(.top, AppSpacing.xs)
                        } label: {
                            Text(LocalizedStringKey(item.question))
                                .font(AppFont.headline)
                                .foregroundStyle(.primary)
                        }
                        .padding(AppSpacing.md)
                        .background(AppColor.cardBackground)
                        .cornerRadius(AppRadius.card)
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("help_contact")
                        .font(AppFont.title3)

                    HStack {
                        Text("help_email_label")
                            .font(AppFont.body)
                        Text("support@trustcare.app")
                            .font(AppFont.body)
                            .foregroundStyle(.secondary)
                    }

                    Button("help_report_issue") {
                        if let url = URL(string: "mailto:support@trustcare.app?subject=TrustCare%20Destek") {
                            openURL(url)
                        }
                    }
                    .font(AppFont.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColor.trustBlue)
                    .cornerRadius(AppRadius.button)
                }
                .padding(AppSpacing.md)
                .background(AppColor.cardBackground)
                .cornerRadius(AppRadius.card)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .navigationTitle("menu_help")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
