import SwiftUI

struct RehberView: View {
    @AppStorage("rehber_consent_given") private var consentGiven: Bool = false
    @StateObject private var viewModel = RehberViewModel()
    @State private var showChat = false

    var body: some View {
        Group {
            if consentGiven {
                if showChat {
                    RehberChatView(viewModel: viewModel, showChat: $showChat)
                } else {
                    RehberSessionListView(viewModel: viewModel, showChat: $showChat)
                }
            } else {
                RehberOnboardingView {
                    consentGiven = true
                }
            }
        }
    }
}
