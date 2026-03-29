import Foundation

final class FilmixPlayerTranslationsRepository: PlayerTranslationsRepository {
    func fetchTranslations(postId: Int, isSeries: Bool) async throws -> [FilmixTranslation] {
        try await withCheckedThrowingContinuation { continuation in
            FilmixService.shared.fetchPlayerData(postId: postId, isSeries: isSeries) { result in
                switch result {
                case .success(let translations):
                    continuation.resume(returning: translations)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
