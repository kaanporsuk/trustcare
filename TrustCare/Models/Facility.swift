import Foundation

struct Facility: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let city: String?
    let countryCode: String?
    let canonicalFacilityTypeId: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case city
        case countryCode = "country_code"
        case canonicalFacilityTypeId = "canonical_facility_type_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
