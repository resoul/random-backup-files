import Foundation

protocol LoadMovieTranslationsUseCaseProtocol {
    func execute(movieId: Int) async throws -> [FilmixTranslation]
}

final class LoadMovieTranslationsUseCase: LoadMovieTranslationsUseCaseProtocol {
    private let repository: PlayerTranslationsRepository

    init(repository: PlayerTranslationsRepository) {
        self.repository = repository
    }

    func execute(movieId: Int) async throws -> [FilmixTranslation] {
        try await repository.fetchTranslations(postId: movieId, isSeries: false)
    }
}
