import Foundation

final class FilmixSearchMoviesRepository: SearchMoviesRepository {
    func search(query: String) async throws -> [Movie] {
        try await withCheckedThrowingContinuation { continuation in
            FilmixService.shared.fetchSearchResults(query: query) { result in
                switch result {
                case .success(let page):
                    continuation.resume(returning: page.movies)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
