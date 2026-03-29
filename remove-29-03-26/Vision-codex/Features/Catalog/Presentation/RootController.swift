import UIKit
import AsyncDisplayKit

protocol RootRouting: AnyObject {
    func showSettings(from presenter: UIViewController)
    func showSearch(from presenter: UIViewController)
    func showDetail(from presenter: UIViewController, movie: Movie, onDismiss: (() -> Void)?)
}

final class RootController: UIViewController {
    private let viewModel: RootViewModel
    private weak var router: RootRouting?
    private var state = RootViewState.initial
    private var currentFocusedMovieId: Int? = nil
    private var tabBarHeightConstraint: NSLayoutConstraint!

    private lazy var backdropImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.alpha = 0
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var backdropBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let vignetteLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.type = .radial
        l.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.70).cgColor]
        l.startPoint = CGPoint(x: 0.5, y: 0.5)
        l.endPoint = CGPoint(x: 1.0, y: 1.0)
        return l
    }()

    private let baseGradientLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.colors = [
            UIColor(red: 0.07, green: 0.07, blue: 0.11, alpha: 1).cgColor,
            UIColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 1).cgColor,
        ]
        return l
    }()

    private lazy var categoryTabBar: CategoryTabBar = {
        let bar = CategoryTabBar()
        bar.delegate = self
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeFlowLayout())
        cv.backgroundColor = .clear
        cv.contentInsetAdjustmentBehavior = .never
        cv.remembersLastFocusedIndexPath = true
        cv.register(MovieCell.self, forCellWithReuseIdentifier: MovieCell.reuseID)
        cv.register(
            LoadingFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: LoadingFooterView.reuseID
        )
        cv.dataSource = self
        cv.delegate = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private lazy var emptyLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        l.textColor = UIColor(white: 0.4, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 2
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.color = .white
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var errorLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        l.textColor = UIColor(white: 0.6, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 3
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var retryButton: DetailButton = {
        let b = DetailButton(title: "↻  Retry", style: .secondary)
        b.isHidden = true
        b.addTarget(self, action: #selector(retryTapped), for: .primaryActionTriggered)
        return b
    }()

    private let videoPreviewPresenter = VideoPreviewPresenter()

    init(
        viewModel: RootViewModel = AppDIContainer.shared.makeRootViewModel(),
        router: RootRouting? = nil
    ) {
        self.viewModel = viewModel
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        additionalSafeAreaInsets = .zero

        view.layer.insertSublayer(baseGradientLayer, at: 0)
        view.addSubview(backdropImageView)
        view.layer.addSublayer(vignetteLayer)
        view.addSubview(backdropBlur)
        view.addSubview(categoryTabBar)
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)
        view.addSubview(loadingIndicator)
        view.addSubview(errorLabel)
        view.addSubview(retryButton)

        videoPreviewPresenter.attach(to: view)

        NSLayoutConstraint.activate([
            backdropImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backdropImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backdropBlur.topAnchor.constraint(equalTo: view.topAnchor),
            backdropBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            categoryTabBar.topAnchor.constraint(equalTo: view.topAnchor),
            categoryTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            {
                let c = categoryTabBar.heightAnchor.constraint(equalToConstant: CategoryTabBar.collapsedHeight)
                tabBarHeightConstraint = c
                return c
            }(),

            collectionView.topAnchor.constraint(equalTo: categoryTabBar.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.55),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            errorLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),

            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 24),
        ])

        bindViewModel()
        viewModel.loadInitial()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        baseGradientLayer.frame = view.bounds
        vignetteLayer.frame = view.bounds
    }

    private func bindViewModel() {
        viewModel.onStateDidChange = { [weak self] newState in
            self?.apply(newState)
        }
    }

    private func apply(_ newState: RootViewState) {
        let oldMoviesWereEmpty = state.movies.isEmpty
        state = newState

        collectionView.reloadData()

        if state.isFetchingInitial {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }

        if let error = state.errorMessage {
            errorLabel.text = error
            errorLabel.isHidden = false
            retryButton.isHidden = false
        } else {
            errorLabel.isHidden = true
            retryButton.isHidden = true
        }

        let shouldShowEmpty = state.hasLoadedFirstPage
            && state.errorMessage == nil
            && state.movies.isEmpty
            && state.emptyMessage != nil

        emptyLabel.text = state.emptyMessage
        emptyLabel.isHidden = !shouldShowEmpty

        if oldMoviesWereEmpty && !state.movies.isEmpty {
            focusFirstCell()
        }

        if state.movies.isEmpty {
            currentFocusedMovieId = nil
            videoPreviewPresenter.hide()
        }
    }

    @objc private func retryTapped() {
        viewModel.retry()
    }

    private func makeFlowLayout() -> UICollectionViewFlowLayout {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .vertical
        l.minimumInteritemSpacing = 28
        l.minimumLineSpacing = 44
        l.sectionInset = UIEdgeInsets(top: 30, left: 80, bottom: 80, right: 80)
        l.footerReferenceSize = CGSize(width: 0, height: 80)
        return l
    }

    private func cellSize() -> CGSize {
        let width = view.bounds.width
        let horizontalPadding = 80.0 * 2
        let spacing = 28.0 * 4
        let w = floor((width - horizontalPadding - spacing) / 5)
        let h = floor(w * 313 / 220)
        return CGSize(width: w, height: h)
    }

    private var preferredFocusCell: UICollectionViewCell? = nil

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if let cell = preferredFocusCell { return [cell] }
        return super.preferredFocusEnvironments
    }

    private func focusFirstCell() {
        guard !state.movies.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            let ip = IndexPath(item: 0, section: 0)
            guard let cell = self.collectionView.cellForItem(at: ip) else { return }
            self.preferredFocusCell = cell
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
            self.preferredFocusCell = nil

            let movie = self.state.movies[0]
            self.currentFocusedMovieId = movie.id
            self.videoPreviewPresenter.show(for: movie, cellSize: self.cellSize())
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        if let cell = context.nextFocusedItem as? MovieCell,
           let ip = collectionView.indexPath(for: cell) {
            let movie = state.movies[ip.item]
            guard movie.id != currentFocusedMovieId else { return }
            currentFocusedMovieId = movie.id
            videoPreviewPresenter.show(for: movie, cellSize: cellSize())
        } else if !(context.nextFocusedItem is MovieCell) {
            currentFocusedMovieId = nil
            videoPreviewPresenter.hide()
        }
    }
}

