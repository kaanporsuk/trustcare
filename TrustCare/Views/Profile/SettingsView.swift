import Supabase
import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var selectedLanguage: String = "en"
    @State private var showDeleteDialog: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var deleteConfirmText: String = ""
    @State private var isExporting: Bool = false
    @State private var exportFileURL: URL?
    @State private var showShareSheet: Bool = false
    @State private var isLoadingConsent: Bool = false

    @AppStorage("notifyReviewUpdates") private var notifyReviewUpdates: Bool = true
    @AppStorage("notifyVerificationStatus") private var notifyVerificationStatus: Bool = true
    @AppStorage("notifyNewProvidersNearby") private var notifyNewProvidersNearby: Bool = false

    @AppStorage("analyticsConsentGranted") private var analyticsConsentGranted: Bool = false
    @AppStorage("marketingConsentGranted") private var marketingConsentGranted: Bool = false
    @AppStorage("consentDataProcessing") private var consentDataProcessing: Bool = true
    @AppStorage("consentAIVerification") private var consentAIVerification: Bool = true

    @AppStorage("colorScheme") private var colorSchemePreference: String = "system"

    private let languages: [(code: String, name: String)] = [
        ("en", "English"),
        ("de", "Deutsch"),
        ("nl", "Nederlands"),
        ("pl", "Polski"),
        ("tr", "Turkce"),
        ("ar", "العربية")
    ]

    var body: some View {
        Form {
            Section(String(localized: "Account")) {
                HStack {
                    Text(String(localized: "Email"))
                    Spacer()
                    Text(email)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text(String(localized: "Phone"))
                    Spacer()
                    Text(phone.isEmpty ? "-" : phone)
                        .foregroundStyle(.secondary)
                }

                NavigationLink(String(localized: "Change Password")) {
                    ChangePasswordView(email: email)
                }

                Button(String(localized: "Sign Out"), role: .destructive) {
                    authVM.signOut()
                }
            }

            Section(String(localized: "Notifications")) {
                Toggle(String(localized: "Review Updates"), isOn: $notifyReviewUpdates)
                Toggle(String(localized: "Verification Status"), isOn: $notifyVerificationStatus)
                Toggle(String(localized: "New Providers Nearby"), isOn: $notifyNewProvidersNearby)
            }

            Section(String(localized: "Preferences")) {
                Picker(String(localized: "Language"), selection: $selectedLanguage) {
                    ForEach(languages, id: \.code) { language in
                        Text("\(language.name)")
                            .tag(language.code)
                    }
                }
                .onChange(of: selectedLanguage) { _, newValue in
                    localizationManager.appLanguage = newValue
                    Task { await profileVM.updateLanguage(newValue) }
                }

                Picker(String(localized: "Theme"), selection: $colorSchemePreference) {
                    Text(String(localized: "System")).tag("system")
                    Text(String(localized: "Light")).tag("light")
                    Text(String(localized: "Dark")).tag("dark")
                }
            }

            Section(String(localized: "Privacy & Consent")) {
                Toggle(String(localized: "Analytics Tracking"), isOn: $analyticsConsentGranted)
                    .onChange(of: analyticsConsentGranted) { _, newValue in
                        guard !isLoadingConsent else { return }
                        Task { await updateConsent(type: "analytics_tracking", granted: newValue) }
                    }

                Toggle(String(localized: "Marketing Communications"), isOn: $marketingConsentGranted)
                    .onChange(of: marketingConsentGranted) { _, newValue in
                        guard !isLoadingConsent else { return }
                        Task { await updateConsent(type: "marketing_communications", granted: newValue) }
                    }

                Toggle(String(localized: "Review data processing"), isOn: $consentDataProcessing)
                    .onChange(of: consentDataProcessing) { _, newValue in
                        guard !isLoadingConsent else { return }
                        Task { await updateConsent(type: "review_data_processing", granted: newValue) }
                    }

                Toggle(String(localized: "AI verification consent"), isOn: $consentAIVerification)
                    .onChange(of: consentAIVerification) { _, newValue in
                        guard !isLoadingConsent else { return }
                        Task { await updateConsent(type: "ai_verification_consent", granted: newValue) }
                    }

                Link(String(localized: "Terms of Service"), destination: URL(string: "https://trustcare.app/terms")!)
                Link(String(localized: "Privacy Policy"), destination: URL(string: "https://trustcare.app/privacy")!)
            }

            Section(String(localized: "Data Export")) {
                Button {
                    Task { await exportUserData() }
                } label: {
                    if isExporting {
                        HStack(spacing: AppSpacing.sm) {
                            ProgressView()
                            Text(String(localized: "Preparing export"))
                        }
                    } else {
                        Text(String(localized: "Download My Data"))
                    }
                }
                .disabled(isExporting)
            }

            Section(String(localized: "About")) {
                HStack {
                    Text(String(localized: "Version"))
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }

                Link(String(localized: "Rate App"), destination: URL(string: "https://example.com/app-store")!)
            }

            Section {
                Button(String(localized: "Delete Account"), role: .destructive) {
                    showDeleteDialog = true
                }
            } header: {
                Text(String(localized: "Danger Zone"))
                    .foregroundStyle(AppColor.error)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissKeyboardOnTap()
        .keyboardDoneToolbar()
        .navigationTitle(String(localized: "Settings"))
        .toolbar(.hidden, for: .tabBar)
        .confirmationDialog(String(localized: "Delete Account"), isPresented: $showDeleteDialog) {
            Button(String(localized: "Continue"), role: .destructive) {
                showDeleteConfirm = true
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "This action cannot be undone."))
        }
        .alert(String(localized: "Type DELETE to confirm"), isPresented: $showDeleteConfirm) {
            TextField(String(localized: "Type DELETE to confirm"), text: $deleteConfirmText)
            Button(String(localized: "Delete Account"), role: .destructive) {
                guard deleteConfirmText == "DELETE" else { return }
                Task { await profileVM.deleteAccount() }
            }
            Button(String(localized: "Cancel"), role: .cancel) {
                deleteConfirmText = ""
            }
        }
        .task {
            if profileVM.profile == nil {
                await profileVM.loadProfile()
            }
            if let profile = profileVM.profile {
                phone = profile.phone ?? ""
                selectedLanguage = profile.preferredLanguage
            }

            if email.isEmpty {
                email = await AuthService.currentUserEmail() ?? ""
            }

            await loadConsentState()
        }
        .alert(String(localized: "Error"), isPresented: Binding(
            get: { profileVM.errorMessage != nil },
            set: { if !$0 { profileVM.errorMessage = nil } }
        )) {
            Button(String(localized: "Done")) {
                profileVM.errorMessage = nil
            }
        } message: {
            Text(profileVM.errorMessage ?? "")
        }
        .sheet(isPresented: $showShareSheet) {
            if let exportFileURL {
                ShareSheet(items: [exportFileURL])
            }
        }
    }

    private func loadConsentState() async {
        isLoadingConsent = true
        defer { isLoadingConsent = false }
        do {
            let session = try await SupabaseManager.shared.client.auth.session

            struct ConsentRow: Decodable {
                let consentType: String
                let granted: Bool

                enum CodingKeys: String, CodingKey {
                    case consentType = "consent_type"
                    case granted
                }
            }

            let response: PostgrestResponse<[ConsentRow]> = try await SupabaseManager.shared.client
                .from("consent_records")
                .select("consent_type, granted")
                .eq("user_id", value: session.user.id.uuidString)
                .eq("version", value: "1.0")
                .execute()

            for record in response.value {
                switch record.consentType {
                case "analytics_tracking":
                    analyticsConsentGranted = record.granted
                case "marketing_communications":
                    marketingConsentGranted = record.granted
                case "review_data_processing":
                    consentDataProcessing = record.granted
                case "ai_verification_consent":
                    consentAIVerification = record.granted
                default:
                    break
                }
            }
        } catch {
            profileVM.errorMessage = localizedErrorMessage(error)
        }
    }

    private func updateConsent(type: String, granted: Bool) async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session

            struct ConsentPayload: Encodable {
                let userId: String
                let consentType: String
                let version: String
                let granted: Bool
                let grantedAt: String

                enum CodingKeys: String, CodingKey {
                    case userId = "user_id"
                    case consentType = "consent_type"
                    case version
                    case granted
                    case grantedAt = "granted_at"
                }
            }

            let now = ISO8601DateFormatter().string(from: Date())
            let payload = ConsentPayload(
                userId: session.user.id.uuidString,
                consentType: type,
                version: "1.0",
                granted: granted,
                grantedAt: now
            )

            _ = try await SupabaseManager.shared.client
                .from("consent_records")
                .upsert(payload, onConflict: "user_id,consent_type,version")
                .execute()
        } catch {
            profileVM.errorMessage = localizedErrorMessage(error)
        }
    }

    private func exportUserData() async {
        guard !isExporting else { return }
        isExporting = true
        defer { isExporting = false }

        do {
            let session = try await SupabaseManager.shared.client.auth.session
            guard let url = URL(string: "\(SupabaseConfig.url)/functions/v1/export-user-data") else {
                throw AppError.validationError(String(localized: "Export endpoint is unavailable."))
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [:], options: [])

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                throw AppError.networkError(String(localized: "Unable to export your data."))
            }

            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("trustcare-export.json")
            try data.write(to: fileURL, options: .atomic)
            exportFileURL = fileURL
            showShareSheet = true
        } catch {
            profileVM.errorMessage = localizedErrorMessage(error)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func localizedErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }

        let message = error.localizedDescription.lowercased()
        if message.contains("network") || message.contains("offline") {
            return String(localized: "Network error. Please check your connection.")
        }
        if message.contains("expired") || message.contains("token") {
            return String(localized: "Your session expired. Please sign in again.")
        }
        return String(localized: "Something went wrong. Please try again.")
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
