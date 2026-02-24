import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    policySection(
                        title: "pp_data_collection_title",
                        bullets: [
                            "pp_data_collection_1",
                            "pp_data_collection_2",
                            "pp_data_collection_3",
                            "pp_data_collection_4"
                        ]
                    )

                    policySection(
                        title: "pp_data_usage_title",
                        bullets: [
                            "pp_data_usage_1",
                            "pp_data_usage_2",
                            "pp_data_usage_3"
                        ]
                    )

                    policySection(
                        title: "pp_data_sharing_title",
                        bullets: [
                            "pp_data_sharing_1",
                            "pp_data_sharing_2",
                            "pp_data_sharing_3"
                        ]
                    )

                    policySection(
                        title: "pp_rights_title",
                        bullets: [
                            "pp_rights_1",
                            "pp_rights_2",
                            "pp_rights_3",
                            "pp_rights_4"
                        ]
                    )

                    policySection(
                        title: "pp_cookies_title",
                        bullets: [
                            "pp_cookies_1",
                            "pp_cookies_2",
                            "pp_cookies_3"
                        ]
                    )

                    policySection(
                        title: "pp_security_title",
                        bullets: [
                            "pp_security_1",
                            "pp_security_2",
                            "pp_security_3"
                        ]
                    )

                    policySection(
                        title: "pp_contact_title",
                        bullets: [
                            "pp_contact_1",
                            "pp_contact_2"
                        ]
                    )

                    Text("pp_last_updated")
                        .font(AppFont.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, AppSpacing.sm)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.lg)
            }
            .navigationTitle("menu_privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
        }
    }

    private func policySection(title: String, bullets: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFont.title3)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(bullets, id: \.self) { line in
                    HStack(alignment: .top, spacing: AppSpacing.xs) {
                        Text("•")
                            .foregroundStyle(AppColor.trustBlue)
                        Text(line)
                            .font(AppFont.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
    }
}
