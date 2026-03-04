import SwiftUI
import UIKit
import Supabase

struct SettingsView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel
    @EnvironmentObject private var localizationManager: LocalizationManager

    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var showDeleteConfirm: Bool = false
    @State private var isExporting: Bool = false
    @State private var exportFileURL: URL?
    @State private var showShareSheet: Bool = false

    @AppStorage("settings_notifications_enabled") private var notificationsEnabled: Bool = true
    @AppStorage("settings_location_services_enabled") private var locationServicesEnabled: Bool = true

    var body: some View {
        Form {
            accountSection
            languageSection
            preferencesSection
            dataPrivacySection
        }
        .navigationTitle("menu_settings")
        .toolbar(.hidden, for: .tabBar)
        .task {
            if profileVM.profile == nil {
                await profileVM.loadProfile()
            }
            if profileVM.myReviews.isEmpty {
                await profileVM.loadReviews(filter: "all")
            }
            email = await AuthService.currentUserEmail() ?? ""
            phone = profileVM.profile?.phone ?? ""
        }
        .confirmationDialog("settings_delete_account", isPresented: $showDeleteConfirm) {
            Button("settings_delete_account_confirm", role: .destructive) {
                Task { await profileVM.deleteAccount() }
            }
            Button("settings_cancel", role: .cancel) { }
        } message: {
            Text("settings_delete_account_warning")
        }
        .alert("error_generic", isPresented: Binding(
            get: { profileVM.errorMessage != nil },
            set: { if !$0 { profileVM.errorMessage = nil } }
        )) {
            Button("button_ok") { profileVM.errorMessage = nil }
        } message: {
            Text(profileVM.errorMessage ?? "")
        }
        .sheet(isPresented: $showShareSheet) {
            if let exportFileURL {
                ShareSheet(items: [exportFileURL])
            }
        }
    }

    private func exportMyData() async {
        guard !isExporting else { return }
        isExporting = true
        defer { isExporting = false }

        do {
            if profileVM.profile == nil {
                await profileVM.loadProfile()
            }
            if profileVM.myReviews.isEmpty {
                await profileVM.loadReviews(filter: "all")
            }

            struct ExportPayload: Encodable {
                let generatedAt: String
                let profile: UserProfile?
                let reviews: [Review]
            }

            let payload = ExportPayload(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                profile: profileVM.profile,
                reviews: profileVM.myReviews
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(payload)

            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("trustcare-user-data.json")
            try data.write(to: fileURL, options: .atomic)
            exportFileURL = fileURL
            showShareSheet = true
        } catch {
            profileVM.errorMessage = error.localizedDescription
        }
    }

    private var accountSection: some View {
        Section("settings_account") {
            HStack {
                Text("settings_email")
                Spacer()
                Text(email.isEmpty ? "-" : email)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("settings_phone")
                Spacer()
                Text(phone.isEmpty ? "-" : phone)
                    .foregroundStyle(.secondary)
            }

            NavigationLink("settings_change_password") {
                ChangePasswordView(email: email)
            }
        }
    }

    private var languageSection: some View {
        Section("language_section_title") {
            NavigationLink {
                LanguageSettingsView { language in
                    Task {
                        await syncLanguagePreference(language.code)
                    }
                }
            } label: {
                HStack {
                    Text("app_language")
                    Spacer()
                    Text(currentLanguageDisplayName)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var currentLanguageDisplayName: String {
        if let current = LocalizationManager.orderedLanguages.first(where: { $0.code == localizationManager.effectiveLanguage }) {
            return current.nativeName
        }
        return localizationManager.effectiveLanguage.uppercased()
    }

    private func syncLanguagePreference(_ code: String) async {
        guard let session = try? await SupabaseManager.shared.client.auth.session else { return }
        _ = try? await SupabaseManager.shared.client
            .from("profiles")
            .update(["preferred_language": code])
            .eq("id", value: session.user.id.uuidString)
            .execute()
    }

    private var preferencesSection: some View {
        Section("settings_preferences") {
            Toggle("settings_notifications", isOn: $notificationsEnabled)
            Toggle("settings_location_services", isOn: $locationServicesEnabled)
        }
    }

    private var dataPrivacySection: some View {
        Section("settings_data_privacy") {
            Button {
                Task { await exportMyData() }
            } label: {
                if isExporting {
                    HStack(spacing: AppSpacing.sm) {
                        ProgressView()
                        Text("settings_downloading_data")
                    }
                } else {
                    Text("settings_download_data")
                }
            }
            .disabled(isExporting)

            Button("settings_delete_account", role: .destructive) {
                showDeleteConfirm = true
            }
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
