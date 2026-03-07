import Foundation

final class TaxonomyI18nLoader {
    static let shared = TaxonomyI18nLoader()

    private var cacheVersion: String = TaxonomyIdentity.cacheVersion
    private var cache: [String: [String: String]] = [:]
    private let lock = NSLock()

    private init() {}

    func localizedLabel(for entityID: String, locale: String, fallback: String) -> String {
        ensureCacheVersion()

        let normalizedID = TaxonomyIdentity.normalizedCanonicalID(entityID)
        guard !normalizedID.isEmpty else { return fallback }

        if let canonicalLabel = TaxonomyCatalogStore.shared.localizedLabel(for: normalizedID, locale: locale) {
            return canonicalLabel
        }

        let localeCode = TaxonomyIdentity.normalizedLocale(locale)
        let localeMap = mapping(for: localeCode)

        if let match = value(for: normalizedID, in: localeMap) {
            return match
        }

        let englishMap = mapping(for: "en")
        if let match = value(for: normalizedID, in: englishMap) {
            return match
        }

        return fallback
    }

    private func mapping(for locale: String) -> [String: String] {
        lock.lock()
        if let cached = cache[locale] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let loaded = loadMapping(for: locale)

        lock.lock()
        cache[locale] = loaded
        lock.unlock()

        return loaded
    }

    private func loadMapping(for locale: String) -> [String: String] {
        // Keep legacy mapping scoped to dedicated taxonomy resources only.
        let url = Bundle.main.url(forResource: locale, withExtension: "json", subdirectory: "TaxonomyI18n")

        guard let url else {
            return [:]
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([String: String].self, from: data)
            return Dictionary(uniqueKeysWithValues: decoded.map { key, value in
                (TaxonomyIdentity.normalizedCanonicalID(key), value)
            })
        } catch {
            return [:]
        }
    }

    private func value(for entityID: String, in mapping: [String: String]) -> String? {
        for key in candidateKeys(for: entityID) {
            if let value = mapping[key], !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return nil
    }

    private func candidateKeys(for entityID: String) -> [String] {
        let trimmed = entityID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let upper = TaxonomyIdentity.normalizedCanonicalID(trimmed)
        let lower = trimmed.lowercased()
        return Array(Set([upper, lower]))
    }

    private func ensureCacheVersion() {
        lock.lock()
        defer { lock.unlock() }

        guard cacheVersion != TaxonomyIdentity.cacheVersion else { return }
        cache = [:]
        cacheVersion = TaxonomyIdentity.cacheVersion
    }
}
