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
        .confirmationDialog("Hesabı Sil", isPresented: $showDeleteConfirm) {
            Button("Hesabımı Sil", role: .destructive) {
                Task { await profileVM.deleteAccount() }
            }
            Button("Vazgeç", role: .cancel) { }
        } message: {
            Text("Bu işlem geri alınamaz")
        }
        .alert("Hata", isPresented: Binding(
            get: { profileVM.errorMessage != nil },
            set: { if !$0 { profileVM.errorMessage = nil } }
        )) {
            Button("Tamam") { profileVM.errorMessage = nil }
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
        Section("Hesap") {
            HStack {
                Text("Email")
                Spacer()
                Text(email.isEmpty ? "-" : email)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Phone")
                Spacer()
                Text(phone.isEmpty ? "-" : phone)
                    .foregroundStyle(.secondary)
            }

            NavigationLink("Şifre Değiştir") {
                ChangePasswordView(email: email)
            }
        }
    }

    private var languageSection: some View {
        Section(String(localized: "Language")) {
            ForEach(LocalizationManager.supportedLanguages) { language in
                languageRow(language)
            }
        }
    }

    private func languageRow(_ language: LocalizationManager.AppLanguage) -> some View {
        Button {
            localizationManager.currentLanguage = language.code
            Task {
                guard let session = try? await SupabaseManager.shared.client.auth.session else {
                    return
                }

                let userId = session.user.id.uuidString
                _ = try? await SupabaseManager.shared.client
                    .from("profiles")
                    .update(["preferred_language": language.code])
                    .eq("id", value: userId)
                    .execute()
            }
        } label: {
            HStack {
                Text(flag(for: language.flag))
                    .font(.title3)
                Text(language.name)
                    .foregroundStyle(.primary)
                Spacer()
                if localizationManager.currentLanguage == language.code {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppColor.trustBlue)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var preferencesSection: some View {
        Section("Tercihler") {
            Toggle("Bildirimler", isOn: $notificationsEnabled)
            Toggle("Konum Hizmetleri", isOn: $locationServicesEnabled)
        }
    }

    private var dataPrivacySection: some View {
        Section("Veri ve Gizlilik") {
            Button {
                Task { await exportMyData() }
            } label: {
                if isExporting {
                    HStack(spacing: AppSpacing.sm) {
                        ProgressView()
                        Text("Veriler hazırlanıyor")
                    }
                } else {
                    Text("Verilerimi İndir")
                }
            }
            .disabled(isExporting)

            Button("Hesabımı Sil", role: .destructive) {
                showDeleteConfirm = true
            }
        }
    }

    private func flag(for countryCode: String) -> String {
        countryCode
            .unicodeScalars
            .compactMap { Unicode.Scalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
