import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel
    @EnvironmentObject private var localizationManager: LocalizationManager

    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var selectedLanguage: String = "en"
    @State private var selectedRegion: String = "US"
    @State private var selectedCurrency: String = "USD"
    @State private var showDeleteDialog: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var deleteConfirmText: String = ""

    @AppStorage("colorScheme") private var colorSchemePreference: String = "system"

    private let languages = LocalizationManager.supportedLanguages
    private let regions: [(code: String, currency: String)] = [
        ("US", "USD"),
        ("GB", "GBP"),
        ("DE", "EUR"),
        ("NL", "EUR"),
        ("PL", "PLN"),
        ("TR", "TRY")
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

                TextField(String(localized: "Phone"), text: $phone)
                    .keyboardType(.phonePad)
                    .onChange(of: phone) { _, newValue in
                        Task { await profileVM.updatePhone(newValue.isEmpty ? nil : newValue) }
                    }

                Button(String(localized: "Change Password")) {
                    Task {
                        if !email.isEmpty {
                            try? await AuthService.resetPassword(email: email)
                        }
                    }
                }
            }

            Section(String(localized: "Language")) {
                Picker(String(localized: "Language"), selection: $selectedLanguage) {
                    ForEach(languages, id: \.code) { language in
                        Text("\(language.name) (\(language.code.uppercased()))")
                            .tag(language.code)
                    }
                }
                .onChange(of: selectedLanguage) { _, newValue in
                    localizationManager.appLanguage = newValue
                    Task { await profileVM.updateLanguage(newValue) }
                }

                Text(String(localized: "App will restart to apply language change"))
                    .font(AppFont.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(String(localized: "Region")) {
                Picker(String(localized: "Country"), selection: $selectedRegion) {
                    ForEach(regions, id: \.code) { region in
                        Text(region.code).tag(region.code)
                    }
                }
                .onChange(of: selectedRegion) { _, newValue in
                    if let region = regions.first(where: { $0.code == newValue }) {
                        selectedCurrency = region.currency
                        Task { await profileVM.updateRegion(countryCode: region.code, currency: region.currency) }
                    }
                }
            }

            Section(String(localized: "Appearance")) {
                Picker(String(localized: "Appearance"), selection: $colorSchemePreference) {
                    Text(String(localized: "System")).tag("system")
                    Text(String(localized: "Light")).tag("light")
                    Text(String(localized: "Dark")).tag("dark")
                }
            }

            Section(String(localized: "About")) {
                HStack {
                    Text(String(localized: "Version"))
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                Link(String(localized: "Terms of Service"), destination: URL(string: "https://trustcare.app/terms")!)
                Link(String(localized: "Privacy Policy"), destination: URL(string: "https://trustcare.app/privacy")!)
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
        .navigationTitle(String(localized: "Settings"))
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
                selectedRegion = profile.countryCode
                selectedCurrency = profile.preferredCurrency
            }

            if email.isEmpty {
                email = await AuthService.currentUserEmail() ?? ""
            }
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
    }
}
