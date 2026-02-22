import SwiftUI

enum ProviderMapColor {
    static func color(for surveyType: String) -> Color {
        switch surveyType {
        case "pharmacy": return AppColor.mapPharmacy
        case "hospital": return AppColor.mapHospital
        case "dental": return AppColor.mapDental
        case "general_clinic": return AppColor.mapClinic
        case "diagnostic": return AppColor.mapDiagnostic
        case "mental_health": return AppColor.mapMentalHealth
        case "rehabilitation": return AppColor.mapRehab
        case "aesthetics": return AppColor.mapAesthetics
        default: return AppColor.unverified
        }
    }

    #if os(iOS)
    static func uiColor(for surveyType: String) -> UIColor {
        UIColor(color(for: surveyType))
    }
    #endif

    static func markerIcon(for surveyType: String) -> String {
        switch surveyType {
        case "pharmacy": return "pills.circle.fill"
        case "hospital": return "cross.case.fill"
        case "dental": return "mouth.fill"
        case "general_clinic": return "stethoscope"
        case "diagnostic": return "testtube.2"
        case "mental_health": return "brain"
        case "rehabilitation": return "figure.walk"
        case "aesthetics": return "sparkles"
        default: return "mappin.circle.fill"
        }
    }

    static func icon(for surveyType: String) -> String {
        markerIcon(for: surveyType)
    }

    static func label(for surveyType: String) -> String {
        switch surveyType {
        case "pharmacy": return "Pharmacy"
        case "hospital": return "Hospital"
        case "dental": return "Dental"
        case "general_clinic": return "Clinic"
        case "diagnostic": return "Lab / Imaging"
        case "mental_health": return "Mental Health"
        case "rehabilitation": return "Rehab / PT"
        case "aesthetics": return "Aesthetics"
        default: return "Other"
        }
    }
}
