import Foundation

struct MovieTranslationsState {
    var translations: [FilmixTranslation]
    var activeTranslation: FilmixTranslation?
    var isLoading: Bool
    var hasErrorOrEmpty: Bool

    static let initial = MovieTranslationsState(
        translations: [],
        activeTranslation: nil,
        isLoading: false,
        hasErrorOrEmpty: false
    )
}

@MainActor
final class MovieTranslationsViewModel {
    private let loadMovieTranslationsUseCase: LoadMovieTranslationsUseCaseProtocol
    private(set) var state: MovieTranslationsState {
        didSet { onStateDidChange?(state) }
    }

    var onStateDidChange: ((MovieTranslationsState) -> Void)?

    init(loadMovieTranslationsUseCase: LoadMovieTranslationsUseCaseProtocol) {
        self.loadMovieTranslationsUseCase = loadMovieTranslationsUseCase
        self.state = .initial
    }

    func load(movieId: Int) {
        guard movieId > 0 else {
            state.hasErrorOrEmpty = true
            return
        }

        state.isLoading = true
        state.hasErrorOrEmpty = false

        Task { [weak self] in
            guard let self else { return }
            do {
                let list = try await loadMovieTranslationsUseCase.execute(movieId: movieId)
                state.isLoading = false
                state.translations = list
                state.activeTranslation = list.first
                state.hasErrorOrEmpty = list.isEmpty
            } catch {
                state.isLoading = false
                state.translations = []
                state.activeTranslation = nil
                state.hasErrorOrEmpty = true
            }
        }
    }

    func select(translation: FilmixTranslation) {
        state.activeTranslation = translation
    }
}
