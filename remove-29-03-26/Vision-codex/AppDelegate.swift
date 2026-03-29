import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?
    private let appBootstrapper = AppDIContainer.shared.makeAppBootstrapper()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        appBootstrapper.prepare()

        let window = UIWindow(frame: UIScreen.main.bounds)
        let appCoordinator = AppDIContainer.shared.makeAppCoordinator(window: window)
        appCoordinator.start()
        self.appCoordinator = appCoordinator
        self.window = window

        return true
    }
}
