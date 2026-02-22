import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var profileVM = ProfileViewModel()
    @State private var selectedTab: Int = 0

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
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Keşfet")
            }
            .tag(0)

            NavigationStack {
                RehberView()
            }
            .tabItem {
                Image(systemName: "bubble.left.and.text.bubble.right")
                Text("Rehber")
            }
            .tag(1)
            .badge("Plus")

            NavigationStack {
                ReviewHubView()
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("Değerlendir")
            }
            .tag(2)

            NavigationStack {
                ProfileView(selectedTab: $selectedTab)
            }
            .environmentObject(profileVM)
            .tabItem {
                Image(systemName: "person.circle")
                Text("Profil")
            }
            .tag(3)
            .badge(profileVM.unreadNotificationCount)
        }
        .tint(AppColor.trustBlue)
        .toolbarBackground(AppColor.cardBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onChange(of: selectedTab) { _, _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .task {
            await profileVM.loadNotificationCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: .trustCareSwitchTab)) { note in
            if let tab = note.object as? Int {
                selectedTab = tab
            }
        }
        .alert(String(localized: "Error"), isPresented: Binding(
            get: { profileVM.errorMessage != nil },
            set: { if !$0 { profileVM.errorMessage = nil } }
        )) {
            Button(String(localized: "OK")) { profileVM.errorMessage = nil }
        } message: {
            Text(profileVM.errorMessage ?? "")
        }
    }
}
