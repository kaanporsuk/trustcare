import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss

    let email: String

    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?
    @State private var showSuccess: Bool = false

    var body: some View {
        Form {
            Section {
                SecureField("Current Password", text: $currentPassword)
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm New Password", text: $confirmPassword)
            }

            Section {
                Button("Update Password") {
                    Task { await updatePassword() }
                }
                .disabled(!canSubmit || isSubmitting)
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .dismissKeyboardOnTap()
        .keyboardDoneToolbar()
        .overlay {
            if isSubmitting {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Done") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Your password has been updated.")
        }
    }

    private var canSubmit: Bool {
        !currentPassword.isEmpty
            && newPassword.count >= 8
            && newPassword == confirmPassword
    }

    private func updatePassword() async {
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isSubmitting = true
        errorMessage = nil
        do {
            try await AuthService.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
