import SwiftUI

struct OnboardingView: View {
    @Binding var appState: AppState
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var currentPage: Int = 0

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            HStack {
                Spacer()
                Button {
                    completeOnboarding()
                } label: {
                    Text("skip")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.trustBlue)
                }
                .padding(.trailing, AppSpacing.lg)
            }

            TabView(selection: $currentPage) {
                onboardingPage(
                    icon: "stethoscope",
                    color: AppColor.trustBlue,
                    title: "Find Trusted Care",
                    description: "Discover verified doctors based on real patient experiences",
                    tag: 0
                )
                onboardingPage(
                    icon: "checkmark.shield.fill",
                    color: AppColor.success,
                    title: "Verified Reviews",
                    description: "AI-verified recommendations you can trust",
                    tag: 1
                )
                onboardingPage(
                    icon: "person.3.fill",
                    color: Color(.systemBlue),
                    title: "Help Others",
                    description: "Your reviews guide others to better healthcare",
                    tag: 2
                )
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if currentPage == 2 {
                    completeOnboarding()
                } else {
                    withAnimation { currentPage += 1 }
                }
            } label: {
                Text(currentPage == 2 ? "Get Started" : "next")
                    .font(AppFont.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColor.trustBlue)
                    .cornerRadius(AppRadius.button)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
        .ignoresSafeArea(.keyboard)
    }

    private func onboardingPage(
        icon: String,
        color: Color,
        title: String,
        description: String,
        tag: Int
    ) -> some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(color)
            Text(title)
                .font(AppFont.title1)
            Text(description)
                .font(AppFont.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            Spacer()
        }
        .tag(tag)
    }

    private func completeOnboarding() {
        hasSeenOnboarding = true
        appState = .auth
    }
}
