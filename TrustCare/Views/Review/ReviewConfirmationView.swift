import SwiftUI

struct ReviewConfirmationView: View {
    let hasProof: Bool
    let onDone: () -> Void

    @State private var animateCheck: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppColor.success)
                .scaleEffect(animateCheck ? 1.0 : 0.5)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: animateCheck)

            Text(String(localized: "Review Submitted!"))
                .font(AppFont.title1)

            Text(hasProof
                 ? String(localized: "AI Verification in Progress")
                 : String(localized: "Published"))
                .font(AppFont.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(hasProof ? AppColor.warning.opacity(0.2) : AppColor.success.opacity(0.2))
                .foregroundStyle(hasProof ? AppColor.warning : AppColor.success)
                .cornerRadius(AppRadius.standard)

            Button(String(localized: "Back to Home")) {
                onDone()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.trustBlue)
        }
        .padding(AppSpacing.xxl)
        .onAppear {
            animateCheck = true
        }
    }
}
