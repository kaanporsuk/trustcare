import Foundation

struct RatingCriterion: Identifiable {
    let id: String
    let icon: String
    let dbColumn: String
    private let labels: [String: String]
    private let questions: [String: String]

    func label(for lang: String) -> String {
        labels[lang] ?? labels["en"] ?? id
    }

    func question(for lang: String) -> String {
        questions[lang] ?? questions["en"] ?? id
    }

    static let all: [RatingCriterion] = [
        RatingCriterion(
            id: "waiting_time",
            icon: "clock",
            dbColumn: "rating_wait_time",
            labels: [
                "en": "Waiting Time",
                "tr": "Bekleme Süresi",
                "de": "Wartezeit",
                "pl": "Czas oczekiwania",
                "nl": "Wachttijd",
                "da": "Ventetid"
            ],
            questions: [
                "en": "How long did you wait after your appointment time?",
                "tr": "Randevu saatinizden sonra ne kadar beklediniz?",
                "de": "Wie lange haben Sie nach Ihrem Termin gewartet?",
                "pl": "Jak długo czekał/a Pan/Pani po umówionej godzinie?",
                "nl": "Hoe lang heeft u gewacht na uw afspraaktijd?",
                "da": "Hvor længe ventede du efter din aftalte tid?"
            ]
        ),
        RatingCriterion(
            id: "bedside_manner",
            icon: "heart",
            dbColumn: "rating_bedside",
            labels: [
                "en": "Bedside Manner",
                "tr": "Doktor Tutumu",
                "de": "Patientenbetreuung",
                "pl": "Podejście lekarza",
                "nl": "Bejegening",
                "da": "Patientkontakt"
            ],
            questions: [
                "en": "Did the doctor listen and explain clearly?",
                "tr": "Doktor sizi dinledi ve açıklamalar yaptı mı?",
                "de": "Hat der Arzt zugehört und verständlich erklärt?",
                "pl": "Czy lekarz słuchał i jasno wyjaśniał?",
                "nl": "Heeft de arts geluisterd en duidelijk uitgelegd?",
                "da": "Lyttede lægen og forklarede tydeligt?"
            ]
        ),
        RatingCriterion(
            id: "treatment_effectiveness",
            icon: "cross.case",
            dbColumn: "rating_efficacy",
            labels: [
                "en": "Treatment Effectiveness",
                "tr": "Tedavi Etkinliği",
                "de": "Behandlungserfolg",
                "pl": "Skuteczność leczenia",
                "nl": "Behandeleffectiviteit",
                "da": "Behandlingseffektivitet"
            ],
            questions: [
                "en": "Did the treatment resolve your issue?",
                "tr": "Tedavi sorununuzu çözdü mü?",
                "de": "Hat die Behandlung Ihr Problem gelöst?",
                "pl": "Czy leczenie rozwiązało problem?",
                "nl": "Heeft de behandeling uw probleem opgelost?",
                "da": "Løste behandlingen dit problem?"
            ]
        ),
        RatingCriterion(
            id: "clinic_hygiene",
            icon: "sparkles",
            dbColumn: "rating_cleanliness",
            labels: [
                "en": "Clinic Hygiene",
                "tr": "Klinik Hijyeni",
                "de": "Sauberkeit der Praxis",
                "pl": "Czystość placówki",
                "nl": "Hygiëne van de praktijk",
                "da": "Klinikkens renlighed"
            ],
            questions: [
                "en": "Was the clinic clean and hygienic?",
                "tr": "Klinik temiz ve hijyenik miydi?",
                "de": "War die Praxis sauber und hygienisch?",
                "pl": "Czy placówka była czysta i higieniczna?",
                "nl": "Was de praktijk schoon en hygiënisch?",
                "da": "Var klinikken ren og hygiejnisk?"
            ]
        )
    ]
}