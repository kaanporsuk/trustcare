import SwiftUI

struct ClaimedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(AppColor.trustBlue)
            Text(String(localized: "Claimed Business"))
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
