import UIKit
import AsyncDisplayKit

// MARK: - Base Tab Controller
class BaseTabController: ASViewController<ASDisplayNode> {
    weak var coordinator: Coordinator?

    init() {
        super.init(node: ASDisplayNode())
        node.backgroundColor = .systemBackground
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}

// MARK: - Dashboard Controller
final class DashboardController: BaseTabController {
    private let viewModel: DashboardViewModel
    private var dashboardNode: DashboardNode!

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
        super.init()

        dashboardNode = DashboardNode(viewModel: viewModel)
        node.addSubnode(dashboardNode)

        title = "Dashboard"
        setupBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItems()
    }

    private func setupNavigationItems() {
        let notificationButton = UIBarButtonItem(
            image: UIImage(systemName: "bell"),
            style: .plain,
            target: self,
            action: #selector(notificationsTapped)
        )

        let profileButton = UIBarButtonItem(
            image: UIImage(systemName: "person.circle"),
            style: .plain,
            target: self,
            action: #selector(profileTapped)
        )

        navigationItem.rightBarButtonItems = [profileButton, notificationButton]
    }

    private func setupBindings() {
        dashboardNode.onCampaignTap = { [weak self] campaignId in
            (self?.coordinator as? DashboardCoordinator)?.showCampaignDetails(campaignId)
        }
    }

    @objc private func notificationsTapped() {
        // Access parent coordinator
        if let tabCoordinator = coordinator?.parent as? MainTabBarCoordinator {
            tabCoordinator.showNotifications()
        }
    }

    @objc private func profileTapped() {
        if let tabCoordinator = coordinator?.parent as? MainTabBarCoordinator {
            tabCoordinator.showProfile()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        dashboardNode.frame = node.bounds
    }
}

// MARK: - Campaigns Controller
final class CampaignsController: BaseTabController {
    private let viewModel: CampaignsViewModel
    private var campaignsNode: CampaignsNode!

    init(viewModel: CampaignsViewModel) {
        self.viewModel = viewModel
        super.init()

        campaignsNode = CampaignsNode(viewModel: viewModel)
        node.addSubnode(campaignsNode)

        title = "Campaigns"
        setupBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItems()
    }

    private func setupNavigationItems() {
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addCampaignTapped)
        )

        navigationItem.rightBarButtonItem = addButton
    }

    private func setupBindings() {
        campaignsNode.onCampaignTap = { [weak self] campaignId in
            (self?.coordinator as? CampaignsCoordinator)?.showCampaignDetails(campaignId)
        }
    }

    @objc private func addCampaignTapped() {
        (coordinator as? CampaignsCoordinator)?.showCreateCampaign()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        campaignsNode.frame = node.bounds
    }
}

// MARK: - Settings Controller
final class SettingsController: BaseTabController {
    private let viewModel: SettingsViewModel
    private var settingsNode: SettingsNode!

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init()

        settingsNode = SettingsNode(viewModel: viewModel)
        node.addSubnode(settingsNode)

        title = "Settings"
        setupBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupBindings() {
        settingsNode.onProfileTap = { [weak self] in
            (self?.coordinator as? SettingsCoordinator)?.showProfile()
        }

        settingsNode.onSMTPSettingsTap = { [weak self] in
            (self?.coordinator as? SettingsCoordinator)?.showSMTPSettings()
        }

        settingsNode.onThemeSettingsTap = { [weak self] in
            (self?.coordinator as? SettingsCoordinator)?.showThemeSettings()
        }

        settingsNode.onLogoutTap = { [weak self] in
            self?.showLogoutConfirmation()
        }
    }

    private func showLogoutConfirmation() {
        let alert = UIAlertController(
            title: "Logout",
            message: "Are you sure you want to logout?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            (self?.coordinator as? SettingsCoordinator)?.logout()
        })

        present(alert, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        settingsNode.frame = node.bounds
    }
}

// MARK: - Example Nodes (UI Components)
final class DashboardNode: ASDisplayNode {
    private let viewModel: DashboardViewModel
    var onCampaignTap: ((String) -> Void)?

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
        super.init()
        automaticallyManagesSubnodes = true
        backgroundColor = .systemBackground

