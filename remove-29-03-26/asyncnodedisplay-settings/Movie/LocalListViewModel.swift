import Foundation
import Combine

// MARK: - LocalListMode

enum LocalListMode {
    case favorites
    case watchHistory

    var emptyMessage: String {
        switch self {
        case .favorites:    return "Нет избранных фильмов\nНажмите «+ Избранное» на странице фильма"
        case .watchHistory: return "Нет незавершённых фильмов или сериалов"
        }
    }
}

// MARK: - LocalListViewModel

@MainActor
final class LocalListViewModel: ObservableObject {

    // MARK: - Published

    @Published private(set) var movies: [Movie] = []
    @Published private(set) var state: LoadingState = .idle

    // MARK: - Dependencies

    let mode: LocalListMode

    init(mode: LocalListMode) {
        self.mode = mode
    }

    // MARK: - Public API

    func load() {
        state = .loading
        switch mode {
        case .favorites:    movies = FavoritesStore.shared.all()
        case .watchHistory: movies = WatchHistoryStore.shared.active()
        }
        state = .loaded
    }

    // MARK: - Computed

    var isEmpty:      Bool   { movies.isEmpty && state == .loaded }
    var emptyMessage: String { mode.emptyMessage }
}
