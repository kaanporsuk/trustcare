import Foundation

struct SurveyMetric: Identifiable {
    let id = UUID()
    let labelKey: String   // Localizable.strings key for label
    let subtextKey: String // Localizable.strings key for subtext
    let dbColumn: String
    let icon: String

    /// Resolve through TrustCare's selected-language lookup to avoid mixed-language UI.
    var label: String { tcString(labelKey, fallback: labelKey) }
    var subtext: String { tcString(subtextKey, fallback: subtextKey) }
}

struct SurveyConfig {
    let type: String
    let displayNameKey: String
    let metrics: [SurveyMetric]

    var displayName: String { tcString(displayNameKey, fallback: displayNameKey) }
}

enum SurveyConfigurations {

    static func config(for surveyType: String) -> SurveyConfig {
        switch surveyType {
        case "general_clinic": return generalClinic
        case "dental": return dental
        case "pharmacy": return pharmacy
        case "hospital": return hospital
        case "diagnostic": return diagnostic
        case "mental_health": return mentalHealth
        case "rehabilitation": return rehabilitation
        case "aesthetics": return aesthetics
        default: return generalClinic
        }
    }

    // ── General Clinic ──────────────────────────────────────────────
    static let generalClinic = SurveyConfig(
        type: "general_clinic",
        displayNameKey: "survey_general_clinic",
        metrics: [
            SurveyMetric(labelKey: "survey_waiting_time", subtextKey: "survey_waiting_time_sub", dbColumn: "rating_wait_time", icon: "clock"),
            SurveyMetric(labelKey: "survey_bedside_manner", subtextKey: "survey_bedside_manner_sub", dbColumn: "rating_bedside", icon: "heart"),
            SurveyMetric(labelKey: "survey_treatment_effectiveness", subtextKey: "survey_treatment_effectiveness_sub", dbColumn: "rating_efficacy", icon: "cross.case"),
            SurveyMetric(labelKey: "survey_clinic_hygiene", subtextKey: "survey_clinic_hygiene_sub", dbColumn: "rating_cleanliness", icon: "sparkles"),
        ]
    )

    // ── Dental ──────────────────────────────────────────────────────
    static let dental = SurveyConfig(
        type: "dental",
        displayNameKey: "survey_dental",
        metrics: [
            SurveyMetric(labelKey: "survey_waiting_time", subtextKey: "survey_dental_wait_sub", dbColumn: "rating_wait_time", icon: "clock"),
            SurveyMetric(labelKey: "survey_pain_management", subtextKey: "survey_pain_management_sub", dbColumn: "rating_pain_mgmt", icon: "bolt.heart"),
            SurveyMetric(labelKey: "survey_bedside_manner", subtextKey: "survey_dental_bedside_sub", dbColumn: "rating_bedside", icon: "heart"),
            SurveyMetric(labelKey: "survey_clinic_hygiene", subtextKey: "survey_dental_hygiene_sub", dbColumn: "rating_cleanliness", icon: "sparkles"),
        ]
    )

    // ── Pharmacy ────────────────────────────────────────────────────
    static let pharmacy = SurveyConfig(
        type: "pharmacy",
        displayNameKey: "survey_pharmacy",
        metrics: [
            SurveyMetric(labelKey: "survey_speed", subtextKey: "survey_speed_sub", dbColumn: "rating_wait_time", icon: "clock"),
            SurveyMetric(labelKey: "survey_accuracy", subtextKey: "survey_accuracy_sub", dbColumn: "rating_accuracy", icon: "checkmark.shield"),
            SurveyMetric(labelKey: "survey_pharmacist_knowledge", subtextKey: "survey_pharmacist_knowledge_sub", dbColumn: "rating_knowledge", icon: "brain"),
            SurveyMetric(labelKey: "survey_staff_courtesy", subtextKey: "survey_staff_courtesy_sub", dbColumn: "rating_courtesy", icon: "face.smiling"),
        ]
    )

