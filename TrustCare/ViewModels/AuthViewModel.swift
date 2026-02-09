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
			return isEmailValid && isPasswordValid && !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isAgeValid
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
			for await change in client.auth.onAuthStateChange {
				switch change.event {
				case .signedIn, .tokenRefreshed:
					isAuthenticated = change.session != nil
				case .signedOut, .userDeleted:
					isAuthenticated = false
				default:
					break
				}
			}
		}
	}

	deinit {
		authListenerTask?.cancel()
	}

	func login() async {
		guard !isLoading else { return }
		errorMessage = nil
		isLoading = true
		do {
			try await AuthService.signIn(email: email, password: password)
			isAuthenticated = true
		} catch {
			errorMessage = error.localizedDescription
		}
		isLoading = false
	}

	func signUp() async {
		guard !isLoading else { return }
		errorMessage = nil
		isLoading = true
		do {
			let referral = referralCode.trimmingCharacters(in: .whitespacesAndNewlines)
			try await AuthService.signUp(
				email: email,
				password: password,
				fullName: fullName,
				referralCode: referral.isEmpty ? nil : referral
			)
			isAuthenticated = true
		} catch {
			errorMessage = error.localizedDescription
		}
		isLoading = false
	}

	func signInWithApple(idToken: String, nonce: String) async {
		guard !isLoading else { return }
		errorMessage = nil
		isLoading = true
		do {
			try await AuthService.signInWithApple(idToken: idToken, nonce: nonce)
			isAuthenticated = true
		} catch {
			errorMessage = error.localizedDescription
		}
		isLoading = false
	}

	func signOut() async {
		guard !isLoading else { return }
		errorMessage = nil
		isLoading = true
		do {
			try await AuthService.signOut()
			isAuthenticated = false
		} catch {
			errorMessage = error.localizedDescription
		}
		isLoading = false
	}
}
