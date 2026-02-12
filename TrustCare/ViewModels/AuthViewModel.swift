import Combine
import Foundation
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var fullName: String = ""
    @Published var referralCode: String = ""
    @Published var dateOfBirth: Date?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isAuthenticated: Bool = false
    @Published var isSignUpMode: Bool = false

    private var authListenerTask: Task<Void, Never>?

    var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    var isPasswordValid: Bool {
        password.count >= 8
    }

    var isAgeValid: Bool {
        guard let dateOfBirth else { return true }
        let calendar = Calendar.current
        guard let minDate = calendar.date(byAdding: .year, value: -16, to: Date()) else {
            return false
        }
        return dateOfBirth <= minDate
    }

    var isFormValid: Bool {
        if isSignUpMode {
            return isEmailValid
                && isPasswordValid
                && !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && isAgeValid
        }
        return isEmailValid && isPasswordValid
    }

    init() {
        Task {
            let session = await AuthService.currentSession()
            isAuthenticated = session != nil
        }

        let client = SupabaseManager.shared.client
        authListenerTask = Task {
            for await (event, session) in client.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .signedIn, .tokenRefreshed:
                        isAuthenticated = session != nil
                    case .signedOut, .userDeleted:
                        isAuthenticated = false
                    default:
                        break
                    }
                }
            }
        }
    }

    deinit {
        authListenerTask?.cancel()
    }

    func login() {
        Task {
            await performLogin()
        }
    }

    func signUp() {
        Task {
            await performSignUp()
        }
    }

    func signInWithApple(idToken: String, nonce: String) {
        Task {
            await performAppleSignIn(idToken: idToken, nonce: nonce)
        }
    }

    func signOut() {
        Task {
            await performSignOut()
        }
    }

    private func performLogin() async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        do {
            try await AuthService.signIn(email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
        isLoading = false
    }

    private func performSignUp() async {
        guard !isLoading else { return }
        errorMessage = nil
        successMessage = nil
        isLoading = true
        do {
            let referral = referralCode.trimmingCharacters(in: .whitespacesAndNewlines)
            try await AuthService.signUp(
                email: email,
                password: password,
                fullName: fullName,
                referralCode: referral.isEmpty ? nil : referral
            )
            
            // Check if we have an active session (email confirmation disabled)
            let session = await AuthService.currentSession()
            if session != nil {
                isAuthenticated = true
            } else {
                // Email confirmation required
                successMessage = String(localized: "Account created! Please check your email to confirm your account.")
                isSignUpMode = false // Switch back to login mode
            }
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
        isLoading = false
    }

    private func performAppleSignIn(idToken: String, nonce: String) async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        do {
            try await AuthService.signInWithApple(idToken: idToken, nonce: nonce)
            isAuthenticated = true
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
        isLoading = false
    }

    private func performSignOut() async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        do {
            try await AuthService.signOut()
            isAuthenticated = false
        } catch {
            errorMessage = localizedErrorMessage(error)
        }
        isLoading = false
    }

    private func localizedErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }

        let message = error.localizedDescription.lowercased()
        if message.contains("invalid login") || message.contains("invalid credentials") {
            return String(localized: "Invalid email or password.")
        }
        if message.contains("already registered") || message.contains("already in use") {
            return String(localized: "This email is already registered.")
        }
        if message.contains("email_address_invalid") || message.contains("invalid email") {
            return String(localized: "Email address is invalid. Please use a valid email.")
        }
        if message.contains("network") || message.contains("offline") {
            return String(localized: "Network error. Please check your connection.")
        }
        
        // For debugging: show the actual error in development
        #if DEBUG
        print("Auth Error: \(error.localizedDescription)")
        return "Error: \(error.localizedDescription)"
        #else
        return String(localized: "Unable to complete your request. Please try again.")
        #endif
    }
}
