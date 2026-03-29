import UIKit
import IGListKit
import Combine

// MARK: - LocalListController

/// Один контроллер для Избранного и Истории.
/// Режим определяется через LocalListViewModel.mode.
final class LocalListController: UIViewController {

    // MARK: - Callbacks → Coordinator

    var onSelectMovie: ((Movie) -> Void)?
    var onFocusMovie:  ((Movie) -> Void)?
    var onFocusLost:   (() -> Void)?

    // MARK: - ViewModel

    private let viewModel: LocalListViewModel

    init(viewModel: LocalListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.contentInsetAdjustmentBehavior = .never
        cv.remembersLastFocusedIndexPath  = true
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private var emptyLabel: UILabel?

    // MARK: - IGListKit

    private lazy var adapter: ListAdapter = {
        ListAdapter(updater: ListAdapterUpdater(), viewController: self)
    }()

    private let sectionController = MoviesSectionController()
    private var currentSection:    MoviesSection?

    // MARK: - Focus

    private var preferredFocusCell: UICollectionViewCell?

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if let cell = preferredFocusCell { return [cell] }
        return super.preferredFocusEnvironments
    }

    // MARK: - State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupAdapter()
        setupSectionCallbacks()
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Локальные данные могли измениться пока был открыт другой экран
        viewModel.load()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - IGListKit

    private func setupAdapter() {
        adapter.collectionView = collectionView
        adapter.dataSource     = self
    }

    private func setupSectionCallbacks() {
        sectionController.onSelectMovie = { [weak self] movie in self?.onSelectMovie?(movie) }
        sectionController.onPrefetch    = { _ in } // нет пагинации
        sectionController.onFocusMovie  = { [weak self] movie, _ in self?.onFocusMovie?(movie) }
        sectionController.onFocusLost   = { [weak self] in self?.onFocusLost?() }
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

    // MARK: - Apply data

    private func applyMovies(_ movies: [Movie]) {
        // Локальные списки — hasNextPage всегда false
        currentSection = MoviesSection(movies: movies, hasNextPage: false)
        adapter.performUpdates(animated: true) { [weak self] _ in
            guard !movies.isEmpty else { return }
            self?.focusFirstCell(movies: movies)
        }
    }

    private func focusFirstCell(movies: [Movie]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            let ip = IndexPath(item: 0, section: 0)
            guard let cell = collectionView.cellForItem(at: ip) else { return }
            preferredFocusCell = cell
            setNeedsFocusUpdate()
            updateFocusIfNeeded()
            preferredFocusCell = nil
            onFocusMovie?(movies[0])
        }
    }

    // MARK: - State handling

    private func handleState(_ state: LoadingState) {
        switch state {
        case .idle, .loading:
            hideEmptyState()
        case .loaded:
            viewModel.isEmpty ? showEmptyState(viewModel.emptyMessage) : hideEmptyState()
        case .error:
            break
        }
    }

    private func showEmptyState(_ message: String) {
        if emptyLabel == nil {
            let label = UILabel()
            label.textColor     = UIColor(white: 0.6, alpha: 1)
            label.font          = .systemFont(ofSize: 28, weight: .medium)
            label.numberOfLines = 0
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                label.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.6),
            ])
            emptyLabel = label
        }
        emptyLabel?.text = message
    }

    private func hideEmptyState() {
        emptyLabel?.removeFromSuperview()
        emptyLabel = nil
    }
}

// MARK: - ListAdapterDataSource

extension LocalListController: ListAdapterDataSource {

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
