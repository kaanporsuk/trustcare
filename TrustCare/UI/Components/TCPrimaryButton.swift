import SwiftUI

struct TCPrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    var fullWidth: Bool = true
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.headline, design: .default).weight(.semibold))
                .foregroundStyle(isEnabled ? Color.white : Color.tcTextSecondary)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .frame(height: 50)
                .padding(.horizontal, fullWidth ? 0 : 16)
                .background(isEnabled ? Color.tcCoral : Color.tcBorder)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .scaleEffect(isPressed ? 0.98 : 1)
                .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}
