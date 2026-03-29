import UIKit

// MARK: - FocusRegion

enum FocusRegion {
    case tabBar
    case content
}

// MARK: - FocusCoordinatorDelegate

protocol FocusCoordinatorDelegate: AnyObject {
    func focusCoordinator(_ coordinator: FocusCoordinator, didChangeTo region: FocusRegion)
}

// MARK: - FocusCoordinator
//
// Отвечает за переключение фокуса между горизонтальным таб-баром и
// вертикальным контентом страницы.
//
// Правила tvOS:
//  • Свайп вверх из контента → фокус в таб-бар
//  • Выбор пункта / свайп вниз из таб-бара → фокус в контент
//  • Кнопка Menu / Back → если в контенте — переходим в таб-бар

final class FocusCoordinator {

    // MARK: - Public

    weak var delegate: FocusCoordinatorDelegate?

    private(set) var currentRegion: FocusRegion = .tabBar

    // MARK: - Weak references (не держим VC)

    weak var tabBarViewController: TVTabBarViewController?
    weak var contentViewController: UIViewController?

    // MARK: - Focus transition

    func moveFocus(to region: FocusRegion, animated: Bool = true) {
        guard region != currentRegion else { return }
        currentRegion = region
        delegate?.focusCoordinator(self, didChangeTo: region)
        applyFocusEnvironment(region: region, animated: animated)
    }

    func toggleFocus(animated: Bool = true) {
        moveFocus(to: currentRegion == .tabBar ? .content : .tabBar, animated: animated)
    }

    // MARK: - Private

    private func applyFocusEnvironment(region: FocusRegion, animated: Bool) {
        switch region {
        case .tabBar:
            tabBarViewController?.setNeedsFocusUpdate()
            tabBarViewController?.updateFocusIfNeeded()
        case .content:
            contentViewController?.setNeedsFocusUpdate()
            contentViewController?.updateFocusIfNeeded()
        }
    }
}

// MARK: - UIFocusEnvironment helpers

extension FocusCoordinator {

    /// Вызывается из RootViewController.shouldUpdateFocus
    func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        // Разрешаем любое обновление фокуса
        return true
    }

    /// Вызывается из RootViewController когда фокус ушёл вниз из TabBar
    func handleSwipeDownFromTabBar() {
        moveFocus(to: .content)
    }

    /// Вызывается когда фокус ушёл вверх из контента
    func handleSwipeUpFromContent() {
        moveFocus(to: .tabBar)
    }

    /// Вызывается при нажатии Menu/Back
    func handleMenuPress() -> Bool {
        if currentRegion == .content {
            moveFocus(to: .tabBar)
            return true   // обработали — не передавать выше
        }
        return false
    }
}
