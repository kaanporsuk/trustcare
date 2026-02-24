import SwiftUI

struct VerifiedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption)
            Text("Verified")
                .font(AppFont.footnote)
        }
        .foregroundStyle(AppColor.success)
    }
}
