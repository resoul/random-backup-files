import Foundation

enum RootContentSource: Equatable {
    case category(url: String?)
    case favorites
    case watchHistory

    var isLocalSource: Bool {
        switch self {
        case .favorites, .watchHistory:
            return true
        case .category:
            return false
        }
    }
}
