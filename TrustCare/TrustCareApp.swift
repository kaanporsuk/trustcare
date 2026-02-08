import SwiftUI

@main
struct TrustCareApp: App {
    @StateObject private var localizationManager = LocalizationManager()

    var body: some Scene {
        WindowGroup {
            Text(String(localized: "app_name"))
                .environment(\.layoutDirection, localizationManager.layoutDirection)
                .environmentObject(localizationManager)
        }
    }
}
