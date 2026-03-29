import UIKit
import IGListKit
import Combine
import Filmix

// MARK: - ContentViewController
//
// Универсальный экран для отображения списка фильмов с пагинацией.
// Параметризован VM: любой ViewModel реализующий PaginatableViewModel.
//
// Реализует ContentLoadable — TVTabBarViewController управляет загрузкой
// через протокол, не зная о конкретном типе VM.
//
// ВАЖНО: ListAdapterDataSource — ObjC протокол.
// Extension generic класса не может содержать @objc члены — реализуем через
// отдельный приватный DataSource объект (не через extension).

final class ContentViewController<VM: PaginatableViewModel>: BaseScreenViewController<VM>, ContentLoadable {

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

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.remembersLastFocusedIndexPath = true
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    // MARK: - IGListKit
    //
    // dataSource — отдельный объект, чтобы обойти ограничение:
    // "Extensions of generic classes cannot contain @objc members"

    private lazy var adapter: ListAdapter = {
        ListAdapter(updater: ListAdapterUpdater(), viewController: self)
    }()

    private let sectionController = MoviesSectionController()

    // Хранит weak ссылку на currentSection через замыкание — без generic
    private lazy var listDataSource: ContentListDataSource = {
        ContentListDataSource(
            sectionProvider: { [weak self] in self?.currentSection },
            sectionController: sectionController
        )
    }()

    // MARK: - Focus + Preview

    private let videoPreviewPresenter = VideoPreviewPresenter()

    private lazy var movieFocusCoordinator = MovieFocusCoordinator(
        backdropImageView: backdropImageView,
        backdropBlur: backdropBlur,
        videoPreviewPresenter: videoPreviewPresenter
    )

    // MARK: - State

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
        viewModel.load(url: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        movieFocusCoordinator.updatePreviewFrameIfNeeded()
    }

    // MARK: - ContentLoadable

    func load(url: URL?) {
        currentSection = nil
        movieFocusCoordinator.handleFocusLost()
        viewModel.load(url: url)
    }

    func loadNextPageIfNeeded(prefetchIndex: Int) {
        viewModel.loadNextPageIfNeeded(prefetchIndex: prefetchIndex)
    }

    // MARK: - Layout

    private func setupLayout() {
        view.insertSubview(backdropImageView, at: 0)
        view.insertSubview(backdropBlur, at: 1)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            backdropImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backdropImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backdropBlur.topAnchor.constraint(equalTo: view.topAnchor),
            backdropBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        videoPreviewPresenter.attach(to: view)
    }

    // MARK: - IGListKit Setup

    private func setupAdapter() {
        adapter.collectionView = collectionView
        adapter.dataSource     = listDataSource
    }

    private func setupSectionCallbacks() {
        sectionController.onSelectMovie = { [weak self] movie in
            self?.openDetail(for: movie)
        }
        sectionController.onPrefetch = { [weak self] index in
            self?.viewModel.loadNextPageIfNeeded(prefetchIndex: index)
        }
        sectionController.onFocusMovie = { [weak self] movie, cellSize in
            self?.movieFocusCoordinator.handleFocus(on: movie, cellSize: cellSize)
        }
        sectionController.onFocusLost = { [weak self] in
            self?.movieFocusCoordinator.handleFocusLost()
        }
    }

    // MARK: - Bindings
    //
    // Используем moviesPublisher / hasNextPagePublisher из протокола —
    // @Published не виден напрямую через generic тип VM

    private func bindViewModel() {
        Publishers.CombineLatest(
            viewModel.moviesPublisher,
            viewModel.hasNextPagePublisher
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] movies, hasNextPage in
            self?.applyMovies(movies, hasNextPage: hasNextPage)
        }
        .store(in: &cancellables)
    }

    // MARK: - Apply Data

    private func applyMovies(_ movies: [Movie], hasNextPage: Bool) {
        let isFirstLoad = currentSection == nil || currentSection?.movies.isEmpty == true
        currentSection = MoviesSection(movies: movies, hasNextPage: hasNextPage)

        adapter.performUpdates(animated: true) { [weak self] _ in
            guard let self, isFirstLoad, !movies.isEmpty else { return }
            self.focusFirstCell(movies: movies)
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

            self.movieFocusCoordinator.handleFocus(on: movies[0], cellSize: cell.bounds.size)
        }
    }

    // MARK: - Navigation

    private func openDetail(for movie: Movie) {
        movieFocusCoordinator.hidePreview()
        // TODO: передать через координатор
    }
}

// MARK: - ContentListDataSource
//
// Отдельный NSObject — держит @objc реализацию ListAdapterDataSource.
// Это обход ограничения Swift: generic классы не могут иметь @objc members в extension.

private final class ContentListDataSource: NSObject, ListAdapterDataSource {

    private let sectionProvider:   () -> MoviesSection?
    private let sectionController: MoviesSectionController

    init(sectionProvider: @escaping () -> MoviesSection?,
         sectionController: MoviesSectionController) {
        self.sectionProvider   = sectionProvider
        self.sectionController = sectionController
    }

    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        guard let s = sectionProvider(), !s.movies.isEmpty else { return [] }
        return [s]
    }

    func listAdapter(_ listAdapter: ListAdapter,
                     sectionControllerFor object: Any) -> ListSectionController {
        sectionController
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? { nil }
}
