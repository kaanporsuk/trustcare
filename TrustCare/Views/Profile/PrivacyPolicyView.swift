import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    policySection(
                        title: "Veri Toplama",
                        bullets: [
                            "Hesap verileri: ad, e-posta, telefon.",
                            "Kullanım verileri: uygulama etkileşimleri ve temel cihaz bilgileri.",
                            "İçerik verileri: değerlendirmeler, puanlar, yüklenen görseller.",
                            "Konum verisi: yalnızca izin verdiğinizde yakın sağlayıcı göstermek için."
                        ]
                    )

                    policySection(
                        title: "Veri Kullanımı",
                        bullets: [
                            "Hizmetin sunulması ve iyileştirilmesi.",
                            "Değerlendirme doğrulama süreçlerinin işletilmesi.",
                            "Güvenlik, kötüye kullanım önleme ve kullanıcı desteği."
                        ]
                    )

                    policySection(
                        title: "Veri Paylaşımı (3. Taraflar)",
                        bullets: [
                            "Yasal yükümlülükler kapsamında yetkili kurumlarla.",
                            "Altyapı hizmet sağlayıcılarıyla (barındırma, güvenlik, analiz) yalnızca gerekli kapsamda.",
                            "Açık rızanız olmadan kişisel veriler ticari amaçla satılmaz."
                        ]
                    )

                    policySection(
                        title: "KVKK Hakları",
                        bullets: [
                            "Erişim hakkı",
                            "Düzeltme hakkı",
                            "Silme hakkı",
                            "İtiraz hakkı"
                        ]
                    )

                    policySection(
                        title: "Çerezler ve İzleme",
                        bullets: [
                            "Uygulama performansı ve güvenliği için sınırlı teknik izleme kullanılabilir.",
                            "Tercih ayarları cihazınızda saklanır.",
                            "Analitik izleme tercihleriniz ayarlardan yönetilebilir."
                        ]
                    )

                    policySection(
                        title: "Veri Güvenliği",
                        bullets: [
                            "Veriler aktarım ve depolama sırasında şifrelenir.",
                            "Erişim kontrolleri ve kayıt mekanizmaları uygulanır.",
                            "Düzenli güvenlik iyileştirmeleri yapılır."
                        ]
                    )

                    policySection(
                        title: "İletişim Bilgileri",
                        bullets: [
                            "E-posta: privacy@trustcare.app",
                            "Destek: support@trustcare.app"
                        ]
                    )

                    Text("Son güncelleme: 22 Şubat 2026")
                        .font(AppFont.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, AppSpacing.sm)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.lg)
            }
            .navigationTitle("Gizlilik Politikası")
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
