import Foundation

final class CoreDataWatchHistoryRepository: WatchHistoryRepository {
    func active() async -> [Movie] {
        WatchHistoryStore.shared.active()
    }
}
