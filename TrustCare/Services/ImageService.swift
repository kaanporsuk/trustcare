@preconcurrency import AVFoundation
import Foundation
import Supabase
import UIKit

enum ImageService {
    private static var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    static func compressImage(
        _ image: UIImage,
        maxSizeKB: Int = 1024,
        quality: CGFloat = 0.7
    ) -> Data? {
        let maxBytes = maxSizeKB * 1024
        var currentQuality = quality
        var data = image.jpegData(compressionQuality: currentQuality)

        while let currentData = data, currentData.count > maxBytes, currentQuality > 0.1 {
            currentQuality = max(0.1, currentQuality - 0.1)
            data = image.jpegData(compressionQuality: currentQuality)
        }

        return data
    }

    static func generateThumbnail(
        _ image: UIImage,
        size: CGSize = CGSize(width: 200, height: 200)
    ) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    static func compressVideo(inputURL: URL) async throws -> URL {
        let asset = AVAsset(url: inputURL)
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetMediumQuality
        ) else {
            throw AppError.uploadFailed
        }

        final class ExportSessionBox: @unchecked Sendable {
            let session: AVAssetExportSession
            init(_ session: AVAssetExportSession) {
                self.session = session
            }
        }

        let sessionBox = ExportSessionBox(exportSession)

        let maxDuration = CMTime(seconds: 30, preferredTimescale: 600)
        let duration = try await asset.load(.duration)
        let trimmedDuration = duration < maxDuration ? duration : maxDuration
        exportSession.timeRange = CMTimeRange(start: .zero, duration: trimmedDuration)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("review_video_\(UUID().uuidString).mp4")

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4

        try await withCheckedThrowingContinuation { continuation in
            sessionBox.session.exportAsynchronously {
                switch sessionBox.session.status {
                case .completed:
                    continuation.resume(returning: ())
                case .failed, .cancelled:
                    continuation.resume(throwing: sessionBox.session.error ?? AppError.uploadFailed)
                default:
                    continuation.resume(throwing: AppError.uploadFailed)
                }
            }
        }

        return outputURL
    }

    static func extractVideoThumbnail(from url: URL) async -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try generator.copyCGImage(
                at: CMTime(seconds: 0, preferredTimescale: 600),
                actualTime: nil
            )
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }

    static func uploadToStorage(
        bucket: String,
        path: String,
        data: Data,
        contentType: String
    ) async throws -> String {
        let options = FileOptions(contentType: contentType)
        _ = try await client
            .storage
            .from(bucket)
            .upload(path, data: data, options: options)

        let url = try client.storage.from(bucket).getPublicURL(path: path)
        return url.absoluteString
    }
}