        layoutSpecBlock = { [weak self] _, _ in
            return self?.layoutSpec() ?? ASLayoutSpec()
        }
    }

    private func layoutSpec() -> ASLayoutSpec {
        // Create your dashboard layout here
        let titleNode = ASTextNode()
        titleNode.attributedText = NSAttributedString(
            string: "Welcome to Dashboard",
            attributes: [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ]
        )

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20),
            child: titleNode
        )
    }
}

final class CampaignsNode: ASDisplayNode {
    private let viewModel: CampaignsViewModel
    var onCampaignTap: ((String) -> Void)?

    init(viewModel: CampaignsViewModel) {
        self.viewModel = viewModel
        super.init()
        automaticallyManagesSubnodes = true
        backgroundColor = .systemBackground

        layoutSpecBlock = { [weak self] _, _ in
            return self?.layoutSpec() ?? ASLayoutSpec()
        }
    }

    private func layoutSpec() -> ASLayoutSpec {
        let titleNode = ASTextNode()
        titleNode.attributedText = NSAttributedString(
            string: "Your Campaigns",
            attributes: [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ]
        )

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20),
            child: titleNode
        )
    }
}

final class SettingsNode: ASDisplayNode {
    private let viewModel: SettingsViewModel

    var onProfileTap: (() -> Void)?
    var onSMTPSettingsTap: (() -> Void)?
    var onThemeSettingsTap: (() -> Void)?
    var onLogoutTap: (() -> Void)?

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init()
        automaticallyManagesSubnodes = true
        backgroundColor = .systemBackground

        layoutSpecBlock = { [weak self] _, _ in
            return self?.layoutSpec() ?? ASLayoutSpec()
        }
    }

    private func layoutSpec() -> ASLayoutSpec {
        let titleNode = ASTextNode()
        titleNode.attributedText = NSAttributedString(
            string: "Settings",
            attributes: [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ]
        )

        // Create setting items
        let profileButton = createSettingButton("Profile", action: { [weak self] in
            self?.onProfileTap?()
        })

        let smtpButton = createSettingButton("SMTP Settings", action: { [weak self] in
            self?.onSMTPSettingsTap?()
        })

        let themeButton = createSettingButton("Theme", action: { [weak self] in
            self?.onThemeSettingsTap?()
        })

        let logoutButton = createSettingButton("Logout", action: { [weak self] in
            self?.onLogoutTap?()
        })

        let stack = ASStackLayoutSpec.vertical()
        stack.spacing = 16
        stack.children = [titleNode, profileButton, smtpButton, themeButton, logoutButton]

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20),
            child: stack
        )
    }

    private func createSettingButton(_ title: String, action: @escaping () -> Void) -> ASButtonNode {
        let button = ASButtonNode()
        button.setTitle(title, with: .systemFont(ofSize: 16), with: .label, for: .normal)
        button.backgroundColor = .systemGray6
        button.cornerRadius = 8
        button.style.height = ASDimension(unit: .points, value: 44)

        button.addTarget(self, action: #selector(buttonTapped(_:)), forControlEvents: .touchUpInside)
        button.view.tag = title.hashValue

        // Store action in associated object
        objc_setAssociatedObject(button, &AssociatedKeys.action, action, .OBJC_ASSOCIATION_COPY)

        return button
    }

    @objc private func buttonTapped(_ sender: ASButtonNode) {
        if let action = objc_getAssociatedObject(sender, &AssociatedKeys.action) as? () -> Void {
            action()
        }
    }
}

private struct AssociatedKeys {
    static var action = "action"
}

// MARK: - ViewModels (Protocol definitions)
protocol DashboardViewModel {
    // Dashboard view model properties and methods
}

protocol CampaignsViewModel {
    // Campaigns view model properties and methods
}

protocol AnalyticsViewModel {
    // Analytics view model properties and methods
}

protocol SettingsViewModel {
    // Settings view model properties and methods
}