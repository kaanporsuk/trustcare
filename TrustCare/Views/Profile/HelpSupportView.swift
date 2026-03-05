import SwiftUI

struct HelpSupportView: View {
    @Environment(\.openURL) private var openURL

    private struct FAQItem {
        let questionKey: String
        let questionFallback: String
        let answerKey: String
        let answerFallback: String
    }

    private var faqItems: [FAQItem] {
        [
            FAQItem(
                questionKey: "help_faq_q1",
                questionFallback: "How do I add a review?",
                answerKey: "help_faq_a1",
                answerFallback: "Open Review, choose a provider, and complete the guided form."
            ),
            FAQItem(
                questionKey: "help_faq_q2",
                questionFallback: "Can I edit my review?",
                answerKey: "help_faq_a2",
                answerFallback: "Yes. Open My Reviews and tap Edit on your review."
            ),
            FAQItem(
                questionKey: "help_faq_q3",
                questionFallback: "What does Verified mean?",
                answerKey: "help_faq_a3",
                answerFallback: "Verified means the review passed our checks or includes supporting proof."
            ),
            FAQItem(
                questionKey: "help_faq_q4",
                questionFallback: "How do I report content?",
                answerKey: "help_faq_a4",
                answerFallback: "Open the review and tap Report. Our team will review it."
            ),
            FAQItem(
                questionKey: "help_faq_q5",
                questionFallback: "How do I delete my account or data?",
                answerKey: "help_faq_a5",
                answerFallback: "Go to Settings and request deletion. We will confirm when completed."
            ),
            FAQItem(
                questionKey: "help_faq_q6",
                questionFallback: "How can I contact support?",
                answerKey: "help_faq_a6",
                answerFallback: "Email support@trustcare.app with your app version and issue details."
            )
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text(tcKey: "help_faq_title", fallback: "Help & Support")
                    .font(AppFont.title2)
                    .foregroundStyle(Color.tcOcean)

                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array(faqItems.enumerated()), id: \.offset) { _, item in
                        DisclosureGroup {
                            Text(tcKey: item.answerKey, fallback: item.answerFallback)
                                .font(AppFont.body)
                                .foregroundStyle(.secondary)
                                .padding(.top, AppSpacing.xs)
                        } label: {
                            Text(tcKey: item.questionKey, fallback: item.questionFallback)
                                .font(AppFont.headline)
                                .foregroundStyle(.primary)
                        }
                        .padding(AppSpacing.md)
                        .background(Color.tcSurface)
                        .cornerRadius(AppRadius.card)
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(tcKey: "help_contact", fallback: "Contact")
                        .font(AppFont.title3)

                    HStack {
                        Text(tcKey: "help_email_label", fallback: "Email")
                            .font(AppFont.body)
                        Text("support@trustcare.app")
                            .font(AppFont.body)
                            .foregroundStyle(.secondary)
                    }

                    Button(tcString("help_report_issue", fallback: "Report an issue")) {
                        if let url = URL(string: "mailto:support@trustcare.app?subject=TrustCare%20Destek") {
                            openURL(url)
                        }
                    }
                    .font(AppFont.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.tcOcean)
                    .cornerRadius(AppRadius.button)
                }
                .padding(AppSpacing.md)
                .background(Color.tcSurface)
                .cornerRadius(AppRadius.card)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .navigationTitle(Text(tcKey: "menu_help", fallback: "Help & support"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
