import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var appRouter: AppRouter
    @StateObject private var profileVM = ProfileViewModel()
    @State private var showReviewNudge = ReviewSubmissionViewModel.shouldShowFirstReviewNudge

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundEffect = nil
        appearance.backgroundColor = UIColor(Color.tcSurface)
        appearance.shadowColor = UIColor(Color.tcBorder)

        let normalColor = UIColor.secondaryLabel
        let selectedColor = UIColor(Color.tcOcean)

        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = UIColor(Color.tcCoral)
        appearance.stackedLayoutAppearance.selected.badgeBackgroundColor = UIColor(Color.tcCoral)

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
                Text(tcKey: "tab_discover", fallback: "Discover")
            }
            .tag(0)

            NavigationStack {
                RehberView()
            }
            .tabItem {
                Image(systemName: "bubble.left.and.text.bubble.right")
                Text(tcKey: "tab_guide", fallback: "Guide")
            }
            .tag(1)
            .badge(tcString("tab_badge_plus", fallback: "PLUS"))

            NavigationStack {
                ReviewHubView()
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text(tcKey: "tab_review", fallback: "Review")
            }
            .tag(2)
            .badge(showReviewNudge ? "" : nil)

            NavigationStack {
                ProfileView(selectedTab: $appRouter.selectedTab)
            }
            .environmentObject(profileVM)
            .tabItem {
                Image(systemName: "person.circle")
                Text(tcKey: "tab_profile", fallback: "Profile")
            }
            .tag(3)
            .badge(profileVM.unreadNotificationCount)
        }
        .tint(Color.tcOcean)
        .background(alignment: .bottom) {
            GeometryReader { proxy in
                Rectangle()
                    .fill(Color.tcSurface)
                    .frame(height: 49 + proxy.safeAreaInsets.bottom)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .clipped()
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
            }
        }
        .toolbarBackground(Color.tcSurface, for: .tabBar)
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
        .onReceive(NotificationCenter.default.publisher(for: .trustCareReviewNudgeUpdated)) { _ in
            showReviewNudge = ReviewSubmissionViewModel.shouldShowFirstReviewNudge
        }
        .alert(tcString("error_generic", fallback: "Error"), isPresented: Binding(
            get: { profileVM.errorMessage != nil },
            set: { if !$0 { profileVM.errorMessage = nil } }
        )) {
            Button(tcString("button_ok", fallback: "OK")) { profileVM.errorMessage = nil }
        } message: {
            Text(profileVM.errorMessage ?? "")
        }
    }
}
