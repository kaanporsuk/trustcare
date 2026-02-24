import PhotosUI
import SwiftUI

struct ClaimProviderView: View {
    let providerId: UUID
    let providerName: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var claimVM = ClaimViewModel()
    @State private var selectedItem: PhotosPickerItem?
    @State private var currentStep: ClaimStep = .role

    enum ClaimStep {
        case role, document, confirmation, success
    }

    var body: some View {
        NavigationStack {
            Group {
                switch currentStep {
                case .role:
                    roleStepView
                case .document:
                    documentStepView
                case .confirmation:
                    confirmationStepView
                case .success:
                    successView
                }
            }
            .navigationTitle(currentStep == .success ? "" : String(localized: "claim_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if currentStep != .success {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("button_cancel") { dismiss() }
                    }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    do {
                        if let data = try await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            claimVM.proofImage = image
                        }
                    } catch {
                        claimVM.errorMessage = String(localized: "Unable to load image. Please try again.")
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { claimVM.errorMessage != nil },
                set: { if !$0 { claimVM.errorMessage = nil } }
            )) {
                Button("OK") { claimVM.errorMessage = nil }
            } message: {
                Text(claimVM.errorMessage ?? "")
            }
        }
    }
    
    private var roleStepView: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("claim_step_1_of_3")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                
                Text("claim_role_question")
                    .font(AppFont.title2)
                    .fontWeight(.bold)
                
                Text(providerName)
                    .font(AppFont.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.lg)
            
            VStack(spacing: AppSpacing.sm) {
                ForEach([ClaimRole.owner, .manager, .representative], id: \.self) { role in
                    Button {
                        claimVM.role = role
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(role.displayName)
                                    .font(AppFont.body)
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            if claimVM.role == role {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppColor.trustBlue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(AppSpacing.md)
                        .background(claimVM.role == role ? AppColor.trustBlue.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(AppRadius.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.card)
                                .stroke(claimVM.role == role ? AppColor.trustBlue : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            
            Spacer()
            
            Button {
                currentStep = .document
            } label: {
                Text("button_continue")
                    .font(AppFont.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColor.trustBlue)
                    .cornerRadius(AppRadius.button)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
    }
    
    private var documentStepView: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("claim_step_2_of_3")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                
                Text("claim_upload_doc")
                    .font(AppFont.title2)
                    .fontWeight(.bold)
                
                Text("claim_accepted_docs")
                    .font(AppFont.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.lg)
            
            if let image = claimVM.proofImage {
                VStack(spacing: AppSpacing.sm) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(AppRadius.card)
                    
                    Button {
                        claimVM.proofImage = nil
                        selectedItem = nil
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("button_remove")
                        }
                        .font(AppFont.footnote)
                        .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            } else {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(AppColor.trustBlue)
                        
                        Text("claim_tap_upload")
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.trustBlue)
                        
                        Text("claim_file_format")
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xxl)
                    .background(AppColor.trustBlue.opacity(0.1))
                    .cornerRadius(AppRadius.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.card)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundStyle(AppColor.trustBlue.opacity(0.3))
                    )
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            
            Spacer()
            
            HStack(spacing: AppSpacing.sm) {
                Button {
                    currentStep = .role
                } label: {
                    Text("button_back")
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.trustBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .cornerRadius(AppRadius.button)
                }
                
                Button {
                    currentStep = .confirmation
                } label: {
                    Text("button_continue")
                        .font(AppFont.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(claimVM.proofImage != nil ? AppColor.trustBlue : Color.gray)
                        .cornerRadius(AppRadius.button)
                }
                .disabled(claimVM.proofImage == nil)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
    }
    
    private var confirmationStepView: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("claim_step_3_of_3")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                
                Text("claim_review_submit")
                    .font(AppFont.title2)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.lg)
            
            VStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("claim_provider_label")
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                    Text(providerName)
                        .font(AppFont.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.md)
                .background(Color(.systemGray6))
                .cornerRadius(AppRadius.card)
                
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("claim_your_role")
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                    Text(claimVM.role.displayName)
                        .font(AppFont.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.md)
                .background(Color(.systemGray6))
                .cornerRadius(AppRadius.card)
                
                if let image = claimVM.proofImage {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("claim_verification_doc")
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .cornerRadius(AppRadius.button)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.md)
                    .background(Color(.systemGray6))
                    .cornerRadius(AppRadius.card)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("claim_confirm_text")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                Text("claim_confirm_1")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                Text("claim_confirm_2")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.lg)
            
            Spacer()
            
            HStack(spacing: AppSpacing.sm) {
                Button {
                    currentStep = .document
                } label: {
                    Text("button_back")
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.trustBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .cornerRadius(AppRadius.button)
                }
                .disabled(claimVM.isLoading)
                
                Button {
                    Task {
                        await claimVM.submit(providerId: providerId)
                        if claimVM.isSubmitted {
                            currentStep = .success
                        }
                    }
                } label: {
                    if claimVM.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("claim_submit")
                            .font(AppFont.headline)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(claimVM.isLoading ? Color.gray : AppColor.trustBlue)
                .cornerRadius(AppRadius.button)
                .disabled(claimVM.isLoading)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
    }
    
    private var successView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("claim_submitted")
                .font(AppFont.title1)
                .fontWeight(.bold)
            
            Text("claim_submitted_message")
                .font(AppFont.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("claim_back_to_provider")
                    .font(AppFont.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColor.trustBlue)
                    .cornerRadius(AppRadius.button)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
    }
}
