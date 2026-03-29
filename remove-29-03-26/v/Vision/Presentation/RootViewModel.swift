import Foundation
import Combine

// MARK: - Loading State

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

// MARK: - RootViewModel

@MainActor
final class RootViewModel: ObservableObject {

    // MARK: - Published

    @Published private(set) var movies: [Movie] = []
    @Published private(set) var state: LoadingState = .idle

    // MARK: - Private

    private var nextPageURL: URL?
    private var isLoadingNextPage = false
    private var currentCategoryURL: String?
    private var isFavoritesTab    = false
    private var isWatchHistoryTab = false

    // MARK: - Category Switch

    func switchCategory(_ category: FilmixCategory, genre: FilmixGenre? = nil) {
        let url       = genre?.url ?? (category.isFavorites || category.isWatchHistory ? nil : category.url)
        let isFav     = category.isFavorites    && genre == nil
        let isHistory = category.isWatchHistory && genre == nil

        // Пропускаем если ничего не изменилось
        guard url != currentCategoryURL
           || isFav     != isFavoritesTab
           || isHistory != isWatchHistoryTab
        else { return }

        currentCategoryURL = url
        isFavoritesTab     = isFav
        isWatchHistoryTab  = isHistory
        nextPageURL        = nil
        isLoadingNextPage  = false
        movies             = []
        state              = .idle

        Task { await loadFirstPage() }
    }

    // MARK: - Load First Page

    func loadFirstPage() async {
        guard state != .loading else { return }
        state = .loading

        if isWatchHistoryTab {
            movies = WatchHistoryStore.shared.active()
            state  = .loaded
            return
        }

        if isFavoritesTab {
            movies = FavoritesStore.shared.all()
            state  = .loaded
            return
        }

        let url = currentCategoryURL.flatMap { URL(string: $0) }

        do {
            let page    = try await FilmixService.shared.fetchPage(url: url)
            nextPageURL = page.nextPageURL
            movies      = page.movies
            state       = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Load Next Page

    func loadNextPageIfNeeded(prefetchIndex: Int) {
        guard !isLoadingNextPage,
              !isFavoritesTab,
              !isWatchHistoryTab,
              let url = nextPageURL,
              prefetchIndex >= movies.count - 15
        else { return }

        isLoadingNextPage = true

        Task {
            do {
                let page = try await FilmixService.shared.fetchPage(url: url)
                nextPageURL = page.nextPageURL
                movies.append(contentsOf: page.movies)
            } catch { /* silent — footer spinner скроется сам */ }
            isLoadingNextPage = false
        }
    }

    // MARK: - Reload local tabs

    /// Вызывать при viewDidAppear — обновляет Избранное и Смотрю если они активны
    func reloadFavoritesOrHistory() {
        guard isFavoritesTab || isWatchHistoryTab else { return }
        Task { await loadFirstPage() }
    }

    // MARK: - Helpers

    var hasNextPage: Bool { nextPageURL != nil && !isFavoritesTab && !isWatchHistoryTab }
    var isEmpty:     Bool { movies.isEmpty && state == .loaded }

    var emptyMessage: String {
        if isFavoritesTab    { return "Нет избранных фильмов\nНажмите «+ Избранное» на странице фильма" }
        if isWatchHistoryTab { return "Нет незавершённых фильмов или сериалов" }
        return ""
    }
}

// MARK: - FilmixService async wrapper

private extension FilmixService {
    func fetchPage(url: URL?) async throws -> FilmixPage {
        try await withCheckedThrowingContinuation { continuation in
            fetchPage(url: url) { result in
                continuation.resume(with: result)
            }
        }
    }
}
