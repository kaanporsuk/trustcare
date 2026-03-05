import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "search_placeholder"

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 44)
        .background(Color.tcSurface)
        .cornerRadius(AppRadius.button)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.button)
                .stroke(Color.tcBorder, lineWidth: 1)
        )
    }
}
