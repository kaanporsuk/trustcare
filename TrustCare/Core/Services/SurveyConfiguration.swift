import Foundation

struct SurveyMetric: Identifiable {
    let id = UUID()
    let label: String
    let subtext: String
    let dbColumn: String
    let icon: String
}

struct SurveyConfig {
    let type: String
    let displayName: String
    let metrics: [SurveyMetric]
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

    static let generalClinic = SurveyConfig(
        type: "general_clinic",
        displayName: "General Clinic",
        metrics: [
            SurveyMetric(
                label: "Waiting Time",
                subtext: "How long did you wait past your appointment time?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Bedside Manner",
                subtext: "How well did the doctor listen to you and explain things?",
                dbColumn: "rating_bedside",
                icon: "heart"
            ),
            SurveyMetric(
                label: "Treatment Effectiveness",
                subtext: "How effectively did the treatment address your health concern?",
                dbColumn: "rating_efficacy",
                icon: "cross.case"
            ),
            SurveyMetric(
                label: "Facility Cleanliness",
                subtext: "How would you rate the overall cleanliness and hygiene?",
                dbColumn: "rating_cleanliness",
                icon: "sparkles"
            )
        ]
    )

    static let dental = SurveyConfig(
        type: "dental",
        displayName: "Dental",
        metrics: [
            SurveyMetric(
                label: "Waiting Time",
                subtext: "How quickly were you seated in the dentist's chair?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Pain Management",
                subtext: "How well did they minimize your discomfort during the procedure?",
                dbColumn: "rating_pain_mgmt",
                icon: "bolt.heart"
            ),
            SurveyMetric(
                label: "Bedside Manner",
                subtext: "How well did the dentist communicate and put you at ease?",
                dbColumn: "rating_bedside",
                icon: "heart"
            ),
            SurveyMetric(
                label: "Facility Cleanliness",
                subtext: "How would you rate the cleanliness of treatment rooms and equipment?",
                dbColumn: "rating_cleanliness",
                icon: "sparkles"
            )
        ]
    )

    static let pharmacy = SurveyConfig(
        type: "pharmacy",
        displayName: "Pharmacy",
        metrics: [
            SurveyMetric(
                label: "Speed of Service",
                subtext: "How quickly were you assisted and checked out?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Accuracy & Care",
                subtext: "How accurately was your prescription filled?",
                dbColumn: "rating_accuracy",
                icon: "checkmark.shield"
            ),
            SurveyMetric(
                label: "Pharmacist Knowledge",
                subtext: "How well did the pharmacist explain dosages and answer your questions?",
                dbColumn: "rating_knowledge",
                icon: "brain"
            ),
            SurveyMetric(
                label: "Staff Courtesy",
                subtext: "How patient and courteous was the staff?",
                dbColumn: "rating_courtesy",
                icon: "face.smiling"
            )
        ]
    )

    static let hospital = SurveyConfig(
        type: "hospital",
        displayName: "Hospital",
        metrics: [
            SurveyMetric(
                label: "Waiting Time",
                subtext: "How quickly were you seen by a doctor?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Quality of Care",
                subtext: "How would you rate the medical care and attention you received?",
                dbColumn: "rating_care_quality",
                icon: "heart.text.square"
            ),
            SurveyMetric(
                label: "Admin Efficiency",
                subtext: "How smooth was the admission, billing, and discharge process?",
                dbColumn: "rating_admin",
                icon: "doc.text"
            ),
            SurveyMetric(
                label: "Facility Cleanliness",
                subtext: "How would you rate the cleanliness of rooms and public areas?",
                dbColumn: "rating_cleanliness",
                icon: "sparkles"
            )
        ]
    )

    static let diagnostic = SurveyConfig(
        type: "diagnostic",
        displayName: "Diagnostic Center",
        metrics: [
            SurveyMetric(
                label: "Waiting Time",
                subtext: "How quickly were you called in for your test?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Procedure Comfort",
                subtext: "How comfortable did the staff make the process?",
                dbColumn: "rating_comfort",
                icon: "hand.raised"
            ),
            SurveyMetric(
                label: "Result Turnaround",
                subtext: "How promptly were your test results delivered?",
                dbColumn: "rating_turnaround",
                icon: "timer"
            ),
            SurveyMetric(
                label: "Facility Cleanliness",
                subtext: "How would you rate the facility's cleanliness?",
                dbColumn: "rating_cleanliness",
                icon: "sparkles"
            )
        ]
    )

    static let mentalHealth = SurveyConfig(
        type: "mental_health",
        displayName: "Mental Health",
        metrics: [
            SurveyMetric(
                label: "Punctuality",
                subtext: "How well did the session start on time?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Empathy & Listening",
                subtext: "How well did you feel heard and understood?",
                dbColumn: "rating_empathy",
                icon: "heart.circle"
            ),
            SurveyMetric(
                label: "Environment Comfort",
                subtext: "How calming and private was the office environment?",
                dbColumn: "rating_environment",
                icon: "leaf"
            ),
            SurveyMetric(
                label: "Communication Clarity",
                subtext: "How clearly were treatment plans or coping strategies explained?",
                dbColumn: "rating_communication",
                icon: "text.bubble"
            )
        ]
    )

    static let rehabilitation = SurveyConfig(
        type: "rehabilitation",
        displayName: "Rehabilitation",
        metrics: [
            SurveyMetric(
                label: "Waiting Time",
                subtext: "How quickly did your therapy session begin?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Treatment Effectiveness",
                subtext: "How much did the sessions improve your mobility or reduce pain?",
                dbColumn: "rating_effectiveness",
                icon: "figure.walk"
            ),
            SurveyMetric(
                label: "Therapist Attentiveness",
                subtext: "How actively did the therapist monitor and adjust your exercises?",
                dbColumn: "rating_attentiveness",
                icon: "eye"
            ),
            SurveyMetric(
                label: "Facility Equipment",
                subtext: "How well-equipped and maintained was the therapy area?",
                dbColumn: "rating_equipment",
                icon: "dumbbell"
            )
        ]
    )

    static let aesthetics = SurveyConfig(
        type: "aesthetics",
        displayName: "Aesthetic Clinic",
        metrics: [
            SurveyMetric(
                label: "Waiting Time",
                subtext: "How long did you wait past your appointment time?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Consultation Quality",
                subtext: "How clearly were the procedure, risks, and realistic outcomes explained?",
                dbColumn: "rating_consultation",
                icon: "text.bubble"
            ),
            SurveyMetric(
                label: "Result Satisfaction",
                subtext: "How satisfied are you with the results of your procedure?",
                dbColumn: "rating_results",
                icon: "star.circle"
            ),
            SurveyMetric(
                label: "Aftercare Support",
                subtext: "How clear and accessible was the aftercare and follow-up support?",
                dbColumn: "rating_aftercare",
                icon: "bandage"
            )
        ]
    )
}
