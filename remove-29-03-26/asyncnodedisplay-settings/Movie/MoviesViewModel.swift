import Foundation
import Combine

// MARK: - MoviesViewModel

@MainActor
final class MoviesViewModel: ObservableObject {

    // MARK: - Published

    @Published private(set) var movies: [Movie] = []
    @Published private(set) var state: LoadingState = .idle

    // MARK: - Private

    private var nextPageURL:      URL?
    private var isLoadingNextPage = false
    private var currentURL:       String?

    // MARK: - Public API

    func load(url: String?) {
        guard url != currentURL else { return }
        currentURL        = url
        nextPageURL       = nil
        isLoadingNextPage = false
        movies            = []
        state             = .idle
        Task { await fetchFirstPage() }
    }

    func loadNextPageIfNeeded(prefetchIndex: Int) {
        guard !isLoadingNextPage,
              let url = nextPageURL,
              prefetchIndex >= movies.count - 15
        else { return }

        isLoadingNextPage = true
        Task {
            do {
                let page    = try await FilmixService.shared.fetchPage(url: url)
                nextPageURL = page.nextPageURL
                movies.append(contentsOf: page.movies)
            } catch {}
            isLoadingNextPage = false
        }
    }

    func retry() {
        let saved  = currentURL
        currentURL = nil
        load(url: saved)
    }

    // MARK: - Computed

    var hasNextPage: Bool { nextPageURL != nil }
    var isEmpty:     Bool { movies.isEmpty && state == .loaded }

    // MARK: - Private

    private func fetchFirstPage() async {
        guard state != .loading else { return }
        state = .loading
        let url = currentURL.flatMap { URL(string: $0) }
        do {
            let page    = try await FilmixService.shared.fetchPage(url: url)
            nextPageURL = page.nextPageURL
            movies      = page.movies
            state       = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

// MARK: - FilmixService async wrapper

private extension FilmixService {
    func fetchPage(url: URL?) async throws -> FilmixPage {
        try await withCheckedThrowingContinuation { continuation in
            fetchPage(url: url) { continuation.resume(with: $0) }
        }
    }
}
