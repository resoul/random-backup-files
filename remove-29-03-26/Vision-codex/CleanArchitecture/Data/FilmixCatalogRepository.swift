import Foundation

final class FilmixCatalogRepository: MovieCatalogRepository {
    func fetchPage(url: URL?) async throws -> MovieCatalogPage {
        try await withCheckedThrowingContinuation { continuation in
            FilmixService.shared.fetchPage(url: url) { result in
                switch result {
                case .success(let page):
                    continuation.resume(returning: MovieCatalogPage(
                        movies: page.movies,
                        nextPageURL: page.nextPageURL
                    ))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
