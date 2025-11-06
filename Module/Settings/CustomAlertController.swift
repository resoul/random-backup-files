import UIKit

class CustomAlertController: UIViewController {
    
    private let overlayView = UIView()
    private let alertView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let warningLabel = UILabel()
    private let checkboxButton = UIButton()
    private let cancelButton = UIButton()
    private let destructiveButton = UIButton()
    
    private var alertTitle: String
    private var message: String
    private var warningText: String?
    private var checkboxText: String?
    private var cancelTitle: String
    private var destructiveTitle: String
    private var cancelAction: (() -> Void)?
    private var destructiveAction: (() -> Void)?
    
    init(title: String, message: String, warningText: String? = nil, checkboxText: String? = nil, cancelTitle: String = "Cancel", destructiveTitle: String, cancelAction: (() -> Void)? = nil, destructiveAction: (() -> Void)? = nil) {
        self.alertTitle = title
        self.message = message
        self.warningText = warningText
        self.checkboxText = checkboxText
        self.cancelTitle = cancelTitle
        self.destructiveTitle = destructiveTitle
        self.cancelAction = cancelAction
        self.destructiveAction = destructiveAction
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupActions()
    }
    
    private func setupViews() {
        view.backgroundColor = UIColor.clear
        
        // Overlay
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        // Alert container
        alertView.backgroundColor = UIColor(red: 0.15, green: 0.18, blue: 0.22, alpha: 1.0) // Dark gray-blue
        alertView.layer.cornerRadius = 12
        alertView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(alertView)
        
        // Title label
        titleLabel.text = alertTitle
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        alertView.addSubview(titleLabel)
        
        // Message label
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        messageLabel.textAlignment = .left
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        alertView.addSubview(messageLabel)
        
        // Warning label (if provided)
        if let warningText = warningText {
            warningLabel.text = warningText
            warningLabel.textColor = UIColor.lightGray
            warningLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            warningLabel.textAlignment = .left
            warningLabel.numberOfLines = 0
            warningLabel.translatesAutoresizingMaskIntoConstraints = false
            alertView.addSubview(warningLabel)
        }
        
        // Checkbox (if provided)
        if let checkboxText = checkboxText {
            checkboxButton.setTitle("  \(checkboxText)", for: .normal)
            checkboxButton.setTitleColor(.white, for: .normal)
            checkboxButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            checkboxButton.contentHorizontalAlignment = .left
            checkboxButton.setImage(UIImage(systemName: "square"), for: .normal)
            checkboxButton.setImage(UIImage(systemName: "checkmark.square"), for: .selected)
            checkboxButton.tintColor = UIColor.systemBlue
            checkboxButton.translatesAutoresizingMaskIntoConstraints = false
            alertView.addSubview(checkboxButton)
        }
        
        // Cancel button
        cancelButton.setTitle(cancelTitle, for: .normal)
        cancelButton.setTitleColor(UIColor.systemBlue, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        alertView.addSubview(cancelButton)
        
        // Destructive button
        destructiveButton.setTitle(destructiveTitle, for: .normal)
        destructiveButton.setTitleColor(UIColor.systemRed, for: .normal)
        destructiveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        destructiveButton.translatesAutoresizingMaskIntoConstraints = false
        alertView.addSubview(destructiveButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Overlay
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Alert view
            alertView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            alertView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            alertView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            alertView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            alertView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: alertView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -20),
            
            // Message
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -20),
        ])
        
        var lastView: UIView = messageLabel
        
        // Warning label constraints (if exists)
        if warningText != nil {
            NSLayoutConstraint.activate([
                warningLabel.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 16),
                warningLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 20),
                warningLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -20),
            ])
            lastView = warningLabel
        }
        
        // Checkbox constraints (if exists)
        if checkboxText != nil {
            NSLayoutConstraint.activate([
                checkboxButton.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 16),
                checkboxButton.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 20),
                checkboxButton.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -20),
                checkboxButton.heightAnchor.constraint(equalToConstant: 44),
            ])
            lastView = checkboxButton
        }
        
        // Buttons
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: destructiveButton.leadingAnchor, constant: -20),
            cancelButton.bottomAnchor.constraint(equalTo: alertView.bottomAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            cancelButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            destructiveButton.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 20),
            destructiveButton.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -20),
            destructiveButton.bottomAnchor.constraint(equalTo: alertView.bottomAnchor, constant: -20),
            destructiveButton.heightAnchor.constraint(equalToConstant: 44),
            destructiveButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
        ])
    }
    
    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        destructiveButton.addTarget(self, action: #selector(destructiveTapped), for: .touchUpInside)
        
        if checkboxText != nil {
            checkboxButton.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        }
        
        // Dismiss on overlay tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        overlayView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true) { [weak self] in
            self?.cancelAction?()
        }
    }
    
    @objc private func destructiveTapped() {
        dismiss(animated: true) { [weak self] in
            self?.destructiveAction?()
        }
    }
    
    @objc private func checkboxTapped() {
        checkboxButton.isSelected.toggle()
    }
    
    @objc private func overlayTapped() {
        cancelTapped()
    }
}

// MARK: - Usage Example
extension UIViewController {
    func showCustomAlert(title: String, message: String, warningText: String? = nil, checkboxText: String? = nil, cancelTitle: String = "Cancel", destructiveTitle: String, cancelAction: (() -> Void)? = nil, destructiveAction: (() -> Void)? = nil) {
        
        let alert = CustomAlertController(
            title: title,
            message: message,
            warningText: warningText,
            checkboxText: checkboxText,
            cancelTitle: cancelTitle,
            destructiveTitle: destructiveTitle,
            cancelAction: cancelAction,
            destructiveAction: destructiveAction
        )
        
        present(alert, animated: true)
    }
}

// Пример как на первом скриншоте
//showCustomAlert(
//    title: "Delete chat",
//    message: "Are you sure you want to delete all message history with Maryna Ostrovska?",
//    warningText: "This action cannot be undone.",
//    checkboxText: "Also delete for Maryna",
//    cancelTitle: "Cancel",
//    destructiveTitle: "Delete"
//) {
//    // Cancel action
//    print("Cancelled")
//} destructiveAction: {
//    // Delete action
//    print("Deleted")
//}

//// Пример как на втором скриншоте
//showCustomAlert(
//    title: "SMTP relay panel",
//    message: "Are you sure you want to leave this group?",
//    cancelTitle: "Cancel",
//    destructiveTitle: "Leave"
//) {
//    // Cancel
//} destructiveAction: {
//    // Leave group
//}
