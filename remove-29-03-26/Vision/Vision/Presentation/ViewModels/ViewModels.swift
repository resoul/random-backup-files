import Foundation
import Combine
import Filmix

// MARK: - HomeViewModel
//
// Главная страница — без пагинации (показывает рекомендации)

@MainActor
final class HomeViewModel: BaseViewModel, PaginatableViewModel {

    @Published private(set) var movies: [Movie] = []
    @Published private(set) var hasNextPage: Bool = false

    var moviesPublisher:      AnyPublisher<[Movie], Never> { $movies.eraseToAnyPublisher() }
    var hasNextPagePublisher: AnyPublisher<Bool,    Never> { $hasNextPage.eraseToAnyPublisher() }

    private let provider: StreamProvider
    private var task: Task<Void, Never>?

    init(provider: StreamProvider) {
        self.provider = provider
    }

    func load(url: URL? = nil) {
        task?.cancel()
        setState(.loading)
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let page = try await provider.fetchPage(url: url)
                guard !Task.isCancelled else { return }
                movies = page.movies
                setState(movies.isEmpty ? .empty("Нет содержимого") : .loaded)
            } catch is CancellationError {
            } catch {
                setState(.error(error.localizedDescription))
            }
        }
    }

    // Главная не пагинируется
    func loadNextPageIfNeeded(prefetchIndex: Int) {}

    @MainActor deinit { task?.cancel() }
}

// MARK: - MoviesViewModel

@MainActor
final class MoviesViewModel: BaseViewModel, PaginatableViewModel {

    @Published private(set) var movies: [Movie] = []
    @Published private(set) var hasNextPage: Bool = false

    var moviesPublisher:      AnyPublisher<[Movie], Never> { $movies.eraseToAnyPublisher() }
    var hasNextPagePublisher: AnyPublisher<Bool,    Never> { $hasNextPage.eraseToAnyPublisher() }

    private let provider: StreamProvider
    private var task: Task<Void, Never>?
    private var nextPageURL: URL?
    private var isLoadingNext = false

    init(provider: StreamProvider) {
        self.provider = provider
    }

    func load(url: URL? = nil) {
        task?.cancel()
        nextPageURL   = nil
        hasNextPage   = false
        isLoadingNext = false
        movies        = []
        setState(.loading)

        task = Task { [weak self] in
            guard let self else { return }
            do {
                let page = try await provider.fetchPage(url: url)
                guard !Task.isCancelled else { return }
                nextPageURL = page.nextPageURL
                hasNextPage = page.nextPageURL != nil
                movies      = page.movies
                setState(movies.isEmpty ? .empty("Нет фильмов") : .loaded)
            } catch is CancellationError {
            } catch {
                setState(.error(error.localizedDescription))
            }
        }
    }

    func loadNextPageIfNeeded(prefetchIndex: Int) {
        guard !isLoadingNext,
              let url = nextPageURL,
              prefetchIndex >= movies.count - 10
        else { return }

        isLoadingNext = true
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let page = try await provider.fetchNextPage(nextPageURL: url)
                guard !Task.isCancelled else { return }
                nextPageURL   = page.nextPageURL
                hasNextPage   = page.nextPageURL != nil
                movies.append(contentsOf: page.movies)
            } catch { /* silent — footer-спиннер скроется сам */ }
            isLoadingNext = false
        }
    }

    @MainActor deinit { task?.cancel() }
}

// MARK: - SeriesViewModel

@MainActor
final class SeriesViewModel: BaseViewModel, PaginatableViewModel {

    @Published private(set) var movies: [Movie] = []
    @Published private(set) var hasNextPage: Bool = false

    var moviesPublisher:      AnyPublisher<[Movie], Never> { $movies.eraseToAnyPublisher() }
    var hasNextPagePublisher: AnyPublisher<Bool,    Never> { $hasNextPage.eraseToAnyPublisher() }

    private let provider: StreamProvider
    private var task: Task<Void, Never>?
    private var nextPageURL: URL?
    private var isLoadingNext = false

    init(provider: StreamProvider) {
        self.provider = provider
    }

    func load(url: URL? = nil) {
        task?.cancel()
        nextPageURL   = nil
        hasNextPage   = false
        isLoadingNext = false
        movies        = []
        setState(.loading)

        task = Task { [weak self] in
            guard let self else { return }
            do {
                let page = try await provider.fetchPage(url: url)
                guard !Task.isCancelled else { return }
                nextPageURL = page.nextPageURL
                hasNextPage = page.nextPageURL != nil
                movies      = page.movies
                setState(movies.isEmpty ? .empty("Нет сериалов") : .loaded)
            } catch is CancellationError {
            } catch {
                setState(.error(error.localizedDescription))
            }
        }
    }

