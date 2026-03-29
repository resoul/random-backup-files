import UIKit

// MARK: - LocalListCoordinator

final class LocalListCoordinator: Coordinator {

    // MARK: - Coordinator

    let rootViewController: UIViewController

    // MARK: - Callbacks → TabCoordinator

    var onSelectMovie: ((Movie) -> Void)?

    // MARK: - Dependencies

    private let viewModel:  LocalListViewModel
    private let controller: LocalListController
    private weak var focusDelegate: FocusEventDelegate?

    // MARK: - Init

    init(mode: LocalListMode, focusDelegate: FocusEventDelegate) {
        self.focusDelegate = focusDelegate
        self.viewModel     = LocalListViewModel(mode: mode)
        self.controller    = LocalListController(viewModel: viewModel)
        self.rootViewController = controller
    }

    // MARK: - Start

    func start() {
        controller.onSelectMovie = { [weak self] movie in self?.onSelectMovie?(movie) }
        controller.onFocusMovie  = { [weak self] movie in self?.focusDelegate?.didFocusMovie(movie) }
        controller.onFocusLost   = { [weak self] in self?.focusDelegate?.didLoseFocus() }
    }

    // MARK: - Public API

    /// Вызывать после закрытия детального экрана — обновляет список
    func reload() {
        viewModel.load()
    }
}
