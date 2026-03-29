import Foundation

protocol LoadSeriesTranslationsUseCaseProtocol {
    func execute(movieId: Int) async throws -> [FilmixTranslation]
}

final class LoadSeriesTranslationsUseCase: LoadSeriesTranslationsUseCaseProtocol {
    private let repository: PlayerTranslationsRepository

    init(repository: PlayerTranslationsRepository) {
        self.repository = repository
    }

    func execute(movieId: Int) async throws -> [FilmixTranslation] {
        try await repository.fetchTranslations(postId: movieId, isSeries: true)
    }
}
