import Foundation

/// Tracks which specialties the user taps/searches to personalize the
/// "top 5" pills over time. Uses UserDefaults for local persistence.
final class SpecialtyTracker {
    static let shared = SpecialtyTracker()

    private let storageKey = "userSpecialtyTaps"

    /// Record a tap on a specialty
    func recordTap(specialtyName: String) {
        var taps = loadTaps()
        taps[specialtyName, default: 0] += 1
        saveTaps(taps)
    }

    /// Get the user's top N specialties by tap count
    func userTopSpecialties(count: Int) -> [String] {
        let taps = loadTaps()
        guard !taps.isEmpty else { return [] }
        return taps
            .sorted { $0.value > $1.value }
            .prefix(count)
            .map(\.key)
    }

    /// Whether the user has any tap history
    var hasHistory: Bool {
        !loadTaps().isEmpty
    }

    private func loadTaps() -> [String: Int] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data)
        else { return [:] }
        return dict
    }

    private func saveTaps(_ taps: [String: Int]) {
        if let data = try? JSONEncoder().encode(taps) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
