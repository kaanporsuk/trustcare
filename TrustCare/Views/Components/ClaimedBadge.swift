import SwiftUI

struct ClaimedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(Color.tcOcean)
            Text("Claimed Business")
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
