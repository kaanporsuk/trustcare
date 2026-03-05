import PhotosUI
import SwiftUI
import UIKit

struct ReviewHubView: View {
    @StateObject private var viewModel = ReviewSubmissionViewModel()
    @ObservedObject private var specialtyService = SpecialtyService.shared
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var providerSearchText: String = ""
    @State private var providerResults: [Provider] = []
    @State private var specialtyResults: [Specialty] = []
    @State private var isSearchingProviders: Bool = false
    @State private var showAddProviderSheet: Bool = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var proofItem: PhotosPickerItem?

    @State private var currentStep: ReviewStep = .provider

    private let launchedFromProviderDetail: Bool

    private enum ReviewStep: Int, CaseIterable {
        case provider = 1
        case visit = 2
        case overall = 3
        case detailed = 4
        case comment = 5
        case mediaAndSubmit = 6

        var title: String {
            switch self {
            case .provider: return tcString("review_step_choose_provider", fallback: "Choose provider")
            case .visit: return tcString("review_step_visit_details", fallback: "Visit details")
            case .overall: return tcString("review_step_overall_rating", fallback: "Overall rating")
            case .detailed: return tcString("review_step_detailed_ratings", fallback: "Detailed ratings")
            case .comment: return tcString("review_step_write_review", fallback: "Write review")
            case .mediaAndSubmit: return tcString("review_step_media_submit", fallback: "Media and submit")
            }
        }
    }

    private var progress: Double {
        Double(currentStep.rawValue) / Double(ReviewStep.allCases.count)
    }

    private var shouldShowTabBoundOverlay: Bool {
        launchedFromProviderDetail || appRouter.selectedTab == 2
    }

    private var canGoNext: Bool {
        switch currentStep {
        case .provider:
            return viewModel.selectedProvider != nil
        case .visit:
            return true
        case .overall:
            return viewModel.overallRating > 0
        case .detailed:
            return true
        case .comment:
            return viewModel.commentCharCount >= 50
        case .mediaAndSubmit:
            return false
        }
    }

