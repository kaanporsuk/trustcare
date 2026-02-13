import PhotosUI
import SwiftUI
import UIKit

struct ReviewFormView: View {
    @StateObject private var viewModel: ReviewSubmissionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var proofItem: PhotosPickerItem?
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var commentHeight: CGFloat = 120

    init(provider: Provider) {
        _viewModel = StateObject(wrappedValue: ReviewSubmissionViewModel(provider: provider))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                providerCard
                visitSection
                ratingsSection
                reviewSection
                photoSection
                verificationSection
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .navigationTitle(String(localized: "Write a Review"))
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: viewModel.ratingWaitTime) { _, _ in viewModel.updateOverallIfNeeded() }
        .onChange(of: viewModel.ratingBedside) { _, _ in viewModel.updateOverallIfNeeded() }
        .onChange(of: viewModel.ratingEfficacy) { _, _ in viewModel.updateOverallIfNeeded() }
        .onChange(of: viewModel.ratingCleanliness) { _, _ in viewModel.updateOverallIfNeeded() }
        .onChange(of: viewModel.ratingStaff) { _, _ in viewModel.updateOverallIfNeeded() }
        .onChange(of: viewModel.ratingValue) { _, _ in viewModel.updateOverallIfNeeded() }
        .onChange(of: viewModel.comment) { _, newValue in
            if newValue.count > 1000 {
                viewModel.comment = String(newValue.prefix(1000))
            }
        }
        .onChange(of: photoItems) { _, newItems in
            Task {
                await loadSelectedImages(newItems)
            }
        }
        .onChange(of: proofItem) { _, newItem in
            Task {
                guard let newItem else { return }
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.proofImage = image
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            submitBar
        }
        .overlay {
            if viewModel.isSubmitting {
                Color.black.opacity(0.35).ignoresSafeArea()
                VStack(spacing: AppSpacing.md) {
                    ProgressView(value: viewModel.mediaUploadProgress)
                        .progressViewStyle(.linear)
                        .tint(.white)
                    Text(String(localized: "Submitting review..."))
                        .font(AppFont.body)
                        .foregroundStyle(.white)
                }
                .padding(AppSpacing.lg)
                .background(Color.black.opacity(0.7))
                .cornerRadius(AppRadius.card)
            }
        }
        .fullScreenCover(isPresented: $viewModel.isComplete) {
            ReviewConfirmationView(hasProof: viewModel.proofImage != nil) {
                viewModel.isComplete = false
                dismiss()
            }
        }
    }

