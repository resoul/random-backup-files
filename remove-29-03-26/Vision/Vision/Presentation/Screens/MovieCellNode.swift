import UIKit
import AsyncDisplayKit
import Filmix

// MARK: - MovieCellNode
//
// Адаптирован из Vision/App/Movie/MovieCellNode.swift
// Изменения:
//   1. Movie.type — теперь ContentType (enum без associated values) вместо Movie.ContentType
//   2. PlaybackStore / WatchHistoryStore — временно убраны (TODO: подключить после реализации)
//   3. PlaceholderArt.generate — без изменений, работает с новой Movie

final class MovieCellNode: ASCellNode {

    // MARK: - Subnodes

    private let posterNode      = ASNetworkImageNode()
    private let topScrimNode    = ASDisplayNode()
    private let bottomScrimNode = ASDisplayNode()

    private let adsBadgeNode    = ASDisplayNode()
    private let adsTextNode     = ASTextNode()

    private let seriesBadgeNode = ASDisplayNode()
    private let seriesTextNode  = ASTextNode()

    // MARK: - State

    private let movie: Movie

    // MARK: - Init

    init(movie: Movie) {
        self.movie = movie
        super.init()
        automaticallyManagesSubnodes = true
        clipsToBounds = true
        cornerRadius  = 14
        cornerRoundingType = .defaultSlowCALayer

        setupPoster()
        setupScrims()
        setupBadges()
        applyMovieData()
    }

    // MARK: - Setup

    private func setupPoster() {
        posterNode.contentMode = .scaleAspectFill
        posterNode.clipsToBounds = true
        posterNode.defaultImage = PlaceholderArt.generate(
            for: movie,
            size: CGSize(width: 440, height: 626)
        )
        if !movie.posterURL.isEmpty {
            posterNode.url = URL(string: movie.posterURL)
        }
    }

    private func setupScrims() {
        topScrimNode.setViewBlock {
            let v = UIView()
            let gradient = CAGradientLayer()
            gradient.colors = [
                UIColor.black.withAlphaComponent(0.45).cgColor,
                UIColor.clear.cgColor,
                UIColor.clear.cgColor,
            ]
            gradient.locations = [0, 0.35, 1.0]
            v.layer.addSublayer(gradient)
            return v
        }

        bottomScrimNode.setViewBlock {
            let v = UIView()
            let gradient = CAGradientLayer()
            gradient.colors = [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.55).cgColor,
            ]
            gradient.locations = [0.5, 1.0]
            v.layer.addSublayer(gradient)
            return v
        }
    }

    private func setupBadges() {
        // ADS
        adsBadgeNode.backgroundColor = UIColor(red: 0.85, green: 0.20, blue: 0.20, alpha: 0.92)
        adsBadgeNode.cornerRadius = 6
        adsBadgeNode.cornerRoundingType = .defaultSlowCALayer
        adsTextNode.attributedText = NSAttributedString(
            string: "ADS",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .heavy),
                .foregroundColor: UIColor.white
            ]
        )

        // SERIES
        seriesBadgeNode.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.88)
        seriesBadgeNode.cornerRadius = 6
        seriesBadgeNode.cornerRoundingType = .defaultSlowCALayer
        seriesTextNode.attributedText = NSAttributedString(
            string: "SERIES",
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .bold),
                .foregroundColor: UIColor.white
            ]
        )
    }

    private func applyMovieData() {
        adsBadgeNode.isHidden    = !movie.isAdIn
        seriesBadgeNode.isHidden = !movie.isSeries

        // TODO: PlaybackStore / WatchHistoryStore — подключить после реализации сервисов
        // if !movie.isSeries {
        //     if let progress = PlaybackStore.shared.movieProgress(movieId: movie.id), progress.hasProgress {
        //         progressFraction = progress.fraction
        //         progressTrack.isHidden = false
        //     }
        // } else {
        //     let inProgress = WatchHistoryStore.shared.isSeriesInProgress(movieId: movie.id)
        //     inProgressNode.isHidden = !inProgress
        // }
    }

    // MARK: - Layout

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let size = constrainedSize.max

        posterNode.style.preferredSize      = size
        topScrimNode.style.preferredSize    = size
        bottomScrimNode.style.preferredSize = size

        // ADS badge — top right
        let adsInner = ASStackLayoutSpec(
            direction: .horizontal, spacing: 0,
            justifyContent: .start, alignItems: .center,
            children: [adsTextNode]
        )
        let adsPadded = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6),
            child: adsInner
        )
        let adsBadge = ASBackgroundLayoutSpec(child: adsPadded, background: adsBadgeNode)
        adsBadge.style.layoutPosition = CGPoint(x: size.width - 70, y: 10)

        // SERIES badge — bottom right
        let seriesInner = ASStackLayoutSpec(
            direction: .horizontal, spacing: 0,
            justifyContent: .start, alignItems: .center,
            children: [seriesTextNode]
        )
        let seriesPadded = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 4, left: 7, bottom: 4, right: 7),
            child: seriesInner
        )
        let seriesBadge = ASBackgroundLayoutSpec(child: seriesPadded, background: seriesBadgeNode)
        seriesBadge.style.layoutPosition = CGPoint(x: size.width - 90, y: size.height - 32)

        let absolute = ASAbsoluteLayoutSpec(sizing: .sizeToFit, children: [
            posterNode,
            topScrimNode,
            bottomScrimNode,
            adsBadge,
            seriesBadge,
        ])

        return absolute
    }
}

