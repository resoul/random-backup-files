import UIKit

class ToastExampleViewController: UIViewController {
    
    private let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Toast Examples"
        
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])
        
        addButton(title: "Simple Toast", action: #selector(showSimpleToast))
        addButton(title: "Toast with Undo", action: #selector(showUndoToast))
        addButton(title: "Toast with Icon", action: #selector(showIconToast))
        addButton(title: "Channel Left Toast", action: #selector(showChannelLeftToast))
        addButton(title: "Custom Toast", action: #selector(showCustomToast))
    }
    
    private func addButton(title: String, action: Selector) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }
    
    @objc private func showSimpleToast() {
        TelegramToast.show(message: "Message sent", in: view)
    }
    
    @objc private func showUndoToast() {
        TelegramToast.showWithUndo(message: "You left the channel.", in: view) {
            print("Undo action triggered")
            TelegramToast.show(message: "Action undone", in: self.view)
        }
    }
    
    @objc private func showIconToast() {
        let icon = UIImage(systemName: "checkmark.circle.fill")
        TelegramToast.showWithIcon(message: "Settings saved", icon: icon, in: view)
    }
    
    @objc private func showChannelLeftToast() {
        // Create a custom configuration like in Telegram
        let config = TelegramToast.Configuration(
            message: "You left the channel.",
            icon: UIImage(systemName: "arrow.uturn.left.circle"),
            showUndoButton: true,
            duration: 5.0
        ) {
            print("Rejoining channel...")
            TelegramToast.show(message: "Rejoined channel", in: self.view)
        }
        
        let toast = TelegramToast(configuration: config)
        toast.show(in: view, duration: 5.0)
    }
    
    @objc private func showCustomToast() {
        let config = TelegramToast.Configuration(
            message: "Settings updated successfully",
            icon: UIImage(systemName: "star.fill"),
            showUndoButton: false,
            duration: 4.0,
            undoAction: nil
        )
        
        let toast = TelegramToast(configuration: config)
        toast.show(in: view, duration: 4.0)
    }
}

// MARK: - SceneDelegate Integration Example
/*
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        let viewController = ToastExampleViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}
*/