    private var providerCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.provider.name)
                .font(AppFont.title3)
            Text(providerSubtitle)
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
    }

    private var providerSubtitle: String {
        let specialty = viewModel.provider.specialty
        if let clinic = viewModel.provider.clinicName, !clinic.isEmpty {
            return "\(specialty) \u{2022} \(clinic)"
        }
        return specialty
    }

    private var visitSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(String(localized: "When did you visit?"))
                .font(AppFont.headline)
            DatePicker(
                "",
                selection: $viewModel.visitDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)

            Text(String(localized: "Visit Type"))
                .font(AppFont.headline)
            VisitTypeSelector(selection: $viewModel.visitType)
        }
    }

    private var ratingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(String(localized: "Rate Your Experience"))
                .font(AppFont.headline)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(String(localized: "Overall Rating"))
                    .font(AppFont.body)
                StarRatingInput(rating: Binding(
                    get: { viewModel.overallRating },
                    set: { viewModel.setOverallRating($0) }
                ), size: 28, showsValue: true)
            }

            RatingRow(label: String(localized: "Waiting Time"), rating: $viewModel.ratingWaitTime)
            RatingRow(label: String(localized: "Bedside Manner"), rating: $viewModel.ratingBedside)
            RatingRow(label: String(localized: "Treatment Efficacy"), rating: $viewModel.ratingEfficacy)
            RatingRow(label: String(localized: "Facility Cleanliness"), rating: $viewModel.ratingCleanliness)
            RatingRow(label: String(localized: "Staff Friendliness"), rating: $viewModel.ratingStaff)
            RatingRow(label: String(localized: "Value for Money"), rating: $viewModel.ratingValue)
        }
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(String(localized: "Your Review"))
                .font(AppFont.headline)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(String(localized: "Title (optional)"))
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                TextField(String(localized: "Give your review a title"), text: $viewModel.title)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.title) { _, newValue in
                        if newValue.count > 100 {
                            viewModel.title = String(newValue.prefix(100))
                        }
                    }
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(String(localized: "Your Experience (required)"))
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)

                ZStack(alignment: .topLeading) {
                    AutoGrowingTextView(text: $viewModel.comment, calculatedHeight: $commentHeight)
                        .frame(minHeight: 120, maxHeight: 200)
                        .padding(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.standard)
                                .stroke(AppColor.border, lineWidth: 1)
                        )

                    if viewModel.comment.isEmpty {
                        Text(String(localized: "Tell others about your visit..."))
                            .foregroundStyle(.secondary)
                            .padding(.top, 12)
                            .padding(.leading, 10)
                    }
                }

                let charText = String(format: String(localized: "min_chars_format"), viewModel.commentCharCount)
                Text(charText)
                    .font(AppFont.footnote)
                    .foregroundStyle(viewModel.isCommentValid ? AppColor.success : AppColor.error)
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(String(localized: "Would you recommend this provider?"))
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: AppSpacing.sm) {
                    RecommendButton(
                        title: String(localized: "Yes"),
                        systemImage: "hand.thumbsup.fill",
                        isSelected: viewModel.wouldRecommend
                    ) {
                        viewModel.wouldRecommend = true
                    }
                    RecommendButton(
                        title: String(localized: "No"),
                        systemImage: "hand.thumbsdown.fill",
                        isSelected: !viewModel.wouldRecommend
                    ) {
                        viewModel.wouldRecommend = false
                    }
                }
            }
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(String(localized: "Add Photos"))
                .font(AppFont.headline)

            PhotosPicker(
                selection: $photoItems,
                maxSelectionCount: 5,
                matching: .images
            ) {
                Label(String(localized: "Add Photos"), systemImage: "camera")
                    .font(AppFont.body)
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, AppSpacing.md)
                    .background(AppColor.trustBlue)
                    .cornerRadius(AppRadius.button)
            }

            if !viewModel.selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .cornerRadius(AppRadius.standard)

                                Button {
                                    viewModel.removeImage(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                }
            }

            Text(String(format: String(localized: "%lld of 5 photos"), viewModel.selectedImages.count))
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(String(localized: "Verify Your Visit"))
                .font(AppFont.headline)
            Text(String(localized: "Upload proof: receipt, prescription, or appointment confirmation"))
                .font(AppFont.caption)
                .foregroundStyle(.secondary)

            PhotosPicker(selection: $proofItem, matching: .images) {
                Label(String(localized: "Upload Proof"), systemImage: "doc.text.image")
                    .font(AppFont.body)
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, AppSpacing.md)
                    .background(AppColor.trustBlue)
                    .cornerRadius(AppRadius.button)
            }

            if let proofImage = viewModel.proofImage {
                Image(uiImage: proofImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 180)
                    .cornerRadius(AppRadius.standard)
            }

            Text(String(localized: "Only visible to our verification system and moderators"))
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var submitBar: some View {
        VStack(spacing: AppSpacing.sm) {
            if let error = viewModel.submissionErrorMessage {
                Text(error)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                Task { await viewModel.submit() }
            } label: {
                if viewModel.isSubmitting {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    Text(String(localized: "Submit Review"))
                        .font(AppFont.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .background(viewModel.canSubmit ? AppColor.trustBlue : AppColor.border)
            .foregroundStyle(.white)
            .cornerRadius(AppRadius.button)
            .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(AppColor.background)
    }

    private func loadSelectedImages(_ items: [PhotosPickerItem]) async {
        let limitedItems = Array(items.prefix(5))
        var images: [UIImage] = []
        for item in limitedItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        viewModel.selectedImages = images
    }
}

private struct RatingRow: View {
    let label: String
    @Binding var rating: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFont.body)
            StarRatingInput(rating: $rating, size: 22, showsValue: true)
        }
    }
}

private struct VisitTypeSelector: View {
    @Binding var selection: VisitType

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: AppSpacing.sm)], spacing: AppSpacing.sm) {
            ForEach(VisitType.allCases) { type in
                Button {
                    selection = type
                } label: {
                    Text(type.displayName)
                        .font(AppFont.caption)
                        .foregroundStyle(selection == type ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(selection == type ? AppColor.trustBlue : AppColor.cardBackground)
                        .cornerRadius(AppRadius.button)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct RecommendButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(AppFont.caption)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? AppColor.trustBlue : AppColor.cardBackground)
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(AppRadius.button)
        }
        .buttonStyle(.plain)
    }
}

private struct AutoGrowingTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var calculatedHeight: CGFloat

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.font = UIFont.systemFont(ofSize: 16)
        view.isScrollEnabled = true
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        AutoGrowingTextView.recalculateHeight(view: uiView, result: $calculatedHeight)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, height: $calculatedHeight)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        @Binding var height: CGFloat

        init(text: Binding<String>, height: Binding<CGFloat>) {
            _text = text
            _height = height
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
            AutoGrowingTextView.recalculateHeight(view: textView, result: $height)
        }
    }

    private static func recalculateHeight(view: UITextView, result: Binding<CGFloat>) {
        let size = view.sizeThatFits(CGSize(width: view.bounds.width, height: .greatestFiniteMagnitude))
        if result.wrappedValue != size.height {
            DispatchQueue.main.async {
                result.wrappedValue = size.height
            }
        }
    }
}

