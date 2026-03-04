import SwiftUI
import MapKit

struct RehberChatView: View {
    @ObservedObject var viewModel: RehberViewModel
    @Binding var showChat: Bool
    @ObservedObject private var specialtyService = SpecialtyService.shared
    @State private var inputText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    persistentInfoBar

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: AppSpacing.sm) {
                                if !viewModel.isLoading && viewModel.messages.isEmpty {
                                    emptyState
                                } else if viewModel.isLoading && viewModel.messages.isEmpty {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.top, AppSpacing.md)
                                }

                                ForEach(viewModel.messages) { message in
                                    messageRow(message)
                                        .id(message.id)
                                }

                                if viewModel.isLoading && !viewModel.messages.isEmpty {
                                    typingIndicator
                                        .id("typing")
                                }
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.md)
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                        .onChange(of: viewModel.isLoading) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(AppFont.footnote)
                            .foregroundStyle(AppColor.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppSpacing.md)
                    }

                    usageCounter

                    inputBar
                }
                .background(AppColor.background)
                .navigationTitle("tab_guide")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            Task {
                                await viewModel.closeCurrentSession()
                                showChat = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("rehber_sessions")
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("rehber_new_short") {
                            Task {
                                await viewModel.closeCurrentSession()
                                viewModel.startNewChat()
                            }
                        }
                    }
                }

                if viewModel.showEmergencyCard {
                    EmergencyCardView {
                        viewModel.dismissEmergencyCard()
                    }
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .task {
                if specialtyService.specialties.isEmpty {
                    await specialtyService.loadSpecialties()
                }
            }
        }
    }

    private var persistentInfoBar: some View {
        HStack(spacing: AppSpacing.xs) {
            Text("🔵")
            Text("rehber_info_bar")
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColor.trustBlue.opacity(0.08))
    }

    private var usageCounter: some View {
        HStack {
            Text(String(localized: "rehber_usage_counter")) + Text(" \(viewModel.usageCount)")
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.xs)
    }

    private var inputBar: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.sm) {
                TextField("rehber_input_placeholder", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(AppFont.body)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColor.cardBackground)
                    .cornerRadius(AppRadius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button)
                            .stroke(AppColor.border, lineWidth: 1)
                    )
                    .submitLabel(.send)
                    .onSubmit {
                        submitCurrentMessage()
                    }

                Button {
                    submitCurrentMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(canSubmitMessage ? AppColor.trustBlue : AppColor.border)
                        .clipShape(Circle())
                }
                .disabled(!canSubmitMessage)
            }

            if viewModel.sendCooldownRemainingSeconds > 0 {
                Text(String(format: "rehber_cooldown", viewModel.sendCooldownRemainingSeconds))
                    .font(AppFont.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.xs)
        .padding(.bottom, AppSpacing.md)
        .background(AppColor.background)
    }

    private var canSubmitMessage: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isLoading
            && viewModel.sendCooldownRemainingSeconds == 0
    }

    private func submitCurrentMessage() {
        guard canSubmitMessage else { return }
        let text = inputText
        inputText = ""
        Task {
            await viewModel.sendMessage(text)
        }
    }

    @ViewBuilder
    private func messageRow(_ message: RehberMessage) -> some View {
        let infoStyleMessage = message.isFallback || message.isRateLimited

        VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: AppSpacing.xs) {
            HStack {
                if message.role == "user" { Spacer(minLength: 50) }

                if infoStyleMessage && message.role == "assistant" {
                    HStack(alignment: .top, spacing: AppSpacing.xs) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)

                        Text(message.content)
                            .font(AppFont.body)
                            .foregroundStyle(Color.primary)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Color(.systemGray5))
                    .cornerRadius(AppRadius.card)
                } else {
                    Text(message.content)
                        .font(AppFont.body)
                        .foregroundStyle(message.role == "user" ? Color.white : Color.primary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(message.role == "user" ? AppColor.trustBlue : Color(.systemGray6))
                        .cornerRadius(AppRadius.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.card)
                                .stroke(message.wasEmergency ? AppColor.error : Color.clear, lineWidth: 2)
                        )
                }

                if message.role == "assistant" { Spacer(minLength: 50) }
            }
            
            // Emergency action card for emergency messages
            if message.role == "assistant", message.wasEmergency {
                emergencyActionCard
            }

            if message.role == "assistant", message.isFallback {
                Button("rehber_try_again") {
                    viewModel.retryLastFailedMessage()
                }
                .font(AppFont.footnote)
                .foregroundStyle(AppColor.trustBlue)
                .padding(.leading, AppSpacing.xs)
            }

            if message.role == "assistant", let specialties = message.recommendedSpecialties, !specialties.isEmpty {
                specialtyCards(specialties)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == "user" ? .trailing : .leading)
        .onAppear {
            if message.role == "assistant", message.wasEmergency {
                // Trigger heavy haptic feedback for emergency
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
            }
        }
    }
    
    private var emergencyActionCard: some View {
        Button {
            if let url = URL(string: "tel://112"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        } label: {
            VStack(spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("rehber_call_emergency")
                            .font(AppFont.headline)
                            .foregroundStyle(.white)
                        
                        Text("112")
                            .font(AppFont.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                }
                .padding(AppSpacing.md)
                
                Text("rehber_emergency_danger")
                    .font(AppFont.footnote)
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
            }
            .background(AppColor.error)
            .cornerRadius(AppRadius.card)
        }
        .buttonStyle(.plain)
    }

    private func specialtyCards(_ specialties: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ForEach(specialties, id: \.self) { specialty in
                Button {
                    NotificationCenter.default.post(name: .trustCareSwitchTab, object: 0)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        NotificationCenter.default.post(name: .trustCareApplySpecialtyFilter, object: specialty)
                    }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: iconName(for: specialty))
                            .foregroundStyle(AppColor.trustBlue)
                        Text(specialty)
                            .font(AppFont.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("rehber_find_provider")
                            .font(AppFont.footnote)
                            .foregroundStyle(AppColor.trustBlue)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColor.cardBackground)
                    .cornerRadius(AppRadius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button)
                            .stroke(AppColor.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, AppSpacing.xs)
    }

    private var typingIndicator: some View {
        HStack {
            TypingDotsView()
            Spacer(minLength: 50)
        }
        .padding(.vertical, AppSpacing.xs)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("rehber_empty_state")
                .font(AppFont.body)
                .foregroundStyle(.secondary)
            Text("rehber_empty_state_sub")
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            if viewModel.isLoading {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("typing", anchor: .bottom)
                }
            } else if let lastId = viewModel.messages.last?.id {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
    }

    private func iconName(for specialtyName: String) -> String {
        if let specialty = specialtyService.specialties.first(where: {
            $0.name.caseInsensitiveCompare(specialtyName) == .orderedSame
            || ($0.nameTr?.caseInsensitiveCompare(specialtyName) == .orderedSame)
        }) {
            return specialty.iconName
        }
        return "cross.case"
    }
}

