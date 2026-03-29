import Foundation

struct SearchViewState {
    var results: [Movie]
    var isLoading: Bool
    var emptyMessage: String?

    static let initial = SearchViewState(results: [], isLoading: false, emptyMessage: nil)
}

@MainActor
final class SearchViewModel {
    private let searchMoviesUseCase: SearchMoviesUseCaseProtocol
    private(set) var state: SearchViewState {
        didSet { onStateDidChange?(state) }
    }

    var onStateDidChange: ((SearchViewState) -> Void)?

    init(searchMoviesUseCase: SearchMoviesUseCaseProtocol) {
        self.searchMoviesUseCase = searchMoviesUseCase
        self.state = .initial
    }

    func search(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .initial
            return
        }

        state.isLoading = true
        state.emptyMessage = nil

        Task { [weak self] in
            guard let self else { return }
            do {
                let movies = try await searchMoviesUseCase.execute(query: trimmed)
                state.isLoading = false
                state.results = movies
                state.emptyMessage = movies.isEmpty ? "Ничего не найдено по запросу «\(trimmed)»" : nil
            } catch {
                state.isLoading = false
                state.results = []
                state.emptyMessage = "Ошибка поиска: \(error.localizedDescription)"
            }
        }
    }

    func clear() {
        state = .initial
    }
}
