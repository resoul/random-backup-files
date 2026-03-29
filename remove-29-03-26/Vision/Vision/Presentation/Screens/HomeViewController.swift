import UIKit
import IGListKit
import Combine
import Filmix

// MARK: - HomeViewController
//
// Заменяет Vision/App/Movie/RootController.swift
// Встраивается в существующую архитектуру через BaseScreenViewController<HomeViewModel>.
//
// Структура:
//   HomeViewController
//     ├── backdropImageView + backdropBlur   (фоновый постер)
//     ├── collectionView (IGListKit)
//     │     └── MoviesSectionController → MovieCell → MovieCellNode (ASDK)
//     └── MovieFocusCoordinator              (backdrop + video preview)

final class HomeViewController: BaseScreenViewController<HomeViewModel> {

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

    private lazy var adapter: ListAdapter = {
        ListAdapter(updater: ListAdapterUpdater(), viewController: self)
    }()

    private let sectionController = MoviesSectionController()

    // MARK: - Focus + Preview

    private let videoPreviewPresenter = VideoPreviewPresenter()

    private lazy var focusCoordinator = MovieFocusCoordinator(
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
        viewModel.load()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        focusCoordinator.updatePreviewFrameIfNeeded()
    }

    // MARK: - Layout

    private func setupLayout() {
        // Backdrop — самый нижний слой (под всеми subviews)
        view.insertSubview(backdropImageView, at: 0)
        view.insertSubview(backdropBlur,      at: 1)
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

        // VideoPreviewPresenter overlay — поверх всего
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
            // Пагинация — подключается когда HomeViewModel будет её поддерживать
            _ = index
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

    private func applyMovies(_ movies: [Movie]) {
        let isFirstLoad = currentSection == nil || currentSection?.movies.isEmpty == true
        currentSection = MoviesSection(movies: movies, hasNextPage: false)

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

            // Backdrop + preview для первого фильма
            self.focusCoordinator.handleFocus(on: movies[0], cellSize: cell.bounds.size)
        }
    }

    // MARK: - State Handling

    private func handleState(_ state: ViewState) {
        switch state {
        case .idle, .loading:
            break
        case .loaded:
            hideOverlayLabels()
        case .empty(let message):
            showOverlayLabel(message)
        case .error(let message):
            showError(message: message)
        }
    }

    // MARK: - Navigation

    private func openDetail(for movie: Movie) {
        focusCoordinator.hidePreview()
        // TODO: открыть MovieDetailViewController через координатор
        // coordinator?.openDetail(movie)
    }

    // MARK: - Empty / Error

    private var overlayLabel: UILabel?

    private func showOverlayLabel(_ text: String) {
        guard overlayLabel == nil else { overlayLabel?.text = text; return }
        let label = UILabel()
        label.text          = text
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
        overlayLabel = label
    }

    private func hideOverlayLabels() {
        overlayLabel?.removeFromSuperview()
        overlayLabel = nil
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            self?.viewModel.load()
        })
        present(alert, animated: true)
    }
}

// MARK: - ListAdapterDataSource

extension HomeViewController: ListAdapterDataSource {

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
