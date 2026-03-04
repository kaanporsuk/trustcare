import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var appRouter: AppRouter
    @StateObject private var profileVM = ProfileViewModel()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        appearance.shadowColor = UIColor(AppColor.border)

        let normalColor = UIColor.secondaryLabel
        let selectedColor = UIColor(AppColor.trustBlue)

        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $appRouter.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("tab_discover")
            }
            .tag(0)

            NavigationStack {
                RehberView()
            }
            .tabItem {
                Image(systemName: "bubble.left.and.text.bubble.right")
                Text("tab_guide")
            }
            .tag(1)
            .badge(Text("tab_badge_plus"))

            NavigationStack {
                ReviewHubView()
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("tab_review")
            }
            .tag(2)

            NavigationStack {
                ProfileView(selectedTab: $appRouter.selectedTab)
            }
            .environmentObject(profileVM)
            .tabItem {
                Image(systemName: "person.circle")
                Text("tab_profile")
            }
            .tag(3)
            .badge(profileVM.unreadNotificationCount)
        }
        .tint(AppColor.trustBlue)
        .toolbarBackground(AppColor.cardBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onChange(of: appRouter.selectedTab) { _, _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .task {
            await profileVM.loadNotificationCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: .trustCareSwitchTab)) { note in
            if let tab = note.object as? Int {
                appRouter.setSelectedTab(tab)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { profileVM.errorMessage != nil },
            set: { if !$0 { profileVM.errorMessage = nil } }
        )) {
            Button("OK") { profileVM.errorMessage = nil }
        } message: {
            Text(profileVM.errorMessage ?? "")
        }
    }
}