    init(initialProvider: Provider? = nil) {
        _viewModel = StateObject(wrappedValue: ReviewSubmissionViewModel(provider: initialProvider))
        _providerSearchText = State(initialValue: initialProvider?.name ?? "")
        _currentStep = State(initialValue: initialProvider != nil ? .visit : .provider)
        launchedFromProviderDetail = initialProvider != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    stepHeader
                    stepContent
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxxl)
            }
            .navigationTitle(Text(tcKey: "tab_review", fallback: "Review"))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await specialtyService.loadSpecialties()
            }
            .task(id: providerSearchText) {
                await searchProvidersAndSpecialties()
            }
            .onChange(of: photoItems) { _, items in
                Task { await loadPhotos(items) }
            }
            .onChange(of: proofItem) { _, item in
                Task { await loadProof(item) }
            }
            .sheet(isPresented: $showAddProviderSheet) {
                AddProviderSheet { provider in
                    viewModel.selectProvider(provider)
                    providerSearchText = provider.name
                    showAddProviderSheet = false
                }
            }
            .fullScreenCover(isPresented: $viewModel.isComplete) {
                ReviewConfirmationView(
                    hasProof: viewModel.didUploadProof,
                    onViewProvider: {
                        routeToProviderDetailAfterSubmit()
                    },
                    onAnotherReview: {
                        viewModel.resetForm(keepProvider: false)
                        providerSearchText = ""
                        currentStep = .provider
                    },
                    onGoHome: {
                        viewModel.isComplete = false
                        NotificationCenter.default.post(name: .trustCareSwitchTab, object: 0)
                    }
                )
            }
            .safeAreaInset(edge: .bottom) {
                if shouldShowTabBoundOverlay {
                    submitBar
                }
            }
            .onChange(of: appRouter.selectedTab) { _, newTab in
                // Prevent stale CTA error state from lingering when users leave Review tab.
                if !launchedFromProviderDetail, newTab != 2 {
                    viewModel.submissionErrorMessage = nil
                }
            }
        }
    }

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(String(format: tcString("review_step_format", fallback: "Step %lld of %lld"), currentStep.rawValue, ReviewStep.allCases.count))
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
            Text(currentStep.title)
                .font(AppFont.title3)
            ProgressView(value: progress)
                .tint(Color.tcOcean)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .provider:
            providerSection
        case .visit:
            visitDetailsSection
        case .overall:
            overallRatingSection
        case .detailed:
            detailedRatingsSection
        case .comment:
            writtenReviewSection
        case .mediaAndSubmit:
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                photosSection
                verificationSection
            }
        }
    }

    private var providerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tcKey: "review_who", fallback: "Who are you reviewing?")
                .font(AppFont.title3)

            if let provider = viewModel.selectedProvider {
                VStack(spacing: AppSpacing.sm) {
                    ProviderMiniCard(provider: provider)
                    
                    Button {
                        viewModel.selectedProvider = nil
                        providerSearchText = ""
                        providerResults = []
                        specialtyResults = []
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                Text(tcKey: "review_change_provider", fallback: "Change provider")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(Color.tcOcean)
                        .cornerRadius(AppRadius.button)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("search_placeholder", text: $providerSearchText)
                        .font(AppFont.body)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 44)
                .background(Color.tcSurface)
                .cornerRadius(AppRadius.button)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.button)
                        .stroke(Color.tcBorder, lineWidth: 1)
                )

                if isSearchingProviders {
                    ProgressView()
                        .padding(.top, AppSpacing.xs)
                }

                if !providerSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        ForEach(providerResults.prefix(6)) { provider in
                            Button {
                                viewModel.selectProvider(provider)
                                providerSearchText = provider.name
                                providerResults = []
                                specialtyResults = []
                            } label: {
                                ProviderMiniRow(provider: provider)
                            }
                            .buttonStyle(.plain)
                        }

                        ForEach(specialtyResults.prefix(4)) { specialty in
                            Button {
                                providerSearchText = specialty.resolvedName(using: localizationManager)
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: specialty.iconName)
                                    Text(specialty.resolvedName(using: localizationManager))
                                        .font(AppFont.body)
                                    Spacer()
                                    Text(tcKey: "specialty_label", fallback: "Specialty")
                                        .font(AppFont.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(Color.tcSurface)
                    .cornerRadius(AppRadius.card)
                }

                Button {
                    showAddProviderSheet = true
                } label: {
                    Text(tcKey: "review_cant_find_add", fallback: "Can't find it? Add new")
                }
                .font(AppFont.caption)
                .foregroundStyle(Color.tcOcean)
            }
        }
    }

    private var visitDetailsSection: some View {
        let lang = localizationManager.effectiveLanguage
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tcKey: "review_visit_details", fallback: "Visit details")
                .font(AppFont.title3)

            DatePicker(tcString("review_visit_date", fallback: "Visit date"), selection: $viewModel.visitDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.compact)

            Picker(tcString("review_visit_type", fallback: "Visit type"), selection: $viewModel.visitType) {
                ForEach(ReviewVisitType.all) { type in
                    Text(type.label(for: lang)).tag(type.id)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var overallRatingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tcKey: "review_overall", fallback: "Overall")
                .font(AppFont.title3)
            Text(tcKey: "review_overall_question", fallback: "How was your overall experience?")
                .font(AppFont.caption)
                .foregroundStyle(.secondary)

            StarRatingInput(rating: $viewModel.overallRating, starSize: 40)
        }
    }

    private var detailedRatingsSection: some View {
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tcKey: "review_detailed", fallback: "Detailed ratings")
                .font(AppFont.title3)

            ForEach(RatingCriterion.all) { criterion in
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: criterion.icon)
                            .foregroundStyle(Color.tcOcean)
                        Text(LocalizedStringKey(criterion.labelKey))
                            .font(.system(size: 17, weight: .semibold))
                    }
                    Text(LocalizedStringKey(criterion.questionKey))
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)

                    StarRatingInput(
                        rating: Binding(
                            get: { viewModel.metricRatings[criterion.dbColumn] ?? 0 },
                            set: { viewModel.metricRatings[criterion.dbColumn] = $0 }
                        ),
                        starSize: 28
                    )
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var writtenReviewSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tcKey: "review_comment", fallback: "Write review")
                .font(AppFont.title3)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.comment)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color.tcSurface)
                    .cornerRadius(AppRadius.standard)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.standard)
                            .stroke(Color.tcBorder, lineWidth: 1)
                    )

                if viewModel.comment.isEmpty {
                    Text(tcKey: "review_comment_placeholder", fallback: "Share your experience in detail")
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 16)
                        .padding(.leading, 14)
                }
            }

            Text(String(format: tcString("review_char_count %lld", fallback: "%lld characters"), viewModel.commentCharCount))
                .font(AppFont.caption)
                .foregroundStyle(viewModel.commentCharCount >= 50 ? Color.tcSage : Color.tcCoral)
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tcKey: "review_add_photo", fallback: "Add photo")
                .font(AppFont.title3)

            PhotosPicker(selection: $photoItems, maxSelectionCount: 5, matching: .images) {
                Label(tcString("review_add_photo", fallback: "Add photo"), systemImage: "photo.on.rectangle")
                    .font(AppFont.body)
                    .padding(.vertical, 8)
                    .padding(.horizontal, AppSpacing.md)
                    .background(Color.tcSurface)
                    .cornerRadius(AppRadius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button)
                            .stroke(Color.tcBorder, lineWidth: 1)
                    )
            }

            if !viewModel.photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(Array(viewModel.photos.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 86, height: 86)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))

                                Button {
                                    viewModel.removePhoto(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white)
                                        .background(Color.black.opacity(0.4))
                                        .clipShape(Circle())
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                }
            }

            Text(tcKey: "review_photos_public", fallback: "Photos and videos are visible to everyone.")
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tcKey: "review_verify", fallback: "Verification")
                .font(AppFont.title3)
            Text(tcKey: "review_verify_hint", fallback: "Upload proof to improve trust.")
                .font(AppFont.caption)
                .foregroundStyle(.secondary)

            PhotosPicker(selection: $proofItem, matching: .images) {
                Label("review_upload_proof", systemImage: "doc.badge.plus")
                    .font(AppFont.body)
                    .padding(.vertical, 8)
                    .padding(.horizontal, AppSpacing.md)
                    .background(Color.tcSurface)
                    .cornerRadius(AppRadius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button)
                            .stroke(Color.tcBorder, lineWidth: 1)
                    )
            }

            if let proof = viewModel.proofImage {
                Image(uiImage: proof)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 140)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
            }

            Text(tcKey: "review_proof_private", fallback: "Proof stays private and is only used for verification.")
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)

            Button(tcString("review_skip_verification", fallback: "Skip verification")) {
                viewModel.proofImage = nil
            }
            .font(AppFont.caption)
            .foregroundStyle(Color.tcOcean)
        }
    }

    private var submitBar: some View {
        VStack(spacing: AppSpacing.xs) {
            if let error = viewModel.submissionErrorMessage {
                Text(error)
                    .font(AppFont.caption)
                    .foregroundStyle(Color.tcCoral)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if currentStep != .provider {
                Button {
                    if let previous = ReviewStep(rawValue: currentStep.rawValue - 1) {
                        currentStep = previous
                    }
                } label: {
                    Text(tcKey: "review_button_back", fallback: "Back")
                        .font(AppFont.body)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(Color.tcOcean)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.button)
                                .stroke(Color.tcOcean, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            if currentStep == .mediaAndSubmit {
                Button {
                    Task { await viewModel.submitReview() }
                } label: {
                    HStack {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(tcKey: "review_submit", fallback: "Submit review")
                            .font(AppFont.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
                .foregroundStyle(.white)
                .background(viewModel.canSubmit ? Color.tcOcean : Color.tcBorder)
                .cornerRadius(AppRadius.button)
            } else {
                Button {
                    if let next = ReviewStep(rawValue: currentStep.rawValue + 1), canGoNext {
                        currentStep = next
                    }
                } label: {
                    Text(tcKey: "review_button_next", fallback: "Next")
                        .font(AppFont.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .disabled(!canGoNext)
                .foregroundStyle(.white)
                .background(canGoNext ? Color.tcOcean : Color.tcBorder)
                .cornerRadius(AppRadius.button)

                if currentStep == .provider && !canGoNext {
                    Text(tcKey: "review_select_provider_to_continue", fallback: "Select a provider to continue")
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(Color.tcSurface)
    }

    private func routeToProviderDetailAfterSubmit() {
        guard let providerId = viewModel.lastSubmittedProviderID,
              let reviewId = viewModel.lastSubmittedReviewID else {
            viewModel.isComplete = false
            return
        }

        NotificationCenter.default.post(
            name: .trustCareReviewSubmitted,
            object: nil,
            userInfo: [
                "providerId": providerId,
                "reviewId": reviewId,
            ]
        )

        viewModel.isComplete = false

        if launchedFromProviderDetail {
            dismiss()
            return
        }

        NotificationCenter.default.post(name: .trustCareSwitchTab, object: 0)
        NotificationCenter.default.post(name: .trustCareRouteToProviderDetail, object: providerId)
    }

    private func searchProvidersAndSpecialties() async {
        let trimmed = providerSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            providerResults = []
            specialtyResults = []
            return
        }

        isSearchingProviders = true
        defer { isSearchingProviders = false }

        do {
            try await Task.sleep(nanoseconds: 300_000_000)
            providerResults = try await ProviderService.searchProvidersTable(query: trimmed, limit: 12)
        } catch {
            providerResults = []
        }

        let normalized = trimmed.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
        specialtyResults = specialtyService.specialties
            .filter { specialty in
                specialty.matchesSearch(normalized)
            }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items.prefix(5) {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        viewModel.photos = images
    }

    private func loadProof(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            viewModel.proofImage = image
        }
    }
}

private struct ProviderMiniCard: View {
    let provider: Provider
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            DynamicProviderAvatarView(provider: provider)
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(provider.name)
                    .font(AppFont.body)
                Text(localizedProviderSpecialty)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(Color.tcSurface)
        .cornerRadius(AppRadius.card)
    }

    private var localizedProviderSpecialty: String {
        guard let specialty = SpecialtyService.shared.specialties.first(where: {
            [
                $0.name,
                $0.nameTr,
                $0.nameDe,
                $0.namePl,
                $0.nameNl,
                $0.nameDa,
            ]
            .compactMap { $0 }
            .contains { $0.caseInsensitiveCompare(provider.specialty) == .orderedSame }
        }) else {
            return provider.specialty
        }

        return specialty.resolvedName(using: localizationManager)
    }
}

private struct ProviderMiniRow: View {
    let provider: Provider
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            DynamicProviderAvatarView(provider: provider)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(provider.name)
                    .font(AppFont.body)
                    .foregroundStyle(.primary)
                Text(localizedProviderSpecialty)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var localizedProviderSpecialty: String {
        guard let specialty = SpecialtyService.shared.specialties.first(where: {
            [
                $0.name,
                $0.nameTr,
                $0.nameDe,
                $0.namePl,
                $0.nameNl,
                $0.nameDa,
            ]
            .compactMap { $0 }
            .contains { $0.caseInsensitiveCompare(provider.specialty) == .orderedSame }
        }) else {
            return provider.specialty
        }

        return specialty.resolvedName(using: localizationManager)
    }
}
