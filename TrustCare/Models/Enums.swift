import SwiftUI

enum VisitType: String, Codable, CaseIterable, Identifiable {
    case consultation, procedure, checkup, emergency, followUp = "follow_up"
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .consultation: return tcString("Consultation", fallback: "Consultation")
        case .procedure: return tcString("Procedure", fallback: "Procedure")
        case .checkup: return tcString("Checkup", fallback: "Checkup")
        case .emergency: return tcString("Emergency", fallback: "Emergency")
        case .followUp: return tcString("Follow-up", fallback: "Follow-up")
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
        case .active: return tcString("Active", fallback: "Active")
        case .pendingVerification: return tcString("Pending Verification", fallback: "Pending Verification")
        case .flagged: return tcString("Flagged", fallback: "Flagged")
        case .removed: return tcString("Removed", fallback: "Removed")
        }
    }
}

enum MediaType: String, Codable {
    case image, video

    var displayName: String {
        switch self {
        case .image: return tcString("Image", fallback: "Image")
        case .video: return tcString("Video", fallback: "Video")
        }
    }
}

enum SubscriptionTier: String, Codable {
    case free, basic, premium

    var displayName: String {
        switch self {
        case .free: return tcString("Free", fallback: "Free")
        case .basic: return tcString("Basic", fallback: "Basic")
        case .premium: return tcString("Premium", fallback: "Premium")
        }
    }
}

enum ClaimStatus: String, Codable {
    case pending, approved, rejected

    var displayName: String {
        switch self {
        case .pending: return tcString("Pending", fallback: "Pending")
        case .approved: return tcString("Approved", fallback: "Approved")
        case .rejected: return tcString("Rejected", fallback: "Rejected")
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
        case .uploadFailed: return tcString("Upload failed. Please try again.", fallback: "Upload failed. Please try again.")
        case .rateLimitExceeded: return tcString("Too many requests. Please try again later.", fallback: "Too many requests. Please try again later.")
        case .notFound: return tcString("Not found.", fallback: "Not found.")
        case .unknown: return tcString("Something went wrong.", fallback: "Something went wrong.")
        }
    }
}
