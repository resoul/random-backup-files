import Foundation

final class StoreBackedFavoritesStateRepository: FavoritesStateRepository {
    func isFavorite(id: Int) -> Bool {
        FavoritesStore.shared.isFavorite(id: id)
    }

    func toggle(_ movie: Movie) {
        FavoritesStore.shared.toggle(movie)
    }

    func allCount() -> Int {
        FavoritesStore.shared.all().count
    }
}
