import UIKit

// MARK: - FocusEventDelegate

protocol FocusEventDelegate: AnyObject {
    func didFocusMovie(_ movie: Movie)
    func didLoseFocus()
}

// MARK: - TabContainerController

/// Контейнер: держит общий UI (backdrop, tabBar, vignetteLayer).
/// Бизнес-логики нет — только layout и проброс событий наверх в TabCoordinator.
final class TabContainerController: UIViewController, FocusEventDelegate {

    // MARK: - Callbacks → TabCoordinator

    var onCategorySelected: ((FilmixCategory) -> Void)?
    var onGenreSelected:     ((FilmixGenre, FilmixCategory) -> Void)?
    var onSearchSubmitted:   ((String) -> Void)?
    var onSettingsSelected:  (() -> Void)?

    // MARK: - Shared components (используются дочерними координаторами)

    let focusCoordinator: FocusCoordinator

    // MARK: - UI

    private let backdropImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let backdropBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let baseGradientLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.colors = [
            UIColor(red: 0.07, green: 0.07, blue: 0.11, alpha: 1).cgColor,
            UIColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 1).cgColor,
        ]
        return l
    }()

    private let vignetteLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.type       = .radial
        l.colors     = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.70).cgColor]
        l.startPoint = CGPoint(x: 0.5, y: 0.5)
        l.endPoint   = CGPoint(x: 1.0, y: 1.0)
        return l
    }()

    private let tabBar = CategoryTabBar()

    private var tabBarHeightConstraint: NSLayoutConstraint!

    /// Область под табом — сюда вставляем дочерние контроллеры
    private let contentContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let videoPreviewPresenter = VideoPreviewPresenter()

    // MARK: - Init

    init() {
        focusCoordinator = FocusCoordinator(
            backdropImageView: backdropImageView,
            backdropBlur:      backdropBlur,
            videoPreviewPresenter: videoPreviewPresenter
        )
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        additionalSafeAreaInsets = .zero
        setupLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        baseGradientLayer.frame = view.bounds
        vignetteLayer.frame     = view.bounds
        videoPreviewPresenter.updateFrameIfNeeded()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.layer.insertSublayer(baseGradientLayer, at: 0)
        view.addSubview(backdropImageView)
        view.layer.addSublayer(vignetteLayer)
        view.addSubview(backdropBlur)
        view.addSubview(contentContainer)
        view.addSubview(tabBar)

        tabBar.delegate = self
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBarHeightConstraint = tabBar.heightAnchor.constraint(
            equalToConstant: CategoryTabBar.collapsedHeight
        )

        NSLayoutConstraint.activate([
            backdropImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backdropImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backdropBlur.topAnchor.constraint(equalTo: view.topAnchor),
            backdropBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            tabBar.topAnchor.constraint(equalTo: view.topAnchor),
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBarHeightConstraint,

            contentContainer.topAnchor.constraint(equalTo: tabBar.bottomAnchor, constant: 20),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // VideoPreview поверх всего
        videoPreviewPresenter.attach(to: view)
    }

    // MARK: - Child VC management

    func embed(child: UIViewController) {
        addChild(child)
        child.view.frame = contentContainer.bounds
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentContainer.addSubview(child.view)
        child.didMove(toParent: self)
    }

    func remove(child: UIViewController) {
        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
    }

    // MARK: - TabBar height

    func updateTabBarHeight(for category: FilmixCategory) {
        let hasGenres = !category.genres.isEmpty && !category.isSearch
        let isSearch  = category.isSearch

        let newHeight: CGFloat
        if isSearch       { newHeight = CategoryTabBar.searchExpandedHeight }
        else if hasGenres { newHeight = CategoryTabBar.expandedHeight }
        else              { newHeight = CategoryTabBar.collapsedHeight }

        guard tabBarHeightConstraint.constant != newHeight else { return }
        tabBarHeightConstraint.constant = newHeight
        UIView.animate(withDuration: 0.28, delay: 0,
                       usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - FocusEventDelegate

    func didFocusMovie(_ movie: Movie) {
        focusCoordinator.handleFocus(on: movie, cellSize: .zero)
    }

    func didLoseFocus() {
        focusCoordinator.handleFocusLost()
    }
}

// MARK: - CategoryTabBarDelegate

extension TabContainerController: CategoryTabBarDelegate {

    func categoryTabBar(_ bar: CategoryTabBar, didSelect category: FilmixCategory) {
        updateTabBarHeight(for: category)
        onCategorySelected?(category)
    }

    func categoryTabBar(_ bar: CategoryTabBar,
                        didSelectGenre genre: FilmixGenre,
                        in category: FilmixCategory) {
        onGenreSelected?(genre, category)
    }

    func categoryTabBar(_ bar: CategoryTabBar, didSubmitSearch query: String) {
        onSearchSubmitted?(query)
    }

    func categoryTabBarDidSelectSettings(_ bar: CategoryTabBar) {
        onSettingsSelected?()
    }
}
