import Foundation
import Supabase

enum TaxonomyService {
    struct TaxonomySearchResult {
        let suggestions: [TaxonomySuggestion]
        let usedEnglishFallback: Bool
    }

    private actor LabelCache {
        private var storage: [String: [String: String]] = [:]

        func value(locale: String, entityId: String) -> String? {
            storage[locale]?[entityId]
        }

        func set(locale: String, mapping: [String: String]) {
            var existing = storage[locale] ?? [:]
            for (key, value) in mapping {
                existing[key] = value
            }
            storage[locale] = existing
        }
    }

    private struct TaxonomyLabelRow: Decodable {
        let entityId: String
        let label: String

        enum CodingKeys: String, CodingKey {
            case entityId = "entity_id"
            case label
        }
    }

    private struct TaxonomyEntityRow: Decodable {
        let id: String
        let entityType: String?
        let defaultName: String
        let sortPriority: Int?

        enum CodingKeys: String, CodingKey {
            case id
            case entityType = "entity_type"
            case defaultName = "default_name"
            case sortPriority = "sort_priority"
        }
    }

    private static var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private static let labelCache = LabelCache()

    static func searchTaxonomy(
        query: String,
        locale: String,
        entityTypeFilter: TaxonomyEntityType? = nil,
        fallbackLocale: String = "en",
        limit: Int = 8
    ) async throws -> [TaxonomySuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var params: [String: AnyJSON] = [
            "search_query": .string(trimmed),
            "current_locale": .string(locale),
            "fallback_locale": .string(fallbackLocale)
        ]

        if let entityTypeFilter {
            params["entity_type_filter"] = .string(entityTypeFilter.rawValue)
        }

        let response: PostgrestResponse<[TaxonomySuggestion]> = try await client
            .rpc("search_taxonomy", params: params)
            .execute()

        return Array(response.value.prefix(limit))
    }

    static func searchTaxonomyWithLocaleFallback(
        query: String,
        locale: String,
        entityTypeFilter: TaxonomyEntityType? = nil,
        limit: Int = 50
    ) async throws -> TaxonomySearchResult {
        let localizedResults = try await searchTaxonomy(
            query: query,
            locale: locale,
            entityTypeFilter: entityTypeFilter,
            fallbackLocale: "",
            limit: limit
        )

        if !localizedResults.isEmpty || locale.lowercased() == "en" {
            return TaxonomySearchResult(suggestions: localizedResults, usedEnglishFallback: false)
        }

        let englishResults = try await searchTaxonomy(
            query: query,
            locale: "en",
            entityTypeFilter: entityTypeFilter,
            fallbackLocale: "en",
            limit: limit
        )

        return TaxonomySearchResult(suggestions: englishResults, usedEnglishFallback: !englishResults.isEmpty)
    }

    static func browseTaxonomy(entityType: TaxonomyEntityType, locale: String, limit: Int = 120) async throws -> [TaxonomySuggestion] {
        let response: PostgrestResponse<[TaxonomyEntityRow]> = try await client
            .from("taxonomy_entities")
            .select("id,entity_type,default_name,sort_priority")
            .eq("entity_type", value: entityType.rawValue)
            .order("sort_priority", ascending: true)
            .order("default_name", ascending: true)
            .limit(limit)
            .execute()

        let entityIDs = response.value.map { $0.id }
        let labels = try await labelsByEntityID(entityIDs: entityIDs, locale: locale)

        return response.value.map { row in
            TaxonomySuggestion(
                entityId: row.id,
                entityType: row.entityType ?? entityType.rawValue,
                label: labels[row.id] ?? row.defaultName,
                score: nil
            )
        }
    }

    static func searchProvidersByTaxonomy(entityIDs: [String]) async throws -> [Provider] {
        let normalized = Array(Set(entityIDs.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }))
            .filter { !$0.isEmpty }

        guard !normalized.isEmpty else { return [] }

        let params: [String: AnyJSON] = [
            "entity_ids": .array(normalized.map { .string($0) })
        ]

        let response: PostgrestResponse<[Provider]> = try await client
            .rpc("search_providers_by_taxonomy", params: params)
            .execute()

        return response.value
    }

    static func validateEntityIDs(_ entityIDs: [String]) async throws -> [String] {
        let normalized = entityIDs
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !normalized.isEmpty else { return [] }

        let uniqueInput = Array(Set(normalized))
        let response: PostgrestResponse<[TaxonomyEntityRow]> = try await client
            .from("taxonomy_entities")
            .select("id")
            .in("id", values: uniqueInput)
            .execute()

        let validSet = Set(response.value.map(\.id))
        var seen = Set<String>()
        var orderedValid: [String] = []

        for entityID in normalized where validSet.contains(entityID) {
            if !seen.contains(entityID) {
                seen.insert(entityID)
                orderedValid.append(entityID)
            }
        }

        return orderedValid
    }

    static func labelsByEntityID(entityIDs: [String], locale: String) async throws -> [String: String] {
        let normalizedIDs = Array(Set(entityIDs.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }))
            .filter { !$0.isEmpty }

        guard !normalizedIDs.isEmpty else { return [:] }

        var result: [String: String] = [:]
        var missing: [String] = []

        for entityID in normalizedIDs {
            if let cached = await labelCache.value(locale: locale, entityId: entityID) {
                result[entityID] = cached
            } else {
                missing.append(entityID)
            }
        }

        guard !missing.isEmpty else { return result }

        let localizedResponse: PostgrestResponse<[TaxonomyLabelRow]> = try await client
            .from("taxonomy_labels")
            .select("entity_id,label")
            .eq("locale", value: locale)
            .in("entity_id", values: missing)
            .execute()

        let localized = Dictionary(uniqueKeysWithValues: localizedResponse.value.map { ($0.entityId, $0.label) })

        let unresolved = missing.filter { localized[$0] == nil }
        var fallback: [String: String] = [:]

        if !unresolved.isEmpty {
            let fallbackResponse: PostgrestResponse<[TaxonomyEntityRow]> = try await client
                .from("taxonomy_entities")
                .select("id,default_name")
                .in("id", values: unresolved)
                .execute()
            fallback = Dictionary(uniqueKeysWithValues: fallbackResponse.value.map { ($0.id, $0.defaultName) })
        }

        let merged = localized.merging(fallback) { current, _ in current }
        await labelCache.set(locale: locale, mapping: merged)

        for entityID in missing {
            if let value = merged[entityID] {
                result[entityID] = value
            }
        }

        return result
    }
}
