import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var confirmPassword: String
    @Binding var agreedToTerms: Bool

    var isConfirmValid: Bool {
        !confirmPassword.isEmpty && confirmPassword == authVM.password
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            labeledField(
                icon: "person",
                placeholder: String(localized: "Full Name"),
                text: $authVM.fullName,
                isValid: !authVM.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )

            labeledField(
                icon: "envelope",
                placeholder: String(localized: "Email"),
                text: $authVM.email,
                isValid: authVM.isEmailValid || authVM.email.isEmpty,
                keyboard: .emailAddress
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            labeledSecureField(
                icon: "lock",
                placeholder: String(localized: "Password"),
                text: $authVM.password,
                isValid: authVM.isPasswordValid || authVM.password.isEmpty
            )

            labeledSecureField(
                icon: "lock.fill",
                placeholder: String(localized: "Confirm Password"),
                text: $confirmPassword,
                isValid: isConfirmValid || confirmPassword.isEmpty
            )

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(String(localized: "Date of Birth"))
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                DatePicker(
                    "",
                    selection: Binding(
                        get: { authVM.dateOfBirth ?? Date() },
                        set: { authVM.dateOfBirth = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(AppSpacing.sm)
                .background(AppColor.cardBackground)
                .cornerRadius(AppRadius.standard)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.standard)
                        .stroke(authVM.isAgeValid ? AppColor.border : AppColor.error, lineWidth: 1)
                )
            }

            labeledField(
                icon: "tag",
                placeholder: String(localized: "Referral Code"),
                text: $authVM.referralCode,
                isValid: true
            )

            Toggle(isOn: $agreedToTerms) {
                Text(String(localized: "I agree to Terms & Privacy"))
                    .font(AppFont.caption)
            }
        }
    }

    private func labeledField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isValid: Bool,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.standard)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.standard)
                .stroke(isValid ? AppColor.border : AppColor.error, lineWidth: 1)
        )
    }

    private func labeledSecureField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isValid: Bool
    ) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            SecureField(placeholder, text: text)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.standard)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.standard)
                .stroke(isValid ? AppColor.border : AppColor.error, lineWidth: 1)
        )
    }
}
