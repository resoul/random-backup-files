import UIKit
import Combine

// MARK: - TVTabBarViewController
//
// Контейнер: держит TVTabBarView сверху и contentContainer снизу.
//
// Связь с контентом через ContentLoadable:
//   При выборе жанра → (activeVC as? ContentLoadable)?.load(url: genre.url)
//   При выборе категории → (activeVC as? ContentLoadable)?.load(url: nil)
//
// TVTabBarViewController НЕ знает про конкретные ViewModel или провайдер.

final class TVTabBarViewController: UIViewController {

    // MARK: - Dependencies

    private let screenMap:        [String: UIViewController]
    private let focusCoordinator: FocusCoordinator

    // MARK: - Subviews

    private lazy var tabBarView: TVTabBarView = {
        let v = TVTabBarView()
        v.delegate = self
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var contentContainer: TVFocusPassthroughView = {
        let v = TVFocusPassthroughView()
        v.backgroundColor = UIColor(red: 0.15, green: 0.11, blue: 0.09, alpha: 1)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var tabBarHeightConstraint: NSLayoutConstraint!
    private var activeVC: UIViewController?

    // MARK: - Init

    init(screenMap: [String: UIViewController],
         focusCoordinator: FocusCoordinator) {
        self.screenMap        = screenMap
        self.focusCoordinator = focusCoordinator
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.15, green: 0.11, blue: 0.09, alpha: 1)
        setupLayout()
        setupFocusCoordinator()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(tabBarView)
        view.addSubview(contentContainer)

        tabBarHeightConstraint = tabBarView.heightAnchor.constraint(
            equalToConstant: TVTabBarView.collapsedHeight
        )

        NSLayoutConstraint.activate([
            tabBarView.topAnchor.constraint(equalTo: view.topAnchor),
            tabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBarHeightConstraint,

            contentContainer.topAnchor.constraint(equalTo: tabBarView.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupFocusCoordinator() {
        focusCoordinator.tabBarViewController = self
        focusCoordinator.delegate             = self
    }

    // MARK: - configure(categories:)

    func configure(categories: [ProviderCategory]) {
        tabBarView.configure(categories: categories)

        if let first = categories.first(where: { !$0.isSearch }) {
            showScreen(for: first, animated: false)
        }
    }

    // MARK: - Screen switching

    private func showScreen(for category: ProviderCategory, animated: Bool) {
        let nextVC = screenMap[category.id]
            ?? makeFallbackVC(category: category)

        guard nextVC !== activeVC else { return }

        activeVC?.willMove(toParent: nil)
        activeVC?.view.removeFromSuperview()
        activeVC?.removeFromParent()

        addChild(nextVC)
        nextVC.view.frame            = contentContainer.bounds
        nextVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentContainer.addSubview(nextVC.view)
        nextVC.didMove(toParent: self)

        activeVC                               = nextVC
        focusCoordinator.contentViewController = nextVC
    }

    private func makeFallbackVC(category: ProviderCategory) -> UIViewController {
        let vc      = UIViewController()
        vc.view.backgroundColor = UIColor(red: 0.15, green: 0.11, blue: 0.09, alpha: 1)
        let label   = UILabel()
        label.text      = category.title
        label.textColor = .white
        label.font      = .systemFont(ofSize: 40, weight: .thin)
        label.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor),
        ])
        return vc
    }

    // MARK: - TabBar height animation

    private func updateTabBarHeight(expanded: Bool, isSearch: Bool = false) {
        let newHeight: CGFloat
        if isSearch           { newHeight = TVTabBarView.searchExpandedHeight }
        else if expanded      { newHeight = TVTabBarView.expandedHeight }
        else                  { newHeight = TVTabBarView.collapsedHeight }

        guard tabBarHeightConstraint.constant != newHeight else { return }
        tabBarHeightConstraint.constant = newHeight
        UIView.animate(withDuration: 0.28, delay: 0,
                       usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Focus Environment

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        switch focusCoordinator.currentRegion {
        case .tabBar:  return [tabBarView]
        case .content: return activeVC.map { [$0] } ?? [contentContainer]
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        if context.previouslyFocusedView?.isDescendant(of: tabBarView) == true,
           context.nextFocusedView?.isDescendant(of: tabBarView) == false {
            focusCoordinator.handleSwipeDownFromTabBar()
        }
        if context.previouslyFocusedView?.isDescendant(of: tabBarView) == false,
           context.nextFocusedView?.isDescendant(of: tabBarView) == true {
            focusCoordinator.handleSwipeUpFromContent()
        }
    }
}

// MARK: - TVTabBarViewDelegate

extension TVTabBarViewController: TVTabBarViewDelegate {

    func tvTabBarView(_ bar: TVTabBarView, didSelect category: ProviderCategory) {
        guard !category.isSearch else { return }

        showScreen(for: category, animated: true)
        updateTabBarHeight(expanded: !category.genres.isEmpty)

        // Загружаем дефолтный URL категории
        // ContentLoadable.load(nil) — VM сама знает свой базовый URL
        (activeVC as? ContentLoadable)?.load(url: nil)

        focusCoordinator.moveFocus(to: .content)
    }

    func tvTabBarView(_ bar: TVTabBarView,
                      didSelectGenre genre: ProviderGenre,
                      in category: ProviderCategory) {
        // Ключевой момент — URL жанра передаём через протокол.
        // TVTabBarViewController не знает что такое MoviesViewModel.
        (activeVC as? ContentLoadable)?.load(url: URL(string: genre.url))

        focusCoordinator.moveFocus(to: .content)
    }

    func tvTabBarView(_ bar: TVTabBarView, didSubmitSearch query: String) {
        let searchCategory = ProviderCategory(
            id: "search", title: "Поиск", icon: "magnifyingglass",
            url: nil, genres: [], isSearch: true
        )
        showScreen(for: searchCategory, animated: true)
        updateTabBarHeight(expanded: false, isSearch: true)
        (activeVC as? SearchViewController)?.viewModel.query = query
    }

    func tvTabBarViewDidSelectSettings(_ bar: TVTabBarView) {
        let settingsCategory = ProviderCategory(
            id: "settings", title: "Настройки", icon: "gearshape.fill",
            url: nil, genres: []
        )
        showScreen(for: settingsCategory, animated: true)
        updateTabBarHeight(expanded: false)
        focusCoordinator.moveFocus(to: .content)
    }
}

// MARK: - FocusCoordinatorDelegate

extension TVTabBarViewController: FocusCoordinatorDelegate {
    func focusCoordinator(_ coordinator: FocusCoordinator, didChangeTo region: FocusRegion) {
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }
}

// MARK: - TVFocusPassthroughView

final class TVFocusPassthroughView: UIView {
    override var canBecomeFocused: Bool { false }
    override var preferredFocusEnvironments: [UIFocusEnvironment] { subviews }
}
