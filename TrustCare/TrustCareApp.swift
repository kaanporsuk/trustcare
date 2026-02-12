//
//  TrustCareApp.swift
//  TrustCare
//
//  Created by Oguz Kaan Porsuk on 10/02/2026.
//

import SwiftUI

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
    @StateObject private var localizationManager = LocalizationManager()
    @StateObject private var authViewModel = AuthViewModel()
    @State private var appState: AppState = .splash
    @State private var path = NavigationPath()
    @AppStorage("colorScheme") private var colorSchemePreference: String = "system"

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
            .environment(\.layoutDirection, localizationManager.layoutDirection)
            .environmentObject(localizationManager)
            .environmentObject(authViewModel)
            .preferredColorScheme(preferredColorScheme)
            .onOpenURL { url in
                handleDeepLink(url)
            }
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
