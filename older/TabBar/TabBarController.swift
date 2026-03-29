import UIKit
import Combine
import FontManager

class TabBarController: UITabBarController {
    weak var coordinator: MainCoordinator?
    private var cancellables = Set<AnyCancellable>()
    private var viewModel: TabBarViewModel
    
    init(viewModel: TabBarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBarManager()
        setupTabBarAppearance()
        bindTheme()
        
        selectedIndex = viewModel.selectedIndex
    }
    
    private func setupTabBarManager() {
        TabBarManager.shared.tabBarController = self
        
        // Инициальная настройка табов
        let enabledTabs = TabBarManager.shared.enabledTabs
        let viewControllers = enabledTabs.compactMap { tab in
            viewModel.createViewController(for: tab)
        }
        
        setViewControllers(viewControllers, animated: false)
    }
    
    private func bindTheme() {
        // Используем Combine для подписки на изменения темы
        ThemeManager.shared.themePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                self?.applyTheme(theme)
            }
            .store(in: &cancellables)
    }
    
    private func applyTheme(_ theme: Theme) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
//        appearance.backgroundColor = theme.tabBarColor
//        
//        tabBar.standardAppearance = appearance
//        tabBar.scrollEdgeAppearance = appearance
//        tabBar.tintColor = theme.accentColor
    }
    
    private func setupTabBarAppearance() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundImage = UIImage()
        tabAppearance.backgroundColor = UIColor.hex("343248")
        
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .font: UIFont.poppinsWithFallback(.regular, size: 11),
            .foregroundColor: UIColor.white
        ]
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .font: UIFont.poppinsWithFallback(.regular, size: 11),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]

        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.white.withAlphaComponent(0.8)
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
        
        tabBar.standardAppearance = tabAppearance
        tabBar.scrollEdgeAppearance = tabAppearance
        
        setNeedsStatusBarAppearanceUpdate()
        
        tabBar.tintColor = .white
        tabBar.barTintColor = .white
        tabBar.isTranslucent = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
