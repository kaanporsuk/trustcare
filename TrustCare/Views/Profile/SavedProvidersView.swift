import SwiftUI
import Supabase

struct SavedProvidersView: View {
    @State private var providers: [Provider] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if providers.isEmpty {
                EmptyStateView(
                    icon: "bookmark",
                    title: String(localized: "saved_empty_title"),
                    message: String(localized: "saved_empty_message"),
                    actionTitle: String(localized: "saved_empty_action")
                ) {
                    NotificationCenter.default.post(name: .trustCareSwitchTab, object: 0)
                }
            } else {
                List(providers) { provider in
                    NavigationLink {
                        ProviderDetailView(providerId: provider.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(provider.name)
                                .font(AppFont.headline)
                            Text(provider.specialty)
                                .font(AppFont.caption)
                                .foregroundStyle(.secondary)
                            if let distance = provider.distanceKm {
                                Text(String(format: "%.1f km", distance))
                                    .font(AppFont.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(String(localized: "menu_saved"))
        .toolbar(.hidden, for: .tabBar)
        .task {
            await loadSavedProviders()
        }
        .refreshable {
            await loadSavedProviders()
        }
        .alert(String(localized: "error_generic"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(String(localized: "button_ok")) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadSavedProviders() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await SupabaseManager.shared.client.auth.session

            struct SavedProviderRow: Decodable {
                let providerId: UUID

                enum CodingKeys: String, CodingKey {
                    case providerId = "provider_id"
                }
            }

            let response: PostgrestResponse<[SavedProviderRow]> = try await SupabaseManager.shared.client
                .from("saved_providers")
                .select("provider_id")
                .eq("user_id", value: session.user.id.uuidString)
                .order("created_at", ascending: false)
                .execute()

            let ids = response.value.map { $0.providerId }
            guard !ids.isEmpty else {
                providers = []
                return
            }

            var fetched: [Provider] = []
            for id in ids {
                if let provider = try? await ProviderService.fetchProviderById(id) {
                    fetched.append(provider)
                }
            }
            providers = fetched
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
