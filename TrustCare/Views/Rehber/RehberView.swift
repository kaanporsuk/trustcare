import SwiftUI

struct RehberView: View {
    @AppStorage("rehber_consent_given") private var consentGiven: Bool = false

    var body: some View {
        Group {
            if consentGiven {
                RehberChatView()
            } else {
                RehberOnboardingView {
                    consentGiven = true
                }
            }
        }
    }
}
