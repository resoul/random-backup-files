import UIKit
import IGListKit
import Filmix

// MARK: - MoviesSection (diffable object)

final class MoviesSection: NSObject, ListDiffable {

    let movies: [Movie]
    let hasNextPage: Bool

    init(movies: [Movie], hasNextPage: Bool) {
        self.movies      = movies
        self.hasNextPage = hasNextPage
    }

    func diffIdentifier() -> NSObjectProtocol {
        "movies-section" as NSObjectProtocol
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let other = object as? MoviesSection else { return false }
        // Сравниваем только границы — IGListKit не делает reload если true.
        // Реальный диффинг при пагинации делает MoviesSectionController.didUpdate через performBatch.
        return movies.count    == other.movies.count
            && hasNextPage     == other.hasNextPage
            && movies.first?.id == other.movies.first?.id
            && movies.last?.id  == other.movies.last?.id
    }
}

// MARK: - MoviesSectionController

final class MoviesSectionController: ListSectionController {

    // MARK: - Callbacks

    var onSelectMovie: ((Movie) -> Void)?
    var onPrefetch:    ((Int) -> Void)?
    var onFocusMovie:  ((Movie, CGSize) -> Void)?
    var onFocusLost:   (() -> Void)?

    // MARK: - Private

    private var moviesSection = MoviesSection(movies: [], hasNextPage: false)
    private var cachedCellSize: CGSize = .zero

    // MARK: - Init

    override init() {
        super.init()
        displayDelegate = self
        inset = UIEdgeInsets(top: 30, left: 80, bottom: 80, right: 80)
        minimumInteritemSpacing = 28
        minimumLineSpacing      = 44
    }

    // MARK: - ListSectionController

    override func numberOfItems() -> Int {
        moviesSection.hasNextPage
            ? moviesSection.movies.count + 1
            : moviesSection.movies.count
    }

    override func sizeForItem(at index: Int) -> CGSize {
        if moviesSection.hasNextPage && index == moviesSection.movies.count {
            return CGSize(width: containerSize.width - 160, height: 80)
        }
        return cellSize()
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let ctx = collectionContext else { fatalError() }

        if moviesSection.hasNextPage && index == moviesSection.movies.count {
            let cell = ctx.dequeueReusableCell(
                of: LoadingFooterCell.self,
                for: self, at: index
            ) as! LoadingFooterCell
            cell.setAnimating(true)
            return cell
        }

        let cell = ctx.dequeueReusableCell(
            of: MovieCell.self,
            for: self, at: index
        ) as! MovieCell
        cell.configure(with: moviesSection.movies[index])
        cell.delegate = self
        return cell
    }

    override func didUpdate(to object: Any) {
        let new = object as! MoviesSection
        let old = moviesSection
        
        let oldMovieCount = old.movies.count
        let newMovieCount = new.movies.count
        
        let isPagination = newMovieCount > oldMovieCount
            && oldMovieCount > 0
            && new.movies.prefix(oldMovieCount).map(\.id) == old.movies.map(\.id)

        if isPagination {
            moviesSection = new
            collectionContext?.performBatch(animated: false, updates: { ctx in
                let newIndices = IndexSet(oldMovieCount..<newMovieCount)
                ctx.insert(in: self, at: newIndices)
                
                let oldHadFooter = old.hasNextPage
                let newHasFooter = new.hasNextPage
                
                switch (oldHadFooter, newHasFooter) {
                case (false, true):
                    ctx.insert(in: self, at: IndexSet(integer: newMovieCount))
                case (true, false):
                    ctx.delete(in: self, at: IndexSet(integer: oldMovieCount))
                case (true, true):
                    break
                case (false, false):
                    break
                }
            }, completion: nil)
        } else {
            // Смена категории / первая загрузка — полный reload
            moviesSection  = new
            cachedCellSize = .zero
        }
    }

    override func didSelectItem(at index: Int) {
        guard index < moviesSection.movies.count else { return }
        onSelectMovie?(moviesSection.movies[index])
    }

    // MARK: - Helpers

    private func cellSize() -> CGSize {
        if cachedCellSize != .zero { return cachedCellSize }
        let available = containerSize.width - 160
        let spacing   = 28.0 * 4
        let w = floor((available - spacing) / 5)
        let h = floor(w * 313 / 220)
        cachedCellSize = CGSize(width: w, height: h)
        return cachedCellSize
    }

    private var containerSize: CGSize {
        collectionContext?.containerSize ?? .zero
    }
}

// MARK: - MovieCellDelegate

extension MoviesSectionController: MovieCellDelegate {
    func movieCell(_ cell: MovieCell, didFocusMovie movie: Movie) {
        onFocusMovie?(movie, cellSize())
    }
    func movieCellDidLoseFocus(_ cell: MovieCell) {
        onFocusLost?()
    }
}

// MARK: - ListDisplayDelegate (prefetch / пагинация)

extension MoviesSectionController: ListDisplayDelegate {

    func listAdapter(_ listAdapter: ListAdapter,
                     willDisplay sectionController: ListSectionController) {}

    func listAdapter(_ listAdapter: ListAdapter,
                     didEndDisplaying sectionController: ListSectionController) {}

    func listAdapter(_ listAdapter: ListAdapter,
                     willDisplay sectionController: ListSectionController,
                     cell: UICollectionViewCell,
                     at index: Int) {
        onPrefetch?(index)
    }

    func listAdapter(_ listAdapter: ListAdapter,
                     didEndDisplaying sectionController: ListSectionController,
                     cell: UICollectionViewCell,
                     at index: Int) {}
}

// MARK: - LoadingFooterCell

final class LoadingFooterCell: UICollectionViewCell {

    private let spinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = UIColor(white: 0.5, alpha: 1)
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func setAnimating(_ animating: Bool) {
        animating ? spinner.startAnimating() : spinner.stopAnimating()
    }

    override var canBecomeFocused: Bool { false }
}
