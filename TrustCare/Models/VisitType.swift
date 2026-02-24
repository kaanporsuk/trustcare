import Foundation

struct ReviewVisitType: Identifiable {
    let id: String
    private let labels: [String: String]

    func label(for lang: String) -> String {
        labels[lang] ?? labels["en"] ?? id
    }

    static let all: [ReviewVisitType] = [
        ReviewVisitType(
            id: "examination",
            labels: [
                "en": "Examination",
                "tr": "Muayene",
                "de": "Untersuchung",
                "pl": "Badanie",
                "nl": "Onderzoek",
                "da": "Undersøgelse"
            ]
        ),
        ReviewVisitType(
            id: "procedure",
            labels: [
                "en": "Procedure",
                "tr": "İşlem",
                "de": "Eingriff",
                "pl": "Zabieg",
                "nl": "Ingreep",
                "da": "Indgreb"
            ]
        ),
        ReviewVisitType(
            id: "checkup",
            labels: [
                "en": "Checkup",
                "tr": "Kontrol",
                "de": "Nachkontrolle",
                "pl": "Kontrola",
                "nl": "Controle",
                "da": "Kontrol"
            ]
        ),
        ReviewVisitType(
            id: "emergency",
            labels: [
                "en": "Emergency",
                "tr": "Acil",
                "de": "Notfall",
                "pl": "Nagły",
                "nl": "Spoed",
                "da": "Akut"
            ]
        )
    ]
}