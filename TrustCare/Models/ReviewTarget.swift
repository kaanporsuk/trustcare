import Foundation

enum ReviewTargetType: String, Codable, CaseIterable {
    case provider
    case facility
}

struct ReviewTarget: Hashable {
    let type: ReviewTargetType
    let id: UUID

    static func provider(_ id: UUID) -> ReviewTarget {
        ReviewTarget(type: .provider, id: id)
    }

    static func facility(_ id: UUID) -> ReviewTarget {
        ReviewTarget(type: .facility, id: id)
    }
}
