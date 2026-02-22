import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel
    @EnvironmentObject private var localizationManager: LocalizationManager

    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var showDeleteConfirm: Bool = false
    @State private var isExporting: Bool = false
    @State private var exportFileURL: URL?
    @State private var showShareSheet: Bool = false

    @AppStorage("appLanguage") private var appLanguage: String = "tr"
    @AppStorage("settings_notifications_enabled") private var notificationsEnabled: Bool = true
    @AppStorage("settings_location_services_enabled") private var locationServicesEnabled: Bool = true

    private let languages: [(code: String, name: String)] = [
        ("tr", "Türkçe"),
        ("en", "English"),
        ("de", "Deutsch"),
        ("nl", "Nederlands"),
        ("pl", "Polski"),
        ("ar", "العربية")
    ]

    var body: some View {
        Form {
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

            Section("Tercihler") {
                Picker("Dil", selection: $appLanguage) {
                    ForEach(languages, id: \.code) { language in
                        Text(language.name).tag(language.code)
                    }
                }
                .onChange(of: appLanguage) { _, newValue in
                    localizationManager.appLanguage = newValue
                    Task { await profileVM.updateLanguage(newValue) }
                }

                Toggle("Bildirimler", isOn: $notificationsEnabled)
                Toggle("Konum Hizmetleri", isOn: $locationServicesEnabled)
            }

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
        .navigationTitle("Ayarlar")
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
            if appLanguage != localizationManager.appLanguage {
                localizationManager.appLanguage = appLanguage
            }
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
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
