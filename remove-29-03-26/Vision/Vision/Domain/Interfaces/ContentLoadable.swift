import Foundation

protocol ContentLoadable: AnyObject {
    func load(url: URL?)
    func loadNextPageIfNeeded(prefetchIndex: Int)
}
