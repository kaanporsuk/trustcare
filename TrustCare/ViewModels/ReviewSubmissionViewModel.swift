import Combine
import Foundation
import UIKit

// MARK: - Contextual Review Metrics Mapping
struct ContextualReviewMetric {
    let label: String
    let subtext: String
}

@MainActor
final class ReviewSubmissionViewModel: ObservableObject {
    let provider: Provider

    @Published var visitDate: Date = Date()
    @Published var visitType: VisitType = .consultation

    @Published var overallRating: Int = 0
    @Published var ratingWaitTime: Int = 0
    @Published var ratingBedside: Int = 0
    @Published var ratingEfficacy: Int = 0
    @Published var ratingCleanliness: Int = 0
    @Published var ratingStaff: Int = 0
    @Published var ratingValue: Int = 0

    @Published var title: String = ""
    @Published var comment: String = ""
    @Published var wouldRecommend: Bool = true
    @Published var selectedImages: [UIImage] = []
    @Published var proofImage: UIImage?
    
    // Contextual metrics (1-5 scale)
    @Published var waitingTime: Int = 0
    @Published var facilityCleanliness: Int = 0
    @Published var doctorCommunication: Int = 0
    @Published var treatmentOutcome: Int = 0
    @Published var proceduralComfort: Int = 0
    @Published var clearExplanations: Int = 0
    @Published var checkoutSpeed: Int = 0
    @Published var stockAvailability: Int = 0
    @Published var pharmacistAdvice: Int = 0
    @Published var staffCourtesy: Int = 0
    @Published var responseTime: Int = 0
    @Published var nursingCare: Int = 0
    @Published var checkInProcess: Int = 0
    @Published var testComfort: Int = 0
    @Published var resultTurnaround: Int = 0
    @Published var sessionPunctuality: Int = 0
    @Published var empathyListening: Int = 0
    @Published var sessionPrivacy: Int = 0
    @Published var actionableAdvice: Int = 0
    @Published var therapyProgress: Int = 0
    @Published var activeSupervision: Int = 0
    @Published var facilityGear: Int = 0
    @Published var consultationQuality: Int = 0
    @Published var resultSatisfaction: Int = 0
    @Published var aftercareSupport: Int = 0

    @Published var isSubmitting: Bool = false
    @Published var submissionErrorMessage: String?
    @Published var isComplete: Bool = false
    @Published var mediaUploadProgress: Double = 0

    private var hasSetOverall: Bool = false

    init(provider: Provider) {
        self.provider = provider
    }

