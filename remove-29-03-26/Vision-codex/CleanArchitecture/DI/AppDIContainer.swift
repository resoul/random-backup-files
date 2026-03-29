import Foundation
import UIKit

final class AppDIContainer {
    static let shared = AppDIContainer()

    private init() {}

    func makeAppBootstrapper() -> AppBootstrapper {
        AppBootstrapper()
    }

    func makeAppCoordinator(window: UIWindow) -> AppCoordinator {
        AppCoordinator(window: window)
    }

    func makeRootViewModel() -> RootViewModel {
        let useCase = LoadRootMoviesUseCase(
            catalogRepository: FilmixCatalogRepository(),
            favoritesRepository: CoreDataFavoritesRepository(),
            watchHistoryRepository: CoreDataWatchHistoryRepository()
        )
        return RootViewModel(loadRootMoviesUseCase: useCase)
    }

    func makeLoadMovieDetailUseCase() -> LoadMovieDetailUseCaseProtocol {
        LoadMovieDetailUseCase(repository: FilmixMovieDetailRepository())
    }

    func makeLoadMovieTranslationsUseCase() -> LoadMovieTranslationsUseCaseProtocol {
        LoadMovieTranslationsUseCase(repository: FilmixPlayerTranslationsRepository())
    }

    func makeLoadSeriesTranslationsUseCase() -> LoadSeriesTranslationsUseCaseProtocol {
        LoadSeriesTranslationsUseCase(repository: FilmixPlayerTranslationsRepository())
    }

    func makeMovieTranslationsViewModel() -> MovieTranslationsViewModel {
        MovieTranslationsViewModel(loadMovieTranslationsUseCase: makeLoadMovieTranslationsUseCase())
    }

    func makeSeriesTranslationsViewModel() -> SeriesTranslationsViewModel {
        SeriesTranslationsViewModel(loadSeriesTranslationsUseCase: makeLoadSeriesTranslationsUseCase())
    }

    func makeSearchMoviesUseCase() -> SearchMoviesUseCaseProtocol {
        SearchMoviesUseCase(repository: FilmixSearchMoviesRepository())
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(searchMoviesUseCase: makeSearchMoviesUseCase())
    }

    func makeFavoritesStateRepository() -> FavoritesStateRepository {
        StoreBackedFavoritesStateRepository()
    }

    func makeWatchHistoryActionsRepository() -> WatchHistoryActionsRepository {
        StoreBackedWatchHistoryActionsRepository()
    }

    func makePlaybackStateRepository() -> PlaybackStateRepository {
        StoreBackedPlaybackStateRepository()
    }

    func makeQualityPreferenceRepository() -> QualityPreferenceRepository {
        StoreBackedQualityPreferenceRepository()
    }

    func makeSeriesPlaybackSelectionRepository() -> SeriesPlaybackSelectionRepository {
        StoreBackedSeriesPlaybackSelectionRepository()
    }
}
