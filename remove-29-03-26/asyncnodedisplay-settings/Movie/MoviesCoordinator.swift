import UIKit

// MARK: - MoviesCoordinator

/// Создаёт MoviesViewModel + MoviesController.
/// Единственное место где знает об обоих — связывает их.
final class MoviesCoordinator: Coordinator {

    // MARK: - Coordinator

    let rootViewController: UIViewController

    // MARK: - Callbacks → TabCoordinator

    var onSelectMovie: ((Movie) -> Void)?

    // MARK: - Dependencies

    private let viewModel   = MoviesViewModel()
    private let controller: MoviesController
    private weak var focusDelegate: FocusEventDelegate?

    // MARK: - Init

    init(focusDelegate: FocusEventDelegate) {
        self.focusDelegate = focusDelegate
        self.controller    = MoviesController(viewModel: viewModel)
        self.rootViewController = controller
    }

    // MARK: - Start

    func start() {
        controller.onSelectMovie = { [weak self] movie in self?.onSelectMovie?(movie) }
        controller.onFocusMovie  = { [weak self] movie in self?.focusDelegate?.didFocusMovie(movie) }
        controller.onFocusLost   = { [weak self] in self?.focusDelegate?.didLoseFocus() }
    }

    // MARK: - Public API

    func show(url: String?) {
        viewModel.load(url: url)
    }
}
