import Foundation

protocol LoadRootMoviesUseCaseProtocol {
    func loadFirstPage(source: RootContentSource) async throws -> MovieCatalogPage
    func loadNextPage(url: URL) async throws -> MovieCatalogPage
}

final class LoadRootMoviesUseCase: LoadRootMoviesUseCaseProtocol {
    private let catalogRepository: MovieCatalogRepository
    private let favoritesRepository: FavoritesRepository
    private let watchHistoryRepository: WatchHistoryRepository

    init(
        catalogRepository: MovieCatalogRepository,
        favoritesRepository: FavoritesRepository,
        watchHistoryRepository: WatchHistoryRepository
    ) {
        self.catalogRepository = catalogRepository
        self.favoritesRepository = favoritesRepository
        self.watchHistoryRepository = watchHistoryRepository
    }

    func loadFirstPage(source: RootContentSource) async throws -> MovieCatalogPage {
        switch source {
        case .category(let urlString):
            let url = urlString.flatMap(URL.init(string:))
            return try await catalogRepository.fetchPage(url: url)

        case .favorites:
            let movies = await favoritesRepository.all()
            return MovieCatalogPage(movies: movies, nextPageURL: nil)

        case .watchHistory:
            let movies = await watchHistoryRepository.active()
            return MovieCatalogPage(movies: movies, nextPageURL: nil)
        }
    }

    func loadNextPage(url: URL) async throws -> MovieCatalogPage {
        try await catalogRepository.fetchPage(url: url)
    }
}
