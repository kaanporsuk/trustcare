import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    termsSection(
                        title: "Hizmet Tanımı",
                        bullets: [
                            "TrustCare, sağlık hizmeti sağlayıcı deneyimlerini paylaşma ve keşfetme platformudur.",
                            "Sunulan bilgiler bilgilendirme amaçlıdır."
                        ]
                    )

                    termsSection(
                        title: "Kullanıcı Yükümlülükleri",
                        bullets: [
                            "Doğru ve güncel hesap bilgisi sağlamak.",
                            "Hesap güvenliğini korumak.",
                            "Platformu hukuka ve etik kurallara uygun kullanmak."
                        ]
                    )

                    termsSection(
                        title: "Değerlendirme Kuralları",
                        bullets: [
                            "Yorumlar gerçek deneyime dayanmalıdır.",
                            "Hakaret, yanıltıcı ve manipülatif içerik yasaktır.",
                            "Doğrulama belgelerinde sahtecilik hesap kapatma sebebidir."
                        ]
                    )

                    termsSection(
                        title: "TrustCare Rehber Sorumluluk Reddi",
                        bullets: [
                            "TrustCare Rehber bir teşhis, reçete veya tedavi hizmeti değildir.",
                            "Sadece uygun uzmanlık alanına yönlendirme yapar.",
                            "Acil durumlarda kullanıcı 112'ye yönlendirilir."
                        ]
                    )

                    termsSection(
                        title: "Fikri Mülkiyet",
                        bullets: [
                            "Uygulama içeriği, marka ve yazılım hakları TrustCare'e aittir.",
                            "İzinsiz çoğaltma ve ticari kullanım yasaktır."
                        ]
                    )

                    termsSection(
                        title: "Hesap Sonlandırma",
                        bullets: [
                            "Kullanıcı hesabını ayarlardan silme talebi oluşturabilir.",
                            "Kural ihlali durumunda TrustCare hesabı askıya alabilir veya sonlandırabilir."
                        ]
                    )

                    termsSection(
                        title: "Uyuşmazlık Çözümü",
                        bullets: [
                            "Uyuşmazlıklarda öncelikle dostane çözüm hedeflenir.",
                            "Çözüm sağlanamazsa Türkiye Cumhuriyeti mevzuatı uygulanır."
                        ]
                    )

                    termsSection(
                        title: "İletişim Bilgileri",
                        bullets: [
                            "E-posta: legal@trustcare.app",
                            "Destek: support@trustcare.app"
                        ]
                    )
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.lg)
            }
            .navigationTitle("Kullanım Koşulları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
        }
    }

    private func termsSection(title: String, bullets: [String]) -> some View {
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
