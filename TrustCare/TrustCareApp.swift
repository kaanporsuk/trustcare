import SwiftUI

enum AppState {
    case splash
    case onboarding
    case auth
    case main
}

@main
struct TrustCareApp: App {
    @StateObject private var localizationManager = LocalizationManager()
    @StateObject private var authViewModel = AuthViewModel()
    @State private var appState: AppState = .splash
    @State private var path = NavigationPath()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                Group {
                    switch appState {
                    case .splash:
                        SplashView(appState: $appState)
                    case .onboarding:
                        OnboardingView(appState: $appState)
                    case .auth:
                        AuthView(appState: $appState)
                    case .main:
                        MainTabView(appState: $appState)
                    }
                }
            }
            .environment(\.layoutDirection, localizationManager.layoutDirection)
            .environmentObject(localizationManager)
            .environmentObject(authViewModel)
        }
    }
}
