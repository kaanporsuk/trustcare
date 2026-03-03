import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String = "inbox.fill",
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(AppColor.trustBlue.opacity(0.5))
            
            Text(LocalizedStringKey(title))
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(LocalizedStringKey(message))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    action()
                }) {
                    Text(LocalizedStringKey(actionTitle))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(AppColor.trustBlue)
                        .cornerRadius(AppRadius.button)
                }
                .padding(.top, AppSpacing.sm)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.lg)
    }
}

// Skeleton card for loading states
struct SkeletonReviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                        .frame(maxWidth: 150)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                        .frame(maxWidth: 100)
                }
                Spacer()
            }
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 12)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 12)
                .frame(maxWidth: 80)
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
        .shimmering()
    }
}

// Shimmer effect modifier
struct ShimmeringModifier: ViewModifier {
    @State private var isShimmering = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isShimmering ? 300 : -300)
                .animation(
                    Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                    value: isShimmering
                )
            )
            .onAppear {
                isShimmering = true
            }
    }
}

extension View {
    func shimmering() -> some View {
        self.modifier(ShimmeringModifier())
    }
}

#Preview {
    VStack(spacing: 20) {
        EmptyStateView(
            icon: "inbox.fill",
            title: "No Reviews",
            message: "Share your first healthcare experience",
            actionTitle: "Write Review"
        ) {}
        
        SkeletonReviewCard()
    }
    .padding()
}
