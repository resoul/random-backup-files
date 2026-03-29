import Foundation

final class FilmixMovieDetailRepository: MovieDetailRepository {
    func fetchDetail(path: String) async throws -> FilmixDetail {
        try await withCheckedThrowingContinuation { continuation in
            FilmixService.shared.fetchDetail(path: path) { result in
                switch result {
                case .success(let detail):
                    continuation.resume(returning: detail)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
