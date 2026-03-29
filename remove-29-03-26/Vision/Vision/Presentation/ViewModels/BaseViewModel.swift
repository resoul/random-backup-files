import Foundation
import Combine

// MARK: - ViewState

enum ViewState: Equatable {
    case idle
    case loading
    case loaded
    case empty(String)
    case error(String)
}

// MARK: - BaseViewModel

@MainActor
class BaseViewModel: ObservableObject {
    @Published private(set) var state: ViewState = .idle

    func setState(_ newState: ViewState) {
        state = newState
    }
}
