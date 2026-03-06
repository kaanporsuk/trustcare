import SwiftUI

struct TCClaimBanner: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tcKey: "Is this your practice?", fallback: "Is this your practice?")
                .font(AppFont.headline)
                .foregroundStyle(Color.tcTextPrimary)

            Text(tcKey: "Add photos, services, prices, and availability", fallback: "Add photos, services, prices, and availability")
                .font(AppFont.body)
                .foregroundStyle(Color.tcTextSecondary)

            Text(tcKey: "Help patients choose you with a complete profile", fallback: "Help patients choose you with a complete profile")
                .font(AppFont.body)
                .foregroundStyle(Color.tcTextSecondary)

            TCPrimaryButton(title: tcString("claim_profile", fallback: "Claim Profile"), fullWidth: true, action: action)
                .padding(.top, 4)
        }
        .padding(AppSpacing.md)
        .background(Color.tcCoral.opacity(0.08))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card)
                .stroke(Color.tcCoral.opacity(0.35), lineWidth: 1)
        }
        .cornerRadius(AppRadius.card)
    }
}
