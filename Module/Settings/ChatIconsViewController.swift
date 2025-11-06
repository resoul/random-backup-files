import UIKit

class ChatIconsViewController: UIViewController {
    
    // MARK: - Properties
    private var isExpanded = false
    private var iconViews: [UIView] = []
    private let iconSize: CGFloat = 60
    private let spacing: CGFloat = 80
    private let animationDuration: TimeInterval = 0.8
    
    // Navigation bar
    private let navigationBar = UIView()
    private let titleLabel = UILabel()
    private let editButton = UIButton()
    private let addButton = UIButton()
    private let composeButton = UIButton()
    
    // Search bar
    private let searchContainer = UIView()
    private let searchBar = UISearchBar()
    
    // Icon data (simulating different chat types)
    private let iconData = [
        ("My Story", UIColor.systemGreen, "📱"),
        ("Telegram", UIColor.systemBlue, "✈️"),
        ("HOKAVT", UIColor.black, "👥"),
        ("ШОУ-Biz", UIColor.systemRed, "🎭"),
        ("КОСМОС", UIColor.systemPurple, "🚀"),
        ("Ты в тренде", UIColor.systemYellow, "⚡")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupIconViews()
        setupGestures()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // Navigation Bar
        setupNavigationBar()
        
        // Search Bar
        setupSearchBar()
    }
    
    private func setupNavigationBar() {
        navigationBar.backgroundColor = .clear
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        
        // Edit button
        editButton.setTitle("Edit", for: .normal)
        editButton.setTitleColor(.systemBlue, for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.addSubview(editButton)
        
        // Title
        titleLabel.text = "Chats"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.addSubview(titleLabel)
        
        // Add button
        addButton.setTitle("+", for: .normal)
        addButton.setTitleColor(.systemBlue, for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        addButton.backgroundColor = .clear
        addButton.layer.cornerRadius = 15
        addButton.layer.borderWidth = 1
        addButton.layer.borderColor = UIColor.systemBlue.cgColor
        addButton.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.addSubview(addButton)
        
        // Compose button
        composeButton.setTitle("✏️", for: .normal)
        composeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        composeButton.backgroundColor = .clear
        composeButton.layer.cornerRadius = 15
        composeButton.layer.borderWidth = 1
        composeButton.layer.borderColor = UIColor.systemBlue.cgColor
        composeButton.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.addSubview(composeButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 60),
            
            editButton.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 16),
            editButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor, constant: 8),
            
            titleLabel.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor, constant: 8),
            
