import AVFoundation
import Foundation
import Supabase
import UIKit

enum ReviewService {
    private static var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    static func submitReview(
        providerId: UUID,
        visitDate: Date,
        visitType: VisitType,
        ratings: (wait: Int, bedside: Int, efficacy: Int, cleanliness: Int),
        priceLevel: Int,
        title: String?,
        comment: String,
        wouldRecommend: Bool,
        proofImage: UIImage?,
        images: [UIImage],
        videoURL: URL?
    ) async throws -> Review {
        let session = try await client.auth.session
        let userId = session.user.id

        var proofUrl: String?
        if let proofImage,
           let proofData = ImageService.compressImage(proofImage, maxSizeKB: 1024) {
            let fileName = "\(UUID().uuidString).jpg"
            let path = "verification-proofs/\(userId.uuidString)/\(fileName)"
            proofUrl = try await ImageService.uploadToStorage(
                bucket: "verification-proofs",
                path: path,
                data: proofData,
                contentType: "image/jpeg"
            )
        }

        let overall = Double(ratings.wait + ratings.bedside + ratings.efficacy + ratings.cleanliness) / 4.0
        let roundedOverall = Double(round(overall * 10) / 10)

        struct ReviewInsert: Encodable {
            let providerId: String
            let userId: String
            let visitDate: Date
            let visitType: String
            let ratingWaitTime: Int
            let ratingBedside: Int
            let ratingEfficacy: Int
            let ratingCleanliness: Int
            let ratingOverall: Double
            let priceLevel: Int
            let title: String?
            let comment: String
            let wouldRecommend: Bool
            let proofImageUrl: String?

            enum CodingKeys: String, CodingKey {
                case providerId = "provider_id"
                case userId = "user_id"
                case visitDate = "visit_date"
                case visitType = "visit_type"
                case ratingWaitTime = "rating_wait_time"
                case ratingBedside = "rating_bedside"
                case ratingEfficacy = "rating_efficacy"
                case ratingCleanliness = "rating_cleanliness"
                case ratingOverall = "rating_overall"
                case priceLevel = "price_level"
                case title
                case comment
                case wouldRecommend = "would_recommend"
                case proofImageUrl = "proof_image_url"
            }
        }

        let insertPayload = ReviewInsert(
            providerId: providerId.uuidString,
            userId: userId.uuidString,
            visitDate: visitDate,
            visitType: visitType.rawValue,
            ratingWaitTime: ratings.wait,
            ratingBedside: ratings.bedside,
            ratingEfficacy: ratings.efficacy,
            ratingCleanliness: ratings.cleanliness,
            ratingOverall: roundedOverall,
            priceLevel: priceLevel,
            title: title,
            comment: comment,
            wouldRecommend: wouldRecommend,
            proofImageUrl: proofUrl
        )

        let reviewResponse: PostgrestResponse<Review> = try await client
            .from("reviews")
            .insert(insertPayload)
            .select()
            .single()
            .execute()

        let review = reviewResponse.value

        try await uploadImages(
            images: images,
            userId: userId,
            reviewId: review.id
        )

        if let videoURL {
            try await uploadVideo(
                videoURL: videoURL,
                userId: userId,
                reviewId: review.id
            )
        }

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

    private static func uploadImages(
        images: [UIImage],
        userId: UUID,
        reviewId: UUID
    ) async throws {
        let limitedImages = Array(images.prefix(5))

        for (index, image) in limitedImages.enumerated() {
            guard let imageData = ImageService.compressImage(image, maxSizeKB: 2048) else { continue }
            let thumbnailImage = ImageService.generateThumbnail(image)
            let thumbnailData = thumbnailImage?.jpegData(compressionQuality: 0.7)

            let fileName = "\(UUID().uuidString).jpg"
            let path = "review-media/\(userId.uuidString)/\(reviewId.uuidString)/\(fileName)"
            let thumbPath = "review-media/\(userId.uuidString)/\(reviewId.uuidString)/thumb_\(fileName)"

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

            try await insertMediaRow(
                reviewId: reviewId,
                userId: userId,
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
        }
    }

    private static func uploadVideo(
        videoURL: URL,
        userId: UUID,
        reviewId: UUID
    ) async throws {
        let compressedURL = try await ImageService.compressVideo(inputURL: videoURL)
        let asset = AVAsset(url: compressedURL)
        let duration = try await asset.load(.duration)
        let durationSeconds = Int(duration.seconds.rounded())

        let fileName = "\(UUID().uuidString).mp4"
        let path = "review-media/\(userId.uuidString)/\(reviewId.uuidString)/\(fileName)"
        let thumbPath = "review-media/\(userId.uuidString)/\(reviewId.uuidString)/thumb_\(fileName).jpg"

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

        try await insertMediaRow(
            reviewId: reviewId,
            userId: userId,
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
