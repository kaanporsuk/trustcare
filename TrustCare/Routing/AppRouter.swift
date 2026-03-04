import Foundation
import Combine

@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: Int = 0

    private weak var homeViewModel: HomeViewModel?
    private var pendingDiscoverEntityID: String?
    private var activeRouteTask: Task<Void, Never>?

    func setSelectedTab(_ tab: Int) {
        selectedTab = tab
    }

    func registerHomeViewModel(_ viewModel: HomeViewModel) {
        homeViewModel = viewModel
        processPendingDiscoverRouteIfPossible()
    }

    func unregisterHomeViewModel(_ viewModel: HomeViewModel) {
        guard homeViewModel === viewModel else { return }
        homeViewModel = nil
    }

    func routeToDiscover(entityID: String) {
        let normalized = entityID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }

        selectedTab = 0
        pendingDiscoverEntityID = normalized
        processPendingDiscoverRouteIfPossible()
    }

    private func processPendingDiscoverRouteIfPossible() {
        guard activeRouteTask == nil else { return }
        guard let pendingDiscoverEntityID else { return }
        guard let viewModel = homeViewModel else { return }

        activeRouteTask = Task { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            await viewModel.applyCanonicalRouteEntityID(pendingDiscoverEntityID)
            if self.pendingDiscoverEntityID == pendingDiscoverEntityID {
                self.pendingDiscoverEntityID = nil
            }
            self.activeRouteTask = nil
            self.processPendingDiscoverRouteIfPossible()
        }
    }
}
