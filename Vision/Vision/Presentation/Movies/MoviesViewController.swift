import UIKit
import AsyncDisplayKit
import Filmix

final class MoviesViewController: ASDKViewController<ASCollectionNode> {

    var viewModel: MoviesViewModel? {
        didSet { startIfNeeded() }
    }

    private var didStart = false
    private var preferredIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    private var movies: [Movie] = []
    
    private let videoPreviewPresenter = VideoPreviewPresenter()

    private let loadingIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.color = .white
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let errorLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        l.textColor = UIColor(white: 0.6, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 2
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private var collectionNode: ASCollectionNode {
        node
    }

    override init() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = Self.cellSize
        layout.minimumInteritemSpacing = 28
        layout.minimumLineSpacing = 44
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 30, left: 80, bottom: 80, right: 80)

        super.init(node: ASCollectionNode(collectionViewLayout: layout))

        collectionNode.backgroundColor = .black
        collectionNode.delegate = self
        collectionNode.dataSource = self
        collectionNode.view.remembersLastFocusedIndexPath = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        view.addSubview(loadingIndicator)
        view.addSubview(errorLabel)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6)
        ])

        startIfNeeded()
        videoPreviewPresenter.attach(to: view)
    }

    private func startIfNeeded() {
        guard isViewLoaded, !didStart, let viewModel else { return }
        didStart = true
        bindViewModel(viewModel)
        viewModel.onViewDidLoad()
    }

    private func bindViewModel(_ viewModel: MoviesViewModel) {
        viewModel.onLoadingChanged = { [weak self] isLoading in
            guard let self else { return }
            if isLoading {
                self.errorLabel.isHidden = true
                self.loadingIndicator.startAnimating()
            } else {
                self.loadingIndicator.stopAnimating()
            }
        }
        viewModel.onMoviesChanged = { [weak self] movies in
            guard let self else { return }
            self.movies = movies
            self.collectionNode.reloadData()
        }
        viewModel.onMoviesAppended = { [weak self] movies in
            guard let self else { return }
            guard !movies.isEmpty else { return }
            let startIndex = self.movies.count
            self.movies.append(contentsOf: movies)
            let indexPaths = (startIndex ..< self.movies.count).map { IndexPath(item: $0, section: 0) }
            self.collectionNode.performBatchUpdates({
                self.collectionNode.insertItems(at: indexPaths)
            }, completion: nil)
        }
        viewModel.onError = { [weak self] message in
            guard let self else { return }
            self.errorLabel.text = message
            self.errorLabel.isHidden = false
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewPresenter.updateFrameIfNeeded()
    }
}

// MARK: - ASCollectionDataSource, ASCollectionDelegate

extension MoviesViewController: ASCollectionDataSource, ASCollectionDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        movies.count
    }

    func collectionView(_ collectionView: ASCollectionView, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        MovieCellNode(movie: movies[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        videoPreviewPresenter.hide()
        viewModel?.didSelectItem(at: indexPath.item)
    }

    func collectionView(
        _ collectionView: ASCollectionView,
        willDisplay cell: ASCellNode,
        forItemAt indexPath: IndexPath
    ) {
        viewModel?.loadNextPageIfNeeded(currentIndex: indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        true
    }

    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        preferredIndexPath
    }

    func collectionView(
        _ collectionView: UICollectionView,
        shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext
    ) -> Bool {
        true
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didUpdateFocusIn context: UICollectionViewFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {
        if let next = context.nextFocusedIndexPath {
            preferredIndexPath = next
            videoPreviewPresenter.show(for: movies[next.item], cellSize: Self.cellSize)
        } else {
            videoPreviewPresenter.hide()
        }
    }
    
    private static var cellSize: CGSize {
        let available = UIScreen.main.bounds.width - 160
        let spacing   = 28.0 * 4
        let w = floor((available - spacing) / 5)
        let h = floor(w * 313 / 220)

        return CGSize(width: w, height: h)
    }
}

// MARK: - MovieCellNode

extension Movie {
    var accentColor: UIColor {
        let palette: [UIColor] = [
            UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1),
            UIColor(red: 0.10, green: 0.28, blue: 0.55, alpha: 1),
            UIColor(red: 0.35, green: 0.12, blue: 0.45, alpha: 1),
            UIColor(red: 0.08, green: 0.35, blue: 0.28, alpha: 1),
            UIColor(red: 0.50, green: 0.10, blue: 0.10, alpha: 1)
        ]

        return palette[abs(id) % palette.count]
    }
}
