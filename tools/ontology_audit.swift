#!/usr/bin/env swift
import Foundation
import Dispatch

struct AuditCheck {
    let name: String
    let required: Bool
    let passed: Bool
    let details: String
}

struct SearchCase {
    let label: String
    let query: String
    let locale: String
    let expectedEntityID: String
}

enum AuditError: Error, CustomStringConvertible {
    case missingEnv(String)
    case invalidURL(String)
    case requestFailed(String)
    case parseFailed(String)

    var description: String {
        switch self {
        case .missingEnv(let key): return "Missing env var: \(key)"
        case .invalidURL(let message): return "Invalid URL: \(message)"
        case .requestFailed(let message): return "Request failed: \(message)"
        case .parseFailed(let message): return "Parse failed: \(message)"
        }
    }
}

struct OntologyAudit {
    static func run() async {
        do {
            let config = try Config.fromEnvironment()
            let client = SupabaseRESTClient(config: config)
            let checks = try await runChecks(client: client)

            print("\n=== TrustCare Ontology Audit ===")
            for check in checks {
                let marker = check.passed ? "PASS" : (check.required ? "FAIL" : "WARN")
                print("[\(marker)] \(check.name): \(check.details)")
            }

            let requiredFailures = checks.filter { $0.required && !$0.passed }
            if requiredFailures.isEmpty {
                print("\nResult: PASS")
                exit(0)
            } else {
                print("\nResult: FAIL (\(requiredFailures.count) required checks failed)")
                exit(1)
            }
        } catch {
            fputs("Ontology audit failed to run: \(error)\n", stderr)
            exit(2)
        }
    }

