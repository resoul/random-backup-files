import Foundation

protocol SearchMoviesRepository {
    func search(query: String) async throws -> [Movie]
}

protocol SearchMoviesUseCaseProtocol {
    func execute(query: String) async throws -> [Movie]
}

final class SearchMoviesUseCase: SearchMoviesUseCaseProtocol {
    private let repository: SearchMoviesRepository

    init(repository: SearchMoviesRepository) {
        self.repository = repository
    }

    func execute(query: String) async throws -> [Movie] {
        try await repository.search(query: query)
    }
}
