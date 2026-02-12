import AVKit
import SDWebImageSwiftUI
import SwiftUI

struct MediaStripView: View {
    let media: [ReviewMedia]
    @State private var selectedImageIndex: Int = 0
    @State private var showImageViewer: Bool = false
    @State private var selectedVideoURL: URL?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(Array(media.enumerated()), id: \.element.id) { index, item in
                    Button {
                        handleTap(index: index, item: item)
                    } label: {
                        ZStack {
                            WebImage(url: URL(string: item.thumbnailUrl ?? item.url))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipped()
                                .cornerRadius(AppRadius.standard)

                            if item.mediaType == .video {
                                Image(systemName: "play.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.mediaType == .video
                        ? String(localized: "Play video")
                        : String(localized: "View image")
                    )
                }
            }
        }
        .sheet(isPresented: $showImageViewer) {
            imageViewer
        }
        .sheet(isPresented: Binding(
            get: { selectedVideoURL != nil },
            set: { if !$0 { selectedVideoURL = nil } }
        )) {
            if let url = selectedVideoURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea()
            }
        }
    }

    private func handleTap(index: Int, item: ReviewMedia) {
        switch item.mediaType {
        case .image:
            let imageItems = media.filter { $0.mediaType == .image }
            selectedImageIndex = imageItems.firstIndex(where: { $0.id == item.id }) ?? 0
            showImageViewer = true
        case .video:
            selectedVideoURL = URL(string: item.url)
        }
    }

    private var imageViewer: some View {
        let imageItems = media.filter { $0.mediaType == .image }
        return TabView(selection: $selectedImageIndex) {
            ForEach(Array(imageItems.enumerated()), id: \.element.id) { index, item in
                WebImage(url: URL(string: item.url))
                    .resizable()
                    .scaledToFit()
                    .tag(index)
                    .background(Color.black)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(Color.black)
    }
}
