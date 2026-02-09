import SwiftUI

struct MainTabView: View {
    @Binding var appState: AppState

    var body: some View {
        TabView {
            Text(String(localized: "tab_find"))
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(String(localized: "tab_find"))
                }

            Text(String(localized: "tab_review"))
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text(String(localized: "tab_review"))
                }

            Text(String(localized: "tab_profile"))
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text(String(localized: "tab_profile"))
                }
        }
        .tint(AppColor.trustBlue)
    }
}
