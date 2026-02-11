import SwiftUI
import UIKit

struct MainTabView: View {
    @StateObject private var profileVM = ProfileViewModel()
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text(String(localized: "tab_find"))
            }
            .tag(0)

            NavigationStack {
                SubmitReviewView(selectedTab: $selectedTab)
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text(String(localized: "tab_review"))
            }
            .tag(1)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Image(systemName: "person.circle")
                Text(String(localized: "tab_profile"))
            }
            .tag(2)
            .badge(profileVM.unreadNotificationCount)
        }
        .environmentObject(profileVM)
        .tint(AppColor.trustBlue)
        .onChange(of: selectedTab) { _, _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .task {
            await profileVM.loadNotificationCount()
        }
    }
}
