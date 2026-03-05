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
                        .foregroundStyle(Color.tcOcean)

                    Text(tcKey: "rehber_title", fallback: "Guide")
                        .font(AppFont.title2)

                    Text(tcKey: "rehber_onboarding_subtitle", fallback: "Get trusted guidance before your next care decision.")
                        .font(AppFont.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.lg)

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    featureRow("rehber_feature_1")
                    featureRow("rehber_feature_2")
                    featureRow("rehber_feature_3")
                }
                .padding(AppSpacing.md)
                .background(Color.tcSurface)
                .cornerRadius(AppRadius.card)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(tcKey: "rehber_onboarding_warning", fallback: "Rehber is informational and does not replace professional medical advice.")
                        .font(AppFont.footnote)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.leading)
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.tcSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.card)
                        .stroke(Color.tcCoral, lineWidth: 1)
                )

                Button {
                    consentChecked.toggle()
                } label: {
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Image(systemName: consentChecked ? "checkmark.square.fill" : "square")
                            .foregroundStyle(consentChecked ? Color.tcOcean : .secondary)
                        Text(tcKey: "rehber_consent_text", fallback: "I understand Rehber provides guidance and I should seek emergency help when needed.")
                            .font(AppFont.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .buttonStyle(.plain)

                Text(tcKey: "rehber_plus_trial", fallback: "Rehber Plus trial is now available")
                    .font(AppFont.footnote)
                    .foregroundStyle(Color.tcCoral)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Color.tcCoral.opacity(0.08))
                    .cornerRadius(AppRadius.button)

                Button {
                    UserDefaults.standard.set(true, forKey: "rehber_consent_given")
                    UserDefaults.standard.set(Date(), forKey: "rehber_consent_date")
                    onStart()
                } label: {
                    Text(tcKey: "rehber_start", fallback: "Start")
                        .font(AppFont.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(consentChecked ? Color.tcOcean : Color.tcBorder)
                        .cornerRadius(AppRadius.button)
                }
                .disabled(!consentChecked)
                .padding(.bottom, AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .background(Color.tcBackground)
        .navigationTitle(Text(tcKey: "tab_guide", fallback: "Rehber"))
    }

    private func featureRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.tcOcean)
            Text(tcKey: text, fallback: "Feature details")
                .font(AppFont.body)
                .foregroundStyle(.primary)
        }
    }
}
