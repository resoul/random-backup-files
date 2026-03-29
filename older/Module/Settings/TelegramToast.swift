import UIKit

class TelegramToast: UIView {
    
    // MARK: - Properties
    private let messageLabel = UILabel()
    private let iconImageView = UIImageView()
    private let undoButton = UIButton(type: .system)
    private let containerView = UIView()
    
    private var hideTimer: Timer?
    private var onUndoAction: (() -> Void)?
    
    // MARK: - Configuration
    struct Configuration {
        let message: String
        let icon: UIImage?
        let showUndoButton: Bool
        let duration: TimeInterval
        let undoAction: (() -> Void)?
        
        init(message: String,
             icon: UIImage? = nil,
             showUndoButton: Bool = false,
             duration: TimeInterval = 3.0,
             undoAction: (() -> Void)? = nil) {
            self.message = message
            self.icon = icon
            self.showUndoButton = showUndoButton
            self.duration = duration
            self.undoAction = undoAction
        }
    }
    
    // MARK: - Initialization
    init(configuration: Configuration) {
        super.init(frame: .zero)
        self.onUndoAction = configuration.undoAction
        setupView(with: configuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupView(with config: Configuration) {
        setupContainerView()
        setupIcon(config.icon)
        setupMessageLabel(config.message)
        setupUndoButton(config.showUndoButton)
        setupConstraints(showUndoButton: config.showUndoButton)
        setupGestures()
    }
    
    private func setupContainerView() {
        containerView.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.95)
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add blur effect
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(blurView)
        
        addSubview(containerView)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func setupIcon(_ icon: UIImage?) {
        if let icon = icon {
            iconImageView.image = icon
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.tintColor = .label
            iconImageView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(iconImageView)
        }
    }
    
    private func setupMessageLabel(_ message: String) {
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        messageLabel.textColor = .label
        messageLabel.numberOfLines = 0
        messageLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
    }
    
    private func setupUndoButton(_ showButton: Bool) {
        guard showButton else { return }
        
        undoButton.setTitle("Undo", for: .normal)
        undoButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        undoButton.setTitleColor(.systemBlue, for: .normal)
        undoButton.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(undoButton)
    }
    
    private func setupConstraints(showUndoButton: Bool) {
        let hasIcon = iconImageView.superview != nil
        
        var constraints: [NSLayoutConstraint] = [
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            containerView.heightAnchor.constraint(greaterThanOrEqualTo: heightAnchor, constant: 56)
        ]
        
        if hasIcon {
            constraints.append(contentsOf: [
                iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                iconImageView.widthAnchor.constraint(equalToConstant: 24),
                iconImageView.heightAnchor.constraint(equalToConstant: 24),
                
                messageLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
                messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
                messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
            ])
        } else {
            constraints.append(contentsOf: [
                messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
                messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
            ])
        }
        
        if showUndoButton {
            constraints.append(contentsOf: [
                undoButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                undoButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                undoButton.leadingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: 16),
                undoButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44)
            ])
        } else {
            constraints.append(
                messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
            )
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupGestures() {
        let swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        containerView.addGestureRecognizer(swipeGesture)
    }
    
    // MARK: - Actions
    @objc private func undoButtonTapped() {
        onUndoAction?()
        hide(animated: true)
    }
    
    @objc private func handleSwipe(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)
        
        switch gesture.state {
        case .changed:
            if translation.x > 0 {
                containerView.transform = CGAffineTransform(translationX: translation.x, y: 0)
            }
        case .ended, .cancelled:
            if translation.x > 100 || velocity.x > 500 {
                hideWithSwipe()
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
                    self.containerView.transform = .identity
                }
            }
        default:
            break
        }
    }
    
    private func hideWithSwipe() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.containerView.transform = CGAffineTransform(translationX: self.bounds.width, y: 0)
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }
        hideTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    func show(in view: UIView, duration: TimeInterval = 3.0) {
        view.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            heightAnchor.constraint(equalToConstant: 56)
        ])
        
        // Initial state
        containerView.transform = CGAffineTransform(translationX: -bounds.width, y: 0)
        alpha = 0
        
        // Animate in
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.containerView.transform = .identity
            self.alpha = 1
        }
        
        // Auto hide
        if duration > 0 {
            hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                self.hide(animated: true)
            }
        }
    }
    
    func hide(animated: Bool = true) {
        hideTimer?.invalidate()
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.containerView.transform = CGAffineTransform(translationX: -self.bounds.width, y: 0)
                self.alpha = 0
            } completion: { _ in
                self.removeFromSuperview()
            }
        } else {
            removeFromSuperview()
        }
    }
}

// MARK: - Convenience Extensions
extension TelegramToast {
    
    static func show(message: String, in view: UIView) {
        let config = Configuration(message: message)
        let toast = TelegramToast(configuration: config)
        toast.show(in: view, duration: config.duration)
    }
    
    static func showWithUndo(message: String, in view: UIView, undoAction: @escaping () -> Void) {
        let config = Configuration(
            message: message,
            showUndoButton: true,
            duration: 5.0,
            undoAction: undoAction
        )
        let toast = TelegramToast(configuration: config)
        toast.show(in: view, duration: config.duration)
    }
    
    static func showWithIcon(message: String, icon: UIImage?, in view: UIView) {
        let config = Configuration(message: message, icon: icon)
        let toast = TelegramToast(configuration: config)
        toast.show(in: view, duration: config.duration)
    }
}
