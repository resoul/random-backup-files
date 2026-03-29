import Foundation
import Filmix

// MARK: - StreamProvider
//
// Протокол абстракции над любым источником видеоконтента.
// tvOS app знает только этот протокол — не знает про Filmix, Kinogo, HDRezka и т.д.
//
// Dependency rule:
//   Presentation → StreamProvider ← FilmixStreamProvider (implements)
//
// Использование:
//   let provider: StreamProvider = FilmixStreamProvider()
//   AppContainer передаёт provider во все UseCases

protocol StreamProvider: AnyObject {

    // MARK: - Identity

    /// Отображаемое имя провайдера (напр. "Filmix", "Kinogo")
    var name: String { get }

    /// Уникальный идентификатор (используется в UserDefaults для сохранения выбора)
    var identifier: String { get }

    // MARK: - Content

    /// Загрузить страницу фильмов.
    /// - Parameters:
    ///   - url: nil = главная страница провайдера, иначе конкретный URL
    ///   - completion: MoviePage с фильмами и ссылкой на следующую страницу
    func fetchPage(url: URL?, completion: @escaping (Result<MoviePage, Error>) -> Void)

    /// Загрузить следующую страницу (пагинация).
    /// По умолчанию вызывает fetchPage(url: nextPageURL).
    func fetchNextPage(nextPageURL: URL, completion: @escaping (Result<MoviePage, Error>) -> Void)

    /// Поиск фильмов по строке запроса.
    func search(query: String, completion: @escaping (Result<MoviePage, Error>) -> Void)
}

// MARK: - StreamProvider default implementations

extension StreamProvider {

    func fetchNextPage(nextPageURL: URL, completion: @escaping (Result<MoviePage, Error>) -> Void) {
        fetchPage(url: nextPageURL, completion: completion)
    }
}

// MARK: - StreamProvider async wrappers
// Удобные async/await обёртки — используются в ViewModels через Task { }

extension StreamProvider {

    func fetchPage(url: URL? = nil) async throws -> MoviePage {
        try await withCheckedThrowingContinuation { cont in
            fetchPage(url: url) { cont.resume(with: $0) }
        }
    }

    func fetchNextPage(nextPageURL: URL) async throws -> MoviePage {
        try await withCheckedThrowingContinuation { cont in
            fetchNextPage(nextPageURL: nextPageURL) { cont.resume(with: $0) }
        }
    }

    func search(query: String) async throws -> MoviePage {
        try await withCheckedThrowingContinuation { cont in
            search(query: query) { cont.resume(with: $0) }
        }
    }
}
