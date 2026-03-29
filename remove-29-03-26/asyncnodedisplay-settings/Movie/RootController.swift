import UIKit
import IGListKit
import Combine

// MARK: - RootController

final class RootController: UIViewController {

    // MARK: - Dependencies

    private let viewModel = RootViewModel()

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

    private let tabBar = CategoryTabBar()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.remembersLastFocusedIndexPath = true
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    // TabBar height constraint — меняется когда открывается/закрывается жанровая строка
    private var tabBarHeightConstraint: NSLayoutConstraint!

    // MARK: - IGListKit

    private lazy var adapter: ListAdapter = {
        ListAdapter(updater: ListAdapterUpdater(), viewController: self)
    }()

    private let sectionController = MoviesSectionController()
    private let videoPreviewPresenter = VideoPreviewPresenter()
    
    private lazy var focusCoordinator = FocusCoordinator(
        backdropImageView: backdropImageView,
        backdropBlur: backdropBlur,
        videoPreviewPresenter: videoPreviewPresenter
    )

    // MARK: - State

    private var cancellables = Set<AnyCancellable>()
    private var currentSection: MoviesSection?
    private var preferredFocusCell: UICollectionViewCell?

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if let cell = preferredFocusCell { return [cell] }
        return super.preferredFocusEnvironments
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupAdapter()
        setupSectionCallbacks()
        bindViewModel()

        // Загружаем первую категорию из FilmixCategory.all
        if let first = FilmixCategory.all.first(where: { !$0.isSearch }) {
            viewModel.switchCategory(first)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.reloadFavoritesOrHistory()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // VideoPreview frame зависит от bounds — пересчитываем после каждого layout pass
        videoPreviewPresenter.updateFrameIfNeeded()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(backdropImageView)
        view.addSubview(backdropBlur)
        view.addSubview(collectionView)
        view.addSubview(tabBar)

        tabBar.delegate = self
        tabBarHeightConstraint = tabBar.heightAnchor.constraint(
            equalToConstant: CategoryTabBar.collapsedHeight
        )

        NSLayoutConstraint.activate([
            // Backdrop — под всем
            backdropImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backdropImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backdropBlur.topAnchor.constraint(equalTo: view.topAnchor),
            backdropBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // TabBar — сверху
            tabBar.topAnchor.constraint(equalTo: view.topAnchor),
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBarHeightConstraint,

            // CollectionView — под табом
            collectionView.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // attach последним — overlay поверх всех subviews
        videoPreviewPresenter.attach(to: view)
    }

    // MARK: - IGListKit Setup

    private func setupAdapter() {
        adapter.collectionView = collectionView
        adapter.dataSource     = self
    }

    private func setupSectionCallbacks() {
        sectionController.onSelectMovie = { [weak self] movie in
            self?.openDetail(for: movie)
        }
        sectionController.onPrefetch = { [weak self] index in
            self?.viewModel.loadNextPageIfNeeded(prefetchIndex: index)
        }
        sectionController.onFocusMovie = { [weak self] movie, cellSize in
            self?.focusCoordinator.handleFocus(on: movie, cellSize: cellSize)
        }
        sectionController.onFocusLost = { [weak self] in
            self?.focusCoordinator.handleFocusLost()
        }
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.$movies
            .receive(on: RunLoop.main)
            .sink { [weak self] movies in self?.applyMovies(movies) }
            .store(in: &cancellables)

        viewModel.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in self?.handleState(state) }
            .store(in: &cancellables)
    }

    // MARK: - Apply Data

//    private func applyMovies(_ movies: [Movie]) {
//        let isFirstLoad = currentSection == nil || currentSection?.movies.isEmpty == true
//        currentSection = MoviesSection(movies: movies, hasNextPage: viewModel.hasNextPage)
//        adapter.performUpdates(animated: true) { [weak self] _ in
//            if isFirstLoad && !movies.isEmpty {
//                self?.focusFirstCell(movies: movies)
//            }
//        }
//
//        if let first = movies.first, backdropImageView.alpha == 0 {
//            focusCoordinator.showInitialBackdrop(for: first)
//        }
//    }
    
    private func applyMovies(_ movies: [Movie]) {
        let isFirstLoad = currentSection == nil || currentSection?.movies.isEmpty == true
        currentSection = MoviesSection(movies: movies, hasNextPage: viewModel.hasNextPage)
        adapter.performUpdates(animated: true) { [weak self] _ in
            if isFirstLoad && !movies.isEmpty {
                self?.focusFirstCell(movies: movies)
            }
        }
    }

    private func focusFirstCell(movies: [Movie]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            let ip = IndexPath(item: 0, section: 0)
            guard let cell = self.collectionView.cellForItem(at: ip) else { return }

            self.preferredFocusCell = cell
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
            self.preferredFocusCell = nil

            // Один вызов — и backdrop и preview
            self.focusCoordinator.handleFocus(on: movies[0], cellSize: cell.bounds.size)
        }
    }

    // MARK: - State Handling

    private func handleState(_ state: LoadingState) {
        switch state {
        case .idle, .loading:
            break
        case .loaded:
            viewModel.isEmpty ? showEmptyState() : hideEmptyState()
        case .error(let message):
            showError(message: message)
        }
    }

    // MARK: - TabBar height sync

    /// Вызывается когда CategoryTabBar меняет высоту (жанры / поиск)
    private func updateTabBarHeight() {
        let hasGenres = tabBar.hasGenres && !tabBar.currentIsSearch
        let isSearch  = tabBar.currentIsSearch

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

    // MARK: - Navigation

    private func openDetail(for movie: Movie) {
        focusCoordinator.hidePreview()
        let detail = MovieDetailViewController(movie: movie)
        present(detail, animated: true)
    }

    // MARK: - Empty / Error

    private var emptyLabel: UILabel?

    private func showEmptyState() {
        guard emptyLabel == nil else { return }
        let label = UILabel()
        label.text          = viewModel.emptyMessage
        label.textColor     = UIColor(white: 0.6, alpha: 1)
        label.font          = .systemFont(ofSize: 28, weight: .medium)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: collectionView.widthAnchor,
                                         multiplier: 0.6),
        ])
        emptyLabel = label
    }

    private func hideEmptyState() {
        emptyLabel?.removeFromSuperview()
        emptyLabel = nil
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            Task { await self?.viewModel.loadFirstPage() }
        })
        present(alert, animated: true)
    }
}

// MARK: - CategoryTabBarDelegate

extension RootController: CategoryTabBarDelegate {

    func categoryTabBar(_ bar: CategoryTabBar, didSelect category: FilmixCategory) {
        viewModel.switchCategory(category)
        updateTabBarHeight()
    }

    func categoryTabBar(_ bar: CategoryTabBar,
                        didSelectGenre genre: FilmixGenre,
                        in category: FilmixCategory) {
        viewModel.switchCategory(category, genre: genre)
    }

    func categoryTabBar(_ bar: CategoryTabBar, didSubmitSearch query: String) {
        // TODO: подключить SearchViewModel / SearchController
    }

    func categoryTabBarDidSelectSettings(_ bar: CategoryTabBar) {
        // TODO: открыть настройки
    }
}

// MARK: - ListAdapterDataSource

extension RootController: ListAdapterDataSource {

    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        guard let s = currentSection, !s.movies.isEmpty else { return [] }
        return [s]
    }

    func listAdapter(_ listAdapter: ListAdapter,
                     sectionControllerFor object: Any) -> ListSectionController {
        sectionController
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? { nil }
}
