import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Privacy Policy")
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
                    Text("TrustCare (\"we\", \"our\", \"us\") is committed to protecting your privacy. This policy explains how we collect, use, and safeguard your personal information.")
                        .font(.body)
                }
                
                Divider()
                
                // Information We Collect
                VStack(alignment: .leading, spacing: 12) {
                    Text("Information We Collect")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint("Account information: name, email, phone number")
                        BulletPoint("Review content: ratings, comments, photos")
                        BulletPoint("Verification documents: receipts, prescriptions (stored securely and only accessible by our verification team)")
                        BulletPoint("Device information: device type, operating system, app version")
                        BulletPoint("Location data: only when you grant permission, used to show nearby providers")
                    }
                }
                
                Divider()
                
                // How We Use Your Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("How We Use Your Information")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint("To provide and improve our services")
                        BulletPoint("To verify review authenticity")
                        BulletPoint("To communicate with you about your account and reviews")
                        BulletPoint("To detect and prevent fraud or abuse")
                    }
                }
                
                Divider()
                
                // Data Storage & Security
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Storage & Security")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint("All data is stored securely using Supabase infrastructure with encryption at rest and in transit")
                        BulletPoint("Verification documents are stored in private buckets accessible only to authorized personnel")
                        BulletPoint("We do not sell your personal data to third parties")
                    }
                }
                
                Divider()
                
                // Your Rights
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Rights")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint("Access: You can request a copy of your data at any time")
                        BulletPoint("Correction: You can update your profile information in the app")
                        BulletPoint("Deletion: You can request account deletion by contacting support@trustcare.app")
                        BulletPoint("Portability: You can request your data in a machine-readable format")
                    }
                }
                
                Divider()
                
                // Data Retention
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Retention")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint("Account data is retained as long as your account is active")
                        BulletPoint("Verification documents are deleted 90 days after review verification")
                        BulletPoint("You can request immediate deletion at any time")
                    }
                }
                
                Divider()
                
                // Contact
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("For privacy inquiries: privacy@trustcare.app")
                        .font(.body)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

private struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("•")
                .foregroundStyle(AppColor.trustBlue)
            
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(nil)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
