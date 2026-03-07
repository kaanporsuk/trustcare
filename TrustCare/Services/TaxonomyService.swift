import Foundation
import Supabase

enum TaxonomyService {
    private static let localizationCacheVersion = "taxonomy-v21-localization-phase1"

    struct TaxonomySearchResult {
        let suggestions: [TaxonomySuggestion]
        let usedEnglishFallback: Bool
    }

    private actor LabelCache {
        private var cacheVersion: String = TaxonomyService.localizationCacheVersion
        private var storage: [String: [String: String]] = [:]

        private func ensureVersion() {
            guard cacheVersion == TaxonomyService.localizationCacheVersion else {
                storage = [:]
                cacheVersion = TaxonomyService.localizationCacheVersion
                return
            }
        }

        func value(locale: String, entityId: String) -> String? {
            ensureVersion()
            return storage[locale]?[entityId]
        }

        func set(locale: String, mapping: [String: String]) {
            ensureVersion()
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

    static func displayLabel(for entityID: String, locale: String) async throws -> String {
        let normalizedID = TaxonomyIdentity.normalizedCanonicalID(entityID)
        guard !normalizedID.isEmpty else { return entityID }

        let labels = try await labelsByEntityID(entityIDs: [normalizedID], locale: locale)
        return labels[normalizedID] ?? normalizedID
    }

    static func localizedLabel(for entityID: String, locale: String, fallback: String) -> String {
        let normalizedLocale = TaxonomyIdentity.normalizedLocale(locale)
        let normalizedID = TaxonomyIdentity.normalizedCanonicalID(entityID)
        guard !normalizedID.isEmpty else { return fallback }

        if let resolved = TaxonomyCatalogStore.shared.localizedLabel(for: normalizedID, locale: normalizedLocale) {
            return resolved
        }

        return TaxonomyI18nLoader.shared.localizedLabel(
            for: normalizedID,
            locale: normalizedLocale,
            fallback: fallback
        )
    }

    static func localizedLabel(for suggestion: TaxonomySuggestion, locale: String) -> String {
        localizedLabel(for: suggestion.entityId, locale: locale, fallback: suggestion.label)
    }

    static func searchTaxonomy(
        query: String,
        locale: String,
        entityTypeFilter: TaxonomyEntityType? = nil,
        fallbackLocale: String = "en",
        limit: Int = 8
    ) async throws -> [TaxonomySuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let localMatches = localSearchTaxonomy(
            query: trimmed,
            locale: locale,
            entityTypeFilter: entityTypeFilter,
            limit: limit
        )
        if !localMatches.isEmpty {
            return localMatches
        }

        var params: [String: AnyJSON] = [
            "search_query": .string(trimmed),
            "current_locale": .string(locale),
            "fallback_locale": .string(fallbackLocale)
        ]

        if let entityTypeFilter {
            if let backendEntityType = entityTypeFilter.backendEntityType {
                params["entity_type_filter"] = .string(backendEntityType)
            }
        }

        let response: PostgrestResponse<[TaxonomySuggestion]> = try await client
            .rpc("search_taxonomy", params: params)
            .execute()

        let filtered = filterToCanonicalV21IfAvailable(response.value)
        let localized = applyLocalBundleOverrides(to: filtered, locale: locale)
        let deduped = dedupeSuggestions(localized)
        return Array(deduped.prefix(limit))
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
        let localSuggestions = TaxonomyCatalogStore.shared.localSuggestions(
            entityType: entityType,
            locale: locale,
            limit: limit
        )
        if !localSuggestions.isEmpty {
            return dedupeSuggestions(localSuggestions)
        }

        guard let backendEntityType = entityType.backendEntityType else {
            return []
        }

        let response: PostgrestResponse<[TaxonomyEntityRow]> = try await client
            .from("taxonomy_entities")
            .select("id,entity_type,default_name,sort_priority")
            .eq("entity_type", value: backendEntityType)
            .order("sort_priority", ascending: true)
            .order("default_name", ascending: true)
            .limit(limit)
            .execute()

        let entityIDs = response.value.map { $0.id }
        let labels = try await labelsByEntityID(entityIDs: entityIDs, locale: locale, entityType: entityType)

        let mapped = response.value.map { row in
            let mappedType = TaxonomyEntityType.fromBackend(row.entityType ?? backendEntityType)?.rawValue ?? entityType.rawValue
            let resolvedLabel = TaxonomyI18nLoader.shared.localizedLabel(
                for: row.id,
                locale: locale,
                fallback: labels[row.id] ?? row.defaultName
            )
            return TaxonomySuggestion(
                entityId: row.id,
                entityType: mappedType,
                label: resolvedLabel,
                score: nil
            )
        }
        return dedupeSuggestions(mapped)
    }

    static func searchProvidersByTaxonomy(entityIDs: [String]) async throws -> [Provider] {
        let normalized = Array(Set(entityIDs.map { TaxonomyIdentity.normalizedCanonicalID($0) }))
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
            .map { TaxonomyIdentity.normalizedCanonicalID($0) }
            .filter { !$0.isEmpty }

        guard !normalized.isEmpty else { return [] }

        let uniqueInput = Array(Set(normalized))
        let localValidSet = Set(uniqueInput.filter { TaxonomyCatalogStore.shared.containsCanonicalID($0) })

        if localValidSet.count == uniqueInput.count {
            var seen = Set<String>()
            var orderedValid: [String] = []
            for entityID in normalized where localValidSet.contains(entityID) {
                if seen.insert(entityID).inserted {
                    orderedValid.append(entityID)
                }
            }
            return orderedValid
        }

        let response: PostgrestResponse<[TaxonomyEntityRow]> = try await client
            .from("taxonomy_entities")
            .select("id")
            .in("id", values: uniqueInput)
            .execute()

        let validSet = localValidSet.union(Set(response.value.map(\.id)))
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

    static func labelsByEntityID(
        entityIDs: [String],
        locale: String,
        entityType: TaxonomyEntityType? = nil
    ) async throws -> [String: String] {
        let normalizedIDs = Array(Set(entityIDs.map { TaxonomyIdentity.normalizedCanonicalID($0) }))
            .filter { !$0.isEmpty }
        let normalizedLocale = TaxonomyIdentity.normalizedLocale(locale)

        guard !normalizedIDs.isEmpty else { return [:] }

        var result: [String: String] = [:]
        var missing: [String] = []

        for entityID in normalizedIDs {
            if let localResolution = TaxonomyCatalogStore.shared.localizedLabelResolution(for: entityID, locale: normalizedLocale) {
                result[entityID] = localResolution.label
                logLabelFallbackIfNeeded(
                    entityType: entityType,
                    locale: normalizedLocale,
                    incomingID: entityID,
                    normalizedID: localResolution.normalizedIncomingID,
                    source: localResolution.source
                )
                continue
            }

            if let cached = await labelCache.value(locale: normalizedLocale, entityId: entityID) {
                result[entityID] = cached
                logLabelFallbackIfNeeded(
                    entityType: entityType,
                    locale: normalizedLocale,
                    incomingID: entityID,
                    normalizedID: TaxonomyIdentity.normalizedCanonicalID(entityID),
                    source: "label_cache"
                )
            } else {
                missing.append(entityID)
            }
        }

        guard !missing.isEmpty else { return result }

        let localizedResponse: PostgrestResponse<[TaxonomyLabelRow]> = try await client
            .from("taxonomy_labels")
            .select("entity_id,label")
            .eq("locale", value: normalizedLocale)
            .in("entity_id", values: missing)
            .execute()

        let localized = Dictionary(uniqueKeysWithValues: localizedResponse.value.map { ($0.entityId, $0.label) })

        let unresolvedAfterLocalized = missing.filter { localized[$0] == nil }
        var englishFallback: [String: String] = [:]

        if !unresolvedAfterLocalized.isEmpty {
            let englishResponse: PostgrestResponse<[TaxonomyLabelRow]> = try await client
                .from("taxonomy_labels")
                .select("entity_id,label")
                .eq("locale", value: "en")
                .in("entity_id", values: unresolvedAfterLocalized)
                .execute()
            englishFallback = Dictionary(uniqueKeysWithValues: englishResponse.value.map { ($0.entityId, $0.label) })
        }

        let unresolvedAfterEnglish = unresolvedAfterLocalized.filter { englishFallback[$0] == nil }
        var defaultFallback: [String: String] = [:]

        if !unresolvedAfterEnglish.isEmpty {
            let fallbackResponse: PostgrestResponse<[TaxonomyEntityRow]> = try await client
                .from("taxonomy_entities")
                .select("id,default_name")
                .in("id", values: unresolvedAfterEnglish)
                .execute()
            defaultFallback = Dictionary(uniqueKeysWithValues: fallbackResponse.value.map { ($0.id, $0.defaultName) })
        }

        let merged = localized
            .merging(englishFallback) { current, _ in current }
            .merging(defaultFallback) { current, _ in current }
        await labelCache.set(locale: normalizedLocale, mapping: merged)

        for entityID in missing {
            if let value = merged[entityID] {
                result[entityID] = TaxonomyI18nLoader.shared.localizedLabel(
                    for: entityID,
                    locale: normalizedLocale,
                    fallback: value
                )
                let source = localized[entityID] != nil
                    ? "locale_label_map"
                    : (englishFallback[entityID] != nil ? "english_label_map" : "backend_default_name")
                logLabelFallbackIfNeeded(
                    entityType: entityType,
                    locale: normalizedLocale,
                    incomingID: entityID,
                    normalizedID: TaxonomyIdentity.normalizedCanonicalID(entityID),
                    source: source
                )
            } else {
                logLabelMiss(
                    entityType: entityType,
                    locale: normalizedLocale,
                    incomingID: entityID,
                    normalizedID: TaxonomyIdentity.normalizedCanonicalID(entityID),
                    source: "unresolved"
                )
            }
        }

        for (entityID, value) in result {
            result[entityID] = TaxonomyI18nLoader.shared.localizedLabel(
                for: entityID,
                locale: normalizedLocale,
                fallback: value
            )
        }

        return result
    }

    private static func logLabelFallbackIfNeeded(
        entityType: TaxonomyEntityType?,
        locale: String,
        incomingID: String,
        normalizedID: String,
        source: String
    ) {
#if DEBUG
        let isFallbackSource = source.contains("english") || source.contains("default") || source.contains("alias") || source == "label_cache"
        if isFallbackSource {
            NSLog("[TaxonomyLabelFallback] entityType=\(entityType?.rawValue ?? "unknown") locale=\(locale) incomingID=\(incomingID) normalizedID=\(normalizedID) source=\(source)")
        }
#endif
    }

    private static func logLabelMiss(
        entityType: TaxonomyEntityType?,
        locale: String,
        incomingID: String,
        normalizedID: String,
        source: String
    ) {
#if DEBUG
        NSLog("[TaxonomyLabelMiss] entityType=\(entityType?.rawValue ?? "unknown") locale=\(locale) incomingID=\(incomingID) normalizedID=\(normalizedID) source=\(source)")
#endif
    }

    private static func applyLocalBundleOverrides(to suggestions: [TaxonomySuggestion], locale: String) -> [TaxonomySuggestion] {
        suggestions.map { suggestion in
            let label = localizedLabel(for: suggestion, locale: locale)
            let canonicalType = TaxonomyEntityType.fromBackend(suggestion.entityType)?.rawValue ?? suggestion.entityType
            return TaxonomySuggestion(
                entityId: suggestion.entityId,
                entityType: canonicalType,
                label: label,
                score: suggestion.score
            )
        }
    }

    private static func filterToCanonicalV21IfAvailable(_ suggestions: [TaxonomySuggestion]) -> [TaxonomySuggestion] {
        // If local corpus is present, v2.1 resources are the authoritative set.
        guard TaxonomyCatalogStore.shared.hasLocalTaxonomyCorpus() else {
            return suggestions
        }

        return suggestions.filter { suggestion in
            TaxonomyCatalogStore.shared.containsCanonicalID(suggestion.entityId)
        }
    }

    private static func dedupeSuggestions(_ suggestions: [TaxonomySuggestion]) -> [TaxonomySuggestion] {
        var seenEntityIDs = Set<String>()
        var seenDisplayKeys = Set<String>()
        var ordered: [TaxonomySuggestion] = []

        for suggestion in suggestions {
            let normalizedEntityID = suggestion.entityId.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalizedEntityID.isEmpty else { continue }
            guard seenEntityIDs.insert(normalizedEntityID).inserted else { continue }

            let displayKey = "\(suggestion.entityType.lowercased())|\(normalizedDisplayLabel(suggestion.label))"
            guard seenDisplayKeys.insert(displayKey).inserted else { continue }

            ordered.append(
                TaxonomySuggestion(
                    entityId: normalizedEntityID,
                    entityType: suggestion.entityType,
                    label: suggestion.label,
                    score: suggestion.score
                )
            )
        }

        return ordered
    }

    private static func normalizedDisplayLabel(_ label: String) -> String {
        label
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func localSearchTaxonomy(
        query: String,
        locale: String,
        entityTypeFilter: TaxonomyEntityType?,
        limit: Int
    ) -> [TaxonomySuggestion] {
        let normalizedQuery = normalizedDisplayLabel(query)
        guard !normalizedQuery.isEmpty else { return [] }

        var candidates = TaxonomyCatalogStore.shared.localSuggestions(entityType: entityTypeFilter, locale: locale, limit: 1000)
        if candidates.isEmpty {
            return []
        }

        candidates = candidates.compactMap { suggestion in
            let aliases = TaxonomyCatalogStore.shared.aliases(for: suggestion.entityId, locale: locale)
            let searchable = [suggestion.label, suggestion.entityId] + aliases
            let matched = searchable.contains { normalizedDisplayLabel($0).contains(normalizedQuery) }
            guard matched else { return nil }
            return suggestion
        }

        return Array(dedupeSuggestions(candidates).prefix(limit))
    }
}
