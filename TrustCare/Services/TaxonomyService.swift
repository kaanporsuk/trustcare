import Foundation
import Supabase

enum TaxonomyService {
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
        let defaultName: String

        enum CodingKeys: String, CodingKey {
            case id
            case defaultName = "default_name"
        }
    }

    private static var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private static let labelCache = LabelCache()

    static func searchTaxonomy(query: String, locale: String, limit: Int = 8) async throws -> [TaxonomySuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let params: [String: AnyJSON] = [
            "search_query": .string(trimmed),
            "current_locale": .string(locale)
        ]

        let response: PostgrestResponse<[TaxonomySuggestion]> = try await client
            .rpc("search_taxonomy", params: params)
            .execute()

        return Array(response.value.prefix(limit))
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