    static func runChecks(client: SupabaseRESTClient) async throws -> [AuditCheck] {
        var checks: [AuditCheck] = []

        let nullCanonicalCount = try await client.count(
            table: "specialties",
            queryItems: [
                URLQueryItem(name: "select", value: "id"),
                URLQueryItem(name: "or", value: "(canonical_entity_id.is.null,canonical_entity_type.is.null)")
            ]
        )
        checks.append(
            AuditCheck(
                name: "specialties canonical nulls",
                required: true,
                passed: nullCanonicalCount == 0,
                details: "rows with null canonical fields = \(nullCanonicalCount)"
            )
        )

        let specialtyCanonicalRows = try await client.fetchArray(
            table: "specialties",
            queryItems: [
                URLQueryItem(name: "select", value: "id,canonical_entity_id"),
                URLQueryItem(name: "canonical_entity_id", value: "not.is.null"),
                URLQueryItem(name: "limit", value: "10000")
            ]
        )
        let canonicalIDs = specialtyCanonicalRows.compactMap { row -> String? in
            (row["canonical_entity_id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        let uniqueCanonicalIDs = Array(Set(canonicalIDs)).sorted()

        let taxonomyRows = try await client.fetchArray(
            table: "taxonomy_entities",
            queryItems: [
                URLQueryItem(name: "select", value: "id"),
                URLQueryItem(name: "limit", value: "10000")
            ]
        )
        let taxonomyIDs = Set(taxonomyRows.compactMap { $0["id"] as? String })
        let missingCanonicalIDs = uniqueCanonicalIDs.filter { !taxonomyIDs.contains($0) }

        checks.append(
            AuditCheck(
                name: "specialties canonical FK integrity",
                required: true,
                passed: missingCanonicalIDs.isEmpty,
                details: "missing canonical IDs in taxonomy_entities = \(missingCanonicalIDs.count)"
            )
        )

        let taxonomyEntityCount = try await client.count(
            table: "taxonomy_entities",
            queryItems: [URLQueryItem(name: "select", value: "id")]
        )
        let enLabelCount = try await client.count(
            table: "taxonomy_labels",
            queryItems: [
                URLQueryItem(name: "select", value: "entity_id"),
                URLQueryItem(name: "locale", value: "eq.en")
            ]
        )

        checks.append(
            AuditCheck(
                name: "taxonomy_labels en coverage",
                required: true,
                passed: enLabelCount == taxonomyEntityCount,
                details: "en labels = \(enLabelCount), entities = \(taxonomyEntityCount)"
            )
        )

        let providerTaxonomyCount = try await client.count(
            table: "provider_taxonomy",
            queryItems: [URLQueryItem(name: "select", value: "provider_id")]
        )

        let providerSpecialtiesCount: Int
        do {
            providerSpecialtiesCount = try await client.count(
                table: "provider_specialties",
                queryItems: [URLQueryItem(name: "select", value: "provider_id")]
            )
        } catch {
            providerSpecialtiesCount = (try? await client.count(
                table: "providers",
                queryItems: [
                    URLQueryItem(name: "select", value: "id"),
                    URLQueryItem(name: "specialty_id", value: "not.is.null")
                ]
            )) ?? 0
        }

        let providerDelta = providerTaxonomyCount - providerSpecialtiesCount
        checks.append(
            AuditCheck(
                name: "provider_taxonomy coverage",
                required: true,
                passed: providerTaxonomyCount >= providerSpecialtiesCount,
                details: "provider_taxonomy = \(providerTaxonomyCount), provider_specialties = \(providerSpecialtiesCount), delta = \(providerDelta)"
            )
        )

        let entTarget = try await preferredExistingEntityID(
            candidates: ["SPEC_ENT", "SPEC_ENT_OTOLARYNGOLOGY"],
            client: client
        )
        let gpTarget = try await preferredExistingEntityID(
            candidates: ["SPEC_GENERAL_PRACTICE", "SPEC_FAMILY_MEDICINE"],
            client: client
        )

        let smokeTests = [
            SearchCase(label: "search_taxonomy smoke (ent/en)", query: "ent", locale: "en", expectedEntityID: entTarget),
            SearchCase(label: "search_taxonomy smoke (kbb/tr)", query: "kbb", locale: "tr", expectedEntityID: entTarget),
            SearchCase(label: "search_taxonomy smoke (hno/de)", query: "hno", locale: "de", expectedEntityID: entTarget),
            SearchCase(label: "search_taxonomy smoke (orl/fr)", query: "orl", locale: "fr", expectedEntityID: entTarget),
            SearchCase(label: "search_taxonomy smoke (gp/en)", query: "gp", locale: "en", expectedEntityID: gpTarget)
        ]

        for smoke in smokeTests {
            let rows = try await client.callSearchTaxonomy(query: smoke.query, locale: smoke.locale)
            let ids = rows.compactMap { $0["entity_id"] as? String }
            let passed = ids.contains(smoke.expectedEntityID)
            checks.append(
                AuditCheck(
                    name: smoke.label,
                    required: true,
                    passed: passed,
                    details: "expected \(smoke.expectedEntityID), got top IDs: \(Array(ids.prefix(5)))"
                )
            )
        }

        return checks
    }

    static func preferredExistingEntityID(candidates: [String], client: SupabaseRESTClient) async throws -> String {
        let rows = try await client.fetchArray(
            table: "taxonomy_entities",
            queryItems: [
                URLQueryItem(name: "select", value: "id"),
                URLQueryItem(name: "id", value: "in.(\(candidates.joined(separator: ",")))")
            ]
        )
        let found = Set(rows.compactMap { $0["id"] as? String })
        if let preferred = candidates.first(where: { found.contains($0) }) {
            return preferred
        }
        throw AuditError.parseFailed("Could not find any candidate entity IDs: \(candidates)")
    }
}

let semaphore = DispatchSemaphore(value: 0)
Task {
    await OntologyAudit.run()
    semaphore.signal()
}
semaphore.wait()

struct Config {
    let baseURL: URL
    let apiKey: String

    static func fromEnvironment() throws -> Config {
        let env = ProcessInfo.processInfo.environment
        guard let rawURL = env["SUPABASE_URL"], !rawURL.isEmpty else {
            throw AuditError.missingEnv("SUPABASE_URL")
        }
        guard let url = URL(string: rawURL) else {
            throw AuditError.invalidURL(rawURL)
        }

        let key = env["SUPABASE_SERVICE_ROLE_KEY"] ?? env["SUPABASE_ANON_KEY"]
        guard let apiKey = key, !apiKey.isEmpty else {
            throw AuditError.missingEnv("SUPABASE_SERVICE_ROLE_KEY (or SUPABASE_ANON_KEY)")
        }

        return Config(baseURL: url, apiKey: apiKey)
    }
}

final class SupabaseRESTClient {
    private let config: Config
    private let session = URLSession.shared

    init(config: Config) {
        self.config = config
    }

    func count(table: String, queryItems: [URLQueryItem]) async throws -> Int {
        let response = try await request(
            method: "GET",
            path: "/rest/v1/\(table)",
            queryItems: queryItems,
            body: nil,
            extraHeaders: [
                "Prefer": "count=exact",
                "Range": "0-0"
            ]
        )

        guard let contentRange = response.http.value(forHTTPHeaderField: "Content-Range") else {
            throw AuditError.parseFailed("Missing Content-Range for table \(table)")
        }

        guard let slashIndex = contentRange.lastIndex(of: "/") else {
            throw AuditError.parseFailed("Unexpected Content-Range format: \(contentRange)")
        }

        let countPart = contentRange[contentRange.index(after: slashIndex)...]
        guard let count = Int(countPart) else {
            throw AuditError.parseFailed("Could not parse count from Content-Range: \(contentRange)")
        }

        return count
    }

    func fetchArray(table: String, queryItems: [URLQueryItem]) async throws -> [[String: Any]] {
        let response = try await request(
            method: "GET",
            path: "/rest/v1/\(table)",
            queryItems: queryItems,
            body: nil,
            extraHeaders: [:]
        )
        return try parseJSONArray(response.data)
    }

    func callSearchTaxonomy(query: String, locale: String) async throws -> [[String: Any]] {
        let payload: [String: Any] = [
            "search_query": query,
            "current_locale": locale,
            "entity_type_filter": "specialty",
            "fallback_locale": "en"
        ]
        let body = try JSONSerialization.data(withJSONObject: payload, options: [])
        let response = try await request(
            method: "POST",
            path: "/rest/v1/rpc/search_taxonomy",
            queryItems: [],
            body: body,
            extraHeaders: ["Content-Type": "application/json"]
        )
        return try parseJSONArray(response.data)
    }

    private func parseJSONArray(_ data: Data) throws -> [[String: Any]] {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let array = object as? [[String: Any]] else {
            throw AuditError.parseFailed("Expected JSON array response")
        }
        return array
    }

    private func request(
        method: String,
        path: String,
        queryItems: [URLQueryItem],
        body: Data?,
        extraHeaders: [String: String]
    ) async throws -> (data: Data, http: HTTPURLResponse) {
        guard var components = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: false) else {
            throw AuditError.invalidURL(config.baseURL.absoluteString)
        }

        components.path = path
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw AuditError.invalidURL("\(config.baseURL.absoluteString)\(path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 30
        request.setValue(config.apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        for (key, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuditError.requestFailed("Non-HTTP response for \(url.absoluteString)")
        }

        guard (200...299).contains(http.statusCode) || http.statusCode == 206 else {
            let bodyText = String(data: data, encoding: .utf8) ?? "<binary>"
            throw AuditError.requestFailed("\(method) \(url.absoluteString) -> \(http.statusCode): \(bodyText)")
        }

        return (data, http)
    }
}
