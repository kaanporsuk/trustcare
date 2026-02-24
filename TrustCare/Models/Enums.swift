import SwiftUI

enum VisitType: String, Codable, CaseIterable, Identifiable {
    case consultation, procedure, checkup, emergency, followUp = "follow_up"
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .consultation: return String(localized: "Consultation")
        case .procedure: return String(localized: "Procedure")
        case .checkup: return String(localized: "Checkup")
        case .emergency: return String(localized: "Emergency")
        case .followUp: return String(localized: "Follow-up")
        }
    }
}

enum PriceLevel: Int, Codable, CaseIterable, Identifiable {
    case budget = 1, moderate = 2, aboveAverage = 3, premium = 4
    var id: Int { rawValue }
    var symbol: String { String(repeating: "$", count: rawValue) }
    var labelKey: String {
        switch self {
        case .budget: return "Budget-friendly"
        case .moderate: return "Moderate"
        case .aboveAverage: return "Above average"
        case .premium: return "Premium"
        }
    }
}

enum ReviewStatus: String, Codable {
    case active
    case pendingVerification = "pending_verification"
    case flagged, removed

    var displayName: String {
        switch self {
        case .active: return String(localized: "Active")
        case .pendingVerification: return String(localized: "Pending Verification")
        case .flagged: return String(localized: "Flagged")
        case .removed: return String(localized: "Removed")
        }
    }
}

enum MediaType: String, Codable {
    case image, video

    var displayName: String {
        switch self {
        case .image: return String(localized: "Image")
        case .video: return String(localized: "Video")
        }
    }
}

enum SubscriptionTier: String, Codable {
    case free, basic, premium

    var displayName: String {
        switch self {
        case .free: return String(localized: "Free")
        case .basic: return String(localized: "Basic")
        case .premium: return String(localized: "Premium")
        }
    }
}

enum ClaimStatus: String, Codable {
    case pending, approved, rejected

    var displayName: String {
        switch self {
        case .pending: return String(localized: "Pending")
        case .approved: return String(localized: "Approved")
        case .rejected: return String(localized: "Rejected")
        }
    }
}

enum ClaimRole: String, Codable, CaseIterable, Identifiable {
    case owner, manager, representative
    var id: String { rawValue }
    var displayNameKey: String {
        switch self {
        case .owner: return "Owner"
        case .manager: return "Manager"
        case .representative: return "Authorized Representative"
        }
    }
}

enum AppError: Error, LocalizedError {
    case networkError(String)
    case authError(String)
    case validationError(String)
    case uploadFailed
    case rateLimitExceeded
    case notFound
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return msg
        case .authError(let msg): return msg
        case .validationError(let msg): return msg
        case .uploadFailed: return String(localized: "Upload failed. Please try again.")
        case .rateLimitExceeded: return String(localized: "Too many requests. Please try again later.")
        case .notFound: return String(localized: "Not found.")
        case .unknown: return String(localized: "Something went wrong.")
        }
    }
}
