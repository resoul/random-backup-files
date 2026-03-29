import Foundation

protocol LoadMovieDetailUseCaseProtocol {
    func execute(path: String) async throws -> FilmixDetail
}

final class LoadMovieDetailUseCase: LoadMovieDetailUseCaseProtocol {
    private let repository: MovieDetailRepository

    init(repository: MovieDetailRepository) {
        self.repository = repository
    }

    func execute(path: String) async throws -> FilmixDetail {
        try await repository.fetchDetail(path: path)
    }
}