// MARK: - MovieCellDelegate

protocol MovieCellDelegate: AnyObject {
    func movieCell(_ cell: MovieCell, didFocusMovie movie: Movie)
    func movieCellDidLoseFocus(_ cell: MovieCell)
}

// MARK: - MovieCell
//
// UICollectionViewCell — держит tvOS focus engine, press handling, shadow.
// Вся отрисовка делегируется MovieCellNode (ASDK, фоновый поток).

final class MovieCell: UICollectionViewCell {

    static let reuseID = "MovieCell"

    weak var delegate: MovieCellDelegate?
    private(set) var movie: Movie?

    private var cellNode: MovieCellNode?

    private let focusBorderView: UIView = {
        let v = UIView()
        v.backgroundColor    = .clear
        v.layer.cornerRadius = 14
        v.layer.cornerCurve  = .continuous
        v.layer.borderWidth  = 3.5
        v.layer.borderColor  = UIColor.white.cgColor
        v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = false
        contentView.layer.cornerRadius = 14

        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.45
        layer.shadowRadius  = 14
        layer.shadowOffset  = CGSize(width: 0, height: 10)

        contentView.addSubview(focusBorderView)
        NSLayoutConstraint.activate([
            focusBorderView.topAnchor.constraint(equalTo: contentView.topAnchor),
            focusBorderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            focusBorderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            focusBorderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with movie: Movie) {
        self.movie = movie
        cellNode?.view.removeFromSuperview()

        let node = MovieCellNode(movie: movie)
        cellNode = node

        let nodeView = node.view
        nodeView.frame = contentView.bounds
        nodeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        nodeView.isUserInteractionEnabled = false
        contentView.insertSubview(nodeView, belowSubview: focusBorderView)
        node.layoutThatFits(ASSizeRange(min: bounds.size, max: bounds.size))
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        movie = nil
        cellNode?.view.removeFromSuperview()
        cellNode = nil
    }

    // MARK: - tvOS Focus

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.transform           = CGAffineTransform(scaleX: 1.09, y: 1.09)
                self.layer.shadowOpacity = 0.9
                self.layer.shadowRadius  = 32
                self.layer.shadowOffset  = CGSize(width: 0, height: 22)
                self.focusBorderView.alpha = 1
            } else {
                self.transform           = .identity
                self.layer.shadowOpacity = 0.45
                self.layer.shadowRadius  = 14
                self.layer.shadowOffset  = CGSize(width: 0, height: 10)
                self.focusBorderView.alpha = 0
            }
        }, completion: nil)

        if isFocused, let movie {
            delegate?.movieCell(self, didFocusMovie: movie)
        } else if !isFocused {
            delegate?.movieCellDidLoseFocus(self)
        }
    }

    // MARK: - Press handling

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesBegan(presses, with: event); return
        }
        UIView.animate(withDuration: 0.07) {
            self.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesEnded(presses, with: event); return
        }
        UIView.animate(withDuration: 0.10) {
            self.transform = self.isFocused
                ? CGAffineTransform(scaleX: 1.09, y: 1.09) : .identity
        }
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) {
            self.transform = self.isFocused
                ? CGAffineTransform(scaleX: 1.09, y: 1.09) : .identity
        }
        super.pressesCancelled(presses, with: event)
    }
}
