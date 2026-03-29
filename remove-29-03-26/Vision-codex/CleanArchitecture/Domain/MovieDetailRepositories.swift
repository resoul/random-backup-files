import Foundation

protocol MovieDetailRepository {
    func fetchDetail(path: String) async throws -> FilmixDetail
}

protocol PlayerTranslationsRepository {
    func fetchTranslations(postId: Int, isSeries: Bool) async throws -> [FilmixTranslation]
}
