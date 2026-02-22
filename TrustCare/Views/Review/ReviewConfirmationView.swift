import SwiftUI

struct ReviewConfirmationView: View {
    let hasProof: Bool
    let onAnotherReview: () -> Void
    let onGoHome: () -> Void

    @State private var animateCheck: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

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
                Text("Değerlendirmeniz gönderildi!")
                    .font(AppFont.title2)
                    .foregroundStyle(AppColor.trustBlue)

                if hasProof {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundStyle(AppColor.pending)
                        Text("Doğrulama beklemede")
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.pending)
                    }
                } else {
                    Text("Teşekkürler! Yorumunuz yayın kuyruğuna alındı.")
                        .font(AppFont.body)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(spacing: AppSpacing.md) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onAnotherReview()
                } label: {
                    Text("Başka Değerlendir")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(AppColor.trustBlue)
                        .cornerRadius(AppRadius.button)
                }

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onGoHome()
                } label: {
                    Text("Ana Sayfaya Dön")
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
