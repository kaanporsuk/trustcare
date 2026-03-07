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

    static let provider: [RatingCriterion] = [
        RatingCriterion(
            id: "provider_expertise",
            icon: "stethoscope",
            dbColumn: "rating_knowledge"
        ),
        RatingCriterion(
            id: "provider_communication",
            icon: "bubble.left.and.text.bubble.right",
            dbColumn: "rating_communication"
        ),
        RatingCriterion(
            id: "provider_trust",
            icon: "checkmark.shield",
            dbColumn: "rating_courtesy"
        ),
        RatingCriterion(
            id: "provider_clarity",
            icon: "lightbulb",
            dbColumn: "rating_consultation"
        ),
        RatingCriterion(
            id: "provider_follow_up",
            icon: "arrow.triangle.2.circlepath",
            dbColumn: "rating_aftercare"
        )
    ]

    static let facility: [RatingCriterion] = [
        RatingCriterion(
            id: "facility_cleanliness",
            icon: "sparkles",
            dbColumn: "rating_cleanliness"
        ),
        RatingCriterion(
            id: "facility_organization",
            icon: "list.bullet.clipboard",
            dbColumn: "rating_admin"
        ),
        RatingCriterion(
            id: "facility_wait_time",
            icon: "clock",
            dbColumn: "rating_wait_time"
        ),
        RatingCriterion(
            id: "facility_staff_professionalism",
            icon: "person.3",
            dbColumn: "rating_staff"
        ),
        RatingCriterion(
            id: "facility_comfort",
            icon: "sofa",
            dbColumn: "rating_comfort"
        ),
        RatingCriterion(
            id: "facility_billing",
            icon: "creditcard",
            dbColumn: "rating_value"
        )
    ]

    static func criteria(for targetType: ReviewTargetType) -> [RatingCriterion] {
        switch targetType {
        case .provider:
            return provider
        case .facility:
            return facility
        }
    }

    static let all: [RatingCriterion] = provider
}