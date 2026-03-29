import UIKit

// MARK: - Coordinator Protocol

protocol Coordinator: AnyObject {
    func start()
}

// MARK: - AppCoordinator

final class AppCoordinator: Coordinator {

    private let window:    UIWindow
    private let container: AppContainer
    private var mainCoordinator: MainCoordinator?

    init(window: UIWindow, container: AppContainer) {
        self.window    = window
        self.container = container
    }

    func start() {
        let coordinator = MainCoordinator(container: container)
        mainCoordinator = coordinator
        coordinator.start()
        window.rootViewController = coordinator.rootViewController
        window.makeKeyAndVisible()
    }
}

// MARK: - MainCoordinator

final class MainCoordinator: Coordinator {

    private(set) var rootViewController: UIViewController!

    private let container:       AppContainer
    private let focusCoordinator = FocusCoordinator()
    private var tabBarCoordinator: TabBarCoordinator?

    init(container: AppContainer) {
        self.container = container
    }

    func start() {
        let tabCoordinator = TabBarCoordinator(
            container:        container,
            focusCoordinator: focusCoordinator
        )
        tabCoordinator.start()
        tabBarCoordinator  = tabCoordinator
        rootViewController = tabCoordinator.rootViewController
    }
}

// MARK: - TabBarCoordinator

final class TabBarCoordinator: Coordinator {

    private(set) var rootViewController: UIViewController!

    private let container:        AppContainer
    private let focusCoordinator: FocusCoordinator

    init(container: AppContainer, focusCoordinator: FocusCoordinator) {
        self.container        = container
        self.focusCoordinator = focusCoordinator
    }

    func start() {
        let screenMap = makeScreenMap()

        let tabBarVC = TVTabBarViewController(
            screenMap:        screenMap,
            focusCoordinator: focusCoordinator
        )

        tabBarVC.configure(categories: ProviderCategory.filmixDefaults)

        focusCoordinator.tabBarViewController = tabBarVC
        rootViewController = tabBarVC
    }

    // MARK: - screenMap: categoryId → ViewController
    //
    // Все экраны с контентом — ContentViewController<VM>.
    // TVTabBarViewController управляет ими через ContentLoadable.

    private func makeScreenMap() -> [String: UIViewController] {
        [
            "home":      container.makeHomeScreen(),
            "movies":    container.makeMoviesScreen(),
            "series":    container.makeSeriesScreen(),
            "cartoons":  container.makeCartoonsScreen(),
            "favorites": container.makeFavoritesScreen(),
            "watching":  container.makeWatchingScreen(),
            "search":    SearchViewController(viewModel: container.makeSearchViewModel()),
            "settings":  SettingsViewController(viewModel: container.makeSettingsViewModel()),
        ]
    }
}
