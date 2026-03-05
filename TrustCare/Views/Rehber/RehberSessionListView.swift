import SwiftUI

struct RehberSessionListView: View {
    @ObservedObject var viewModel: RehberViewModel
    @Binding var showChat: Bool
    @State private var sessionToDelete: RehberSession?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header section
                VStack(spacing: AppSpacing.md) {
                    VStack(spacing: AppSpacing.xs) {
                        Text(tcKey: "rehber_title", fallback: "Guide")
                            .font(AppFont.title2)
                            .fontWeight(.bold)
                        
                        Text(tcKey: "rehber_subtitle", fallback: "Your health guidance assistant")
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, AppSpacing.lg)
                    
                    // Disclaimer card
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.tcOcean)
                        
                        Text(tcKey: "rehber_disclaimer", fallback: "Rehber provides guidance, not a medical diagnosis.")
                            .font(AppFont.footnote)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Color.tcOcean.opacity(0.1))
                    .cornerRadius(AppRadius.card)
                    .padding(.horizontal, AppSpacing.md)

                    RehberPlusBannerCard()
                        .padding(.horizontal, AppSpacing.md)
                    
                    // New Conversation button
                    Button {
                        viewModel.startNewChat()
                        showChat = true
                    } label: {
                        Text(tcKey: "rehber_new_conversation", fallback: "Start new conversation")
                            .font(AppFont.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.tcOcean)
                            .cornerRadius(AppRadius.button)
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
                .padding(.bottom, AppSpacing.lg)
                .background(Color.tcBackground)
                
                // Recent Sessions section
                if viewModel.sessions.isEmpty && !viewModel.isLoadingSessions {
                    Spacer()
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        Text(tcKey: "rehber_no_conversations", fallback: "No conversations yet")
                            .font(AppFont.headline)
                            .foregroundStyle(.primary)
                        
                        Text(tcKey: "rehber_start_guidance", fallback: "Start a new chat to get guided support.")
                            .font(AppFont.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(tcKey: "rehber_recent_sessions", fallback: "Recent sessions")
                            .font(AppFont.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, AppSpacing.md)
                        
                        if viewModel.isLoadingSessions {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, AppSpacing.lg)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(viewModel.sessions) { session in
                                        sessionRow(session)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button(role: .destructive) {
                                                    sessionToDelete = session
                                                    showDeleteConfirmation = true
                                                } label: {
                                                    Label(tcString("rehber_delete", fallback: "Delete"), systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .background(Color.tcBackground)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadSessions()
            }
            .refreshable {
                await viewModel.loadSessions()
            }
            .alert(tcString("rehber_delete_conversation_title", fallback: "Delete conversation"), isPresented: $showDeleteConfirmation, presenting: sessionToDelete) { session in
                Button(tcString("settings_cancel", fallback: "Cancel"), role: .cancel) {
                    sessionToDelete = nil
                }
                Button(tcString("rehber_delete", fallback: "Delete"), role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteSession(id: session.id)
                            sessionToDelete = nil
                        } catch {
                            // Show error?
                        }
                    }
                }
            } message: { session in
                Text(tcKey: "rehber_delete_conversation_message", fallback: "This conversation will be removed.")
            }
        }
    }
    
    @ViewBuilder
    private func sessionRow(_ session: RehberSession) -> some View {
        Button {
            Task {
                do {
                    try await viewModel.loadSessionMessages(sessionId: session.id)
                    showChat = true
                } catch {
                    viewModel.errorMessage = "rehber_load_conversation_error"
                }
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.xs) {
                        Text(session.displayTitle)
                            .font(AppFont.body)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        
                        if session.wasEmergency {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(session.formattedDate)
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
            .background(Color.tcSurface)
        }
        .buttonStyle(.plain)
        
        Divider()
            .padding(.leading, AppSpacing.md)
    }
}
