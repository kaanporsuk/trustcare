//
//  TrustCareApp.swift
//  TrustCare
//
//  Created by Oguz Kaan Porsuk on 10/02/2026.
//

import SwiftUI

extension Notification.Name {
    static let trustCareRouteToAuth = Notification.Name("trustCareRouteToAuth")
    static let trustCareSwitchTab = Notification.Name("trustCareSwitchTab")
    static let trustCareApplySpecialtyFilter = Notification.Name("trustCareApplySpecialtyFilter")
    static let trustCareApplyCanonicalSpecialtyFilter = Notification.Name("trustCareApplyCanonicalSpecialtyFilter")
}

enum AppState {
    case splash
    case onboarding
    case auth
    case main
}

enum AppRoute: Hashable {
    case provider(UUID)
}

@main
struct TrustCareApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var localizationManager = LocalizationManager()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appRouter = AppRouter()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var appState: AppState = .splash
    @State private var path = NavigationPath()
    @AppStorage("colorScheme") private var colorSchemePreference: String = "system"

    init() {
        Task {
            await SpecialtyService.shared.loadSpecialties()
        }
    }

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
                        MainTabView()
                            .environmentObject(localizationManager)
                            .environmentObject(appRouter)
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .provider(let id):
                        ProviderDetailView(providerId: id)
                    }
                }
            }
            .dismissKeyboardOnTap()
            .environment(\.locale, localizationManager.locale)
            .environmentObject(localizationManager)
            .environmentObject(authViewModel)
            .environmentObject(appRouter)
            .environmentObject(networkMonitor)
            .preferredColorScheme(preferredColorScheme)
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                Task {
                    await authViewModel.verifySessionState()
                }
            }
            .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
                if !isAuthenticated, appState == .main {
                    path = NavigationPath()
                    appState = .auth
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .trustCareRouteToAuth)) { _ in
                path = NavigationPath()
                appState = .auth
            }
            .id(localizationManager.effectiveLanguage)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "trustcare" else { return }

        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        if host == "provider", let idString = pathComponents.first, let id = UUID(uuidString: idString) {
            appState = .main
            path = NavigationPath()
            path.append(AppRoute.provider(id))
            return
        }

        if host == "review", let idString = pathComponents.first, let reviewId = UUID(uuidString: idString) {
            Task {
                do {
                    let review = try await ReviewService.fetchReviewById(reviewId)
                    appState = .main
                    path = NavigationPath()
                    path.append(AppRoute.provider(review.providerId))
                } catch {
                    return
                }
            }
        }
    }
}
