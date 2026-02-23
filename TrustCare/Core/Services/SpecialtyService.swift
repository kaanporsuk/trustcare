import Combine
import Foundation
import Supabase

@MainActor
final class SpecialtyService: ObservableObject {
    static let shared = SpecialtyService()

    @Published var specialties: [Specialty] = []
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
            let response: [Specialty] = try await SupabaseManager.shared.client
                .from("specialties")
                .select("id, name, name_tr, name_de, name_pl, name_nl, name_da, category, subcategory, icon_name, survey_type, color_hex, display_order, is_popular, is_active")
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

    func popularSpecialties() -> [Specialty] {
        specialties.filter { $0.isPopular }
    }

    func specialtiesByCategory() -> [(category: String, items: [Specialty])] {
        let grouped = Dictionary(grouping: specialties) { $0.category }
        return grouped
            .sorted { ($0.value.first?.displayOrder ?? 0) < ($1.value.first?.displayOrder ?? 0) }
            .map { (category: $0.key, items: $0.value) }
    }

    func surveyType(for specialtyName: String) -> String {
        guard !specialties.isEmpty else {
            return inferSurveyTypeFromKeywords(specialtyName)
        }

        let lower = specialtyName.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))

        if let match = specialties.first(where: {
            [
                $0.name,
                $0.nameTr,
                $0.nameDe,
                $0.namePl,
                $0.nameNl,
                $0.nameDa,
            ]
            .compactMap { $0?.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR")) }
            .contains(lower)
        }) {
            return match.surveyType
        }

        if let match = specialties.first(where: {
            [
                $0.name,
                $0.nameTr,
                $0.nameDe,
                $0.namePl,
                $0.nameNl,
                $0.nameDa,
            ]
            .compactMap { $0?.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR")) }
            .contains { lower.contains($0) }
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
        if lower.contains("pharmacy") || lower.contains("eczane") { return "pharmacy" }
        if lower.contains("hospital") || lower.contains("hastane") { return "hospital" }
        if lower.contains("dentist") || lower.contains("diş") || lower.contains("dental") { return "dental" }
        if lower.contains("psychi") || lower.contains("psycho") || lower.contains("psiki") || lower.contains("terapi") { return "mental_health" }
        if lower.contains("physio") || lower.contains("fizik tedavi") || lower.contains("rehabilit") { return "rehabilitation" }
        if lower.contains("lab") || lower.contains("radiol") || lower.contains("patol") || lower.contains("röntgen") { return "diagnostic" }
        if lower.contains("estetik") || lower.contains("aesthetic") || lower.contains("cosmetic") || lower.contains("saç ekimi") { return "aesthetics" }
        return "general_clinic"
    }

    private func saveToCache(_ data: [Specialty]) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
        }
    }

    private func loadFromCache() -> [Specialty]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode([Specialty].self, from: data) else {
            return nil
        }
        return decoded
    }

    private func isCacheExpired() -> Bool {
        let timestamp = UserDefaults.standard.double(forKey: cacheTimestampKey)
        return Date().timeIntervalSince1970 - timestamp > cacheDuration
    }
}
