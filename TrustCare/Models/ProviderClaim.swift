import Foundation

struct ProviderClaim: Identifiable, Codable {
    let id: UUID
    let providerId: UUID
    let claimantUserId: UUID
    let claimantRole: ClaimRole
    let businessEmail: String
    let phone: String?
    let licenseNumber: String?
    let proofDocumentUrl: String?
    let status: ClaimStatus
    let rejectionReason: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, phone, status
        case providerId = "provider_id"
        case claimantUserId = "claimant_user_id"
        case claimantRole = "claimant_role"
        case businessEmail = "business_email"
        case licenseNumber = "license_number"
        case proofDocumentUrl = "proof_document_url"
        case rejectionReason = "rejection_reason"
        case createdAt = "created_at"
    }
}
