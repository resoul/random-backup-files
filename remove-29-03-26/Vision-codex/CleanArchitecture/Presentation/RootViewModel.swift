import Foundation

struct RootViewState {
    var movies: [Movie]
    var nextPageURL: URL?
    var isFetchingInitial: Bool
    var isFetchingNext: Bool
    var hasLoadedFirstPage: Bool
    var errorMessage: String?
    var emptyMessage: String?
    var source: RootContentSource

    static let initial = RootViewState(
        movies: [],
        nextPageURL: nil,
        isFetchingInitial: false,
        isFetchingNext: false,
        hasLoadedFirstPage: false,
        errorMessage: nil,
        emptyMessage: nil,
        source: .category(url: nil)
    )
}

@MainActor
final class RootViewModel {
    private let loadRootMoviesUseCase: LoadRootMoviesUseCaseProtocol
    private(set) var state: RootViewState {
        didSet { onStateDidChange?(state) }
    }

    var onStateDidChange: ((RootViewState) -> Void)?

    init(loadRootMoviesUseCase: LoadRootMoviesUseCaseProtocol, initialSource: RootContentSource = .category(url: nil)) {
        self.loadRootMoviesUseCase = loadRootMoviesUseCase
        self.state = RootViewState.initial
        self.state.source = initialSource
    }

    func loadInitial() {
        guard !state.isFetchingInitial else { return }

        state.isFetchingInitial = true
        state.errorMessage = nil

        Task { [weak self] in
            guard let self else { return }
            do {
                let page = try await loadRootMoviesUseCase.loadFirstPage(source: state.source)
                applyFirstPage(page)
            } catch {
                state.isFetchingInitial = false
                state.hasLoadedFirstPage = true
                state.errorMessage = "Failed to load\n\(error.localizedDescription)"
                state.emptyMessage = nil
            }
        }
    }

    func retry() {
        loadInitial()
    }

    func switchSource(_ source: RootContentSource) {
        guard state.source != source else { return }

        state.source = source
        state.movies = []
        state.nextPageURL = nil
        state.hasLoadedFirstPage = false
        state.isFetchingInitial = false
        state.isFetchingNext = false
        state.errorMessage = nil
        state.emptyMessage = nil

        loadInitial()
    }

    func loadNextPageIfNeeded() {
        guard !state.isFetchingInitial, !state.isFetchingNext else { return }
        guard case .category = state.source, let nextPageURL = state.nextPageURL else { return }

        state.isFetchingNext = true

        Task { [weak self] in
            guard let self else { return }
            do {
                let page = try await loadRootMoviesUseCase.loadNextPage(url: nextPageURL)
                state.movies.append(contentsOf: page.movies)
                state.nextPageURL = page.nextPageURL
                state.isFetchingNext = false
            } catch {
                state.isFetchingNext = false
            }
        }
    }

    func refreshIfLocalSource() {
        guard state.source.isLocalSource else { return }
        loadInitial()
    }

    private func applyFirstPage(_ page: MovieCatalogPage) {
        state.movies = page.movies
        state.nextPageURL = page.nextPageURL
        state.isFetchingInitial = false
        state.isFetchingNext = false
        state.hasLoadedFirstPage = true
        state.errorMessage = nil

        switch state.source {
        case .favorites:
            state.emptyMessage = "Нет избранных фильмов\nНажмите «+ Добавить в избранное» на странице фильма"
        case .watchHistory:
            state.emptyMessage = "Нет незавершённых фильмов или сериалов"
        case .category:
            state.emptyMessage = nil
        }
    }
}
