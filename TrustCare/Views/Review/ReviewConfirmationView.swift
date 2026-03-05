import SwiftUI

struct ReviewConfirmationView: View {
    let hasProof: Bool
    let onViewProvider: () -> Void
    let onAnotherReview: () -> Void
    let onGoHome: () -> Void

    @State private var animateCheck: Bool = false
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.tcSage.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(Color.tcSage)
                    .scaleEffect(animateCheck ? 1.0 : 0.3)
                    .opacity(animateCheck ? 1.0 : 0)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateCheck)

            VStack(spacing: AppSpacing.sm) {
                Text("review_submitted_title")
                    .font(AppFont.title2)
                    .foregroundStyle(Color.tcOcean)

                if hasProof {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "clock.badge.exclamationmark")
                        Text("review_verification_pending")
                            .font(AppFont.body.weight(.semibold))
                    }
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.12), in: Capsule())
                    .overlay {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.0),
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.0),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .offset(x: shimmerPhase * 220)
                            .mask(Capsule())
                            .allowsHitTesting(false)
                    }
                } else {
                    Text("review_submitted_message")
                        .font(AppFont.body)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(spacing: AppSpacing.md) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onViewProvider()
                } label: {
                    Text("View provider")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(Color.tcOcean)
                        .cornerRadius(AppRadius.button)
                }

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onAnotherReview()
                } label: {
                    Text("review_another")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(Color.tcOcean)
                        .cornerRadius(AppRadius.button)
                }

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onGoHome()
                } label: {
                    Text("review_go_home")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(Color.tcOcean)
                        .background(Color.tcSurface)
                        .cornerRadius(AppRadius.button)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .padding(AppSpacing.xl)
        .background(Color.white)
        .onAppear {
            animateCheck = true
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                shimmerPhase = 1.3
            }
        }
    }
}
