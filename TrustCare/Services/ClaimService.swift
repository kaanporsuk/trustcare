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
        proofImage: UIImage?
    ) async throws {
        let session = try await client.auth.session
        
        // Use the user's email from their auth session as the business email
        let businessEmail = session.user.email ?? "no-email@trustcare.app"

        var proofPath: String?
        if let proofImage {
            guard let compressedData = ImageService.compressImage(
                proofImage,
                maxSizeKB: 1024,
                quality: 0.7
            ) else {
                throw AppError.uploadFailed
            }

            // Path format: {user_id}/{provider_id}/{timestamp}.jpg
            let timestamp = Int(Date().timeIntervalSince1970)
            let fileName = "\(timestamp).jpg"
            let path = "\(session.user.id.uuidString)/\(providerId.uuidString)/\(fileName)"
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
            let proofDocumentUrl: String?

            enum CodingKeys: String, CodingKey {
                case providerId = "provider_id"
                case claimantUserId = "claimant_user_id"
                case claimantRole = "claimant_role"
                case businessEmail = "business_email"
                case proofDocumentUrl = "proof_document_url"
            }
        }

        let payload = ClaimInsert(
            providerId: providerId.uuidString,
            claimantUserId: session.user.id.uuidString,
            claimantRole: role.rawValue,
            businessEmail: businessEmail,
            proofDocumentUrl: proofPath
        )

        _ = try await client
            .from("provider_claims")
            .insert(payload)
            .execute()
    }
    
    static func getMyClaimStatus(providerId: UUID) async throws -> ProviderClaim? {
        guard let session = try? await client.auth.session else {
            return nil
        }
        
        let response: PostgrestResponse<ProviderClaim> = try await client
            .from("provider_claims")
            .select()
            .eq("provider_id", value: providerId.uuidString)
            .eq("claimant_user_id", value: session.user.id.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .maybeSingle()
            .execute()
        
        return response.value
    }
    
    static func hasPendingClaim(providerId: UUID) async throws -> Bool {
        guard let claim = try await getMyClaimStatus(providerId: providerId) else {
            return false
        }
        return claim.status == .pending
    }
}
