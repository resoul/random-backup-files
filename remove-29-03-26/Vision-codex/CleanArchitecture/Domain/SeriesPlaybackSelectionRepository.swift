import Foundation

protocol SeriesPlaybackSelectionRepository {
    func save(movieId: Int, season: Int, episode: Int, quality: String, studio: String)
}
