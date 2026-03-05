import SwiftUI

struct TCSearchBar: View {
    @Binding var text: String
    let placeholderKey: String
    let placeholderFallback: String
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.tcTextSecondary)

            TextField(
                "",
                text: $text,
                prompt: Text(tcKey: placeholderKey, fallback: placeholderFallback)
                    .foregroundStyle(Color.tcTextSecondary)
            )
            .foregroundStyle(Color.tcTextPrimary)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .onSubmit {
                onSubmit?()
            }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.tcTextSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Clear search"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.tcSurface)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(Color.tcBorder, lineWidth: 1)
        }
    }
}
