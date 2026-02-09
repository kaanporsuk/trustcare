import SwiftUI

struct SplashView: View {
	@Binding var appState: AppState
	@AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

	var body: some View {
		ZStack {
			LinearGradient(
				colors: [AppColor.trustBlue, AppColor.trustBlueLight],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			.ignoresSafeArea()

			VStack(spacing: AppSpacing.lg) {
				Image(systemName: "cross.case.fill")
					.font(.system(size: 80))
					.foregroundStyle(.white)
				Text(String(localized: "app_name"))
					.font(AppFont.title1)
					.foregroundStyle(.white)
				Text(String(localized: "tagline"))
					.font(AppFont.body)
					.foregroundStyle(Color.white.opacity(0.9))
			}
		}
		.task {
			try? await Task.sleep(nanoseconds: 2_000_000_000)
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
