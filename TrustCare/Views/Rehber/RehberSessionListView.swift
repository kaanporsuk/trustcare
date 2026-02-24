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
                        Text(String(localized: "rehber_title"))
                            .font(AppFont.title2)
                            .fontWeight(.bold)
                        
                        Text(String(localized: "rehber_subtitle"))
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, AppSpacing.lg)
                    
                    // Disclaimer card
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.blue)
                        
                        Text(String(localized: "rehber_disclaimer"))
                            .font(AppFont.footnote)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(AppColor.trustBlue.opacity(0.1))
                    .cornerRadius(AppRadius.card)
                    .padding(.horizontal, AppSpacing.md)
                    
                    // New Conversation button
                    Button {
                        viewModel.startNewChat()
                        showChat = true
                    } label: {
                        Text(String(localized: "rehber_new_conversation"))
                            .font(AppFont.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColor.trustBlue)
                            .cornerRadius(AppRadius.button)
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
                .padding(.bottom, AppSpacing.lg)
                .background(AppColor.background)
                
                // Recent Sessions section
                if viewModel.sessions.isEmpty && !viewModel.isLoadingSessions {
                    Spacer()
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        Text(String(localized: "rehber_no_conversations"))
                            .font(AppFont.headline)
                            .foregroundStyle(.primary)
                        
                        Text(String(localized: "rehber_start_guidance"))
                            .font(AppFont.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(String(localized: "rehber_recent_sessions"))
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
                                                    Label(String(localized: "rehber_delete"), systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadSessions()
            }
            .refreshable {
                await viewModel.loadSessions()
            }
            .alert(String(localized: "rehber_delete_conversation_title"), isPresented: $showDeleteConfirmation, presenting: sessionToDelete) { session in
                Button(String(localized: "settings_cancel"), role: .cancel) {
                    sessionToDelete = nil
                }
                Button(String(localized: "rehber_delete"), role: .destructive) {
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
                Text(String(localized: "rehber_delete_conversation_message"))
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
                    viewModel.errorMessage = String(localized: "rehber_load_conversation_error")
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
            .background(AppColor.cardBackground)
        }
        .buttonStyle(.plain)
        
        Divider()
            .padding(.leading, AppSpacing.md)
    }
}
