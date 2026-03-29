import UIKit
import Combine

// MARK: - PlaceholderViewController

final class PlaceholderViewController: UIViewController {

    private let tabItem:     TabItem
    private let message: String

    private lazy var iconView: UIImageView = {
        let cfg = UIImage.SymbolConfiguration(pointSize: 80, weight: .thin)
        let v = UIImageView(image: UIImage(systemName: tabItem.sfSymbol, withConfiguration: cfg))
        v.tintColor = Theme.Colors.textSecondary
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text          = tabItem.title
        l.font          = Theme.Fonts.title(size: 52)
        l.textColor     = Theme.Colors.textPrimary
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.text          = message
        l.font          = Theme.Fonts.body()
        l.textColor     = Theme.Colors.textSecondary
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    init(tab: TabItem, message: String = "Раздел в разработке") {
        self.tabItem     = tab
        self.message = message
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Colors.background

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, subtitleLabel])
        stack.axis      = .vertical
        stack.spacing   = 24
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        // ✅ Только centerX + centerY — без leading/trailing на стеке
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            // Ограничиваем ширину чтобы текст не уходил за края
            stack.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.7),
        ])
    }
}

// MARK: - BaseScreenViewController

class BaseScreenViewController<VM: BaseViewModel>: UIViewController {

    let viewModel: VM
    var cancellables = Set<AnyCancellable>()

    // MARK: - Overlay views

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.color = Theme.Colors.accent
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var emptyLabel: UILabel = {
        let l = UILabel()
        l.font          = Theme.Fonts.body()
        l.textColor     = Theme.Colors.textSecondary
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden      = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var errorLabel: UILabel = {
        let l = UILabel()
        l.font          = Theme.Fonts.body()
        l.textColor     = UIColor.systemRed
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden      = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init

    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Colors.background
        setupOverlays()
        bindState()
    }

    // MARK: - Setup

    private func setupOverlays() {
        view.addSubview(loadingIndicator)
        view.addSubview(emptyLabel)
        view.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            // Spinner — просто по центру
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // emptyLabel / errorLabel — centerX + centerY + widthAnchor.lessThanOrEqualTo
            // leading/trailing конфликтуют с width==0 до первого layout-прохода
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.7),

            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.7),
        ])
    }

    private func bindState() {
        viewModel.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in self?.applyState(state) }
            .store(in: &cancellables)
    }

    // MARK: - State rendering

    private func applyState(_ state: ViewState) {
        loadingIndicator.isHidden = state != .loading
        emptyLabel.isHidden       = true
        errorLabel.isHidden       = true

        switch state {
        case .loading:
            loadingIndicator.startAnimating()

        case .loaded:
            loadingIndicator.stopAnimating()
            didLoad()

        case .empty(let msg):
            loadingIndicator.stopAnimating()
            emptyLabel.text     = msg
            emptyLabel.isHidden = false

        case .error(let msg):
            loadingIndicator.stopAnimating()
            errorLabel.text     = msg
            errorLabel.isHidden = false

        case .idle:
            loadingIndicator.stopAnimating()
        }
    }

    /// Переопределить в наследнике для реакции на успешную загрузку
    func didLoad() {}
}
