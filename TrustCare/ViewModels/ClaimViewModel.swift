import Combine
import Foundation
import UIKit

@MainActor
final class ClaimViewModel: ObservableObject {
	@Published var role: ClaimRole = .owner
	@Published var businessEmail: String = ""
	@Published var phone: String = ""
	@Published var licenseNumber: String = ""
	@Published var proofImage: UIImage?
	@Published var isLoading: Bool = false
	@Published var errorMessage: String?
	@Published var isSubmitted: Bool = false

	var isFormValid: Bool {
		let trimmedEmail = businessEmail.trimmingCharacters(in: .whitespacesAndNewlines)
		return trimmedEmail.contains("@") && trimmedEmail.contains(".")
	}

	func submit(providerId: UUID) async {
		guard !isLoading else { return }
		guard isFormValid else {
			errorMessage = String(localized: "Please enter a valid email address.")
			return
		}

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
			isSubmitted = true
		} catch {
			errorMessage = localizedErrorMessage(error)
		}

		isLoading = false
	}

	func reset() {
		role = .owner
		businessEmail = ""
		phone = ""
		licenseNumber = ""
		proofImage = nil
		errorMessage = nil
		isSubmitted = false
	}

	private func localizedErrorMessage(_ error: Error) -> String {
		if let appError = error as? AppError {
			return appError.localizedDescription
		}

		let message = error.localizedDescription.lowercased()
		if message.contains("network") || message.contains("offline") {
			return String(localized: "Network error. Please check your connection.")
		}
		if message.contains("duplicate") || message.contains("already") {
			return String(localized: "A claim already exists for this provider.")
		}
		return String(localized: "Unable to submit claim. Please try again.")
	}
}
