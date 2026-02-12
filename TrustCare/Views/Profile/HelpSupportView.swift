import SwiftUI
import MessageUI

struct HelpSupportView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Help & Support")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColor.trustBlue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Getting Started Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Getting Started")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    FAQItem(
                        question: "How do I find a doctor?",
                        answer: "Use the Find tab to search by name, specialty, or location. You can filter results and view providers on a map."
                    )
                    
                    FAQItem(
                        question: "How do I write a review?",
                        answer: "Tap the Review tab, search for your provider, rate your experience across key criteria, and submit. You can optionally verify your visit with proof."
                    )
                }
                
                Divider()
                
                // Reviews & Verification Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Reviews & Verification")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    FAQItem(
                        question: "What counts as proof of visit?",
                        answer: "Receipts, prescriptions, appointment confirmations, or medical reports. Photos are reviewed by our team and are never shared publicly."
                    )
                    
                    FAQItem(
                        question: "How long does verification take?",
                        answer: "Most reviews are verified within 24-48 hours. You'll receive a notification when your review is verified."
                    )
                    
                    FAQItem(
                        question: "Can I edit my review?",
                        answer: "You can edit reviews that are still in \"pending\" status. Once verified, reviews cannot be edited."
                    )
                }
                
                Divider()
                
                // Account Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    FAQItem(
                        question: "How do I change my password?",
                        answer: "Go to Profile > Settings > Change Password."
                    )
                    
                    FAQItem(
                        question: "How do I delete my account?",
                        answer: "Contact us at support@trustcare.app. We will process your request within 30 days per GDPR/KVKK requirements."
                    )
                }
                
                Divider()
                
                // Contact Us Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Contact Us")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Email:")
                                .fontWeight(.semibold)
                            Text("support@trustcare.app")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Response time:")
                                .fontWeight(.semibold)
                            Text("Within 48 hours")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.body)
                    
                    Button(action: { sendFeedback() }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Send Feedback")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(AppColor.trustBlue)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
    
    private func sendFeedback() {
        UIPasteboard.general.string = "support@trustcare.app"
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

private struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Q: \(question)")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(nil)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(AppColor.trustBlue)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Text("A: \(answer)")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        HelpSupportView()
    }
}
