import SwiftUI

struct HelpSupportView: View {
    @Environment(\.openURL) private var openURL

    private let faqItems: [(question: String, answer: String)] = [
        (
            "TrustCare nedir?",
            "TrustCare, doğrulanmış hasta deneyimlerine dayalı sağlık hizmeti sağlayıcı değerlendirme platformudur."
        ),
        (
            "Değerlendirmeler nasıl doğrulanır?",
            "Ziyaret kanıtı (fatura, reçete, randevu onayı) yükleyerek değerlendirmenizi doğrulayabilirsiniz."
        ),
        (
            "TrustCare Rehber nedir?",
            "Belirtilerinize göre doğru uzmanlık alanını öneren bir bilgilendirme hizmetidir. Tıbbi teşhis değildir."
        ),
        (
            "Verilerim güvende mi?",
            "Evet. KVKK uyumlu altyapımız ile kişisel verileriniz şifrelenerek saklanır."
        ),
        (
            "Bir sağlık sağlayıcıyı nasıl eklerim?",
            "Değerlendirme sekmesinde \"Bulamadınız mı? Yeni ekle\" seçeneğini kullanabilirsiniz."
        ),
        (
            "Değerlendirmemi düzenleyebilir miyim?",
            "İlk 24 saat içinde değerlendirmelerinizi düzenleyebilirsiniz."
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Sık Sorulan Sorular")
                    .font(AppFont.title2)
                    .foregroundStyle(AppColor.trustBlue)

                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array(faqItems.enumerated()), id: \.offset) { _, item in
                        DisclosureGroup {
                            Text(item.answer)
                                .font(AppFont.body)
                                .foregroundStyle(.secondary)
                                .padding(.top, AppSpacing.xs)
                        } label: {
                            Text(item.question)
                                .font(AppFont.headline)
                                .foregroundStyle(.primary)
                        }
                        .padding(AppSpacing.md)
                        .background(AppColor.cardBackground)
                        .cornerRadius(AppRadius.card)
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("İletişim")
                        .font(AppFont.title3)

                    HStack {
                        Text("Email:")
                            .font(AppFont.body)
                        Text("support@trustcare.app")
                            .font(AppFont.body)
                            .foregroundStyle(.secondary)
                    }

                    Button("Sorun Bildir") {
                        if let url = URL(string: "mailto:support@trustcare.app?subject=TrustCare%20Destek") {
                            openURL(url)
                        }
                    }
                    .font(AppFont.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColor.trustBlue)
                    .cornerRadius(AppRadius.button)
                }
                .padding(AppSpacing.md)
                .background(AppColor.cardBackground)
                .cornerRadius(AppRadius.card)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .navigationTitle("Yardım ve Destek")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
