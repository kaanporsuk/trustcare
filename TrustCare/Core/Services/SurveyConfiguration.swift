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
                subtext: "How well did the doctor listen and explain?",
                dbColumn: "rating_bedside",
                icon: "heart"
            ),
            SurveyMetric(
                label: "Treatment Effectiveness",
                subtext: "How well did the treatment address your concern?",
                dbColumn: "rating_efficacy",
                icon: "cross.case"
            ),
            SurveyMetric(
                label: "Facility Cleanliness",
                subtext: "Was the clinic clean and hygienic?",
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
                subtext: "How quickly were you seated?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Pain Management",
                subtext: "How well did they minimize discomfort?",
                dbColumn: "rating_pain_mgmt",
                icon: "bolt.heart"
            ),
            SurveyMetric(
                label: "Bedside Manner",
                subtext: "Did the dentist communicate clearly?",
                dbColumn: "rating_bedside",
                icon: "heart"
            ),
            SurveyMetric(
                label: "Facility Cleanliness",
                subtext: "Were treatment rooms and equipment clean?",
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
                subtext: "How quickly were you assisted?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Accuracy & Care",
                subtext: "Was your prescription filled correctly?",
                dbColumn: "rating_accuracy",
                icon: "checkmark.shield"
            ),
            SurveyMetric(
                label: "Pharmacist Knowledge",
                subtext: "Did the pharmacist explain dosages clearly?",
                dbColumn: "rating_knowledge",
                icon: "brain"
            ),
            SurveyMetric(
                label: "Staff Courtesy",
                subtext: "Was the staff patient and helpful?",
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
                subtext: "How would you rate the medical attention?",
                dbColumn: "rating_care_quality",
                icon: "heart.text.square"
            ),
            SurveyMetric(
                label: "Admin Efficiency",
                subtext: "How smooth was admission and discharge?",
                dbColumn: "rating_admin",
                icon: "doc.text"
            ),
            SurveyMetric(
                label: "Facility Cleanliness",
                subtext: "Were rooms and areas clean?",
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
                subtext: "How quickly were you called for your test?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Procedure Comfort",
                subtext: "Did staff make the process comfortable?",
                dbColumn: "rating_comfort",
                icon: "hand.raised"
            ),
            SurveyMetric(
                label: "Result Turnaround",
                subtext: "Were results delivered on time?",
                dbColumn: "rating_turnaround",
                icon: "timer"
            ),
            SurveyMetric(
                label: "Facility Cleanliness",
                subtext: "Was the facility sanitary?",
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
                subtext: "Did your session start on time?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Empathy & Listening",
                subtext: "Did you feel genuinely heard?",
                dbColumn: "rating_empathy",
                icon: "heart.circle"
            ),
            SurveyMetric(
                label: "Environment Comfort",
                subtext: "Was the office calming and private?",
                dbColumn: "rating_environment",
                icon: "leaf"
            ),
            SurveyMetric(
                label: "Communication Clarity",
                subtext: "Were treatment plans explained clearly?",
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
                subtext: "How quickly did your session begin?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Treatment Effectiveness",
                subtext: "Did sessions improve mobility or reduce pain?",
                dbColumn: "rating_effectiveness",
                icon: "figure.walk"
            ),
            SurveyMetric(
                label: "Therapist Attentiveness",
                subtext: "Did the therapist monitor and adjust?",
                dbColumn: "rating_attentiveness",
                icon: "eye"
            ),
            SurveyMetric(
                label: "Facility Equipment",
                subtext: "Was the area well-equipped?",
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
                subtext: "How long past your appointment time?",
                dbColumn: "rating_wait_time",
                icon: "clock"
            ),
            SurveyMetric(
                label: "Consultation Quality",
                subtext: "Were procedure risks and outcomes explained?",
                dbColumn: "rating_consultation",
                icon: "text.bubble"
            ),
            SurveyMetric(
                label: "Result Satisfaction",
                subtext: "Are you satisfied with results?",
                dbColumn: "rating_results",
                icon: "star.circle"
            ),
            SurveyMetric(
                label: "Aftercare Support",
                subtext: "Were aftercare instructions and follow-up clear?",
                dbColumn: "rating_aftercare",
                icon: "bandage"
            )
        ]
    )
}
