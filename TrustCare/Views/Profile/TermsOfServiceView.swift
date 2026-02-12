import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Terms of Service")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColor.trustBlue)
                    
                    Text("Last Updated: February 2026")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Introduction
                VStack(alignment: .leading, spacing: 12) {
                    Text("Welcome to TrustCare. By using our app, you agree to these terms.")
                        .font(.body)
                }
                
                Divider()
                
                // 1. Acceptance of Terms
                TermsSection(
                    number: 1,
                    title: "Acceptance of Terms",
                    content: "By creating an account or using TrustCare, you agree to be bound by these Terms of Service and our Privacy Policy."
                )
                
                Divider()
                
                // 2. User Accounts
                TermsSection(
                    number: 2,
                    title: "User Accounts",
                    bulletPoints: [
                        "You must provide accurate information when creating an account",
                        "You are responsible for maintaining the security of your account",
                        "You must be at least 18 years old to use TrustCare"
                    ]
                )
                
                Divider()
                
                // 3. Reviews & Content
                TermsSection(
                    number: 3,
                    title: "Reviews & Content",
                    bulletPoints: [
                        "Reviews must be based on genuine personal healthcare experiences",
                        "You must not post false, misleading, or defamatory content",
                        "You must not post reviews for providers you have not visited",
                        "Submitting fraudulent verification documents is strictly prohibited and may result in permanent account suspension",
                        "We reserve the right to remove reviews that violate these terms"
                    ]
                )
                
                Divider()
                
                // 4. Verification
                TermsSection(
                    number: 4,
                    title: "Verification",
                    bulletPoints: [
                        "Verification documents are used solely to confirm visit authenticity",
                        "Documents are reviewed by authorized personnel only",
                        "Verified reviews carry a verification badge visible to other users"
                    ]
                )
                
                Divider()
                
                // 5. Provider Information
                TermsSection(
                    number: 5,
                    title: "Provider Information",
                    bulletPoints: [
                        "Provider listings may be submitted by users and are not independently verified by TrustCare unless marked as such",
                        "We do not guarantee the accuracy of provider information",
                        "Providers can claim their profiles by contacting us"
                    ]
                )
                
                Divider()
                
                // 6. Prohibited Conduct
                TermsSection(
                    number: 6,
                    title: "Prohibited Conduct",
                    bulletPoints: [
                        "Harassment or abuse of other users or providers",
                        "Spam or automated review submission",
                        "Attempting to manipulate ratings or reviews",
                        "Reverse engineering or scraping app data"
                    ]
                )
                
                Divider()
                
                // 7. Limitation of Liability
                TermsSection(
                    number: 7,
                    title: "Limitation of Liability",
                    content: "TrustCare provides information for general guidance only. We are not a medical advice service. Always consult qualified healthcare professionals for medical decisions."
                )
                
                Divider()
                
                // 8. Changes to Terms
                TermsSection(
                    number: 8,
                    title: "Changes to Terms",
                    content: "We may update these terms from time to time. Continued use of the app constitutes acceptance of updated terms."
                )
                
                Divider()
                
                // 9. Contact
                TermsSection(
                    number: 9,
                    title: "Contact",
                    content: "For questions about these terms: legal@trustcare.app"
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

private struct TermsSection: View {
    let number: Int
    let title: String
    let content: String?
    let bulletPoints: [String]?
    
    init(number: Int, title: String, content: String) {
        self.number = number
        self.title = title
        self.content = content
        self.bulletPoints = nil
    }
    
    init(number: Int, title: String, bulletPoints: [String]) {
        self.number = number
        self.title = title
        self.content = nil
        self.bulletPoints = bulletPoints
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(number). \(title)")
                .font(.title3)
                .fontWeight(.semibold)
            
            if let content = content {
                Text(content)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
            }
            
            if let bulletPoints = bulletPoints {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(bulletPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 12) {
                            Text("•")
                                .foregroundStyle(AppColor.trustBlue)
                            
                            Text(point)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(nil)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}