// MARK: - CategoryTabBarDelegate

extension RootController: CategoryTabBarDelegate {

    func categoryTabBarDidSelectSettings(_ bar: CategoryTabBar) {
        videoPreviewPresenter.hide()
        router?.showSettings(from: self)
    }

    func categoryTabBar(_ bar: CategoryTabBar, didSelect category: FilmixCategory) {
        updateTabBarHeight(hasGenres: !category.genres.isEmpty)

        currentFocusedMovieId = nil
        videoPreviewPresenter.hide()

        if category.isWatchHistory {
            viewModel.switchSource(.watchHistory)
        } else if category.isFavorites {
            viewModel.switchSource(.favorites)
        } else {
            viewModel.switchSource(.category(url: category.url))
        }
    }

    func categoryTabBar(_ bar: CategoryTabBar, didSelectGenre genre: FilmixGenre, in category: FilmixCategory) {
        currentFocusedMovieId = nil
        videoPreviewPresenter.hide()
        viewModel.switchSource(.category(url: genre.url))
    }

    func categoryTabBarDidSelectSearch(_ bar: CategoryTabBar) {
        videoPreviewPresenter.hide()
        router?.showSearch(from: self)
    }

    private func updateTabBarHeight(hasGenres: Bool) {
        let target = hasGenres ? CategoryTabBar.expandedHeight : CategoryTabBar.collapsedHeight
        guard tabBarHeightConstraint.constant != target else { return }
        tabBarHeightConstraint.constant = target
        UIView.animate(withDuration: 0.28, delay: 0,
                       usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UICollectionViewDataSource

extension RootController: UICollectionViewDataSource {

    func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int {
        state.movies.count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: MovieCell.reuseID, for: ip) as! MovieCell
        cell.configure(with: state.movies[ip.item])
        return cell
    }

    func collectionView(
        _ cv: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at ip: IndexPath
    ) -> UICollectionReusableView {
        let footer = cv.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: LoadingFooterView.reuseID,
            for: ip
        ) as! LoadingFooterView
        footer.setAnimating(state.isFetchingNext && state.nextPageURL != nil)
        return footer
    }
}

// MARK: - UICollectionViewDelegate

extension RootController: UICollectionViewDelegate {

    func collectionView(_ cv: UICollectionView, didSelectItemAt ip: IndexPath) {
        videoPreviewPresenter.hide()
        router?.showDetail(
            from: self,
            movie: state.movies[ip.item],
            onDismiss: { [weak self] in
                self?.viewModel.refreshIfLocalSource()
            }
        )
    }

    func collectionView(_ cv: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt ip: IndexPath) {
        let threshold = max(0, state.movies.count - 10)
        if ip.item >= threshold {
            viewModel.loadNextPageIfNeeded()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension RootController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt ip: IndexPath) -> CGSize {
        cellSize()
    }

    func collectionView(
        _ cv: UICollectionView,
        layout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        guard case .category = state.source else { return .zero }
        return state.nextPageURL != nil ? CGSize(width: cv.bounds.width, height: 80) : .zero
    }
}
