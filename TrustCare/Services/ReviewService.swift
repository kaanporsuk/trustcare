import AVFoundation
import Foundation
import Supabase
import UIKit

enum ReviewService {
    private static var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private struct UploadedMediaAsset {
        let mediaType: MediaType
        let storagePath: String
        let url: String
        let thumbnailUrl: String?
        let fileSizeBytes: Int
        let durationSeconds: Int?
        let width: Int?
        let height: Int?
        let displayOrder: Int
    }

    static func submitReview(
        providerId: UUID,
        visitDate: Date,
        visitType: VisitType,
        surveyType: String,
        metricRatings: [String: Int],
        overallRating: Int,
        priceLevel: Int,
        title: String?,
        comment: String,
        wouldRecommend: Bool,
        proofImage: UIImage?,
        images: [UIImage],
        videoURL: URL?,
        statusOverride: String? = nil,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> Review {
        // Check if user is authenticated
        guard let session = try? await client.auth.session else {
            throw AppError.authError(
                String(localized: "Please sign in to submit a review.")
            )
        }
        let userId = session.user.id

        print("🔵 ReviewService.submitReview started")
        print("  Provider ID: \(providerId)")
        print("  User ID: \(userId)")
        print("  Visit date: \(visitDate)")
        print("  Visit type: \(visitType.rawValue)")
        print("  Survey type: \(surveyType)")
        print("  Dynamic metric ratings: \(metricRatings)")
        print("  Price level: \(priceLevel)")
        print("  Comment length: \(comment.count)")
        print("  Proof image selected: \(proofImage != nil)")
        print("  Images: \(images.count), video: \(videoURL != nil)")

        let imageCount = min(images.count, 5)
        let totalSteps = Double(1
            + (proofImage != nil ? 1 : 0)
            + imageCount
            + (videoURL != nil ? 1 : 0))
        var completedSteps = 0.0
        let advanceProgress: () -> Void = {
            completedSteps += 1
            let progress = min(1, completedSteps / max(1, totalSteps))
            progressHandler?(progress)
        }

        let pendingReviewId = UUID()

        let uploadedImages = try await uploadImagesToStorage(
            images: images,
            userId: userId,
            reviewId: pendingReviewId,
            onStep: advanceProgress
        )

        let uploadedVideo = try await uploadVideoToStorage(
            videoURL: videoURL,
            userId: userId,
            reviewId: pendingReviewId,
            onStep: advanceProgress
        )

        var proofUrl: String?
        if let proofImage,
           let proofData = ImageService.compressImage(proofImage, maxSizeKB: 1024) {
            let fileName = "\(UUID().uuidString).jpg"
            let path = "\(userId.uuidString)/\(fileName)"
            proofUrl = try await ImageService.uploadToStorage(
                bucket: "verification-proofs",
                path: path,
                data: proofData,
                contentType: "image/jpeg"
            )
            advanceProgress()
        }

        let validMetricValues = metricRatings.values.filter { (1...5).contains($0) }
        let derivedOverall = validMetricValues.isEmpty
            ? Double(overallRating)
            : Double(validMetricValues.reduce(0, +)) / Double(validMetricValues.count)
        let resolvedOverall = overallRating > 0 ? Double(overallRating) : derivedOverall
        let roundedOverall = Double(round(resolvedOverall * 10) / 10)
        let status = statusOverride ?? (proofImage != nil ? "pending_verification" : "active")

        func metric(_ key: String) -> Int? {
            guard let value = metricRatings[key], (1...5).contains(value) else {
                return nil
            }
            return value
        }

        struct ReviewInsert: Encodable {
            let id: String
            let providerId: String
            let userId: String
            let visitDate: Date
            let visitType: String
            let surveyType: String
            let ratingWaitTime: Int?
            let ratingBedside: Int?
            let ratingEfficacy: Int?
            let ratingCleanliness: Int?
            let ratingStaff: Int
            let ratingValue: Int
            let ratingPainMgmt: Int?
            let ratingAccuracy: Int?
            let ratingKnowledge: Int?
            let ratingCourtesy: Int?
            let ratingCareQuality: Int?
            let ratingAdmin: Int?
            let ratingComfort: Int?
            let ratingTurnaround: Int?
            let ratingEmpathy: Int?
            let ratingEnvironment: Int?
            let ratingCommunication: Int?
            let ratingEffectiveness: Int?
            let ratingAttentiveness: Int?
            let ratingEquipment: Int?
            let ratingConsultation: Int?
            let ratingResults: Int?
            let ratingAftercare: Int?
            let ratingOverall: Double
            let priceLevel: Int
            let title: String?
            let comment: String
            let wouldRecommend: Bool
            let proofImageUrl: String?
            let isVerified: Bool
            let status: String

            enum CodingKeys: String, CodingKey {
                case id
                case providerId = "provider_id"
                case userId = "user_id"
                case visitDate = "visit_date"
                case visitType = "visit_type"
                case surveyType = "survey_type"
                case ratingWaitTime = "rating_wait_time"
                case ratingBedside = "rating_bedside"
                case ratingEfficacy = "rating_efficacy"
                case ratingCleanliness = "rating_cleanliness"
                case ratingStaff = "rating_staff"
                case ratingValue = "rating_value"
                case ratingPainMgmt = "rating_pain_mgmt"
                case ratingAccuracy = "rating_accuracy"
                case ratingKnowledge = "rating_knowledge"
                case ratingCourtesy = "rating_courtesy"
                case ratingCareQuality = "rating_care_quality"
                case ratingAdmin = "rating_admin"
                case ratingComfort = "rating_comfort"
                case ratingTurnaround = "rating_turnaround"
                case ratingEmpathy = "rating_empathy"
                case ratingEnvironment = "rating_environment"
                case ratingCommunication = "rating_communication"
                case ratingEffectiveness = "rating_effectiveness"
                case ratingAttentiveness = "rating_attentiveness"
                case ratingEquipment = "rating_equipment"
                case ratingConsultation = "rating_consultation"
                case ratingResults = "rating_results"
                case ratingAftercare = "rating_aftercare"
                case ratingOverall = "rating_overall"
                case priceLevel = "price_level"
                case title
                case comment
                case wouldRecommend = "would_recommend"
                case proofImageUrl = "proof_image_url"
                case isVerified = "is_verified"
                case status
            }
        }

        let insertPayload = ReviewInsert(
            id: pendingReviewId.uuidString,
            providerId: providerId.uuidString,
            userId: userId.uuidString,
            visitDate: visitDate,
            visitType: visitType.rawValue,
            surveyType: surveyType,
            ratingWaitTime: metric("rating_wait_time"),
            ratingBedside: metric("rating_bedside"),
            ratingEfficacy: metric("rating_efficacy"),
            ratingCleanliness: metric("rating_cleanliness"),
            ratingStaff: max(1, min(5, overallRating)),
            ratingValue: max(1, min(5, overallRating)),
            ratingPainMgmt: metric("rating_pain_mgmt"),
            ratingAccuracy: metric("rating_accuracy"),
            ratingKnowledge: metric("rating_knowledge"),
            ratingCourtesy: metric("rating_courtesy"),
            ratingCareQuality: metric("rating_care_quality"),
            ratingAdmin: metric("rating_admin"),
            ratingComfort: metric("rating_comfort"),
            ratingTurnaround: metric("rating_turnaround"),
            ratingEmpathy: metric("rating_empathy"),
            ratingEnvironment: metric("rating_environment"),
            ratingCommunication: metric("rating_communication"),
            ratingEffectiveness: metric("rating_effectiveness"),
            ratingAttentiveness: metric("rating_attentiveness"),
            ratingEquipment: metric("rating_equipment"),
            ratingConsultation: metric("rating_consultation"),
            ratingResults: metric("rating_results"),
            ratingAftercare: metric("rating_aftercare"),
            ratingOverall: roundedOverall,
            priceLevel: priceLevel,
            title: title,
            comment: comment,
            wouldRecommend: wouldRecommend,
            proofImageUrl: proofUrl,
            isVerified: false,
            status: status
        )

        print("  Insert payload: status=\(status), proof_url=\(proofUrl ?? "nil")")

        let reviewResponse: PostgrestResponse<Review>
        do {
            reviewResponse = try await client
                .from("reviews")
                .insert(insertPayload)
                .select()
                .single()
                .execute()
        } catch {
            print("❌ ReviewService.submitReview insert failed")
            print("  Error: \(error)")
            print("  Error type: \(type(of: error))")
            print("  Localized: \(error.localizedDescription)")
            throw error
        }

        let review = reviewResponse.value
        advanceProgress()

        var uploadedAssets = uploadedImages
        if let uploadedVideo {
            uploadedAssets.append(uploadedVideo)
        }

        try await persistUploadedMedia(
            assets: uploadedAssets,
            userId: userId,
            reviewId: review.id
        )

        return review
    }

    static func fetchReviewById(_ id: UUID) async throws -> Review {
        let response: PostgrestResponse<Review> = try await client
            .from("reviews")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()

        return response.value
    }

    private static func uploadImagesToStorage(
        images: [UIImage],
        userId: UUID,
        reviewId: UUID,
        onStep: (() -> Void)?
    ) async throws -> [UploadedMediaAsset] {
        let limitedImages = Array(images.prefix(5))
        var uploadedAssets: [UploadedMediaAsset] = []

        for (index, image) in limitedImages.enumerated() {
            guard let imageData = ImageService.compressImage(image, maxSizeKB: 1024) else { continue }
            let thumbnailImage = ImageService.generateThumbnail(image)
            let thumbnailData = thumbnailImage?.jpegData(compressionQuality: 0.7)

            let fileName = "\(UUID().uuidString).jpg"
            let path = "\(userId.uuidString)/\(reviewId.uuidString)/\(fileName)"
            let thumbPath = "\(userId.uuidString)/\(reviewId.uuidString)/thumb_\(fileName)"

            let url = try await ImageService.uploadToStorage(
                bucket: "review-media",
                path: path,
                data: imageData,
                contentType: "image/jpeg"
            )

            var thumbnailUrl: String?
            if let thumbData = thumbnailData {
                thumbnailUrl = try await ImageService.uploadToStorage(
                    bucket: "review-media",
                    path: thumbPath,
                    data: thumbData,
                    contentType: "image/jpeg"
                )
            }

            let width = Int(image.size.width)
            let height = Int(image.size.height)

            uploadedAssets.append(
                UploadedMediaAsset(
                    mediaType: .image,
                    storagePath: path,
                    url: url,
                    thumbnailUrl: thumbnailUrl,
                    fileSizeBytes: imageData.count,
                    durationSeconds: nil,
                    width: width,
                    height: height,
                    displayOrder: index + 1
                )
            )

            onStep?()
        }

        return uploadedAssets
    }

    private static func uploadVideoToStorage(
        videoURL: URL?,
        userId: UUID,
        reviewId: UUID,
        onStep: (() -> Void)?
    ) async throws -> UploadedMediaAsset? {
        guard let videoURL else {
            return nil
        }

        let compressedURL = try await ImageService.compressVideo(inputURL: videoURL)
        let asset = AVAsset(url: compressedURL)
        let duration = try await asset.load(.duration)
        let durationSeconds = Int(duration.seconds.rounded())

        let fileName = "\(UUID().uuidString).mp4"
        let path = "\(userId.uuidString)/\(reviewId.uuidString)/\(fileName)"
        let thumbName = "thumb_\(UUID().uuidString).jpg"
        let thumbPath = "\(userId.uuidString)/\(reviewId.uuidString)/\(thumbName)"

        let videoData = try Data(contentsOf: compressedURL)
        let url = try await ImageService.uploadToStorage(
            bucket: "review-media",
            path: path,
            data: videoData,
            contentType: "video/mp4"
        )

        var thumbnailUrl: String?
        if let thumbImage = await ImageService.extractVideoThumbnail(from: compressedURL),
           let thumbData = ImageService.compressImage(thumbImage, maxSizeKB: 512) {
            thumbnailUrl = try await ImageService.uploadToStorage(
                bucket: "review-media",
                path: thumbPath,
                data: thumbData,
                contentType: "image/jpeg"
            )
        }

        var width: Int?
        var height: Int?
        if let track = try await asset.loadTracks(withMediaType: .video).first {
            let naturalSize = try await track.load(.naturalSize)
            let transform = try await track.load(.preferredTransform)
            let size = naturalSize.applying(transform)
            width = Int(abs(size.width))
            height = Int(abs(size.height))
        }

        onStep?()

        return UploadedMediaAsset(
            mediaType: .video,
            storagePath: path,
            url: url,
            thumbnailUrl: thumbnailUrl,
            fileSizeBytes: videoData.count,
            durationSeconds: durationSeconds,
            width: width,
            height: height,
            displayOrder: 1
        )
    }

    private static func persistUploadedMedia(
        assets: [UploadedMediaAsset],
        userId: UUID,
        reviewId: UUID
    ) async throws {
        for asset in assets {
            try await insertMediaRow(
                reviewId: reviewId,
                userId: userId,
                mediaType: asset.mediaType,
                storagePath: asset.storagePath,
                url: asset.url,
                thumbnailUrl: asset.thumbnailUrl,
                fileSizeBytes: asset.fileSizeBytes,
                durationSeconds: asset.durationSeconds,
                width: asset.width,
                height: asset.height,
                displayOrder: asset.displayOrder
            )
        }
    }

    private static func insertMediaRow(
        reviewId: UUID,
        userId: UUID,
        mediaType: MediaType,
        storagePath: String,
        url: String,
        thumbnailUrl: String?,
        fileSizeBytes: Int,
        durationSeconds: Int?,
        width: Int?,
        height: Int?,
        displayOrder: Int
    ) async throws {
        struct MediaInsert: Encodable {
            let reviewId: String
            let userId: String
            let mediaType: String
            let storagePath: String
            let url: String
            let thumbnailUrl: String?
            let fileSizeBytes: Int
            let durationSeconds: Int?
            let width: Int?
            let height: Int?
            let displayOrder: Int

            enum CodingKeys: String, CodingKey {
                case reviewId = "review_id"
                case userId = "user_id"
                case mediaType = "media_type"
                case storagePath = "storage_path"
                case url
                case thumbnailUrl = "thumbnail_url"
                case fileSizeBytes = "file_size_bytes"
                case durationSeconds = "duration_seconds"
                case width
                case height
                case displayOrder = "display_order"
            }
        }

        let payload = MediaInsert(
            reviewId: reviewId.uuidString,
            userId: userId.uuidString,
            mediaType: mediaType.rawValue,
            storagePath: storagePath,
            url: url,
            thumbnailUrl: thumbnailUrl,
            fileSizeBytes: fileSizeBytes,
            durationSeconds: durationSeconds,
            width: width,
            height: height,
            displayOrder: displayOrder
        )

        _ = try await client
            .from("review_media")
            .insert(payload)
            .execute()
    }
    
    // MARK: - Review Voting
    
    static func voteReview(reviewId: UUID, isHelpful: Bool) async throws {
        guard let session = try? await client.auth.session else {
            throw AppError.authError(String(localized: "Please sign in to vote."))
        }
        let userId = session.user.id
        
        struct VoteUpsert: Encodable {
            let reviewId: String
            let userId: String
            let isHelpful: Bool
            
            enum CodingKeys: String, CodingKey {
                case reviewId = "review_id"
                case userId = "user_id"
                case isHelpful = "is_helpful"
            }
        }
        
        let payload = VoteUpsert(
            reviewId: reviewId.uuidString,
            userId: userId.uuidString,
            isHelpful: isHelpful
        )
        
        _ = try await client
            .from("review_votes")
            .upsert(payload, onConflict: "review_id,user_id")
            .execute()
    }
    
    static func removeVote(reviewId: UUID) async throws {
        guard let session = try? await client.auth.session else {
            throw AppError.authError(String(localized: "Please sign in."))
        }
        let userId = session.user.id
        
        _ = try await client
            .from("review_votes")
            .delete()
            .eq("review_id", value: reviewId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    static func getMyVote(reviewId: UUID) async throws -> Bool? {
        guard let session = try? await client.auth.session else {
            return nil
        }
        let userId = session.user.id
        
        let response: PostgrestResponse<ReviewVote> = try await client
            .from("review_votes")
            .select()
            .eq("review_id", value: reviewId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .maybeSingle()
            .execute()
        
        return response.value?.isHelpful
    }
    
    static func getHelpfulCount(reviewId: UUID) async throws -> Int {
        let response = try await client
            .from("review_votes")
            .select("*", head: true, count: .exact)
            .eq("review_id", value: reviewId.uuidString)
            .eq("is_helpful", value: true)
            .execute()
        
        return response.count ?? 0
    }
    
    // MARK: - Report Review
    
    static func reportReview(reviewId: UUID, reason: ReportReason, description: String?) async throws {
        guard let session = try? await client.auth.session else {
            throw AppError.authError(String(localized: "Please sign in to report."))
        }
        let userId = session.user.id
        
        struct ReportInsert: Encodable {
            let reviewId: String
            let reporterId: String
            let reason: String
            let description: String?
            
            enum CodingKeys: String, CodingKey {
                case reviewId = "review_id"
                case reporterId = "reporter_id"
                case reason
                case description
            }
        }
        
        let payload = ReportInsert(
            reviewId: reviewId.uuidString,
            reporterId: userId.uuidString,
            reason: reason.rawValue,
            description: description
        )
        
        _ = try await client
            .from("reported_reviews")
            .insert(payload)
            .execute()
    }
    
    static func hasReported(reviewId: UUID) async throws -> Bool {
        guard let session = try? await client.auth.session else {
            return false
        }
        let userId = session.user.id
        
        let response = try await client
            .from("reported_reviews")
            .select("id", head: true, count: .exact)
            .eq("review_id", value: reviewId.uuidString)
            .eq("reporter_id", value: userId.uuidString)
            .execute()
        
        return (response.count ?? 0) > 0
    }
}
