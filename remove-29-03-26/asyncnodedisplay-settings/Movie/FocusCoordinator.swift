import UIKit

// MARK: - FocusCoordinatorDelegate

protocol FocusCoordinatorDelegate: AnyObject {
    func focusCoordinator(_ coordinator: FocusCoordinator, didFocusMovie movie: Movie)
    func focusCoordinatorDidLoseFocus(_ coordinator: FocusCoordinator)
}

// MARK: - FocusCoordinator

/// Отвечает за:
/// - backdrop (постер на фоне) с дебаунсом 120ms — не мигает при быстром скролле
/// - VideoPreviewPresenter
/// - дедупликацию: не перерисовывает если тот же фильм
final class FocusCoordinator {

    // MARK: - Dependencies

    weak var delegate: FocusCoordinatorDelegate?

    private let backdropImageView: UIImageView
    private let backdropBlur:      UIVisualEffectView
    private let videoPreviewPresenter: VideoPreviewPresenter

    // MARK: - State

    private var currentMovieId:   Int?
    private var backdropWorkItem: DispatchWorkItem?

    // MARK: - Init

    init(backdropImageView: UIImageView,
         backdropBlur:      UIVisualEffectView,
         videoPreviewPresenter: VideoPreviewPresenter) {
        self.backdropImageView     = backdropImageView
        self.backdropBlur          = backdropBlur
        self.videoPreviewPresenter = videoPreviewPresenter
    }

    // MARK: - Public API

    func handleFocus(on movie: Movie, cellSize: CGSize) {
        guard movie.id != currentMovieId else { return }
        currentMovieId = movie.id

        videoPreviewPresenter.show(for: movie, cellSize: cellSize)
        delegate?.focusCoordinator(self, didFocusMovie: movie)

        // Backdrop обновляем с задержкой — не перерисовывается при быстром пролистывании
        scheduleBackdrop(for: movie)
    }

    func handleFocusLost() {
        guard currentMovieId != nil else { return }
        currentMovieId = nil
        backdropWorkItem?.cancel()
        backdropWorkItem = nil
        videoPreviewPresenter.hide()
        delegate?.focusCoordinatorDidLoseFocus(self)
    }

    /// Показывает backdrop сразу без дебаунса — для первого фильма при загрузке
    func showInitialBackdrop(for movie: Movie) {
        currentMovieId = movie.id
        updateBackdrop(for: movie)
    }

    func hidePreview() {
        videoPreviewPresenter.hide()
    }

    // MARK: - Private

    private func scheduleBackdrop(for movie: Movie) {
        backdropWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self, self.currentMovieId == movie.id else { return }
            self.updateBackdrop(for: movie)
        }
        backdropWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: item)
    }

    private func updateBackdrop(for movie: Movie) {
        guard !movie.posterURL.isEmpty else { return }

        PosterCache.shared.image(for: movie.posterURL, placeholder: nil) { [weak self] image in
            guard let self, self.currentMovieId == movie.id else { return }

            // Один плавный переход — без промежуточного placeholder
            UIView.transition(
                with: self.backdropImageView,
                duration: 0.4,
                options: [.transitionCrossDissolve, .allowUserInteraction]
            ) {
                self.backdropImageView.image = image
            }

            // Fade in при первом появлении
            guard self.backdropImageView.alpha == 0 else { return }
            UIView.animate(withDuration: 0.3) {
                self.backdropImageView.alpha = 0.6
                self.backdropBlur.alpha      = 0.94
            }
        }
    }
}
