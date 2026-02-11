import SwiftUI
import AuthenticationServices
import CryptoKit

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var appState: AppState
    @State private var currentNonce: String?
    @State private var agreedToTerms: Bool = false
    @State private var confirmPassword: String = ""

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess { fatalError("Unable to generate nonce") }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(AppColor.trustBlue)
                        .padding(.top, AppSpacing.xxl)

                    Text(authVM.isSignUpMode ? String(localized: "Create Account") : String(localized: "Welcome Back"))
                        .font(AppFont.title1)

                    VStack(spacing: AppSpacing.md) {
                        if authVM.isSignUpMode {
                            SignUpView(
                                confirmPassword: $confirmPassword,
                                agreedToTerms: $agreedToTerms
                            )
                        } else {
                            loginFields
                        }
                    }
                    .padding(.horizontal, AppSpacing.xl)

                    Button {
                        if authVM.isSignUpMode {
                            authVM.signUp()
                        } else {
                            authVM.login()
                        }
                    } label: {
                        Text(authVM.isSignUpMode ? String(localized: "Create Account") : String(localized: "Log In"))
                            .font(AppFont.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppColor.trustBlue)
                            .cornerRadius(AppRadius.button)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .disabled(!isActionEnabled)

                    HStack {
                        Rectangle().frame(height: 1).foregroundStyle(AppColor.border)
                        Text(String(localized: "OR"))
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                        Rectangle().frame(height: 1).foregroundStyle(AppColor.border)
                    }
                    .padding(.horizontal, AppSpacing.xl)

                    SignInWithAppleButton(.signIn) { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        switch result {
                        case .success(let auth):
                            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                                  let tokenData = credential.identityToken,
                                  let idToken = String(data: tokenData, encoding: .utf8),
                                  let nonce = currentNonce else { return }
                            authVM.signInWithApple(idToken: idToken, nonce: nonce)
                        case .failure(let error):
                            authVM.errorMessage = error.localizedDescription
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(AppRadius.button)
                    .padding(.horizontal, AppSpacing.xl)

                    Button {
                        withAnimation { authVM.isSignUpMode.toggle() }
                    } label: {
                        Text(authVM.isSignUpMode ? String(localized: "Already have an account? Log In") : String(localized: "Don't have an account? Sign Up"))
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.trustBlue)
                    }
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            if authVM.isLoading {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                ProgressView(String(localized: "Loading..."))
                    .padding()
                    .background(AppColor.cardBackground)
                    .cornerRadius(AppRadius.standard)
            }
        }
        .alert(String(localized: "Error"), isPresented: Binding(
            get: { authVM.errorMessage != nil },
            set: { if !$0 { authVM.errorMessage = nil } }
        )) {
            Button(String(localized: "Done")) {
                authVM.errorMessage = nil
            }
        } message: {
            Text(authVM.errorMessage ?? "")
        }
        .onChange(of: authVM.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                appState = .main
            }
        }
    }

    private var isActionEnabled: Bool {
        if authVM.isSignUpMode {
            return authVM.isFormValid
                && !authVM.isLoading
                && agreedToTerms
                && confirmPassword == authVM.password
                && !confirmPassword.isEmpty
        }
        return authVM.isFormValid && !authVM.isLoading
    }

    private var loginFields: some View {
        VStack(spacing: AppSpacing.md) {
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
