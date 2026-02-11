import PhotosUI
import SwiftUI

struct ClaimProviderView: View {
    let providerId: UUID
    let providerName: String
    @Environment(\.dismiss) private var dismiss
    @State private var role: ClaimRole = .owner
    @State private var businessEmail: String = ""
    @State private var phone: String = ""
    @State private var licenseNumber: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var proofImage: UIImage?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showSuccess: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(String(localized: "Claim This Practice"))
                        .font(AppFont.title2)
                }

                Section {
                    Picker(String(localized: "Role"), selection: $role) {
                        ForEach(ClaimRole.allCases) { item in
                            Text(item.displayName).tag(item)
                        }
                    }

                    TextField(String(localized: "Business Email"), text: $businessEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField(String(localized: "Phone"), text: $phone)
                        .keyboardType(.phonePad)

                    TextField(String(localized: "License Number"), text: $licenseNumber)
                }

                Section {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "doc")
                            Text(String(localized: "Upload Proof"))
                        }
                    }
                }

                Section {
                    Button {
                        Task { await submitClaim() }
                    } label: {
                        Text(String(localized: "Submit Claim"))
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading || businessEmail.isEmpty)
                }
            }
            .navigationTitle(providerName)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        proofImage = image
                    }
                }
            }
            .alert(String(localized: "Error"), isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(String(localized: "Done")) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert(String(localized: "Claim submitted"), isPresented: $showSuccess) {
                Button(String(localized: "Done")) {
                    dismiss()
                }
            }
        }
    }

    private func submitClaim() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await ClaimService.submitClaim(
                providerId: providerId,
                role: role,
                email: businessEmail,
                phone: phone.isEmpty ? nil : phone,
                license: licenseNumber.isEmpty ? nil : licenseNumber,
                proofImage: proofImage
            )
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
