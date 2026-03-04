import Foundation

enum TaxonomyEntityType: String, CaseIterable, Identifiable {
    case specialty
    case service
    case facility

    var id: String { rawValue }

    var segmentTitleKey: String {
        switch self {
        case .specialty:
            return "taxonomy_segment_specialties"
        case .service:
            return "taxonomy_segment_treatments"
        case .facility:
            return "taxonomy_segment_facilities"
        }
    }

    var searchPlaceholderKey: String {
        switch self {
        case .specialty:
            return "search_specialties"
        case .service:
            return "search_treatments"
        case .facility:
            return "search_facilities"
        }
    }
}
