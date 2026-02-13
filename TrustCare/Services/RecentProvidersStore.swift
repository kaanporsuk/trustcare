import Foundation

enum RecentProvidersStore {
    private static let key = "recentProviders"
    private static let maxCount = 10

    static func load() -> [Provider] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Provider].self, from: data)) ?? []
    }

    static func add(_ provider: Provider) {
        var providers = load()
        providers.removeAll { $0.id == provider.id }
        providers.insert(provider, at: 0)
        if providers.count > maxCount {
            providers = Array(providers.prefix(maxCount))
        }
        save(providers)
    }

    private static func save(_ providers: [Provider]) {
        if let data = try? JSONEncoder().encode(providers) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
