import Foundation
import Supabase
import UIKit

enum ClaimService {
    private static var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    static func submitClaim(
        providerId: UUID,
        role: ClaimRole,
        email: String,
        phone: String?,
        license: String?,
        proofImage: UIImage?
    ) async throws {
        let session = try await client.auth.session

        var proofPath: String?
        if let proofImage {
            guard let compressedData = ImageService.compressImage(
                proofImage,
                maxSizeKB: 1024,
                quality: 0.7
            ) else {
                throw AppError.uploadFailed
            }

            let fileName = "\(UUID().uuidString).jpg"
            let path = "\(session.user.id.uuidString)/\(fileName)"
            let options = FileOptions(contentType: "image/jpeg")
            let upload = try await client
                .storage
                .from("claim-documents")
                .upload(path, data: compressedData, options: options)
            proofPath = upload.path
        }

        struct ClaimInsert: Encodable {
            let providerId: String
            let claimantUserId: String
            let claimantRole: String
            let businessEmail: String
            let phone: String?
            let licenseNumber: String?
            let proofDocumentUrl: String?

            enum CodingKeys: String, CodingKey {
                case providerId = "provider_id"
                case claimantUserId = "claimant_user_id"
                case claimantRole = "claimant_role"
                case businessEmail = "business_email"
                case phone
                case licenseNumber = "license_number"
                case proofDocumentUrl = "proof_document_url"
            }
        }

        let payload = ClaimInsert(
            providerId: providerId.uuidString,
            claimantUserId: session.user.id.uuidString,
            claimantRole: role.rawValue,
            businessEmail: email,
            phone: phone,
            licenseNumber: license,
            proofDocumentUrl: proofPath
        )

        _ = try await client
            .from("provider_claims")
            .insert(payload)
            .execute()
    }
}
