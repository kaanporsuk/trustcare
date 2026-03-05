import SwiftUI

struct RehberPlusBannerCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.tcOcean)
                .frame(width: 32, height: 32)
                .background(Color.tcOcean.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(tcKey: "rehber_plus_banner_title", fallback: "Rehber Plus is rolling out")
                    .font(AppFont.headline)
                    .foregroundStyle(Color.tcTextPrimary)
                Text(tcKey: "rehber_plus_banner_body", fallback: "Smarter guidance, better follow-ups, and richer medical context are on the way.")
                    .font(AppFont.footnote)
                    .foregroundStyle(Color.tcTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .background(Color.tcSurface)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .stroke(Color.tcBorder.opacity(0.8), lineWidth: 1)
        )
        .cornerRadius(AppRadius.card)
    }
}
