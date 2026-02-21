import SwiftUI

enum ProviderMapColor {
    static func color(for surveyType: String) -> Color {
        switch surveyType {
        case "pharmacy": return Color(hex: "#34C759")
        case "hospital": return Color(hex: "#5856D6")
        case "dental": return Color(hex: "#007AFF")
        case "general_clinic": return Color(hex: "#0055FF")
        case "diagnostic": return Color(hex: "#FF9500")
        case "mental_health": return Color(hex: "#AF52DE")
        case "rehabilitation": return Color(hex: "#00C7BE")
        case "aesthetics": return Color(hex: "#FF2D55")
        default: return Color(hex: "#8E8E93")
        }
    }

    #if os(iOS)
    static func uiColor(for surveyType: String) -> UIColor {
        UIColor(color(for: surveyType))
    }
    #endif

    static func icon(for surveyType: String) -> String {
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
