import SwiftUI
import UIKit
import Supabase

struct SettingsView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var showDeleteConfirm: Bool = false
    @State private var isExporting: Bool = false
    @State private var exportFileURL: URL?
    @State private var showShareSheet: Bool = false
    @State private var showLanguagePicker: Bool = false

    @AppStorage("settings_notifications_enabled") private var notificationsEnabled: Bool = true
    @AppStorage("settings_location_services_enabled") private var locationServicesEnabled: Bool = true

    var body: some View {
        Form {
            accountSection
            languageSection
            preferencesSection
            dataPrivacySection
        }
        .navigationTitle(Text(tcKey: "menu_settings", fallback: "Settings"))
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
        .confirmationDialog(tcString("settings_delete_account", fallback: "Delete account"), isPresented: $showDeleteConfirm) {
            Button(tcString("settings_delete_account_confirm", fallback: "Delete account"), role: .destructive) {
                Task { await profileVM.deleteAccount() }
            }
            Button(tcString("settings_cancel", fallback: "Cancel"), role: .cancel) { }
        } message: {
            Text(tcKey: "settings_delete_account_warning", fallback: "This action cannot be undone.")
        }
        .alert(tcString("error_generic", fallback: "Error"), isPresented: Binding(
            get: { profileVM.errorMessage != nil },
            set: { if !$0 { profileVM.errorMessage = nil } }
        )) {
            Button(tcString("button_ok", fallback: "OK")) { profileVM.errorMessage = nil }
        } message: {
            Text(profileVM.errorMessage ?? "")
        }
        .sheet(isPresented: $showShareSheet) {
            if let exportFileURL {
                ShareSheet(items: [exportFileURL])
            }
        }
        .sheet(isPresented: Binding(
            get: { showLanguagePicker && horizontalSizeClass != .regular },
            set: { showLanguagePicker = $0 }
        )) {
            NavigationStack {
                LanguageSettingsView { language in
                    Task {
                        await syncLanguagePreference(language.code)
                    }
                }
                .onAppear {
                    debugLog("Opened LanguageSettingsView")
                }
            }
        }
        .popover(isPresented: Binding(
            get: { showLanguagePicker && horizontalSizeClass == .regular },
            set: { showLanguagePicker = $0 }
        )) {
            NavigationStack {
                LanguageSettingsView { language in
                    Task {
                        await syncLanguagePreference(language.code)
                    }
                }
            }
            .frame(minWidth: 420, minHeight: 520)
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
        Section(tcString("settings_account", fallback: "Account")) {
            HStack {
                Text(tcKey: "settings_email", fallback: "Email")
                Spacer()
                Text(email.isEmpty ? "-" : email)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(tcKey: "settings_phone", fallback: "Phone")
                Spacer()
                Text(phone.isEmpty ? "-" : phone)
                    .foregroundStyle(.secondary)
            }

            NavigationLink(tcString("settings_change_password", fallback: "Change password")) {
                ChangePasswordView(email: email)
            }
        }
    }

    private var languageSection: some View {
        Section(tcString("language_section_title", fallback: "Language")) {
            Button {
                debugLog("Language row tapped")
                showLanguagePicker = true
            } label: {
                HStack {
                    Text(tcKey: "app_language", fallback: "App Language")
                    Spacer()
                    Text(currentLanguageDisplayName)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.languageRow")
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

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[SettingsView] \(message)")
        #endif
    }

    private var preferencesSection: some View {
        Section(tcString("settings_preferences", fallback: "Preferences")) {
            Toggle(tcString("settings_notifications", fallback: "Notifications"), isOn: $notificationsEnabled)
            Toggle(tcString("settings_location_services", fallback: "Location services"), isOn: $locationServicesEnabled)
        }
    }

    private var dataPrivacySection: some View {
        Section(tcString("settings_data_privacy", fallback: "Data & Privacy")) {
            Button {
                Task { await exportMyData() }
            } label: {
                if isExporting {
                    HStack(spacing: AppSpacing.sm) {
                        ProgressView()
                        Text(tcKey: "settings_downloading_data", fallback: "Preparing your data...")
                    }
                } else {
                    Text(tcKey: "settings_download_data", fallback: "Download my data")
                }
            }
            .disabled(isExporting)

            Button(tcString("settings_delete_account", fallback: "Delete account"), role: .destructive) {
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
