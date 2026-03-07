import Foundation

enum TaxonomyEntityType: String, CaseIterable, Identifiable {
    case specialty
    case treatmentProcedure = "treatment_procedure"
    case facilityType = "facility_type"
    case symptomConcern = "symptom_concern"

    var id: String { rawValue }

    static var pickerCases: [TaxonomyEntityType] {
        [.specialty, .treatmentProcedure, .facilityType]
    }

    var backendEntityType: String? {
        switch self {
        case .specialty:
            return "specialty"
        case .treatmentProcedure:
            return "service"
        case .facilityType:
            return "facility"
        case .symptomConcern:
            return nil
        }
    }

    var storageKey: String {
        switch self {
        case .specialty:
            return "specialty"
        case .treatmentProcedure:
            return "service"
        case .facilityType:
            return "facility"
        case .symptomConcern:
            return "symptom_concern"
        }
    }

    static func fromBackend(_ value: String) -> TaxonomyEntityType? {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "specialty":
            return .specialty
        case "service", "treatment_procedure":
            return .treatmentProcedure
        case "facility", "facility_type":
            return .facilityType
        case "symptom_concern":
            return .symptomConcern
        default:
            return nil
        }
    }

    var segmentTitleKey: String {
        switch self {
        case .specialty:
            return "taxonomy_segment_specialties"
        case .treatmentProcedure:
            return "taxonomy_segment_treatments"
        case .facilityType:
            return "taxonomy_segment_facilities"
        case .symptomConcern:
            return "taxonomy_segment_symptoms"
        }
    }

    var searchPlaceholderKey: String {
        switch self {
        case .specialty:
            return "search_specialties"
        case .treatmentProcedure:
            return "search_treatments"
        case .facilityType:
            return "search_facilities"
        case .symptomConcern:
            return "search_symptoms"
        }
    }
}
