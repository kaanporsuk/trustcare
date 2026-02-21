import Combine
import Foundation
import Supabase

struct SpecialtyItem: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let nameTr: String?
    let category: String
    let subcategory: String?
    let iconName: String
    let surveyType: String
    let displayOrder: Int
    let isPopular: Bool
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, category, subcategory
        case nameTr = "name_tr"
        case iconName = "icon_name"
        case surveyType = "survey_type"
        case displayOrder = "display_order"
        case isPopular = "is_popular"
        case isActive = "is_active"
    }
}

@MainActor
final class SpecialtyService: ObservableObject {
    static let shared = SpecialtyService()

    @Published var specialties: [SpecialtyItem] = []
    @Published var isLoaded = false

    private let cacheKey = "cached_specialties_v2"
    private let cacheTimestampKey = "specialties_cache_timestamp_v2"
    private let cacheDuration: TimeInterval = 86400

    func loadSpecialties() async {
        if let cached = loadFromCache(), !isCacheExpired() {
            specialties = cached
            isLoaded = true
            return
        }

        do {
            let response: [SpecialtyItem] = try await SupabaseManager.shared.client
                .from("specialties")
                .select()
                .eq("is_active", value: true)
                .order("display_order")
                .execute()
                .value
            specialties = response
            isLoaded = true
            saveToCache(response)
        } catch {
            print("Failed to load specialties: \(error)")
            if let cached = loadFromCache() {
                specialties = cached
                isLoaded = true
            }
        }
    }

    func popularSpecialties() -> [SpecialtyItem] {
        specialties.filter { $0.isPopular }
    }

    func specialtiesByCategory() -> [(category: String, items: [SpecialtyItem])] {
        let grouped = Dictionary(grouping: specialties) { $0.category }
        return grouped
            .sorted { ($0.value.first?.displayOrder ?? 0) < ($1.value.first?.displayOrder ?? 0) }
            .map { (category: $0.key, items: $0.value) }
    }

    func surveyType(for specialtyName: String) -> String {
        guard !specialties.isEmpty else {
            return inferSurveyTypeFromKeywords(specialtyName)
        }

        let lower = specialtyName.lowercased()

        if let match = specialties.first(where: { $0.name.lowercased() == lower }) {
            return match.surveyType
        }

        if let match = specialties.first(where: { $0.nameTr?.lowercased() == lower }) {
            return match.surveyType
        }

        if let match = specialties.first(where: { lower.contains($0.name.lowercased()) }) {
            return match.surveyType
        }

        if let match = specialties.first(where: {
            guard let tr = $0.nameTr?.lowercased() else { return false }
            return lower.contains(tr)
        }) {
            return match.surveyType
        }

        return inferSurveyTypeFromKeywords(specialtyName)
    }

    func surveyConfig(for specialtyName: String) -> SurveyConfig {
        SurveyConfigurations.config(for: surveyType(for: specialtyName))
    }

    private func inferSurveyTypeFromKeywords(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("pharmacy") || lower.contains("eczane") || lower.contains("apotek") { return "pharmacy" }
        if lower.contains("hospital") || lower.contains("hastane") || lower.contains("urgent") || lower.contains("acil") { return "hospital" }
        if lower.contains("dentist") || lower.contains("diş") || lower.contains("dental") || lower.contains("orthodon") { return "dental" }
        if lower.contains("psychi") || lower.contains("psycho") || lower.contains("psiki") || lower.contains("terapi") || lower.contains("psikoloj") { return "mental_health" }
        if lower.contains("physio") || lower.contains("fizik tedavi") || lower.contains("rehabilit") { return "rehabilitation" }
        if lower.contains("lab") || lower.contains("radyoloj") || lower.contains("radiol") || lower.contains("patoloj") { return "diagnostic" }
        if lower.contains("estetik") || lower.contains("aesthetic") || lower.contains("cosmetic") || lower.contains("saç ekimi") || lower.contains("hair transplant") { return "aesthetics" }
        return "general_clinic"
    }

    private func saveToCache(_ data: [SpecialtyItem]) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
        }
    }

    private func loadFromCache() -> [SpecialtyItem]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode([SpecialtyItem].self, from: data) else {
            return nil
        }
        return decoded
    }

    private func isCacheExpired() -> Bool {
        let timestamp = UserDefaults.standard.double(forKey: cacheTimestampKey)
        return Date().timeIntervalSince1970 - timestamp > cacheDuration
    }
}
