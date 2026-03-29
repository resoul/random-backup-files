import Foundation
import Combine
import Filmix

// MARK: - PaginatableViewModel
//
// Протокол для ViewModel которая умеет загружать страницы контента.
// ContentViewController параметризован этим протоколом —
// он не знает про MoviesViewModel, SeriesViewModel и т.д.
//
// Реализуют:
//   MoviesViewModel, SeriesViewModel, CartoonsViewModel,
//   FavoritesViewModel, WatchingViewModel

protocol PaginatableViewModel: BaseViewModel {

    // MARK: - State

    var movies:      [Movie] { get }
    var hasNextPage: Bool    { get }

    // MARK: - Publishers
    //
    // @Published не виден через generic протокол — передаём AnyPublisher явно.
    // Каждая VM реализует их через { $movies.eraseToAnyPublisher() }

    var moviesPublisher:      AnyPublisher<[Movie], Never> { get }
    var hasNextPagePublisher: AnyPublisher<Bool,    Never> { get }

    // MARK: - Commands

    func load(url: URL?)
    func loadNextPageIfNeeded(prefetchIndex: Int)
}