    // MARK: - Context-Aware Metrics
    /// Returns the relevant contextual metrics for the provider's category
    func contextualMetricsForProvider() -> [ContextualReviewMetric] {
        guard let category = getProviderCategory(from: provider.specialty) else {
            return []
        }

        switch category {
        case .pharmacy:
            return [
                ContextualReviewMetric(
                    label: String(localized: "Checkout Speed"),
                    subtext: String(localized: "How quickly were you assisted and checked out?")
                ),
                ContextualReviewMetric(
                    label: String(localized: "Stock Availability"),
                    subtext: String(localized: "Did they have your medications or offer clear alternatives?")
                ),
                ContextualReviewMetric(
                    label: String(localized: "Pharmacist Advice"),
                    subtext: String(localized: "How helpful was the pharmacist's guidance on usage and side effects?")
                ),
                ContextualReviewMetric(
                    label: String(localized: "Staff Courtesy"),
                    subtext: String(localized: "How patient and courteous was the support staff?")
                )
            ]

        case .hospital:
            return [
                ContextualReviewMetric(
                    label: String(localized: "Response Time"),
                    subtext: String(localized: "How quickly were you attended to by the medical team?")
                ),
                ContextualReviewMetric(
                    label: String(localized: "Nursing Care"),
                    subtext: String(localized: "How attentive and competent were the nursing staff?")
                ),
                ContextualReviewMetric(
                    label: String(localized: "Check-in Process"),
                    subtext: String(localized: "How smooth was the admission, billing, and discharge process?")
                ),
                ContextualReviewMetric(
                    label: String(localized: "Cleanliness"),
                    subtext: String(localized: "How clean were the patient rooms and public areas?")
                )
            ]

        case .dentist:
            return [
                ContextualReviewMetric(
                    label: String(localized: "Waiting Time"),
                    subtext: String(localized: "How quickly were you seated for your appointment?")
                ),
                ContextualReviewMetric(
                    label: String(localized: "Procedural Comfort"),
                    subtext: String(localized: "How well did they manage your comfort during the procedure?")
                ),
                ContextualReviewMetric(
                    label: String(localized: "Clear Explanations"),
                    subtext: String(localized: "How clearly did the dentist explain the procedure and costs?")
                ),
                ContextualReviewMetric(
                    label: String(localized: "Cleanliness"),
                    subtext: String(localized: "How clean were the treatment rooms and equipment?")
                )
            ]

        case .clinic:
            return [
                ContextualReviewMetric(
                    label: String(localized: "Waiting Time"),
                    subtext: String(localized: "How long did you wait past your appointment time?")
                ),
                ContextualReviewMetric(
                    label: String(localized: "Doctor Comm."),
                    subtext: String(localized: "How carefully did the doctor listen and explain things?")
                ),
                ContextualReviewMetric(
                    label: String(localized: "Treatment Outcome"),
                    subtext: String(localized: "How well did the advice or treatment address your concern?")
                ),
                ContextualReviewMetric(
                    label: String(localized: "Cleanliness"),
                    subtext: String(localized: "How clean and hygienic was the clinic?")
                )
            ]

        case .all:
            // Diagnostic centers and labs
            return [
                ContextualReviewMetric(
                    label: String(localized: "Waiting Time"),
                    subtext: String(localized: "How quickly were you called in for your test?")
                ),
                ContextualReviewMetric(
                    label: String(localized: "Test Comfort"),
                    subtext: String(localized: "How comfortable did the staff make the blood draw or imaging process?")
                ),
                ContextualReviewMetric(
                    label: String(localized: "Result Turnaround"),
                    subtext: String(localized: "How well did they meet the promised timeframe for your results?")
                ),
                ContextualReviewMetric(
                    label: String(localized: "Cleanliness"),
                    subtext: String(localized: "How clean and sanitary was the facility?")
                )
            ]
        }
    }

    /// Returns metrics for mental health providers
    private func mentalHealthMetrics() -> [ContextualReviewMetric] {
        return [
            ContextualReviewMetric(
                label: String(localized: "Session Punctuality"),
                subtext: String(localized: "Did your session start on time?")
            ),
            ContextualReviewMetric(
                label: String(localized: "Empathy & Listening"),
                subtext: String(localized: "How well did the therapist listen and understand you?")
            ),
            ContextualReviewMetric(
                label: String(localized: "Session Privacy"),
                subtext: String(localized: "How secure and private was the session environment?")
            ),
            ContextualReviewMetric(
                label: String(localized: "Actionable Advice"),
                subtext: String(localized: "Did you receive actionable advice and strategies?")
            ),
            ContextualReviewMetric(
                label: String(localized: "Therapy Progress"),
                subtext: String(localized: "Do you feel you're making progress toward your goals?")
            )
        ]
    }

    /// Returns metrics for physical therapy providers
    private func physicalTherapyMetrics() -> [ContextualReviewMetric] {
        return [
            ContextualReviewMetric(
                label: String(localized: "Session Punctuality"),
                subtext: String(localized: "Did your session start on time?")
            ),
            ContextualReviewMetric(
                label: String(localized: "Empathy & Listening"),
                subtext: String(localized: "How well did the therapist listen to your concerns?")
            ),
            ContextualReviewMetric(
                label: String(localized: "Active Supervision"),
                subtext: String(localized: "How closely did the therapist supervise your exercises?")
            ),
            ContextualReviewMetric(
                label: String(localized: "Actionable Advice"),
                subtext: String(localized: "Did you receive clear home exercise instructions?")
            ),
            ContextualReviewMetric(
                label: String(localized: "Therapy Progress"),
                subtext: String(localized: "Do you feel improvement in your condition?")
            ),
            ContextualReviewMetric(
                label: String(localized: "Facility & Gear"),
                subtext: String(localized: "How well-maintained was the equipment and facility?")
            ),
            ContextualReviewMetric(
                label: String(localized: "Aftercare Support"),
                subtext: String(localized: "How good was the follow-up and aftercare support?")
            )
        ]
    }

