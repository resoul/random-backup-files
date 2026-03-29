import UIKit

// MARK: - MainTabBarCoordinator
final class MainTabBarCoordinator: Coordinator {
    // MARK: - Navigation Methods
    func showProfile() {
        // Present profile modally from current tab
        let profileCoordinator = container.makeProfileCoordinator()
        let navController = UINavigationController()

        profileCoordinator.navigationController = navController
        profileCoordinator.delegate = self
        addChildCoordinator(profileCoordinator)

        profileCoordinator.start()
        tabBarController.present(navController, animated: true)
    }

    func showNotifications() {
        // Present notifications from current tab
        let notificationsCoordinator = container.makeNotificationsCoordinator()
        let navController = UINavigationController()

        notificationsCoordinator.navigationController = navController
        addChildCoordinator(notificationsCoordinator)

        notificationsCoordinator.start()
        tabBarController.present(navController, animated: true)
    }
}

// MARK: - MainTabBarController
final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    weak var coordinator: MainTabBarCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        delegate = self
    }

    private func setupAppearance() {
        tabBar.backgroundColor = .systemBackground
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .systemGray

        // Add shadow
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -1)
        tabBar.layer.shadowRadius = 4
        tabBar.layer.shadowOpacity = 0.1
    }

    // MARK: - UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Handle tab selection
        guard let tabType = TabType(rawValue: tabBarController.selectedIndex) else { return }

        // Notify coordinator about tab change
        handleTabSelection(tabType)
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // Check if user can access this tab
        guard let index = tabBarController.viewControllers?.firstIndex(of: viewController),
              let tabType = TabType(rawValue: index) else { return true }

        return canSelectTab(tabType)
    }

    private func handleTabSelection(_ tabType: TabType) {
        // Handle double tap to scroll to top or refresh
        if selectedIndex == tabType.rawValue {
            handleDoubleTap(for: tabType)
        }

        // Analytics tracking
        trackTabSelection(tabType)
    }

    private func handleDoubleTap(for tabType: TabType) {
        // Get the coordinator for the tab and handle double tap
        coordinator?.getCoordinator(for: tabType)?.handleDoubleTap?()
    }

    private func canSelectTab(_ tabType: TabType) -> Bool {
        // Add permission checks here if needed
        switch tabType {
        case .analytics:
            // Check if user has analytics permissions
            return true // container.userPermissions.canViewAnalytics
        default:
            return true
        }
    }

    private func trackTabSelection(_ tabType: TabType) {
        // Analytics tracking
        // AnalyticsManager.shared.track("tab_selected", parameters: ["tab": tabType.title])
    }
}

// MARK: - Container Extensions for Tab Coordinators
extension Container {
    func makeDashboardCoordinator() -> DashboardCoordinator {
        return DashboardCoordinator(container: self)
    }

    func makeCampaignsCoordinator() -> CampaignsCoordinator {
        return CampaignsCoordinator(container: self)
    }

    func makeAnalyticsCoordinator() -> AnalyticsCoordinator {
        return AnalyticsCoordinator(container: self)
    }

    func makeSettingsCoordinator() -> SettingsCoordinator {
        return SettingsCoordinator(container: self)
    }

    func makeProfileCoordinator() -> ProfileCoordinator {
        return ProfileCoordinator(container: self)
    }

    func makeNotificationsCoordinator() -> NotificationsCoordinator {
        return NotificationsCoordinator(container: self)
    }
}

// MARK: - Individual Tab Coordinators
final class DashboardCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController = UINavigationController()
    var container: Container

    init(container: Container) {
        self.container = container
    }

    func start() {
        let viewModel = container.makeDashboardViewModel()
        let controller = DashboardController(viewModel: viewModel)
        controller.coordinator = self

        navigationController.setViewControllers([controller], animated: false)
    }

    func showCampaignDetails(_ campaignId: String) {
        let viewModel = container.makeCampaignDetailsViewModel(campaignId: campaignId)
        let controller = CampaignDetailsController(viewModel: viewModel)
        controller.coordinator = self

        navigationController.pushViewController(controller, animated: true)
    }
}

final class CampaignsCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController = UINavigationController()
    var container: Container

    init(container: Container) {
        self.container = container
    }

    func start() {
        let viewModel = container.makeCampaignsViewModel()
        let controller = CampaignsController(viewModel: viewModel)
        controller.coordinator = self

        navigationController.setViewControllers([controller], animated: false)
    }

    func showCreateCampaign() {
        let createCampaignCoordinator = container.makeCreateCampaignCoordinator()
        let navController = UINavigationController()

        createCampaignCoordinator.navigationController = navController
        createCampaignCoordinator.delegate = self
        addChildCoordinator(createCampaignCoordinator)

        createCampaignCoordinator.start()
        navigationController.present(navController, animated: true)
    }

    func showCampaignDetails(_ campaignId: String) {
        let viewModel = container.makeCampaignDetailsViewModel(campaignId: campaignId)
        let controller = CampaignDetailsController(viewModel: viewModel)
        controller.coordinator = self

        navigationController.pushViewController(controller, animated: true)
    }
}

final class AnalyticsCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController = UINavigationController()
    var container: Container

    init(container: Container) {
        self.container = container
    }

    func start() {
        let viewModel = container.makeAnalyticsViewModel()
        let controller = AnalyticsController(viewModel: viewModel)
        controller.coordinator = self

        navigationController.setViewControllers([controller], animated: false)
    }

    func showDetailedReport(for metric: String) {
        let viewModel = container.makeDetailedReportViewModel(metric: metric)
        let controller = DetailedReportController(viewModel: viewModel)
        controller.coordinator = self

        navigationController.pushViewController(controller, animated: true)
    }
}

final class SettingsCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController = UINavigationController()
    var container: Container

    init(container: Container) {
        self.container = container
    }

    func start() {
        let viewModel = container.makeSettingsViewModel()
        let controller = SettingsController(viewModel: viewModel)
        controller.coordinator = self

        navigationController.setViewControllers([controller], animated: false)
    }

    func showProfile() {
        let viewModel = container.makeProfileViewModel()
        let controller = ProfileController(viewModel: viewModel)
        controller.coordinator = self

        navigationController.pushViewController(controller, animated: true)
    }

    func showSMTPSettings() {
        let viewModel = container.makeSMTPSettingsViewModel()
        let controller = SMTPSettingsController(viewModel: viewModel)
        controller.coordinator = self

        navigationController.pushViewController(controller, animated: true)
    }

    func showThemeSettings() {
        let viewModel = container.makeThemeSettingsViewModel()
        let controller = ThemeSettingsController(viewModel: viewModel)
        controller.coordinator = self

        navigationController.pushViewController(controller, animated: true)
    }

    func logout() {
        // Handle logout - should notify parent coordinator
        delegate?.coordinatorDidLogout(self)
    }
}
