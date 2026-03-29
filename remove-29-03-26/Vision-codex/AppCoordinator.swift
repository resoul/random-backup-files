import UIKit

final class AppCoordinator {
    private let window: UIWindow

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let rootViewController = RootController(router: self)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
    }
}

extension AppCoordinator: RootRouting {
    func showSettings(from presenter: UIViewController) {
        let settingsViewController = SettingsViewController()
        settingsViewController.modalPresentationStyle = .overFullScreen
        settingsViewController.modalTransitionStyle = .crossDissolve
        presenter.present(settingsViewController, animated: true)
    }

    func showSearch(from presenter: UIViewController) {
        let searchViewController = SearchViewController()
        searchViewController.modalPresentationStyle = .overFullScreen
        searchViewController.modalTransitionStyle = .crossDissolve
        presenter.present(searchViewController, animated: true)
    }

    func showDetail(from presenter: UIViewController, movie: Movie, onDismiss: (() -> Void)?) {
        let detailViewController = BaseDetailViewController.make(movie: movie)
        detailViewController.onDismiss = onDismiss
        presenter.present(detailViewController, animated: true)
    }
}
