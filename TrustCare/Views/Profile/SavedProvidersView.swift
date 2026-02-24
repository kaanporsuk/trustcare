import SwiftUI
import Supabase

struct SavedProvidersView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager
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
                    title: "saved_empty_title",
                    message: "saved_empty_message",
                    actionTitle: "saved_empty_action"
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
                            Text(localizedSpecialty(for: provider))
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
        .navigationTitle("menu_saved")
        .toolbar(.hidden, for: .tabBar)
        .task {
            await loadSavedProviders()
        }
        .refreshable {
            await loadSavedProviders()
        }
        .alert("error_generic", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("button_ok") { errorMessage = nil }
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

    private func localizedSpecialty(for provider: Provider) -> String {
        guard let specialty = SpecialtyService.shared.specialties.first(where: {
            [$0.name, $0.nameTr, $0.nameDe, $0.namePl, $0.nameNl, $0.nameDa]
                .compactMap { $0 }
                .contains { $0.caseInsensitiveCompare(provider.specialty) == .orderedSame }
        }) else {
            return provider.specialty
        }
        return specialty.resolvedName(using: localizationManager)
    }
}
