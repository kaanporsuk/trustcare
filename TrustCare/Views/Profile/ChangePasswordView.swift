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
                SecureField(String(localized: "Current Password"), text: $currentPassword)
                SecureField(String(localized: "New Password"), text: $newPassword)
                SecureField(String(localized: "Confirm New Password"), text: $confirmPassword)
            }

            Section {
                Button(String(localized: "Update Password")) {
                    Task { await updatePassword() }
                }
                .disabled(!canSubmit || isSubmitting)
            }
        }
        .navigationTitle(String(localized: "Change Password"))
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
        .alert(String(localized: "Error"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(String(localized: "Done")) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert(String(localized: "Success"), isPresented: $showSuccess) {
            Button(String(localized: "Done")) {
                dismiss()
            }
        } message: {
            Text(String(localized: "Your password has been updated."))
        }
    }

    private var canSubmit: Bool {
        !currentPassword.isEmpty
            && newPassword.count >= 8
            && newPassword == confirmPassword
    }

    private func updatePassword() async {
        guard newPassword.count >= 8 else {
            errorMessage = String(localized: "Password must be at least 8 characters.")
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = String(localized: "Passwords do not match.")
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
