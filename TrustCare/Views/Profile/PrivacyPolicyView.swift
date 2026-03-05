import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            LegalMarkdownContentView(kind: .privacy)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.lg)
        }
        .navigationTitle(Text(tcKey: "menu_privacy", fallback: "Privacy Policy"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
