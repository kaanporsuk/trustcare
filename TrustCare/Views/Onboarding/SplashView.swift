import SwiftUI

struct SplashView: View {
    @Binding var appState: AppState
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.tcOcean, Color.tcSage],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                Text("app_name")
                    .font(AppFont.title1)
                    .foregroundStyle(.white)
                Text("tagline")
                    .font(AppFont.body)
                    .foregroundStyle(Color.white.opacity(0.9))
            }
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
