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
                    Picker("report_reason", selection: $selectedReason) {
                        ForEach(ReportReason.allCases, id: \.self) { reason in
                                Text(LocalizedStringKey(reason.displayNameKey)).tag(reason)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("report_header")
                }
                
                Section {
                    TextField("report_optional_details", text: $details, axis: .vertical)
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
                    Text("report_additional_details")
                } footer: {
                    Text("report_footer")
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(AppFont.footnote)
                            .foregroundStyle(AppColor.error)
                    }
                }
            }
            .navigationTitle("report_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button_cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("button_submit") {
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
                        userInfo: ["message": "report_thank_you"]
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
