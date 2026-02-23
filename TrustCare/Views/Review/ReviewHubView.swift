import PhotosUI
import SwiftUI
import UIKit

struct ReviewHubView: View {
    @StateObject private var viewModel = ReviewSubmissionViewModel()
    @ObservedObject private var specialtyService = SpecialtyService.shared
    @EnvironmentObject private var localizationManager: LocalizationManager

    @State private var providerSearchText: String = ""
    @State private var providerResults: [Provider] = []
    @State private var specialtyResults: [Specialty] = []
    @State private var isSearchingProviders: Bool = false
    @State private var showAddProviderSheet: Bool = false
    @State private var showProofPicker: Bool = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var proofItem: PhotosPickerItem?

    init(initialProvider: Provider? = nil) {
        _viewModel = StateObject(wrappedValue: ReviewSubmissionViewModel(provider: initialProvider))
        _providerSearchText = State(initialValue: initialProvider?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    providerSection
                    visitDetailsSection
                    overallRatingSection
                    detailedRatingsSection
                    writtenReviewSection
                    photosSection
                    verificationSection
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxxl)
            }
            .navigationTitle(String(localized: "tab_review"))
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
                    onAnotherReview: {
                        viewModel.resetForm(keepProvider: false)
                        providerSearchText = ""
                    },
                    onGoHome: {
                        viewModel.isComplete = false
                        NotificationCenter.default.post(name: .trustCareSwitchTab, object: 0)
                    }
                )
            }
            .safeAreaInset(edge: .bottom) {
                submitBar
            }
        }
    }

    private var providerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(String(localized: "review_who"))
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
                            Text(String(localized: "review_change_provider"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(AppColor.trustBlue)
                        .cornerRadius(AppRadius.button)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField(String(localized: "search_placeholder"), text: $providerSearchText)
                        .font(AppFont.body)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 44)
                .background(AppColor.cardBackground)
                .cornerRadius(AppRadius.button)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.button)
                        .stroke(AppColor.border, lineWidth: 1)
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
                                    Text("Uzmanlık")
                                        .font(AppFont.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColor.cardBackground)
                    .cornerRadius(AppRadius.card)
                }

                Button("Bulamadınız mı? Yeni ekle") {
                    showAddProviderSheet = true
                }
                .font(AppFont.caption)
                .foregroundStyle(AppColor.trustBlue)
            }
        }
    }

    private var visitDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Ziyaret Detayları")
                .font(AppFont.title3)

            DatePicker(String(localized: "review_visit_date"), selection: $viewModel.visitDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.compact)

            Picker("Ziyaret Türü", selection: $viewModel.visitType) {
                Text("Muayene").tag("Muayene")
                Text("İşlem").tag("İşlem")
                Text("Kontrol").tag("Kontrol")
                Text("Acil").tag("Acil")
            }
            .pickerStyle(.segmented)
        }
    }

    private var overallRatingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(String(localized: "review_overall"))
                .font(AppFont.title3)
            Text("Genel deneyiminiz nasıldı?")
                .font(AppFont.caption)
                .foregroundStyle(.secondary)

            StarRatingInput(rating: $viewModel.overallRating, starSize: 40)
        }
    }

    private var detailedRatingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(String(localized: "review_detailed"))
                .font(AppFont.title3)

            ForEach(viewModel.surveyConfig.metrics) { metric in
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: metric.icon)
                            .foregroundStyle(AppColor.trustBlue)
                        Text(metric.label)
                            .font(.system(size: 17, weight: .semibold))
                    }
                    Text(metric.subtext)
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)

                    StarRatingInput(
                        rating: Binding(
                            get: { viewModel.metricRatings[metric.dbColumn] ?? 0 },
                            set: { viewModel.metricRatings[metric.dbColumn] = $0 }
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
            Text(String(localized: "review_comment"))
                .font(AppFont.title3)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.comment)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(AppColor.cardBackground)
                    .cornerRadius(AppRadius.standard)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.standard)
                            .stroke(AppColor.border, lineWidth: 1)
                    )

                if viewModel.comment.isEmpty {
                    Text("Deneyiminizi paylaşın... (en az 50 karakter)")
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 16)
                        .padding(.leading, 14)
                }
            }

            Text("\(viewModel.commentCharCount)/50 minimum")
                .font(AppFont.caption)
                .foregroundStyle(viewModel.commentCharCount >= 50 ? AppColor.success : AppColor.error)
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(String(localized: "review_add_photo"))
                .font(AppFont.title3)

            PhotosPicker(selection: $photoItems, maxSelectionCount: 5, matching: .images) {
                Label(String(localized: "review_add_photo"), systemImage: "photo.on.rectangle")
                    .font(AppFont.body)
                    .padding(.vertical, 8)
                    .padding(.horizontal, AppSpacing.md)
                    .background(AppColor.cardBackground)
                    .cornerRadius(AppRadius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button)
                            .stroke(AppColor.border, lineWidth: 1)
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

            Text("Fotoğraflar herkes tarafından görülebilir")
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(String(localized: "review_verify"))
                .font(AppFont.title3)
            Text("Fatura, reçete veya randevu onayı yükleyin")
                .font(AppFont.caption)
                .foregroundStyle(.secondary)

            PhotosPicker(selection: $proofItem, matching: .images) {
                Label("Doğrulama Belgesi Yükle", systemImage: "doc.badge.plus")
                    .font(AppFont.body)
                    .padding(.vertical, 8)
                    .padding(.horizontal, AppSpacing.md)
                    .background(AppColor.cardBackground)
                    .cornerRadius(AppRadius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button)
                            .stroke(AppColor.border, lineWidth: 1)
                    )
            }

            if let proof = viewModel.proofImage {
                Image(uiImage: proof)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 140)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
            }

            Text("Sadece doğrulama sistemimiz tarafından görülür")
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)

            Button("Doğrulamayı Atla") {
                viewModel.proofImage = nil
            }
            .font(AppFont.caption)
            .foregroundStyle(AppColor.trustBlue)
        }
    }

    private var submitBar: some View {
        VStack(spacing: AppSpacing.xs) {
            if let error = viewModel.submissionErrorMessage {
                Text(error)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                Task { await viewModel.submitReview() }
            } label: {
                HStack {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(String(localized: "review_submit"))
                        .font(AppFont.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
            .foregroundStyle(.white)
            .background(viewModel.canSubmit ? AppColor.trustBlue : AppColor.border)
            .cornerRadius(AppRadius.button)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(AppColor.cardBackground)
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
        .background(AppColor.cardBackground)
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
