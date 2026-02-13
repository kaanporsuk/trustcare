import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject private var authVM: AuthViewModel
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
                ReviewHubView()
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text(String(localized: "tab_review"))
            }
            .tag(1)

            NavigationStack {
                ProfileView(selectedTab: $selectedTab)
            }
            .environmentObject(profileVM)
            .tabItem {
                Image(systemName: "person.circle")
                Text(String(localized: "tab_profile"))
            }
            .tag(2)
            .badge(profileVM.unreadNotificationCount)
        }
        .tint(AppColor.trustBlue)
        .onChange(of: selectedTab) { _, _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .task {
            await profileVM.loadNotificationCount()
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