    func loadNextPageIfNeeded(prefetchIndex: Int) {
        guard !isLoadingNext,
              let url = nextPageURL,
              prefetchIndex >= movies.count - 10
        else { return }

        isLoadingNext = true
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let page = try await provider.fetchNextPage(nextPageURL: url)
                guard !Task.isCancelled else { return }
                nextPageURL   = page.nextPageURL
                hasNextPage   = page.nextPageURL != nil
                movies.append(contentsOf: page.movies)
            } catch {}
            isLoadingNext = false
        }
    }

    @MainActor deinit { task?.cancel() }
}

// MARK: - CartoonsViewModel

@MainActor
final class CartoonsViewModel: BaseViewModel, PaginatableViewModel {

    @Published private(set) var movies: [Movie] = []
    @Published private(set) var hasNextPage: Bool = false

    var moviesPublisher:      AnyPublisher<[Movie], Never> { $movies.eraseToAnyPublisher() }
    var hasNextPagePublisher: AnyPublisher<Bool,    Never> { $hasNextPage.eraseToAnyPublisher() }

    private let provider: StreamProvider
    private var task: Task<Void, Never>?
    private var nextPageURL: URL?
    private var isLoadingNext = false

    init(provider: StreamProvider) {
        self.provider = provider
    }

    func load(url: URL? = nil) {
        task?.cancel()
        nextPageURL   = nil
        hasNextPage   = false
        isLoadingNext = false
        movies        = []
        setState(.loading)

        task = Task { [weak self] in
            guard let self else { return }
            do {
                let page = try await provider.fetchPage(url: url)
                guard !Task.isCancelled else { return }
                nextPageURL = page.nextPageURL
                hasNextPage = page.nextPageURL != nil
                movies      = page.movies
                setState(movies.isEmpty ? .empty("Нет мультфильмов") : .loaded)
            } catch is CancellationError {
            } catch {
                setState(.error(error.localizedDescription))
            }
        }
    }

    func loadNextPageIfNeeded(prefetchIndex: Int) {
        guard !isLoadingNext,
              let url = nextPageURL,
              prefetchIndex >= movies.count - 10
        else { return }

        isLoadingNext = true
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let page = try await provider.fetchNextPage(nextPageURL: url)
                guard !Task.isCancelled else { return }
                nextPageURL   = page.nextPageURL
                hasNextPage   = page.nextPageURL != nil
                movies.append(contentsOf: page.movies)
            } catch {}
            isLoadingNext = false
        }
    }

    @MainActor deinit { task?.cancel() }
}

// MARK: - FavoritesViewModel

@MainActor
final class FavoritesViewModel: BaseViewModel, PaginatableViewModel {

    @Published private(set) var movies: [Movie] = []
    @Published private(set) var hasNextPage: Bool = false

    var moviesPublisher:      AnyPublisher<[Movie], Never> { $movies.eraseToAnyPublisher() }
    var hasNextPagePublisher: AnyPublisher<Bool,    Never> { $hasNextPage.eraseToAnyPublisher() }

    override init() { super.init() }

    func load(url: URL? = nil) {
        movies = []
        setState(.empty("Нет избранных фильмов\nНажмите «+ Избранное» на странице фильма"))
    }

    func loadNextPageIfNeeded(prefetchIndex: Int) {}
}

// MARK: - WatchingViewModel

@MainActor
final class WatchingViewModel: BaseViewModel, PaginatableViewModel {

    @Published private(set) var movies: [Movie] = []
    @Published private(set) var hasNextPage: Bool = false

    var moviesPublisher:      AnyPublisher<[Movie], Never> { $movies.eraseToAnyPublisher() }
    var hasNextPagePublisher: AnyPublisher<Bool,    Never> { $hasNextPage.eraseToAnyPublisher() }

    override init() { super.init() }

    func load(url: URL? = nil) {
        movies = []
        setState(.empty("Нет незавершённых просмотров"))
    }

    func loadNextPageIfNeeded(prefetchIndex: Int) {}
}

// MARK: - SearchViewModel

@MainActor
final class SearchViewModel: BaseViewModel {

    @Published private(set) var results: [Movie] = []
    @Published var query: String = ""

    private let provider: StreamProvider
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(provider: StreamProvider) {
        self.provider = provider
        super.init()

        $query
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] q in
                if q.isEmpty {
                    self?.results = []
                    self?.setState(.idle)
                } else {
                    self?.performSearch(q)
                }
            }
            .store(in: &cancellables)
    }

    private func performSearch(_ q: String) {
        searchTask?.cancel()
        setState(.loading)
        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let page = try await provider.search(query: q)
                guard !Task.isCancelled else { return }
                results = page.movies
                setState(results.isEmpty ? .empty("Ничего не найдено") : .loaded)
            } catch is CancellationError {
            } catch {
                setState(.error(error.localizedDescription))
            }
        }
    }

    @MainActor deinit { searchTask?.cancel() }
}

// MARK: - SettingsViewModel

@MainActor
final class SettingsViewModel: BaseViewModel {
    @Published var appVersion: String =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    override init() { super.init() }
}
