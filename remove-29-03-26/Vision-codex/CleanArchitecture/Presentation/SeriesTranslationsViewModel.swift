import Foundation

struct SeriesTranslationsState {
    var translations: [FilmixTranslation]
    var activeTranslation: FilmixTranslation?
    var isLoading: Bool
    var hasErrorOrEmpty: Bool

    static let initial = SeriesTranslationsState(
        translations: [],
        activeTranslation: nil,
        isLoading: false,
        hasErrorOrEmpty: false
    )
}

@MainActor
final class SeriesTranslationsViewModel {
    private let loadSeriesTranslationsUseCase: LoadSeriesTranslationsUseCaseProtocol
    private(set) var state: SeriesTranslationsState {
        didSet { onStateDidChange?(state) }
    }

    var onStateDidChange: ((SeriesTranslationsState) -> Void)?

    init(loadSeriesTranslationsUseCase: LoadSeriesTranslationsUseCaseProtocol) {
        self.loadSeriesTranslationsUseCase = loadSeriesTranslationsUseCase
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
                let list = try await loadSeriesTranslationsUseCase.execute(movieId: movieId)
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
