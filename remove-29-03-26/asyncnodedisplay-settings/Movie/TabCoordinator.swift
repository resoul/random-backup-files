import UIKit
import Combine

// MARK: - TabCoordinator

/// Главный координатор экрана.
/// Владеет: CategoryTabBar, backdrop, FocusCoordinator, VideoPreviewPresenter.
/// Создаёт дочерние координаторы и свитчит их при смене вкладки.
final class TabCoordinator: Coordinator {
    private let containerController: TabContainerController
    var rootViewController: UIViewController { containerController }

    init() {
        self.containerController = TabContainerController()
    }

    // MARK: - Child coordinators

    private var moviesCoordinator:    MoviesCoordinator?
    private var favoritesCoordinator: LocalListCoordinator?
    private var historyCoordinator:   LocalListCoordinator?
    private var searchCoordinator:    SearchCoordinator?

    private var activeCoordinator: Coordinator?

    // MARK: - Start

    func start() {
        containerController.onCategorySelected  = { [weak self] category in self?.handle(category: category) }
        containerController.onGenreSelected     = { [weak self] genre, category in self?.handle(genre: genre, in: category) }
        containerController.onSearchSubmitted   = { [weak self] query in self?.handleSearch(query: query) }
        containerController.onSettingsSelected  = { [weak self] in self?.openSettings() }

        // Запускаем первую категорию
        if let first = FilmixCategory.all.first(where: { !$0.isSearch && !$0.isFavorites && !$0.isWatchHistory }) {
            handle(category: first)
        }
    }

    // MARK: - Category routing

    private func handle(category: FilmixCategory, genre: FilmixGenre? = nil) {
        if category.isSearch {
            switchToSearch()
        } else if category.isFavorites {
            switchToFavorites()
        } else if category.isWatchHistory {
            switchToHistory()
        } else {
            let url = genre?.url ?? category.url
            switchToMovies(url: url)
        }
    }

    private func handle(genre: FilmixGenre, in category: FilmixCategory) {
        switchToMovies(url: genre.url)
    }

    private func handleSearch(query: String) {
        switchToSearch(query: query)
    }

    // MARK: - Switch to Movies

    private func switchToMovies(url: String?) {
        if moviesCoordinator == nil {
            let coordinator = MoviesCoordinator(
                focusDelegate: containerController
            )
            coordinator.onSelectMovie = { [weak self] movie in
                self?.openDetail(for: movie)
            }
            coordinator.start()
            moviesCoordinator = coordinator
        }
        moviesCoordinator?.show(url: url)
        switchActive(to: moviesCoordinator!)
    }

    // MARK: - Switch to Favorites

    private func switchToFavorites() {
        if favoritesCoordinator == nil {
            let coordinator = LocalListCoordinator(
                mode: .favorites,
                focusDelegate: containerController
            )
            coordinator.onSelectMovie = { [weak self] movie in
                self?.openDetail(for: movie)
            }
            coordinator.start()
            favoritesCoordinator = coordinator
        }
        favoritesCoordinator?.reload()
        switchActive(to: favoritesCoordinator!)
    }

    // MARK: - Switch to History

    private func switchToHistory() {
        if historyCoordinator == nil {
            let coordinator = LocalListCoordinator(
                mode: .watchHistory,
                focusDelegate: containerController
            )
            coordinator.onSelectMovie = { [weak self] movie in
                self?.openDetail(for: movie)
            }
            coordinator.start()
            historyCoordinator = coordinator
        }
        historyCoordinator?.reload()
        switchActive(to: historyCoordinator!)
    }

    // MARK: - Switch to Search

    private func switchToSearch(query: String? = nil) {
        if searchCoordinator == nil {
            let coordinator = SearchCoordinator()
            coordinator.onSelectMovie = { [weak self] movie in
                self?.openDetail(for: movie)
            }
            coordinator.start()
            searchCoordinator = coordinator
        }
        if let query { searchCoordinator?.search(query: query) }
        switchActive(to: searchCoordinator!)
    }

    // MARK: - Active child switching

    private func switchActive(to coordinator: Coordinator) {
        guard coordinator !== activeCoordinator else { return }

        // Убираем текущий
        if let current = activeCoordinator {
            containerController.remove(child: current.rootViewController)
        }

        // Ставим новый
        containerController.embed(child: coordinator.rootViewController)
        activeCoordinator = coordinator
    }

    // MARK: - Detail

    private func openDetail(for movie: Movie) {
        containerController.focusCoordinator.hidePreview()
        let detail = MovieDetailViewController(movie: movie)
        detail.onDismiss = { [weak self] in
            // Обновляем локальные вкладки если они активны
            self?.favoritesCoordinator?.reload()
            self?.historyCoordinator?.reload()
        }
        containerController.present(detail, animated: true)
    }

    // MARK: - Settings

    private func openSettings() {
        containerController.focusCoordinator.hidePreview()
        let vc = SettingsViewController()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle   = .crossDissolve
        containerController.present(vc, animated: true)
    }
}
