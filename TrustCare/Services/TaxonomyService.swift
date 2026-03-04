import Foundation
import Supabase

enum TaxonomyService {
    private static var client: SupabaseClient {
        SupabaseManager.shared.client
    }

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
}
