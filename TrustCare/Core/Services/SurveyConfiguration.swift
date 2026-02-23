import Foundation

struct SurveyMetric: Identifiable {
    let id = UUID()
    let label: String
    let subtext: String
    let dbColumn: String
    let icon: String
}

struct SurveyConfig {
    let type: String
    let displayName: String
    let metrics: [SurveyMetric]
}

enum SurveyConfigurations {

    static func config(for surveyType: String) -> SurveyConfig {
        let baseConfig: SurveyConfig
        switch surveyType {
        case "general_clinic": baseConfig = generalClinic
        case "dental": baseConfig = dental
        case "pharmacy": baseConfig = pharmacy
        case "hospital": baseConfig = hospital
        case "diagnostic": baseConfig = diagnostic
        case "mental_health": baseConfig = mentalHealth
        case "rehabilitation": baseConfig = rehabilitation
        case "aesthetics": baseConfig = aesthetics
        default: baseConfig = generalClinic
        }

        return SurveyConfig(
            type: baseConfig.type,
            displayName: localized("survey.\(baseConfig.type).display_name", fallback: baseConfig.displayName),
            metrics: baseConfig.metrics.map { metric in
                SurveyMetric(
                    label: localized("survey.\(baseConfig.type).\(metric.dbColumn).label", fallback: metric.label),
                    subtext: localized("survey.\(baseConfig.type).\(metric.dbColumn).subtext", fallback: metric.subtext),
                    dbColumn: metric.dbColumn,
                    icon: metric.icon
                )
            }
        )
    }

    private static func localized(_ key: String, fallback: String) -> String {
        let languageCode = UserDefaults.standard.string(forKey: "appLanguage") ?? LocalizationManager.detectSystemLanguage()
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return fallback
        }

