import Foundation

struct RatingCriterion: Identifiable {
    let id: String
    let icon: String
    let dbColumn: String

    var labelKey: String {
        "review_criterion_\(id)"
    }

    var questionKey: String {
        "review_criterion_\(id)_question"
    }

    static let all: [RatingCriterion] = [
        RatingCriterion(
            id: "waiting_time",
            icon: "clock",
            dbColumn: "rating_wait_time"
        ),
        RatingCriterion(
            id: "bedside_manner",
            icon: "heart",
            dbColumn: "rating_bedside"
        ),
        RatingCriterion(
            id: "treatment_effectiveness",
            icon: "cross.case",
            dbColumn: "rating_efficacy"
        ),
        RatingCriterion(
            id: "clinic_hygiene",
            icon: "sparkles",
            dbColumn: "rating_cleanliness"
        )
    ]
}