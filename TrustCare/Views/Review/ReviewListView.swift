import SwiftUI

struct ReviewListView: View {
    let providerId: UUID

    var body: some View {
        Text(String(localized: "Reviews"))
            .font(AppFont.title2)
    }
}
