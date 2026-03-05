import SwiftUI

enum ProviderMapColor {
    static func color(for surveyType: String) -> Color {
        switch surveyType {
        case "pharmacy": return Color.tcSage
        case "hospital": return Color.tcOcean
        case "dental": return Color.tcOcean
        case "general_clinic": return Color.tcOcean
        case "diagnostic": return Color.tcCoral
        case "mental_health": return Color.tcCoral
        case "rehabilitation": return Color.tcSage
        case "aesthetics": return Color.tcCoral
        default: return Color.tcTextSecondary
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
