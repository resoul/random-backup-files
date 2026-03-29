import UIKit

protocol Coordinator: AnyObject {
    var rootViewController: UIViewController { get }
    func start()
}
