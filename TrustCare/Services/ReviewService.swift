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
        ratings: (wait: Int, bedside: Int, efficacy: Int, cleanliness: Int, staff: Int, value: Int),
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
        print("  Ratings: wait=\(ratings.wait), bedside=\(ratings.bedside), efficacy=\(ratings.efficacy), cleanliness=\(ratings.cleanliness), staff=\(ratings.staff), value=\(ratings.value)")
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

        let derivedOverall = Double(ratings.wait + ratings.bedside + ratings.efficacy + ratings.cleanliness + ratings.staff + ratings.value) / 6.0
        let resolvedOverall = overallRating > 0 ? Double(overallRating) : derivedOverall
        let roundedOverall = Double(round(resolvedOverall * 10) / 10)
        let status = statusOverride ?? (proofImage != nil ? "pending_verification" : "active")

        struct ReviewInsert: Encodable {
            let id: String
            let providerId: String
            let userId: String
            let visitDate: Date
            let visitType: String
            let ratingWaitTime: Int
            let ratingBedside: Int
            let ratingEfficacy: Int
            let ratingCleanliness: Int
            let ratingStaff: Int
            let ratingValue: Int
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
                case ratingWaitTime = "rating_wait_time"
                case ratingBedside = "rating_bedside"
                case ratingEfficacy = "rating_efficacy"
                case ratingCleanliness = "rating_cleanliness"
                case ratingStaff = "rating_staff"
                case ratingValue = "rating_value"
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
            ratingWaitTime: ratings.wait,
            ratingBedside: ratings.bedside,
            ratingEfficacy: ratings.efficacy,
            ratingCleanliness: ratings.cleanliness,
            ratingStaff: ratings.staff,
            ratingValue: ratings.value,
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
}
