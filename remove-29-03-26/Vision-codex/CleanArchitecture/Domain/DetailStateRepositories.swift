import Foundation

protocol FavoritesStateRepository {
    func isFavorite(id: Int) -> Bool
    func toggle(_ movie: Movie)
    func allCount() -> Int
}

protocol WatchHistoryActionsRepository {
    func touch(_ movie: Movie)
    func isSeriesInProgress(movieId: Int) -> Bool
}

protocol PlaybackStateRepository {
    func movieProgress(movieId: Int) -> PlaybackProgress?
    func episodeProgress(movieId: Int, season: Int, episode: Int) -> PlaybackProgress?
    func saveMovieProgress(
        movieId: Int,
        position: Double,
        duration: Double,
        studio: String,
        quality: String,
        streamURL: String
    )
    func saveEpisodeProgress(movieId: Int, season: Int, episode: Int, position: Double, duration: Double)
    func isEpisodeWatched(movieId: Int, season: Int, episode: Int) -> Bool
    func setEpisodeWatched(_ watched: Bool, movieId: Int, season: Int, episode: Int)
    func totalEpisodeCount() -> Int
    func clearAllEpisodes()
}
