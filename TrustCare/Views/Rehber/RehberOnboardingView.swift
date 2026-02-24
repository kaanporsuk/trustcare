import SwiftUI

struct RehberOnboardingView: View {
    @State private var consentChecked: Bool = false
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(AppColor.trustBlue)

                    Text("rehber_title")
                        .font(AppFont.title2)

                    Text("rehber_onboarding_subtitle")
                        .font(AppFont.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.lg)

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    featureRow(String(localized: "rehber_feature_1"))
                    featureRow(String(localized: "rehber_feature_2"))
                    featureRow(String(localized: "rehber_feature_3"))
                }
                .padding(AppSpacing.md)
                .background(AppColor.cardBackground)
                .cornerRadius(AppRadius.card)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("rehber_onboarding_warning")
                        .font(AppFont.footnote)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.leading)
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColor.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.card)
                        .stroke(AppColor.warning, lineWidth: 1)
                )

                Button {
                    consentChecked.toggle()
                } label: {
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Image(systemName: consentChecked ? "checkmark.square.fill" : "square")
                            .foregroundStyle(consentChecked ? AppColor.trustBlue : .secondary)
                        Text("rehber_consent_text")
                            .font(AppFont.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .buttonStyle(.plain)

                Text("rehber_plus_trial")
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.premium)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColor.premium.opacity(0.08))
                    .cornerRadius(AppRadius.button)

                Button {
                    UserDefaults.standard.set(true, forKey: "rehber_consent_given")
                    UserDefaults.standard.set(Date(), forKey: "rehber_consent_date")
                    onStart()
                } label: {
                    Text("rehber_start")
                        .font(AppFont.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(consentChecked ? AppColor.trustBlue : AppColor.border)
                        .cornerRadius(AppRadius.button)
                }
                .disabled(!consentChecked)
                .padding(.bottom, AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .background(AppColor.background)
        .navigationTitle("tab_guide")
    }

    private func featureRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColor.trustBlue)
            Text(text)
                .font(AppFont.body)
                .foregroundStyle(.primary)
        }
    }
}
