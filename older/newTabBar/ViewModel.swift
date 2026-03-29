import UIKit

// MARK: - Container Extensions for ViewModels
extension Container {

    // MARK: - Dashboard
    func makeDashboardViewModel() -> DashboardViewModel {
        return DashboardViewModelImpl(
            campaignsRepository: campaignsRepository,
            analyticsRepository: analyticsRepository,
            userRepository: userRepository
        )
    }

    // MARK: - Campaigns
    func makeCampaignsViewModel() -> CampaignsViewModel {
        return CampaignsViewModelImpl(
            campaignsRepository: campaignsRepository,
            userRepository: userRepository
        )
    }

    func makeCampaignDetailsViewModel(campaignId: String) -> CampaignDetailsViewModel {
        return CampaignDetailsViewModelImpl(
            campaignId: campaignId,
            campaignsRepository: campaignsRepository,
            analyticsRepository: analyticsRepository
        )
    }

    func makeCreateCampaignCoordinator() -> CreateCampaignCoordinator {
        return CreateCampaignCoordinator(container: self)
    }

    // MARK: - Analytics
    func makeAnalyticsViewModel() -> AnalyticsViewModel {
        return AnalyticsViewModelImpl(
            analyticsRepository: analyticsRepository,
            campaignsRepository: campaignsRepository
        )
    }

    func makeDetailedReportViewModel(metric: String) -> DetailedReportViewModel {
        return DetailedReportViewModelImpl(
            metric: metric,
            analyticsRepository: analyticsRepository
        )
    }

    // MARK: - Settings
    func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModelImpl(
            userRepository: userRepository,
            themeManager: themeManager,
            appConfiguration: appConfiguration
        )
    }

    func makeProfileViewModel() -> ProfileViewModel {
        return ProfileViewModelImpl(
            userRepository: userRepository
        )
    }

    func makeSMTPSettingsViewModel() -> SMTPSettingsViewModel {
        return SMTPSettingsViewModelImpl(
            userRepository: userRepository,
            smtpRepository: smtpRepository
        )
    }

    func makeThemeSettingsViewModel() -> ThemeSettingsViewModel {
        return ThemeSettingsViewModelImpl(
            themeManager: themeManager
        )
    }

    // MARK: - Profile (Modal)
    func makeProfileCoordinator() -> ProfileCoordinator {
        return ProfileCoordinator(container: self)
    }

    // MARK: - Notifications (Modal)
    func makeNotificationsCoordinator() -> NotificationsCoordinator {
        return NotificationsCoordinator(container: self)
    }

    func makeNotificationsViewModel() -> NotificationsViewModel {
        return NotificationsViewModelImpl(
            notificationsRepository: notificationsRepository
        )
    }
}

// MARK: - Additional Repository Protocols
extension Container: CampaignsRepositoryContainer {
    var campaignsRepository: CampaignsRepository {
        repository.campaignsRepository
    }
}

extension Container: AnalyticsRepositoryContainer {
    var analyticsRepository: AnalyticsRepository {
        repository.analyticsRepository
    }
}

extension Container: UserRepositoryContainer {
    var userRepository: UserRepository {
        repository.userRepository
    }
}

extension Container: SMTPRepositoryContainer {
    var smtpRepository: SMTPRepository {
        repository.smtpRepository
    }
}

extension Container: NotificationsRepositoryContainer {
    var notificationsRepository: NotificationsRepository {
        repository.notificationsRepository
    }
}

// MARK: - Repository Container Protocols
protocol CampaignsRepositoryContainer {
    var campaignsRepository: CampaignsRepository { get }
}

protocol AnalyticsRepositoryContainer {
    var analyticsRepository: AnalyticsRepository { get }
}

protocol UserRepositoryContainer {
    var userRepository: UserRepository { get }
}

protocol SMTPRepositoryContainer {
    var smtpRepository: SMTPRepository { get }
}

protocol NotificationsRepositoryContainer {
    var notificationsRepository: NotificationsRepository { get }
}

// MARK: - Repository Extensions
extension Repository {

    private(set) lazy var campaignsRepository: CampaignsRepository = {
        return CampaignsRepositoryImpl(
            networkService: service.networkService,
            storage: storage.campaignStorage
        )
    }()

    private(set) lazy var analyticsRepository: AnalyticsRepository = {
        return AnalyticsRepositoryImpl(
            networkService: service.networkService,
            storage: storage.analyticsStorage
        )
    }()

    private(set) lazy var userRepository: UserRepository = {
        return UserRepositoryImpl(
            networkService: service.networkService,
            userStorage: storage.userStorage
        )
    }()

    private(set) lazy var smtpRepository: SMTPRepository = {
        return SMTPRepositoryImpl(
            networkService: service.networkService
        )
    }()

    private(set) lazy var notificationsRepository: NotificationsRepository = {
        return NotificationsRepositoryImpl(
            networkService: service.networkService,
            storage: storage.notificationStorage
        )
    }()
}

// MARK: - Storage Extensions
extension Storage {