    /// Returns metrics for aesthetics/cosmetic providers
    private func aestheticsMetrics() -> [ContextualReviewMetric] {
        return [
            ContextualReviewMetric(
                label: String(localized: "Consultation Quality"),
                subtext: String(localized: "How thorough and personalized was the consultation?")
            ),
            ContextualReviewMetric(
                label: String(localized: "Facility & Gear"),
                subtext: String(localized: "How professional was the facility and equipment?")
            ),
            ContextualReviewMetric(
                label: String(localized: "Result Satisfaction"),
                subtext: String(localized: "How satisfied are you with the results?")
            ),
            ContextualReviewMetric(
                label: String(localized: "Clear Explanations"),
                subtext: String(localized: "How clearly were risks and benefits explained?")
            ),
            ContextualReviewMetric(
                label: String(localized: "Aftercare Support"),
                subtext: String(localized: "How helpful was the aftercare guidance?")
            )
        ]
    }

    var commentCharCount: Int {
        comment.count
    }
    
    // MARK: - Contextual Metrics Management
    func updateContextualMetric(index: Int, value: Int) {
        let metrics = contextualMetricsForProvider()
        guard index < metrics.count else { return }
        
        let metric = metrics[index]
        
        // Map metric label to ViewModel property
        switch metric.label {
        case String(localized: "Waiting Time"):
            waitingTime = value
        case String(localized: "Doctor Comm."):
            doctorCommunication = value
        case String(localized: "Treatment Outcome"):
            treatmentOutcome = value
        case String(localized: "Cleanliness"):
            facilityCleanliness = value
        case String(localized: "Procedural Comfort"):
            proceduralComfort = value
        case String(localized: "Clear Explanations"):
            clearExplanations = value
        case String(localized: "Checkout Speed"):
            checkoutSpeed = value
        case String(localized: "Stock Availability"):
            stockAvailability = value
        case String(localized: "Pharmacist Advice"):
            pharmacistAdvice = value
        case String(localized: "Staff Courtesy"):
            staffCourtesy = value
        case String(localized: "Response Time"):
            responseTime = value
        case String(localized: "Nursing Care"):
            nursingCare = value
        case String(localized: "Check-in Process"):
            checkInProcess = value
        case String(localized: "Test Comfort"):
            testComfort = value
        case String(localized: "Result Turnaround"):
            resultTurnaround = value
        case String(localized: "Session Punctuality"):
            sessionPunctuality = value
        case String(localized: "Empathy & Listening"):
            empathyListening = value
        case String(localized: "Session Privacy"):
            sessionPrivacy = value
        case String(localized: "Actionable Advice"):
            actionableAdvice = value
        case String(localized: "Therapy Progress"):
            therapyProgress = value
        case String(localized: "Active Supervision"):
            activeSupervision = value
        case String(localized: "Facility & Gear"):
            facilityGear = value
        case String(localized: "Aftercare Support"):
            aftercareSupport = value
        case String(localized: "Consultation Quality"):
            consultationQuality = value
        case String(localized: "Result Satisfaction"):
            resultSatisfaction = value
        default:
            break
        }
    }
    
