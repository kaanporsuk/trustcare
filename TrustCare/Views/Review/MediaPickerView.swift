import AVFoundation
import PhotosUI
import SwiftUI

struct MediaPickerView: View {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedVideo: URL?
    @Binding var selectedVideoDuration: Double?

    @State private var imageItems: [PhotosPickerItem] = []
    @State private var videoItem: PhotosPickerItem?
    @State private var videoThumbnail: UIImage?
    @State private var videoDuration: Double?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Add Photos or Video")
                .font(AppFont.title2)
            Text("Help others see what to expect")
                .font(AppFont.body)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                PhotosPicker(
                    selection: $imageItems,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    Label("Add Photos", systemImage: "photo.on.rectangle")
                        .font(AppFont.headline)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .cornerRadius(8)

                                Button {
                                    selectedImages.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .accessibilityLabel("Remove photo")
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                }

                Text("media_photo_count_\(selectedImages.count)")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                PhotosPicker(
                    selection: $videoItem,
                    matching: .videos
                ) {
                    Label("Add Video", systemImage: "video")
                        .font(AppFont.headline)
                }

                if let thumbnail = videoThumbnail {
                    ZStack(alignment: .topTrailing) {
                        ZStack {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 160, height: 90)
                                .clipped()
                                .cornerRadius(8)

                            Image(systemName: "play.fill")
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }

                        Button {
                            selectedVideo = nil
                            videoItem = nil
                            videoThumbnail = nil
                            videoDuration = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Remove video")
                        .offset(x: 6, y: -6)
                    }
                }

                if let duration = videoDuration, duration > 30 {
                    Text("Video will be trimmed to 30 seconds")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.warning)
                }
            }

            Button("Skip") {
                selectedImages = []
                selectedVideo = nil
                videoItem = nil
                videoThumbnail = nil
                videoDuration = nil
            }
            .font(AppFont.body)

            Text("Photos and videos are visible to everyone.")
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)
        }
        .onChange(of: imageItems) { _, newItems in
            Task {
                var images: [UIImage] = []
                for item in newItems {
                    if let image = await loadImage(from: item) {
                        images.append(image)
                    }
                }
                selectedImages = Array(images.prefix(5))
            }
        }
        .onChange(of: videoItem) { _, newItem in
            Task {
                guard let newItem else { return }
                if let url = await loadVideoURL(from: newItem) {
                    selectedVideo = url
                    videoThumbnail = await ImageService.extractVideoThumbnail(from: url)
                    do {
                        let duration = try await AVAsset(url: url).load(.duration)
                        videoDuration = duration.seconds
                        selectedVideoDuration = duration.seconds
                    } catch {
                        errorMessage = "Something went wrong."
                    }
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Done") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadImage(from item: PhotosPickerItem) async -> UIImage? {
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                return UIImage(data: data)
            }
        } catch {
            return nil
        }
        return nil
    }

    private func loadVideoURL(from item: PhotosPickerItem) async -> URL? {
        do {
            if let url = try await item.loadTransferable(type: URL.self) {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("review_video_\(UUID().uuidString).mov")
                do {
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }
                } catch {
                    errorMessage = "Something went wrong."
                    return nil
                }
                try FileManager.default.copyItem(at: url, to: tempURL)
                return tempURL
            }
        } catch {
            errorMessage = "Something went wrong."
            return nil
        }
        return nil
    }
}
