// Переключение на конкретный таб
coordinator.selectTab(.campaigns)

// Установка бейджа
coordinator.setBadge(for: .campaigns, value: "5")

// Показ профиля поверх текущего таба
coordinator.showProfile()

// Показ уведомлений
coordinator.showNotifications()

// Обработка ссылок вида: myapp://campaigns/123
appCoordinator.handleDeepLink(url)

// Навигация по push уведомлению
appCoordinator.handlePushNotification(userInfo)