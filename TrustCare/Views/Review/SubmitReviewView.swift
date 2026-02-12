import PhotosUI
import SwiftUI
import UIKit

struct SubmitReviewView: View {
    @Binding var selectedTab: Int
    let preselectedProvider: Provider?
    @StateObject private var viewModel = ReviewSubmissionViewModel()
    @State private var showAddProviderSheet: Bool = false
    @State private var proofItem: PhotosPickerItem?
    @State private var showProviderAddedToast: Bool = false

    init(
        selectedTab: Binding<Int> = .constant(0),
        preselectedProvider: Provider? = nil
    ) {
        _selectedTab = selectedTab
        self.preselectedProvider = preselectedProvider
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                ProgressView(value: Double(viewModel.currentStep), total: 7)
                    .progressViewStyle(.linear)
                    .tint(AppColor.trustBlue)
                    .padding(.horizontal, AppSpacing.lg)

                stepContent

                Spacer()

                navigationBar
            }
            .padding(.vertical, AppSpacing.lg)
            .navigationTitle(String(localized: "Write a Review"))
            .navigationBarTitleDisplayMode(.inline)
            .dismissKeyboardOnTap()
            .keyboardDoneToolbar()
            .sheet(isPresented: $showAddProviderSheet) {
                AddProviderSheet { provider in
                    viewModel.selectProvider(provider, advanceToStep2: true)
                    showProviderAddedToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        showProviderAddedToast = false
                    }
                }
            }
            .task(id: preselectedProvider?.id) {
                if let provider = preselectedProvider, viewModel.selectedProvider == nil {
                    viewModel.selectedProvider = provider
                    viewModel.searchText = provider.name
                }
            }
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.searchProviders()
            }
            .onChange(of: proofItem) { _, newItem in
                Task {
                    guard let newItem else { return }
                    do {
                        if let data = try await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            viewModel.proofImage = image
                            viewModel.showSkipVerificationNote = false
                        }
                    } catch {
                        viewModel.submissionErrorMessage = String(localized: "Unable to upload media. Please try again.")
                    }
                }
            }
            .overlay {
                if viewModel.isSubmitting {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
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
            .overlay(alignment: .top) {
                if showProviderAddedToast {
                    Text(String(localized: "Provider added successfully"))
                        .font(AppFont.caption)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.black.opacity(0.8))
                        .foregroundStyle(.white)
                        .cornerRadius(AppRadius.standard)
                        .padding(.top, AppSpacing.lg)
                }
            }
            .alert(String(localized: "Error"), isPresented: Binding(
                get: { viewModel.submissionErrorMessage != nil },
                set: { if !$0 { viewModel.submissionErrorMessage = nil } }
            )) {
                Button(String(localized: "Done")) {
                    viewModel.submissionErrorMessage = nil
                }
            } message: {
                Text(viewModel.submissionErrorMessage ?? "")
            }
            .fullScreenCover(isPresented: $viewModel.isComplete) {
                ReviewConfirmationView(hasProof: viewModel.proofImage != nil) {
                    viewModel.isComplete = false
                    viewModel.currentStep = 1
                    viewModel.showSkipVerificationNote = false
                    selectedTab = 0
                }
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case 1:
            stepFindProvider
        case 2:
            stepVisitDetails
        case 3:
            stepRatings
        case 4:
            stepPrice
        case 5:
            stepWrittenReview
        case 6:
            stepMedia
        default:
            stepVerification
        }
    }

    private var stepFindProvider: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SearchBarView(text: $viewModel.searchText)
                .padding(.horizontal, AppSpacing.lg)

            if let message = viewModel.searchErrorMessage {
                Text(message)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.error)
                    .padding(.horizontal, AppSpacing.lg)
            }

            if let provider = viewModel.selectedProvider {
                Button {
                    viewModel.selectedProvider = nil
                    viewModel.searchText = ""
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColor.success)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(provider.name)
                                .font(AppFont.headline)
                            Text(provider.specialty)
                                .font(AppFont.caption)
                                .foregroundStyle(.secondary)
                            Text(provider.address)
                                .font(AppFont.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(localized: "Change"))
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.trustBlue)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColor.cardBackground)
                    .cornerRadius(AppRadius.card)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.lg)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.sm) {
                        if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            && viewModel.searchResults.isEmpty
                            && !viewModel.isLoading {
                            VStack(spacing: AppSpacing.sm) {
                                Text(String(localized: "No providers found"))
                                    .font(AppFont.body)
                                    .foregroundStyle(.secondary)
                                Button {
                                    showAddProviderSheet = true
                                } label: {
                                    Text(String(localized: "Add a new provider"))
                                        .font(AppFont.body)
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, AppSpacing.md)
                                        .background(AppColor.trustBlue)
                                        .cornerRadius(AppRadius.button)
                                }
                            }
                            .padding(.top, AppSpacing.lg)
                        }

                        ForEach(viewModel.searchResults) { provider in
                            Button {
                                viewModel.selectProvider(provider)
                            } label: {
                                HStack(alignment: .top, spacing: AppSpacing.sm) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(provider.name)
                                            .font(AppFont.headline)
                                        Text(provider.specialty)
                                            .font(AppFont.caption)
                                            .foregroundStyle(.secondary)
                                        Text(provider.address)
                                            .font(AppFont.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if viewModel.selectedProvider?.id == provider.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppColor.trustBlue)
                                    }
                                }
                                .padding(AppSpacing.md)
                                .background(AppColor.cardBackground)
                                .cornerRadius(AppRadius.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.card)
                                        .stroke(
                                            viewModel.selectedProvider?.id == provider.id ? AppColor.trustBlue : .clear,
                                            lineWidth: 2
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            Button {
                showAddProviderSheet = true
            } label: {
                Text(String(localized: "Can't find them? Add a new provider"))
                    .font(AppFont.caption)
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, AppSpacing.md)
                    .background(AppColor.trustBlue)
                    .cornerRadius(AppRadius.button)
                    .padding(.horizontal, AppSpacing.lg)
            }
        }
    }

    private var stepVisitDetails: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            DatePicker(
                String(localized: "When was your visit?"),
                selection: $viewModel.visitDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .padding(.horizontal, AppSpacing.lg)

            Picker(String(localized: "Visit Type"), selection: $viewModel.visitType) {
                ForEach(VisitType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    private var stepRatings: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                RatingSliderView(
                    icon: "clock",
                    label: String(localized: "Wait Time"),
                    value: $viewModel.ratingWaitTime
                )
                RatingSliderView(
                    icon: "heart",
                    label: String(localized: "Bedside Manner"),
                    value: $viewModel.ratingBedside
                )
                RatingSliderView(
                    icon: "cross.case",
                    label: String(localized: "Treatment Efficacy"),
                    value: $viewModel.ratingEfficacy
                )
                RatingSliderView(
                    icon: "sparkles",
                    label: String(localized: "Cleanliness"),
                    value: $viewModel.ratingCleanliness
                )

                VStack(spacing: AppSpacing.sm) {
                    Text(String(localized: "Overall Rating"))
                        .font(AppFont.headline)
                    StarRatingView(rating: viewModel.overallRating)
                }
                .padding(AppSpacing.md)
                .background(AppColor.cardBackground)
                .cornerRadius(AppRadius.card)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var stepPrice: some View {
        ScrollView {
            PriceLevelPicker(selection: $viewModel.priceLevel)
                .padding(.horizontal, AppSpacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var stepWrittenReview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                TextField(String(localized: "Give your review a title"), text: $viewModel.title)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.title) { _, newValue in
                        if newValue.count > 100 {
                            viewModel.title = String(newValue.prefix(100))
                        }
                    }

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.comment)
                        .frame(minHeight: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.standard)
                                .stroke(AppColor.border, lineWidth: 1)
                        )

                    if viewModel.comment.isEmpty {
                        Text(String(localized: "Share your experience..."))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 6)
                    }
                }

                Text(viewModel.commentCharCount)
                    .font(AppFont.footnote)
                    .foregroundStyle(viewModel.comment.count < 50 ? AppColor.error : .secondary)

                Toggle(String(localized: "Would you recommend?"), isOn: $viewModel.wouldRecommend)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var stepMedia: some View {
        ScrollView {
            MediaPickerView(
                selectedImages: $viewModel.selectedImages,
                selectedVideo: $viewModel.selectedVideo,
                selectedVideoDuration: $viewModel.selectedVideoDuration
            )
            .padding(.horizontal, AppSpacing.lg)

            Button(String(localized: "Skip")) {
                viewModel.skipPhotos()
            }
            .font(AppFont.body)
            .foregroundStyle(AppColor.trustBlue)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var stepVerification: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(String(localized: "Verify Your Visit"))
                    .font(AppFont.title2)
                Text(String(localized: "Upload proof: receipt, prescription, or appointment confirmation"))
                    .font(AppFont.body)
                    .foregroundStyle(.secondary)

                PhotosPicker(selection: $proofItem, matching: .images) {
                    Label(String(localized: "Upload Proof"), systemImage: "doc.text.image")
                        .font(AppFont.headline)
                }

                if let proofImage = viewModel.proofImage {
                    Image(uiImage: proofImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(AppRadius.standard)
                }

                Text(String(localized: "Only visible to our verification system and moderators"))
                    .font(AppFont.footnote)
                    .foregroundStyle(.secondary)

                Button(String(localized: "Skip Verification")) {
                    proofItem = nil
                    Task { await viewModel.skipVerification() }
                }
                .font(AppFont.body)

                if viewModel.showSkipVerificationNote {
                    Text(String(localized: "Your review will be marked as unverified."))
                        .font(AppFont.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, AppSpacing.xs)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var navigationBar: some View {
        HStack {
            if viewModel.currentStep > 1 {
                Button(String(localized: "Back")) {
                    viewModel.previousStep()
                }
                .buttonStyle(.bordered)
            } else {
                Button(String(localized: "Cancel")) {
                    viewModel.resetFlow()
                    selectedTab = 0
                }
                .buttonStyle(.bordered)
            }

            Spacer()

                     Button(viewModel.currentStep == 7
                         ? String(localized: "Submit Review")
                         : String(localized: "Next")) {
                if viewModel.currentStep == 7 {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    Task { await viewModel.submit() }
                } else {
                    viewModel.nextStep()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.trustBlue)
            .disabled(!viewModel.canAdvance)
            .opacity(viewModel.canAdvance ? 1.0 : 0.5)
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}