    // ── Hospital ────────────────────────────────────────────────────
    static let hospital = SurveyConfig(
        type: "hospital",
        displayNameKey: "survey_hospital",
        metrics: [
            SurveyMetric(labelKey: "survey_waiting_time", subtextKey: "survey_hospital_wait_sub", dbColumn: "rating_wait_time", icon: "clock"),
            SurveyMetric(labelKey: "survey_care_quality", subtextKey: "survey_care_quality_sub", dbColumn: "rating_care_quality", icon: "heart.text.square"),
            SurveyMetric(labelKey: "survey_admin_efficiency", subtextKey: "survey_admin_efficiency_sub", dbColumn: "rating_admin", icon: "doc.text"),
            SurveyMetric(labelKey: "survey_room_hygiene", subtextKey: "survey_room_hygiene_sub", dbColumn: "rating_cleanliness", icon: "sparkles"),
        ]
    )

    // ── Diagnostic ──────────────────────────────────────────────────
    static let diagnostic = SurveyConfig(
        type: "diagnostic",
        displayNameKey: "survey_diagnostic",
        metrics: [
            SurveyMetric(labelKey: "survey_waiting_time", subtextKey: "survey_diagnostic_wait_sub", dbColumn: "rating_wait_time", icon: "clock"),
            SurveyMetric(labelKey: "survey_procedure_comfort", subtextKey: "survey_procedure_comfort_sub", dbColumn: "rating_comfort", icon: "hand.raised"),
            SurveyMetric(labelKey: "survey_result_speed", subtextKey: "survey_result_speed_sub", dbColumn: "rating_turnaround", icon: "timer"),
            SurveyMetric(labelKey: "survey_facility_hygiene", subtextKey: "survey_facility_hygiene_sub", dbColumn: "rating_cleanliness", icon: "sparkles"),
        ]
    )

    // ── Mental Health ───────────────────────────────────────────────
    static let mentalHealth = SurveyConfig(
        type: "mental_health",
        displayNameKey: "survey_mental_health",
        metrics: [
            SurveyMetric(labelKey: "survey_punctuality", subtextKey: "survey_punctuality_sub", dbColumn: "rating_wait_time", icon: "clock"),
            SurveyMetric(labelKey: "survey_empathy", subtextKey: "survey_empathy_sub", dbColumn: "rating_empathy", icon: "heart.circle"),
            SurveyMetric(labelKey: "survey_environment_comfort", subtextKey: "survey_environment_comfort_sub", dbColumn: "rating_environment", icon: "leaf"),
            SurveyMetric(labelKey: "survey_communication_clarity", subtextKey: "survey_communication_clarity_sub", dbColumn: "rating_communication", icon: "text.bubble"),
        ]
    )

    // ── Rehabilitation ──────────────────────────────────────────────
    static let rehabilitation = SurveyConfig(
        type: "rehabilitation",
        displayNameKey: "survey_rehabilitation",
        metrics: [
            SurveyMetric(labelKey: "survey_waiting_time", subtextKey: "survey_rehab_wait_sub", dbColumn: "rating_wait_time", icon: "clock"),
            SurveyMetric(labelKey: "survey_treatment_effectiveness", subtextKey: "survey_rehab_effectiveness_sub", dbColumn: "rating_effectiveness", icon: "figure.walk"),
            SurveyMetric(labelKey: "survey_therapist_attentiveness", subtextKey: "survey_therapist_attentiveness_sub", dbColumn: "rating_attentiveness", icon: "eye"),
            SurveyMetric(labelKey: "survey_facility_equipment", subtextKey: "survey_facility_equipment_sub", dbColumn: "rating_equipment", icon: "dumbbell"),
        ]
    )

    // ── Aesthetics ──────────────────────────────────────────────────
    static let aesthetics = SurveyConfig(
        type: "aesthetics",
        displayNameKey: "survey_aesthetics",
        metrics: [
            SurveyMetric(labelKey: "survey_waiting_time", subtextKey: "survey_waiting_time_sub", dbColumn: "rating_wait_time", icon: "clock"),
            SurveyMetric(labelKey: "survey_consultation_quality", subtextKey: "survey_consultation_quality_sub", dbColumn: "rating_consultation", icon: "text.bubble"),
            SurveyMetric(labelKey: "survey_result_satisfaction", subtextKey: "survey_result_satisfaction_sub", dbColumn: "rating_results", icon: "star.circle"),
            SurveyMetric(labelKey: "survey_aftercare", subtextKey: "survey_aftercare_sub", dbColumn: "rating_aftercare", icon: "bandage"),
        ]
    )
}
