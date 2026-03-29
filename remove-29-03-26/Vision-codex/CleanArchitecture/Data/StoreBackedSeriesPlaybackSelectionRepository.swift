import Foundation

final class StoreBackedSeriesPlaybackSelectionRepository: SeriesPlaybackSelectionRepository {
    func save(movieId: Int, season: Int, episode: Int, quality: String, studio: String) {
        SeriesPickerStore.shared.save(
            movieId: movieId,
            season: season,
            episode: episode,
            quality: quality,
            studio: studio
        )
    }
}