        let localizedValue = NSLocalizedString(key, tableName: "Localizable", bundle: bundle, value: fallback, comment: "")
        return localizedValue.isEmpty ? fallback : localizedValue
    }

    static let generalClinic = SurveyConfig(
        type: "general_clinic",
        displayName: "General Clinic",
        metrics: [
            SurveyMetric(
                label: "Bekleme Süresi",
                subtext: "Randevu saatinizden sonra ne kadar beklediniz?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Doktor Tutumu",
                subtext: "Doktor sizi dinledi ve açıklamalar yaptı mı?",
                dbColumn: "rating_bedside",
                icon: "heart"
            ),
            SurveyMetric(
                label: "Tedavi Etkinliği",
                subtext: "Tedavi sorununuzu çözdü mü?",
                dbColumn: "rating_efficacy",
                icon: "cross.case"
            ),
            SurveyMetric(
                label: "Klinik Hijyeni",
                subtext: "Klinik temiz ve hijyenik miydi?",
                dbColumn: "rating_cleanliness",
                icon: "sparkles"
            )
        ]
    )

    static let dental = SurveyConfig(
        type: "dental",
        displayName: "Dental",
        metrics: [
            SurveyMetric(
                label: "Bekleme Süresi",
                subtext: "Ne kadar hızlı oturtulan dindiniz?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Ağrı Yönetimi",
                subtext: "Ağrıyı ne kadar iyi kontrol ettiler?",
                dbColumn: "rating_pain_mgmt",
                icon: "bolt.heart"
            ),
            SurveyMetric(
                label: "Doktor Tutumu",
                subtext: "Diş hekimi açık bir şekilde iletişim kurdu mu?",
                dbColumn: "rating_bedside",
                icon: "heart"
            ),
            SurveyMetric(
                label: "Klinik Hijyeni",
                subtext: "Tedavi odaları ve ekipman temiz miydi?",
                dbColumn: "rating_cleanliness",
                icon: "sparkles"
            )
        ]
    )

    static let pharmacy = SurveyConfig(
        type: "pharmacy",
        displayName: "Pharmacy",
        metrics: [
            SurveyMetric(
                label: "Hız",
                subtext: "Ne kadar hızlı hizmet aldınız?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Doğruluk ve Özen",
                subtext: "Reçeteniz doğru hazırlandı mı?",
                dbColumn: "rating_accuracy",
                icon: "checkmark.shield"
            ),
            SurveyMetric(
                label: "Eczacı Bilgisi",
                subtext: "Eczacı sorularınızı iyi yanıtladı mı?",
                dbColumn: "rating_knowledge",
                icon: "brain"
            ),
            SurveyMetric(
                label: "Personel Nezaketi",
                subtext: "Personel kibar mıydı?",
                dbColumn: "rating_courtesy",
                icon: "face.smiling"
            )
        ]
    )

    static let hospital = SurveyConfig(
        type: "hospital",
        displayName: "Hospital",
        metrics: [
            SurveyMetric(
                label: "Bekleme Süresi",
                subtext: "Doktor tarafından ne kadar hızlı görüldünüz?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Bakım Kalitesi",
                subtext: "Tıbbi bakımı nasıl değerlendirirsiniz?",
                dbColumn: "rating_care_quality",
                icon: "heart.text.square"
            ),
            SurveyMetric(
                label: "İdari Verimlilik",
                subtext: "Yatış ve taburcu işlemleri sorunsuz geçti mi?",
                dbColumn: "rating_admin",
                icon: "doc.text"
            ),
            SurveyMetric(
                label: "Odaların Hijyeni",
                subtext: "Odalar ve alanlar temiz miydi?",
                dbColumn: "rating_cleanliness",
                icon: "sparkles"
            )
        ]
    )

    static let diagnostic = SurveyConfig(
        type: "diagnostic",
        displayName: "Diagnostic Center",
        metrics: [
            SurveyMetric(
                label: "Bekleme Süresi",
                subtext: "Testiniz için ne kadar hızlı çağrıldınız?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Işlem Konforu",
                subtext: "Personel işlemi rahat yaptı mı?",
                dbColumn: "rating_comfort",
                icon: "hand.raised"
            ),
            SurveyMetric(
                label: "Sonuç Hızı",
                subtext: "Sonuçlar zamanında verildi mi?",
                dbColumn: "rating_turnaround",
                icon: "timer"
            ),
            SurveyMetric(
                label: "Tessis Hijyeni",
                subtext: "Tesis temiz ve hijyenik miydi?",
                dbColumn: "rating_cleanliness",
                icon: "sparkles"
            )
        ]
    )

    static let mentalHealth = SurveyConfig(
        type: "mental_health",
        displayName: "Mental Health",
        metrics: [
            SurveyMetric(
                label: "Zamanında Başlama",
                subtext: "Seansınız zamanında başladı mı?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Empati & Dinleme",
                subtext: "Sizi gerçekten duydunuz mu?",
                dbColumn: "rating_empathy",
                icon: "heart.circle"
            ),
            SurveyMetric(
                label: "Ortam Konforu",
                subtext: "Ofis huzlu ve özel miydi?",
                dbColumn: "rating_environment",
                icon: "leaf"
            ),
            SurveyMetric(
                label: "İletişim Açıklığı",
                subtext: "Tedavi planları açıkça anlatıldı mı?",
                dbColumn: "rating_communication",
                icon: "text.bubble"
            )
        ]
    )

    static let rehabilitation = SurveyConfig(
        type: "rehabilitation",
        displayName: "Rehabilitation",
        metrics: [
            SurveyMetric(
                label: "Bekleme Süresi",
                subtext: "Seansınız ne kadar hızlı başladı?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Tedavi Etkinliği",
                subtext: "Seanslar hareket kabiliyetini iyileştirdi mi veya ağrı azalttı mı?",
                dbColumn: "rating_effectiveness",
                icon: "figure.walk"
            ),
            SurveyMetric(
                label: "Terapist Dikkatililiği",
                subtext: "Terapist sizi izledi ve uyarlamalar yaptı mı?",
                dbColumn: "rating_attentiveness",
                icon: "eye"
            ),
            SurveyMetric(
                label: "Tessis Ekipmanı",
                subtext: "Alan iyi donanımlı mıydı?",
                dbColumn: "rating_equipment",
                icon: "dumbbell"
            )
        ]
    )

    static let aesthetics = SurveyConfig(
        type: "aesthetics",
        displayName: "Aesthetic Clinic",
        metrics: [
            SurveyMetric(
                label: "Bekleme Süresi",
                subtext: "Randevu saatinizden sonra ne kadar beklediniz?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Danışmanlık Kalitesi",
                subtext: "İşlem riskleri ve sonuçları açıklandı mı?",
                dbColumn: "rating_consultation",
                icon: "text.bubble"
            ),
            SurveyMetric(
                label: "Sonuç Memnuniyeti",
                subtext: "Sonuçlardan memnun musunuz?",
                dbColumn: "rating_results",
                icon: "star.circle"
            ),
            SurveyMetric(
                label: "Sonrası Bakım",
                subtext: "Sonrası talimatları ve takip açıkça anlatıldı mı?",
                dbColumn: "rating_aftercare",
                icon: "bandage"
            )
        ]
    )
}
