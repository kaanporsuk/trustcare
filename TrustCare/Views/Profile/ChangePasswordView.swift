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
                SecureField(tcString("settings_current_password", fallback: "Current Password"), text: $currentPassword)
                SecureField(tcString("settings_new_password", fallback: "New Password"), text: $newPassword)
                SecureField(tcString("settings_confirm_new_password", fallback: "Confirm New Password"), text: $confirmPassword)
            }

            Section {
                Button(tcString("settings_update_password", fallback: "Update Password")) {
                    Task { await updatePassword() }
                }
                .disabled(!canSubmit || isSubmitting)
            }
        }
        .navigationTitle(tcString("settings_change_password", fallback: "Change Password"))
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
        .alert(tcString("error_generic", fallback: "Error"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(tcString("button_done", fallback: "Done")) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert(tcString("success_title", fallback: "Success"), isPresented: $showSuccess) {
            Button(tcString("button_done", fallback: "Done")) {
                dismiss()
            }
        } message: {
            Text(tcKey: "settings_password_updated_message", fallback: "Your password has been updated.")
        }
    }

    private var canSubmit: Bool {
        !currentPassword.isEmpty
            && newPassword.count >= 8
            && newPassword == confirmPassword
    }

    private func updatePassword() async {
        guard newPassword.count >= 8 else {
            errorMessage = tcString("settings_password_length_error", fallback: "Password must be at least 8 characters.")
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = tcString("settings_password_match_error", fallback: "Passwords do not match.")
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
