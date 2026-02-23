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
            .navigationTitle(currentStep == .success ? "" : "Claim Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if currentStep != .success {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
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
            .alert(String(localized: "Error"), isPresented: Binding(
                get: { claimVM.errorMessage != nil },
                set: { if !$0 { claimVM.errorMessage = nil } }
            )) {
                Button(String(localized: "OK")) { claimVM.errorMessage = nil }
            } message: {
                Text(claimVM.errorMessage ?? "")
            }
        }
    }
    
    private var roleStepView: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Step 1 of 3")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                
                Text("What is your role at this practice?")
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
                Text("Continue")
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
                Text("Step 2 of 3")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                
                Text("Upload verification document")
                    .font(AppFont.title2)
                    .fontWeight(.bold)
                
                Text("Accepted: Medical license, business registration, employment letter, or official ID with practice name")
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
                            Text("Remove")
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
                        
                        Text("Tap to upload document")
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.trustBlue)
                        
                        Text("JPG or PNG, max 1MB")
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
                    Text("Back")
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
                    Text("Continue")
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
                Text("Step 3 of 3")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                
                Text("Review & Submit")
                    .font(AppFont.title2)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.lg)
            
            VStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Provider")
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
                    Text("Your Role")
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
                        Text("Verification Document")
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
                Text("By submitting, you confirm that:")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                Text("• You are authorized to manage this profile")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                Text("• All information provided is accurate")
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
                    Text("Back")
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
                        Text("Submit Claim")
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
            
            Text("Claim Submitted!")
                .font(AppFont.title1)
                .fontWeight(.bold)
            
            Text("We'll review your claim within 1-3 business days. You'll be notified when it's approved.")
                .font(AppFont.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Back to Provider")
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
