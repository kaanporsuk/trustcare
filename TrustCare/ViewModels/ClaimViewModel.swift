import Combine
import Foundation
import UIKit

@MainActor
final class ClaimViewModel: ObservableObject {
	@Published var role: ClaimRole = .owner
	@Published var proofImage: UIImage?
	@Published var isLoading: Bool = false
	@Published var errorMessage: String?
	@Published var isSubmitted: Bool = false

	var isFormValid: Bool {
		proofImage != nil
	}

	func submit(providerId: UUID) async {
		guard !isLoading else { return }
		guard isFormValid else {
			errorMessage = String(localized: "Please upload a verification document.")
			return
		}

		isLoading = true
		errorMessage = nil

		do {
			try await ClaimService.submitClaim(
				providerId: providerId,
				role: role,
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
