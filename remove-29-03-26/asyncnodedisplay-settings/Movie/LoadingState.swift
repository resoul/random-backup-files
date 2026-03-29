// MARK: - LoadingState

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}
