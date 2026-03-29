import Foundation

final class CoreDataFavoritesRepository: FavoritesRepository {
    func all() async -> [Movie] {
        FavoritesStore.shared.all()
    }
}
