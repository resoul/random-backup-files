
// MARK: - Custom Tab Bar Controller
class CustomTabBarController: UIViewController {
    
    private let tabBar = CustomTabBar()
    private var currentViewController: UIViewController?
    private let menuOverlay = MenuOverlayView()
    
    private lazy var viewControllers: [UIViewController] = [
        createViewController(title: "Home", icon: "house.fill"),
        createViewController(title: "Inbox", icon: "tray.fill"),
        UIViewController(), // Placeholder for center button
        createViewController(title: "My Tasks", icon: "person.fill"),
        createViewController(title: "Spaces", icon: "square.grid.2x2.fill")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupTabBar()
        setupMenuOverlay()
        selectTab(at: 0)
    }
    
    private func setupTabBar() {
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBar.delegate = self
        view.addSubview(tabBar)
        
        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabBar.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.12, constant: 40)
        ])
    }
    
    private func setupMenuOverlay() {
        menuOverlay.translatesAutoresizingMaskIntoConstraints = false
        menuOverlay.alpha = 0
        menuOverlay.delegate = self
        view.addSubview(menuOverlay)
        
        NSLayoutConstraint.activate([
            menuOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            menuOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            menuOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            menuOverlay.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
        ])
    }
    
    private func selectTab(at index: Int) {
        guard index < viewControllers.count else { return }
        
        currentViewController?.willMove(toParent: nil)
        currentViewController?.view.removeFromSuperview()
        currentViewController?.removeFromParent()
        
        let selectedVC = viewControllers[index]
        addChild(selectedVC)
        selectedVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(selectedVC.view, at: 0)
        
        NSLayoutConstraint.activate([
            selectedVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            selectedVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            selectedVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            selectedVC.view.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
        ])
        
        selectedVC.didMove(toParent: self)
        currentViewController = selectedVC
    }
    
    private func createViewController(title: String, icon: String) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
        ])
        
        return vc
    }
    
    private func showMenu() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.menuOverlay.alpha = 1
            self.menuOverlay.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    private func hideMenu() {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.menuOverlay.alpha = 0
        }
    }
}

// MARK: - CustomTabBarDelegate
extension CustomTabBarController: CustomTabBarDelegate {
    func tabBar(_ tabBar: CustomTabBar, didSelectItemAt index: Int) {
        if index == 4 {
            showMenu()
        } else if index != 2 {
            selectTab(at: index)
        }
    }
    
    func tabBarDidTapCenterButton(_ tabBar: CustomTabBar) {
        print("Center button tapped")
    }
}

// MARK: - MenuOverlayDelegate
extension CustomTabBarController: MenuOverlayDelegate {
    func menuOverlayDidTapBackground(_ overlay: MenuOverlayView) {
        hideMenu()
    }
    
    func menuOverlay(_ overlay: MenuOverlayView, didSelectItemAt index: Int) {
        hideMenu()
        print("Menu item \(index) selected")
    }
}

// MARK: - Custom Tab Bar Delegate
protocol CustomTabBarDelegate: AnyObject {
    func tabBar(_ tabBar: CustomTabBar, didSelectItemAt index: Int)
    func tabBarDidTapCenterButton(_ tabBar: CustomTabBar)
}

// MARK: - Custom Tab Bar
class CustomTabBar: UIView {
    
    weak var delegate: CustomTabBarDelegate?
    
    private let containerView = UIView()
    private let stackView = UIStackView()
    private let centerButton = UIButton(type: .system)
    
    private let items: [(title: String, icon: String)] = [
        ("Home", "house.fill"),
        ("Inbox", "tray.fill"),
        ("", "plus"),
        ("My Tasks", "person.fill"),
        ("Forms", "checklist")
    ]
    
    private var buttons: [UIButton] = []
    private var selectedIndex: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .clear
        
        // Container with purple background and rounded corners
        containerView.backgroundColor = UIColor(red: 0.58, green: 0.26, blue: 0.68, alpha: 1.0)
        containerView.layer.cornerRadius = 30
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
        
        // Stack view for buttons
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
        
        // Create buttons
        for (index, item) in items.enumerated() {
            if index == 2 {
                setupCenterButton()
            } else {
                let button = createTabButton(title: item.title, icon: item.icon, index: index)
                stackView.addArrangedSubview(button)
                buttons.append(button)
            }
        }
        
        updateButtonStates()
    }
    
    private func setupCenterButton() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        centerButton.backgroundColor = UIColor(white: 1, alpha: 0.2)
        centerButton.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)), for: .normal)
        centerButton.tintColor = .white
        centerButton.layer.cornerRadius = 30
        centerButton.translatesAutoresizingMaskIntoConstraints = false
        centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)
        
        containerView.addSubview(centerButton)
        
        NSLayoutConstraint.activate([
            centerButton.widthAnchor.constraint(equalToConstant: 60),
            centerButton.heightAnchor.constraint(equalToConstant: 60),
            centerButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            centerButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        stackView.addArrangedSubview(containerView)
    }
    
    private func createTabButton(title: String, icon: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = index
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white.withAlphaComponent(0.7)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.7)
        label.textAlignment = .center
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        
        button.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),
            stackView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        selectedIndex = sender.tag
        updateButtonStates()
        delegate?.tabBar(self, didSelectItemAt: sender.tag)
    }
    
    @objc private func centerButtonTapped() {
        delegate?.tabBarDidTapCenterButton(self)
    }
    
    private func updateButtonStates() {
        for button in buttons {
            let isSelected = button.tag == selectedIndex
            
            if let stackView = button.subviews.first as? UIStackView {
                if let imageView = stackView.arrangedSubviews.first as? UIImageView {
                    imageView.tintColor = isSelected ? .white : .white.withAlphaComponent(0.7)
                }
                if let label = stackView.arrangedSubviews.last as? UILabel {
                    label.textColor = isSelected ? .white : .white.withAlphaComponent(0.7)
                }
            }
        }
    }
}

