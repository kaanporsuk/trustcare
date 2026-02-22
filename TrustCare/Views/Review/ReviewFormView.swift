import SwiftUI

struct ReviewFormView: View {
    let provider: Provider

    var body: some View {
        ReviewHubView(initialProvider: provider)
    }
}