    private(set) lazy var campaignStorage: CampaignStorage = {
        return CampaignStorage(dataSource: source)
    }()

    private(set) lazy var analyticsStorage: AnalyticsStorage = {
        return AnalyticsStorage(dataSource: source)
    }()

    private(set) lazy var notificationStorage: NotificationStorage = {
        return NotificationStorage(dataSource: source)
    }()
}

// MARK: - ViewModel Implementations (Examples)
final class DashboardViewModelImpl: DashboardViewModel {
    private let campaignsRepository: CampaignsRepository
    private let analyticsRepository: AnalyticsRepository
    private let userRepository: UserRepository

    init(
        campaignsRepository: CampaignsRepository,
        analyticsRepository: AnalyticsRepository,
        userRepository: UserRepository
    ) {
        self.campaignsRepository = campaignsRepository
        self.analyticsRepository = analyticsRepository
        self.userRepository = userRepository
    }

    // Implement dashboard logic here
}

final class CampaignsViewModelImpl: CampaignsViewModel {
    private let campaignsRepository: CampaignsRepository
    private let userRepository: UserRepository

    init(
        campaignsRepository: CampaignsRepository,
        userRepository: UserRepository
    ) {
        self.campaignsRepository = campaignsRepository
        self.userRepository = userRepository
    }

    // Implement campaigns logic here
}

final class SettingsViewModelImpl: SettingsViewModel {
    private let userRepository: UserRepository
    private let themeManager: ThemeManager
    private let appConfiguration: AppConfiguration

    init(
        userRepository: UserRepository,
        themeManager: ThemeManager,
        appConfiguration: AppConfiguration
    ) {
        self.userRepository = userRepository
        self.themeManager = themeManager
        self.appConfiguration = appConfiguration
    }

    // Implement settings logic here
}

// MARK: - Modal Coordinators
final class ProfileCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController = UINavigationController()
    var container: Container
    weak var delegate: CoordinatorDelegate?

    init(container: Container) {
        self.container = container
    }

    func start() {
        let viewModel = container.makeProfileViewModel()
        let controller = ProfileController(viewModel: viewModel)
        controller.coordinator = self

        // Add close button
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        navigationController.setViewControllers([controller], animated: false)
    }

    @objc private func closeTapped() {
        delegate?.coordinatorDidFinish(self)
    }
}

final class NotificationsCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController = UINavigationController()
    var container: Container
    weak var delegate: CoordinatorDelegate?

    init(container: Container) {
        self.container = container
    }

    func start() {
        let viewModel = container.makeNotificationsViewModel()
        let controller = NotificationsController(viewModel: viewModel)
        controller.coordinator = self

        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        navigationController.setViewControllers([controller], animated: false)
    }

    @objc private func closeTapped() {
        delegate?.coordinatorDidFinish(self)
    }
}

final class CreateCampaignCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController = UINavigationController()
    var container: Container
    weak var delegate: CoordinatorDelegate?

    init(container: Container) {
        self.container = container
    }

    func start() {
        let viewModel = container.makeCreateCampaignViewModel()
        let controller = CreateCampaignController(viewModel: viewModel)
        controller.coordinator = self

        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationController.setViewControllers([controller], animated: false)
    }

    @objc private func cancelTapped() {
        delegate?.coordinatorDidFinish(self)
    }

    func campaignCreated() {
        delegate?.coordinatorDidFinish(self)
    }
}

// MARK: - Additional ViewModels needed
extension Container {
    func makeCreateCampaignViewModel() -> CreateCampaignViewModel {
        return CreateCampaignViewModelImpl(
            campaignsRepository: campaignsRepository
        )
    }
}

// MARK: - Repository Protocols (Examples)
protocol CampaignsRepository {
    func getCampaigns() async throws -> [Campaign]
    func getCampaign(id: String) async throws -> Campaign
    func createCampaign(_ campaign: CreateCampaignRequest) async throws -> Campaign
    func updateCampaign(_ campaign: Campaign) async throws -> Campaign
    func deleteCampaign(id: String) async throws
}

protocol AnalyticsRepository {
    func getDashboardAnalytics() async throws -> DashboardAnalytics
    func getCampaignAnalytics(campaignId: String) async throws -> CampaignAnalytics
    func getDetailedReport(for metric: String) async throws -> DetailedReport
}

protocol UserRepository {
    func getCurrentUser() async throws -> User
    func updateUser(_ user: User) async throws -> User
    func updateProfile(_ profile: UserProfile) async throws -> UserProfile
}

protocol SMTPRepository {
    func getSMTPSettings() async throws -> SMTPSettings
    func updateSMTPSettings(_ settings: SMTPSettings) async throws -> SMTPSettings
    func testSMTPConnection(_ settings: SMTPSettings) async throws -> Bool
}

protocol NotificationsRepository {
    func getNotifications() async throws -> [Notification]
    func markAsRead(notificationId: String) async throws
    func markAllAsRead() async throws
    func getUnreadCount() async throws -> Int
}