import SwiftUI

struct ReportReviewSheet: View {
    let reviewId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason = .spam
    @State private var details: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?
    var onReported: () -> Void
    
    private let maxDetailsLength = 500
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Reason", selection: $selectedReason) {
                        ForEach(ReportReason.allCases, id: \.self) { reason in
                            Text(reason.displayName).tag(reason)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Why are you reporting this review?")
                }
                
                Section {
                    TextField("Optional details", text: $details, axis: .vertical)
                        .lineLimit(4...8)
                        .onChange(of: details) { _, newValue in
                            if newValue.count > maxDetailsLength {
                                details = String(newValue.prefix(maxDetailsLength))
                            }
                        }
                    Text("\(details.count)/\(maxDetailsLength)")
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } header: {
                    Text("Additional details (optional)")
                } footer: {
                    Text("Please provide any additional context that might help us review this report.")
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(AppFont.footnote)
                            .foregroundStyle(AppColor.error)
                    }
                }
            }
            .navigationTitle("Report Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
    
    private func submitReport() {
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                try await ReviewService.reportReview(
                    reviewId: reviewId,
                    reason: selectedReason,
                    description: details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : details
                )
                
                await MainActor.run {
                    onReported()
                    dismiss()
                    
                    // Show success toast
                    NotificationCenter.default.post(
                        name: .showToast,
                        object: nil,
                        userInfo: ["message": String(localized: "Thank you. We'll review this report.")]
                    )
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

extension Notification.Name {
    static let showToast = Notification.Name("showToast")
}
