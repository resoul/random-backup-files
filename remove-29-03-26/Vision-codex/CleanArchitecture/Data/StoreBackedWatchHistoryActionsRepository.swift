import Foundation

final class StoreBackedWatchHistoryActionsRepository: WatchHistoryActionsRepository {
    func touch(_ movie: Movie) {
        WatchHistoryStore.shared.touch(movie)
    }

    func isSeriesInProgress(movieId: Int) -> Bool {
        WatchHistoryStore.shared.isSeriesInProgress(movieId: movieId)
    }
}
