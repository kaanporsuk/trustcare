import SwiftUI

struct SplashView: View {
    @Binding var appState: AppState
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some View {
        ZStack {
            Color.tcBackground
            .ignoresSafeArea()

            Circle()
                .fill(Color.tcOcean.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 10)
                .offset(y: -120)

            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 74, weight: .bold))
                    .foregroundStyle(Color.tcOcean)
                    .padding(20)
                    .background(Color.tcSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.tcOcean.opacity(0.2), lineWidth: 1)
                    )
                Text("app_name")
                    .font(AppFont.title1)
                    .foregroundStyle(Color.tcTextPrimary)
                Text(tcKey: "tagline", fallback: "Healthcare, Verified.")
                    .font(AppFont.body)
                    .foregroundStyle(Color.tcTextSecondary)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .task {
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
            } catch {
                return
            }
            let session = await AuthService.currentSession()
            if session != nil {
                appState = .main
            } else if hasSeenOnboarding {
                appState = .auth
            } else {
                appState = .onboarding
            }
        }
    }
}
