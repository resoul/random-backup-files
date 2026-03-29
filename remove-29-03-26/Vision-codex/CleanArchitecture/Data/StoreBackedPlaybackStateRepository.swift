import Foundation

final class StoreBackedPlaybackStateRepository: PlaybackStateRepository {
    func movieProgress(movieId: Int) -> PlaybackProgress? {
        PlaybackStore.shared.movieProgress(movieId: movieId)
    }

    func episodeProgress(movieId: Int, season: Int, episode: Int) -> PlaybackProgress? {
        PlaybackStore.shared.episodeProgress(movieId: movieId, season: season, episode: episode)
    }

    func saveMovieProgress(
        movieId: Int,
        position: Double,
        duration: Double,
        studio: String,
        quality: String,
        streamURL: String
    ) {
        PlaybackStore.shared.saveMovieProgress(
            movieId: movieId,
            position: position,
            duration: duration,
            studio: studio,
            quality: quality,
            streamURL: streamURL
        )
    }

    func saveEpisodeProgress(movieId: Int, season: Int, episode: Int, position: Double, duration: Double) {
        PlaybackStore.shared.saveEpisodeProgress(
            movieId: movieId,
            season: season,
            episode: episode,
            position: position,
            duration: duration
        )
    }

    func isEpisodeWatched(movieId: Int, season: Int, episode: Int) -> Bool {
        PlaybackStore.shared.isEpisodeWatched(movieId: movieId, season: season, episode: episode)
    }

    func setEpisodeWatched(_ watched: Bool, movieId: Int, season: Int, episode: Int) {
        PlaybackStore.shared.setEpisodeWatched(watched, movieId: movieId, season: season, episode: episode)
    }

    func totalEpisodeCount() -> Int {
        PlaybackStore.shared.totalEpisodeCount()
    }

    func clearAllEpisodes() {
        PlaybackStore.shared.clearAllEpisodes()
    }
}
