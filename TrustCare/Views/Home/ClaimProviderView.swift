import PhotosUI
import SwiftUI

struct ClaimProviderView: View {
    let providerId: UUID
    let providerName: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var claimVM = ClaimViewModel()
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(String(localized: "Claim This Practice"))
                        .font(AppFont.title2)
                }

                Section {
                    Picker(String(localized: "Role"), selection: $claimVM.role) {
                        ForEach(ClaimRole.allCases) { item in
                            Text(item.displayName).tag(item)
                        }
                    }

                    TextField(String(localized: "Business Email"), text: $claimVM.businessEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField(String(localized: "Phone"), text: $claimVM.phone)
                        .keyboardType(.phonePad)

                    TextField(String(localized: "License Number"), text: $claimVM.licenseNumber)
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
                        Task { await claimVM.submit(providerId: providerId) }
                    } label: {
                        Text(String(localized: "Submit Claim"))
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(claimVM.isLoading || !claimVM.isFormValid)
                }
            }
            .navigationTitle(providerName)
            .overlay {
                if claimVM.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    do {
                        if let data = try await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            claimVM.proofImage = image
                        }
                    } catch {
                        claimVM.errorMessage = String(localized: "Unable to upload media. Please try again.")
                    }
                }
            }
            .alert(String(localized: "Error"), isPresented: Binding(
                get: { claimVM.errorMessage != nil },
                set: { if !$0 { claimVM.errorMessage = nil } }
            )) {
                Button(String(localized: "Done")) { claimVM.errorMessage = nil }
            } message: {
                Text(claimVM.errorMessage ?? "")
            }
            .alert(String(localized: "Claim submitted"), isPresented: $claimVM.isSubmitted) {
                Button(String(localized: "Done")) {
                    claimVM.reset()
                    dismiss()
                }
            }
        }
    }
}