            composeButton.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor, constant: -16),
            composeButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor, constant: 8),
            composeButton.widthAnchor.constraint(equalToConstant: 30),
            composeButton.heightAnchor.constraint(equalToConstant: 30),
            
            addButton.trailingAnchor.constraint(equalTo: composeButton.leadingAnchor, constant: -12),
            addButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor, constant: 8),
            addButton.widthAnchor.constraint(equalToConstant: 30),
            addButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupSearchBar() {
        searchContainer.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        searchContainer.layer.cornerRadius = 10
        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchContainer)
        
        searchBar.placeholder = "Search"
        searchBar.backgroundColor = .clear
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.addSubview(searchBar)
        
        NSLayoutConstraint.activate([
            searchContainer.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 16),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchContainer.heightAnchor.constraint(equalToConstant: 44),
            
            searchBar.topAnchor.constraint(equalTo: searchContainer.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor),
            searchBar.bottomAnchor.constraint(equalTo: searchContainer.bottomAnchor)
        ])
    }
    
    private func setupIconViews() {
        for (index, data) in iconData.enumerated() {
            let iconView = createIconView(title: data.0, color: data.1, emoji: data.2, index: index)
            iconViews.append(iconView)
            view.addSubview(iconView)
        }
        
        // Start in collapsed state
        layoutIconsCollapsed()
    }
    
    private func createIconView(title: String, color: UIColor, emoji: String, index: Int) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon circle
        let iconView = UIView()
        iconView.backgroundColor = color
        iconView.layer.cornerRadius = iconSize / 2
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subtle shadow
        iconView.layer.shadowColor = UIColor.black.cgColor
        iconView.layer.shadowOpacity = 0.2
        iconView.layer.shadowOffset = CGSize(width: 0, height: 2)
        iconView.layer.shadowRadius = 4
        
        // Add green border for first 3 icons (like in Telegram)
        if index < 3 {
            iconView.layer.borderWidth = 2.5
            iconView.layer.borderColor = UIColor.systemGreen.cgColor
        }
        
        // Create a gradient effect for some icons
        if index == 1 { // Telegram icon
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [UIColor.systemBlue.cgColor, UIColor.systemCyan.cgColor]
            gradientLayer.frame = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
            gradientLayer.cornerRadius = iconSize / 2
            iconView.layer.insertSublayer(gradientLayer, at: 0)
        }
        
        // Emoji label
        let emojiLabel = UILabel()
        emojiLabel.text = emoji
        emojiLabel.font = UIFont.systemFont(ofSize: 24)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        iconView.addSubview(emojiLabel)
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        
        // Add tap gesture to individual icons
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(iconTapped(_:)))
        containerView.addGestureRecognizer(tapGesture)
        containerView.tag = index
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),
            
            emojiLabel.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: -10),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 10),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    @objc private func iconTapped(_ gesture: UITapGestureRecognizer) {
        guard let iconView = gesture.view else { return }
        let index = iconView.tag
        
        // Animate the tapped icon
        UIView.animate(withDuration: 0.1, animations: {
            iconView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                iconView.transform = .identity
            }
        }
        
        print("Tapped icon: \(iconData[index].0)")
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Layout Methods
    private func layoutIconsCollapsed() {
        let centerX = view.bounds.midX
        let centerY = view.bounds.midY - 50
        
        for (index, iconView) in iconViews.enumerated() {
            if index < 3 {
                // Show only first 3 icons in a stack
                let offsetX: CGFloat = CGFloat(index - 1) * 5 // Slight horizontal offset
                let offsetY: CGFloat = CGFloat(index) * -3 // Stack them vertically
                
                iconView.center = CGPoint(x: centerX + offsetX, y: centerY + offsetY)
                iconView.alpha = 1.0
                iconView.transform = .identity
            } else {
                // Hide other icons
                iconView.center = CGPoint(x: centerX, y: centerY)
                iconView.alpha = 0.0
                iconView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }
        }
        
        // Position the stack in the title area
        let stackCenterX = titleLabel.center.x + 100
        let stackCenterY = titleLabel.center.y
        
        for (index, iconView) in iconViews.enumerated() {
            if index < 3 {
                let offsetX: CGFloat = CGFloat(index - 1) * 8
                iconView.center = CGPoint(x: stackCenterX + offsetX, y: stackCenterY)
                iconView.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            }
        }
    }
    
    private func layoutIconsExpanded() {
        let startX: CGFloat = 60
        let startY: CGFloat = searchContainer.frame.maxY + 40
        let itemsPerRow = 3
        
        for (index, iconView) in iconViews.enumerated() {
            let row = index / itemsPerRow
            let col = index % itemsPerRow
            
            let x = startX + CGFloat(col) * (iconSize + spacing)
            let y = startY + CGFloat(row) * (iconSize + spacing)
            
            iconView.center = CGPoint(x: x, y: y)
            iconView.alpha = 1.0
            iconView.transform = .identity
        }
    }
    
    // MARK: - Animation
    @objc private func handleTap() {
        toggleIcons()
    }
    
    private func toggleIcons() {
        isExpanded.toggle()
        
        if isExpanded {
            expandIcons()
        } else {
            collapseIcons()
        }
    }
    
    private func expandIcons() {
        // First, make all icons visible
        for iconView in iconViews {
            iconView.alpha = 1.0
        }
        
        // Animate with a beautiful elastic effect
        for (index, iconView) in iconViews.enumerated() {
            let delay = Double(index) * 0.08
            let finalX = 60 + CGFloat(index % 3) * (iconSize + spacing)
            let finalY = searchContainer.frame.maxY + 40 + CGFloat(index / 3) * (iconSize + spacing)
            
            // Create a curved animation path
            let animation = CAKeyframeAnimation(keyPath: "position")
            animation.duration = 0.6
            animation.beginTime = CACurrentMediaTime() + delay
            animation.fillMode = .backwards
            
            let startPoint = iconView.layer.position
            let endPoint = CGPoint(x: finalX, y: finalY)
            let controlPoint = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: startPoint.y - 30)
            
            let path = UIBezierPath()
            path.move(to: startPoint)
            path.addQuadCurve(to: endPoint, controlPoint: controlPoint)
            animation.path = path.cgPath
            
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            iconView.layer.add(animation, forKey: "expand")
            iconView.layer.position = endPoint
            
            // Scale animation
            UIView.animate(withDuration: 0.6, delay: delay, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: []) {
                iconView.transform = .identity
            }
        }
    }
    
    private func collapseIcons() {
        let stackCenterX = titleLabel.center.x + 100
        let stackCenterY = titleLabel.center.y
        
        // Animate icons back to stack
        for (index, iconView) in iconViews.enumerated().reversed() {
            let delay = Double(iconViews.count - index - 1) * 0.04
            
            if index < 3 {
                // Stack the first 3 icons
                let offsetX: CGFloat = CGFloat(index - 1) * 8
                let finalPoint = CGPoint(x: stackCenterX + offsetX, y: stackCenterY)
                
                UIView.animate(withDuration: 0.5, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: []) {
                    iconView.center = finalPoint
                    iconView.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
                }
            } else {
                // Hide other icons
                UIView.animate(withDuration: 0.3, delay: delay, options: [.curveEaseIn]) {
                    iconView.alpha = 0.0
                    iconView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    iconView.center = CGPoint(x: stackCenterX, y: stackCenterY)
                }
            }
        }
    }
}

// MARK: - Scene Delegate Integration
extension ChatIconsViewController {
    static func createAndPresent(in window: UIWindow?) {
        let viewController = ChatIconsViewController()
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
    }
}
