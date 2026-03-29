import UIKit

protocol TabBarViewModel {
    var selectedIndex: Int { get }
    func createViewController(for tab: TabItem) -> UIViewController
}

class TabBarViewModelImpl: TabBarViewModel {
    private let container: Container
    
    init(container: Container) {
        self.container = container
    }
    
    var selectedIndex: Int {
        return 0 // Default to first tab
    }
    
    func createViewController(for tab: TabItem) -> UIViewController {
        let navigationController = UINavigationController()
        
        // Set up tab bar item
        navigationController.tabBarItem = UITabBarItem(
            title: tab.title,
            image: UIImage(systemName: tab.icon),
            selectedImage: UIImage(systemName: tab.icon + ".fill")
        )
        
        // Create the appropriate coordinator and controller
        switch tab.id {
        case "home":
            let coordinator = container.makeHomeCoordinator(navigationController: navigationController)
            coordinator.start()
            return navigationController
            
        case "profile":
            let coordinator = container.makeProfileCoordinator(navigationController: navigationController)
            coordinator.start()
            return navigationController
            
        case "settings":
            let coordinator = container.makeSettingsCoordinator(navigationController: navigationController)
            coordinator.start()
            return navigationController
            
        case "search":
            return createSearchViewController(navigationController: navigationController)
            
        case "favorites":
            return createFavoritesViewController(navigationController: navigationController)
            
        case "messages":
            return createMessagesViewController(navigationController: navigationController)
            
        default:
            return createDefaultViewController(for: tab, navigationController: navigationController)
        }
    }
    
    private func createSearchViewController(navigationController: UINavigationController) -> UIViewController {
        let searchVC = SearchViewController()
        navigationController.setViewControllers([searchVC], animated: false)
        return navigationController
    }
    
    private func createFavoritesViewController(navigationController: UINavigationController) -> UIViewController {
        let favoritesVC = FavoritesViewController()
        navigationController.setViewControllers([favoritesVC], animated: false)
        return navigationController
    }
    
    private func createMessagesViewController(navigationController: UINavigationController) -> UIViewController {
        let messagesVC = MessagesViewController()
        navigationController.setViewControllers([messagesVC], animated: false)
        return navigationController
    }
    
    private func createDefaultViewController(for tab: TabItem, navigationController: UINavigationController) -> UIViewController {
        let defaultVC = DefaultTabViewController()
        defaultVC.configure(with: tab)
        navigationController.setViewControllers([defaultVC], animated: false)
        return navigationController
    }
}

// MARK: - Placeholder View Controllers
// These should be replaced with actual implementations

class SearchViewController: UIViewController, BaseController {
    var coordinator: MainCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Search"
        
        let label = UILabel()
        label.text = "Search View"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

class FavoritesViewController: UIViewController, BaseController {
    var coordinator: MainCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Favorites"
        
        let label = UILabel()
        label.text = "Favorites View"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

class MessagesViewController: UIViewController, BaseController {
    var coordinator: MainCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Messages"
        
        let label = UILabel()
        label.text = "Messages View"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

class DefaultTabViewController: UIViewController, BaseController {
    var coordinator: MainCoordinator?
    private var tabItem: TabItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    func configure(with tab: TabItem) {
        self.tabItem = tab
        title = tab.title
    }
    
    private func setupUI() {
        let label = UILabel()
        label.text = tabItem?.title ?? "Default Tab"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