    func getContextualMetricValue(index: Int) -> Int {
        let metrics = contextualMetricsForProvider()
        guard index < metrics.count else { return 0 }
        
        let metric = metrics[index]
        
        // Map metric label to ViewModel property
        switch metric.label {
        case String(localized: "Waiting Time"):
            return waitingTime
        case String(localized: "Doctor Comm."):
            return doctorCommunication
        case String(localized: "Treatment Outcome"):
            return treatmentOutcome
        case String(localized: "Cleanliness"):
            return facilityCleanliness
        case String(localized: "Procedural Comfort"):
            return proceduralComfort
        case String(localized: "Clear Explanations"):
            return clearExplanations
        case String(localized: "Checkout Speed"):
            return checkoutSpeed
        case String(localized: "Stock Availability"):
            return stockAvailability
        case String(localized: "Pharmacist Advice"):
            return pharmacistAdvice
        case String(localized: "Staff Courtesy"):
            return staffCourtesy
        case String(localized: "Response Time"):
            return responseTime
        case String(localized: "Nursing Care"):
            return nursingCare
        case String(localized: "Check-in Process"):
            return checkInProcess
        case String(localized: "Test Comfort"):
            return testComfort
        case String(localized: "Result Turnaround"):
            return resultTurnaround
        case String(localized: "Session Punctuality"):
            return sessionPunctuality
        case String(localized: "Empathy & Listening"):
            return empathyListening
        case String(localized: "Session Privacy"):
            return sessionPrivacy
        case String(localized: "Actionable Advice"):
            return actionableAdvice
        case String(localized: "Therapy Progress"):
            return therapyProgress
        case String(localized: "Active Supervision"):
            return activeSupervision
        case String(localized: "Facility & Gear"):
            return facilityGear
        case String(localized: "Aftercare Support"):
            return aftercareSupport
        case String(localized: "Consultation Quality"):
            return consultationQuality
        case String(localized: "Result Satisfaction"):
            return resultSatisfaction
        default:
            return 0
        }
    }

    var isCommentValid: Bool {
        comment.trimmingCharacters(in: .whitespacesAndNewlines).count >= 50
    }

    var canSubmit: Bool {
        overallRating > 0 && isCommentValid
    }

    func setOverallRating(_ value: Int) {
        overallRating = value
        hasSetOverall = true
    }

    func updateOverallIfNeeded() {
        guard !hasSetOverall else { return }
        let ratings = [ratingWaitTime, ratingBedside, ratingEfficacy, ratingCleanliness, ratingStaff, ratingValue]
        guard ratings.allSatisfy({ $0 > 0 }) else {
            overallRating = 0
            return
        }
        let average = Double(ratings.reduce(0, +)) / Double(ratings.count)
        overallRating = Int(round(average))
    }

    func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)
    }

    func submit() async {
        guard await AuthService.currentSession() != nil else {
            submissionErrorMessage = String(localized: "Please sign in to submit a review.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if overallRating < 1 {
            submissionErrorMessage = String(localized: "Please complete all ratings before submitting.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        if trimmedComment.count < 50 {
            submissionErrorMessage = String(format: String(localized: "Your review must be at least 50 characters. Currently %lld / 50."), commentCharCount)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        if [ratingWaitTime, ratingBedside, ratingEfficacy, ratingCleanliness, ratingStaff, ratingValue].contains(where: { $0 < 1 }) {
            submissionErrorMessage = String(localized: "Please complete all ratings before submitting.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        if selectedImages.count > 5 {
            submissionErrorMessage = String(localized: "You can upload up to 5 photos.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        isSubmitting = true
        submissionErrorMessage = nil
        mediaUploadProgress = 0
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let priceLevel = max(1, min(4, Int(round(Double(ratingValue) / 1.25))))

        do {
            _ = try await ReviewService.submitReview(
                providerId: provider.id,
                visitDate: visitDate,
                visitType: visitType,
                ratings: (
                    wait: ratingWaitTime,
                    bedside: ratingBedside,
                    efficacy: ratingEfficacy,
                    cleanliness: ratingCleanliness,
                    staff: ratingStaff,
                    value: ratingValue
                ),
                overallRating: overallRating,
                priceLevel: priceLevel,
                title: title.isEmpty ? nil : title,
                comment: comment,
                wouldRecommend: wouldRecommend,
                proofImage: proofImage,
                images: selectedImages,
                videoURL: nil,
                progressHandler: { [weak self] progress in
                    Task { @MainActor in
                        self?.mediaUploadProgress = progress
                    }
                }
            )
            mediaUploadProgress = 1
            isComplete = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            let message = localizedErrorMessage(error)
            submissionErrorMessage = message
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        isSubmitting = false
    }

    private func localizedErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }

        let localized = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !localized.isEmpty,
           localized != "The operation couldn’t be completed." {
            return localized
        }

        let debugDescription = String(describing: error).trimmingCharacters(in: .whitespacesAndNewlines)
        if !debugDescription.isEmpty {
            return debugDescription
        }

        return String(localized: "Unknown error")
    }
}