// MARK: - Menu Overlay Delegate
protocol MenuOverlayDelegate: AnyObject {
    func menuOverlayDidTapBackground(_ overlay: MenuOverlayView)
    func menuOverlay(_ overlay: MenuOverlayView, didSelectItemAt index: Int)
}

// MARK: - Menu Overlay View
class MenuOverlayView: UIView {
    
    weak var delegate: MenuOverlayDelegate?
    
    private let menuContainer = UIView()
    private let menuStackView = UIStackView()
    
    private let menuItems: [(title: String, icon: String, color: UIColor)] = [
        ("Docs", "doc.text.fill", UIColor(red: 0.2, green: 0.6, blue: 0.86, alpha: 1.0)),
        ("Clips", "play.rectangle.fill", UIColor(red: 0.95, green: 0.45, blue: 0.38, alpha: 1.0)),
        ("Dashboards", "chart.bar.fill", UIColor(red: 0.67, green: 0.47, blue: 0.76, alpha: 1.0)),
        ("Forms", "checkmark.square.fill", UIColor(red: 0.45, green: 0.55, blue: 0.82, alpha: 1.0)),
        ("Brain", "brain.head.profile", UIColor(red: 0.75, green: 0.5, blue: 0.9, alpha: 1.0)),
        ("Spaces", "sparkles", UIColor(red: 0.58, green: 0.42, blue: 0.78, alpha: 1.0)),
        ("Notepad", "note.text", UIColor(red: 1.0, green: 0.75, blue: 0.27, alpha: 1.0)),
        ("Chats", "message.fill", UIColor(red: 0.35, green: 0.78, blue: 0.72, alpha: 1.0)),
        ("Planner", "calendar", UIColor(red: 0.9, green: 0.35, blue: 0.45, alpha: 1.0))
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        addGestureRecognizer(tapGesture)
        
        setupMenuContainer()
    }
    
    private func setupMenuContainer() {
        menuContainer.backgroundColor = UIColor(red: 0.58, green: 0.26, blue: 0.68, alpha: 1.0)
        menuContainer.layer.cornerRadius = 30
        menuContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(menuContainer)
        
        NSLayoutConstraint.activate([
            menuContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            menuContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            menuContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            menuContainer.heightAnchor.constraint(equalToConstant: 400)
        ])
        
        setupMenuItems()
    }
    
    private func setupMenuItems() {
        menuStackView.axis = .vertical
        menuStackView.spacing = 0
        menuStackView.translatesAutoresizingMaskIntoConstraints = false
        menuContainer.addSubview(menuStackView)
        
        NSLayoutConstraint.activate([
            menuStackView.leadingAnchor.constraint(equalTo: menuContainer.leadingAnchor, constant: 20),
            menuStackView.trailingAnchor.constraint(equalTo: menuContainer.trailingAnchor, constant: -20),
            menuStackView.topAnchor.constraint(equalTo: menuContainer.topAnchor, constant: 20),
            menuStackView.bottomAnchor.constraint(equalTo: menuContainer.bottomAnchor, constant: -20)
        ])
        
        // Create grid layout (4 items per row for first 8, then 1 for planner)
        var currentRow: UIStackView?
        
        for (index, item) in menuItems.enumerated() {
            if index % 4 == 0 {
                currentRow = createRow()
                menuStackView.addArrangedSubview(currentRow!)
            }
            
            let itemView = createMenuItem(title: item.title, icon: item.icon, color: item.color, index: index)
            currentRow?.addArrangedSubview(itemView)
        }
        
        // Fill last row if needed
        if let lastRow = currentRow, lastRow.arrangedSubviews.count < 4 {
            let remaining = 4 - lastRow.arrangedSubviews.count
            for _ in 0..<remaining {
                let spacer = UIView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                lastRow.addArrangedSubview(spacer)
            }
        }
    }
    
    private func createRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }
    
    private func createMenuItem(title: String, icon: String, color: UIColor, index: Int) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let button = UIButton(type: .system)
        button.tag = index
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(menuItemTapped(_:)), for: .touchUpInside)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let iconContainer = UIView()
        iconContainer.backgroundColor = color
        iconContainer.layer.cornerRadius = 16
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        iconContainer.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 56),
            iconContainer.heightAnchor.constraint(equalToConstant: 56),
            imageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 28),
            imageView.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        
        stackView.addArrangedSubview(iconContainer)
        stackView.addArrangedSubview(label)
        
        container.addSubview(button)
        container.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            stackView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    @objc private func backgroundTapped() {
        delegate?.menuOverlayDidTapBackground(self)
    }
    
    @objc private func menuItemTapped(_ sender: UIButton) {
        delegate?.menuOverlay(self, didSelectItemAt: sender.tag)
    }
}
