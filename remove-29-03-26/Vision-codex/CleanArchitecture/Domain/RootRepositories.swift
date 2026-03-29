import Foundation

struct MovieCatalogPage {
    let movies: [Movie]
    let nextPageURL: URL?
}

protocol MovieCatalogRepository {
    func fetchPage(url: URL?) async throws -> MovieCatalogPage
}

protocol FavoritesRepository {
    func all() async -> [Movie]
}

protocol WatchHistoryRepository {
    func active() async -> [Movie]
}