private struct TypingDotsView: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 6) {
            dot(delay: 0)
            dot(delay: 0.2)
            dot(delay: 0.4)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(Color(.systemGray6))
        .cornerRadius(AppRadius.card)
        .onAppear {
            isAnimating = true
        }
    }

    private func dot(delay: Double) -> some View {
        Circle()
            .fill(Color.secondary)
            .frame(width: 7, height: 7)
            .scaleEffect(isAnimating ? 1.0 : 0.6)
            .opacity(isAnimating ? 1 : 0.4)
            .animation(
                .easeInOut(duration: 0.6)
                    .repeatForever()
                    .delay(delay),
                value: isAnimating
            )
    }
}

struct EmergencyCardView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            AppColor.error.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                Spacer()

                Text("rehber_emergency_title")
                    .font(AppFont.title1)
                    .foregroundStyle(.white)

                Text("rehber_emergency_subtitle")
                    .font(AppFont.headline)
                    .foregroundStyle(.white)

                Button {
                    if let url = URL(string: "tel://112"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("rehber_call_112")
                        .font(AppFont.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.red)
                        .cornerRadius(AppRadius.button)
                }

                Button {
                    let query = "Acil Servis".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Acil%20Servis"
                    if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("rehber_nearest_emergency")
                        .font(AppFont.headline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(AppRadius.button)
                }

                Spacer()

                Button("close_button") {
                    onDismiss()
                }
                .font(AppFont.footnote)
                .foregroundStyle(Color.white.opacity(0.85))
                .padding(.bottom, AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
}
