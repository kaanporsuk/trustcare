import SwiftUI

struct ReviewConfirmationView: View {
    let hasProof: Bool
    let onDone: () -> Void

    @State private var animateCheck: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Animated checkmark
            ZStack {
                Circle()
                    .fill(AppColor.success.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(AppColor.success)
                    .scaleEffect(animateCheck ? 1.0 : 0.3)
                    .opacity(animateCheck ? 1.0 : 0)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateCheck)

            VStack(spacing: AppSpacing.sm) {
                Text(String(localized: "Review Submitted!"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColor.trustBlue)
                
                if hasProof {
                    Text(String(localized: "Your review is pending verification"))
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text(String(localized: "We'll verify your proof within 24-48 hours and notify you"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text(String(localized: "Your review has been submitted"))
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text(String(localized: "You can add verification documents anytime"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            VStack(spacing: AppSpacing.md) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onDone()
                }) {
                    Text(String(localized: "Write Another Review"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(AppColor.trustBlue)
                        .cornerRadius(AppRadius.button)
                }

                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onDone()
                }) {
                    Text(String(localized: "Go Home"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(AppColor.trustBlue)
                        .background(AppColor.cardBackground)
                        .cornerRadius(AppRadius.button)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .padding(AppSpacing.xl)
        .background(Color.white)
        .onAppear {
            animateCheck = true
        }
    }
}
