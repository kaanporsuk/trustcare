import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        LegalMarkdownContentView(kind: .terms)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        .navigationTitle(Text(tcKey: "menu_terms", fallback: "Terms of Service"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
