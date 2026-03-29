import UIKit

// MARK: - SearchCoordinator

final class SearchCoordinator: Coordinator {

    // MARK: - Coordinator

    let rootViewController: UIViewController

    // MARK: - Callbacks → TabCoordinator

    var onSelectMovie: ((Movie) -> Void)?

    // MARK: - Init

    init() {
        // Используем существующий SearchViewController
        self.rootViewController = SearchViewController()
    }

    // MARK: - Start

    func start() {
        guard let vc = rootViewController as? SearchViewController else { return }
//        vc.onSelectMovie = { [weak self] movie in self?.onSelectMovie?(movie) }
    }

    // MARK: - Public API

    func search(query: String) {
        guard let vc = rootViewController as? SearchViewController else { return }
//        vc.search(query: query)
    }
}
