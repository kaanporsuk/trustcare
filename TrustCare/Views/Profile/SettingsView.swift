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
    @State private var pendingLanguageCode: String?
    @State private var showLanguageConfirmation: Bool = false

    @AppStorage("settings_notifications_enabled") private var notificationsEnabled: Bool = true
    @AppStorage("settings_location_services_enabled") private var locationServicesEnabled: Bool = true

    var body: some View {
        Form {
            accountSection
            languageSection
            preferencesSection
            dataPrivacySection
        }
        .navigationTitle(String(localized: "menu_settings"))
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
        .confirmationDialog(String(localized: "settings_delete_account"), isPresented: $showDeleteConfirm) {
            Button(String(localized: "settings_delete_account_confirm"), role: .destructive) {
                Task { await profileVM.deleteAccount() }
            }
            Button(String(localized: "settings_cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "settings_delete_account_warning"))
        }
        .alert(String(localized: "error_generic"), isPresented: Binding(
            get: { profileVM.errorMessage != nil },
            set: { if !$0 { profileVM.errorMessage = nil } }
        )) {
            Button(String(localized: "button_ok")) { profileVM.errorMessage = nil }
        } message: {
            Text(profileVM.errorMessage ?? "")
        }
        .alert(String(localized: "language_changed_alert"), isPresented: $showLanguageConfirmation) {
            Button(String(localized: "language_restart_now"), role: .destructive) {
                if let code = pendingLanguageCode {
                    // 1. Apply the language change
                    localizationManager.changeLanguage(to: code)

                    // 2. Update Supabase profile (fire and forget)
                    Task {
                        guard let session = try? await SupabaseManager.shared.client.auth.session else {
                            return
                        }
                        let userId = session.user.id.uuidString
                        _ = try? await SupabaseManager.shared.client
                            .from("profiles")
                            .update(["preferred_language": code])
                            .eq("id", value: userId)
                            .execute()
                    }

                    // 3. Force quit — iOS will relaunch with new language
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        exit(0)
                    }
                }
            }
            Button(String(localized: "language_later"), role: .cancel) {
                pendingLanguageCode = nil
            }
        } message: {
            if let code = pendingLanguageCode,
               let langName = LocalizationManager.supportedLanguages.first(where: { $0.code == code })?.name {
                Text(String(localized: "language_changed_message_named \(langName)"))
            } else {
                Text(String(localized: "language_changed_message"))
            }
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
        Section(String(localized: "settings_account")) {
            HStack {
                Text(String(localized: "settings_email"))
                Spacer()
                Text(email.isEmpty ? "-" : email)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(String(localized: "settings_phone"))
                Spacer()
                Text(phone.isEmpty ? "-" : phone)
                    .foregroundStyle(.secondary)
            }

            NavigationLink(String(localized: "settings_change_password")) {
                ChangePasswordView(email: email)
            }
        }
    }

    private var languageSection: some View {
        Section(String(localized: "language_section_title")) {
            ForEach(LocalizationManager.supportedLanguages) { language in
                languageRow(language)
            }
        }
    }

    private func languageRow(_ language: LocalizationManager.AppLanguage) -> some View {
        Button {
            if localizationManager.effectiveLanguage != language.code {
                pendingLanguageCode = language.code
                showLanguageConfirmation = true
            }
        } label: {
            HStack(spacing: 12) {
                Text(language.flag)
                    .font(.title3)
                Text(language.name)
                    .foregroundStyle(.primary)
                Spacer()
                if localizationManager.effectiveLanguage == language.code {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppColor.trustBlue)
                        .fontWeight(.semibold)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var preferencesSection: some View {
        Section(String(localized: "settings_preferences")) {
            Toggle(String(localized: "settings_notifications"), isOn: $notificationsEnabled)
            Toggle(String(localized: "settings_location_services"), isOn: $locationServicesEnabled)
        }
    }

    private var dataPrivacySection: some View {
        Section(String(localized: "settings_data_privacy")) {
            Button {
                Task { await exportMyData() }
            } label: {
                if isExporting {
                    HStack(spacing: AppSpacing.sm) {
                        ProgressView()
                        Text(String(localized: "settings_downloading_data"))
                    }
                } else {
                    Text(String(localized: "settings_download_data"))
                }
            }
            .disabled(isExporting)

            Button(String(localized: "settings_delete_account"), role: .destructive) {
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
