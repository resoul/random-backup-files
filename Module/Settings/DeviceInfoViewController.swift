//import UIKit
//import Combine
//
//@available(iOS 13.0, *)
//class DeviceInfoViewController: UIViewController {
//    
//    @IBOutlet weak var deviceInfoLabel: UILabel!
//    @IBOutlet weak var orientationLabel: UILabel!
//    @IBOutlet weak var batteryLabel: UILabel!
//    @IBOutlet weak var safeAreaLabel: UILabel!
//    @IBOutlet weak var refreshButton: UIButton!
//    @IBOutlet weak var autoUpdateSwitch: UISwitch!
//    
//    private let deviceManager = DeviceManager.shared
//    private var cancellables = Set<AnyCancellable>()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupCombineSubscriptions()
//        updateDeviceInfo()
//    }
//    
//    private func setupUI() {
//        title = "Информация об устройстве"
//        
//        // Настройка labels
//        [deviceInfoLabel, orientationLabel, batteryLabel, safeAreaLabel].forEach { label in
//            label?.numberOfLines = 0
//            label?.font = UIFont.systemFont(ofSize: 14)
//            label?.textAlignment = .left
//        }
//        
//        refreshButton.setTitle("Обновить", for: .normal)
//        refreshButton.addTarget(self, action: #selector(refreshButtonTapped), for: .touchUpInside)
//        
//        autoUpdateSwitch.addTarget(self, action: #selector(autoUpdateSwitchChanged), for: .valueChanged)
//        autoUpdateSwitch.isOn = true
//    }
//    
//    private func setupCombineSubscriptions() {
//        // Подписка на основные изменения устройства
//        deviceManager.$currentDevice
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] device in
//                self?.updateDeviceInfoLabel(with: device)
//            }
//            .store(in: &cancellables)
//        
//        // Подписка на значимые изменения ориентации с debounce
//        deviceManager.debouncedOrientationChanges(for: 0.5)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] orientation in
//                self?.updateOrientationLabel(orientation)
//                self?.showOrientationAlert(orientation)
//            }
//            .store(in: &cancellables)
//        
//        // Подписка на изменения батареи с throttle
//        deviceManager.throttledBatteryChanges()
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] level in
//                self?.updateBatteryLabel(level)
//            }
//            .store(in: &cancellables)
//        
//        // Подписка на критические изменения батареи
//        deviceManager.criticalBatteryChanges
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] level in
//                self?.showCriticalBatteryAlert(level)
//            }
//            .store(in: &cancellables)
//        
//        // Подписка на изменения статуса зарядки
//        deviceManager.chargingStatusChanges
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] isCharging in
//                self?.updateChargingStatus(isCharging)
//            }
//            .store(in: &cancellables)
//        
//        // Подписка на изменения Safe Area
//        deviceManager.safeAreaPublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] safeArea in
//                self?.updateSafeAreaLabel(safeArea)
//            }
//            .store(in: &cancellables)
//        
//        // Автоматическое обновление каждые 2 секунды (если включено)
//        autoUpdateSwitch.publisher(for: .valueChanged)
//            .flatMap { [weak self] control -> AnyPublisher<Device, Never> in
//                guard let self = self else { return Empty().eraseToAnyPublisher() }
//                if control.isOn {
//                    return self.deviceManager.deviceUpdates(every: 2.0)
//                } else {
//                    return Empty().eraseToAnyPublisher()
//                }
//            }
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] device in
//                // Обновления уже происходят через $currentDevice
//                print("Автоматическое обновление: \(Date())")
//            }
//            .store(in: &cancellables)
//        
//        // Комбинированные изменения для сложной логики
//        Publishers.CombineLatest3(
//            deviceManager.orientationPublisher,
//            deviceManager.batteryLevelPublisher,
//            deviceManager.chargingStatusChanges
//        )
//        .debounce(for: 0.3, scheduler: DispatchQueue.main)
//        .sink { [weak self] orientation, batteryLevel, isCharging in
//            self?.handleCombinedChanges(orientation: orientation,
//                                      batteryLevel: batteryLevel,
//                                      isCharging: isCharging)
//        }
//        .store(in: &cancellables)
//    }
//    
//    @objc private func refreshButtonTapped() {
//        updateDeviceInfo()
//        
//        // Анимация кнопки
//        UIView.animate(withDuration: 0.1, animations: {
//            self.refreshButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
//        }) { _ in
//            UIView.animate(withDuration: 0.1) {
//                self.refreshButton.transform = .identity
//            }
//        }
//        
//        // Создаем импульсную обратную связь
//        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
//        impactFeedback.impactOccurred()
//    }
//    
//    @objc private func autoUpdateSwitchChanged(_ sender: UISwitch) {
//        print("Автоматическое обновление: \(sender.isOn ? "включено" : "выключено")")
//    }
//    
//    private func updateDeviceInfo() {
//        let device = deviceManager.getCurrentDevice()
//        updateDeviceInfoLabel(with: device)
//        updateOrientationLabel(device.orientation)
//        updateBatteryLabel(device.batteryLevel)
//        updateSafeAreaLabel(deviceManager.getSafeAreaInsets())
//    }
//    
//    private func updateDeviceInfoLabel(with device: Device) {
//        deviceInfoLabel.text = device.description
//    }
//    
//    private func updateOrientationLabel(_ orientation: UIDeviceOrientation) {
//        let orientationText = getOrientationDescription(orientation)
//        orientationLabel.text = "🔄 Текущая ориентация: \(orientationText)"
//        
//        // Анимация изменения
//        UIView.transition(with: orientationLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
//            self.orientationLabel.textColor = .systemBlue
//        }) { _ in
//            UIView.animate(withDuration: 0.3, delay: 0.5, options: [], animations: {
//                self.orientationLabel.textColor = .label
//            })
//        }
//    }
//    
//    private func updateBatteryLabel(_ level: Float) {
//        let percentage = Int(level * 100)
//        let batteryIcon = getBatteryIcon(level: level)
//        batteryLabel.text = "\(batteryIcon) Батарея: \(percentage)%"
//        
//        // Меняем цвет в зависимости от уровня заряда
//        if level <= 0.2 {
//            batteryLabel.textColor = .systemRed
//        } else if level <= 0.5 {
//            batteryLabel.textColor = .systemOrange
//        } else {
//            batteryLabel.textColor = .systemGreen
//        }
//    }
//    
//    private func updateSafeAreaLabel(_ safeArea: UIEdgeInsets) {
//        safeAreaLabel.text = """
//        📱 Safe Area:
//        Top: \(Int(safeArea.top)), Bottom: \(Int(safeArea.bottom))
//        Left: \(Int(safeArea.left)), Right: \(Int(safeArea.right))
//        """
//    }
//    
//    private func updateChargingStatus(_ isCharging: Bool) {
//        if isCharging {
//            showToast("⚡ Устройство подключено к зарядке")
//        } else {
//            showToast("🔋 Зарядка отключена")
//        }
//    }
//    
//    private func showOrientationAlert(_ orientation: UIDeviceOrientation) {
//        let orientationText = getOrientationDescription(orientation)
//        
//        // Показываем только для значимых изменений ориентации
//        switch orientation {
//        case .portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight:
//            showToast("🔄 Ориентация изменена: \(orientationText)")
//        default:
//            break
//        }
//    }
//    
//    private func showCriticalBatteryAlert(_ level: Float) {
//        let percentage = Int(level * 100)
//        let alert = UIAlertController(
//            title: "⚠️ Низкий заряд батареи",
//            message: "Осталось \(percentage)% заряда. Рекомендуется подключить зарядное устройство.",
//            preferredStyle: .alert
//        )
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }
//    
//    private func handleCombinedChanges(orientation: UIDeviceOrientation, batteryLevel: Float, isCharging: Bool) {
//        // Пример сложной логики на основе комбинированных изменений
//        if batteryLevel < 0.15 && !isCharging &&
//           (orientation == .landscapeLeft || orientation == .landscapeRight) {
//            print("⚠️ Критическая ситуация: низкий заряд в альбомной ориентации без зарядки")
//        }
//    }
//    
//    // MARK: - Helper Methods
//    
//    private func getOrientationDescription(_ orientation: UIDeviceOrientation) -> String {
//        switch orientation {
//        case .portrait: return "Портрет"
//        case .portraitUpsideDown: return "Портрет (перевернутый)"
//        case .landscapeLeft: return "Альбом (влево)"
//        case .landscapeRight: return "Альбом (вправо)"
//        case .faceUp: return "Лицом вверх"
//        case .faceDown: return "Лицом вниз"
//        default: return "Неизвестно"
//        }
//    }
//    
//    private func getBatteryIcon(level: Float) -> String {
//        if level <= 0.1 {
//            return "🪫"
//        } else if level <= 0.25 {
//            return "🔋"
//        } else if level <= 0.75 {
//            return "🔋"
//        } else {
//            return "🔋"
//        }
//    }
//    
//    private func showToast(_ message: String) {
//        let toastLabel = UILabel()
//        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
//        toastLabel.textColor = .white
//        toastLabel.textAlignment = .center
//        toastLabel.font = UIFont.systemFont(ofSize: 14)
//        toastLabel.text = message
//        toastLabel.alpha = 0
//        toastLabel.layer.cornerRadius = 10
//        toastLabel.clipsToBounds = true
//        
//        view.addSubview(toastLabel)
//        toastLabel.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
//            toastLabel.heightAnchor.constraint(equalToConstant: 40),
//            toastLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
//            toastLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
//        ])
//        
//        UIView.animate(withDuration: 0.3, animations: {
//            toastLabel.alpha = 1
//        }) { _ in
//            UIView.animate(withDuration: 0.3, delay: 2.0, options: [], animations: {
//                toastLabel.alpha = 0
//            }) { _ in
//                toastLabel.removeFromSuperview()
//            }
//        }
//    }
//}
//
//// MARK: - Advanced Usage Examples
//@available(iOS 13.0, *)
//extension DeviceInfoViewController {
//    
//    /// Пример использования операторов Combine для сложных сценариев
//    private func setupAdvancedCombineExamples() {
//        // Пример 1: Отслеживание изменений только в рабочие часы
//        deviceManager.orientationPublisher
//            .filter { _ in
//                let hour = Calendar.current.component(.hour, from: Date())
//                return hour >= 9 && hour <= 17 // Только с 9 до 17
//            }
//            .sink { orientation in
//                print("Изменение ориентации в рабочее время: \(orientation)")
//            }
//            .store(in: &cancellables)
//        
//        // Пример 2: Группировка изменений батареи по временным окнам
//        deviceManager.batteryLevelPublisher
//            .collect(.byTime(DispatchQueue.main, 10.0)) // Собираем изменения за 10 секунд
//            .sink { batteryLevels in
//                if batteryLevels.count > 1 {
//                    let delta = batteryLevels.last! - batteryLevels.first!
//                    print("Изменение заряда за 10 сек: \(delta * 100)%")
//                }
//            }
//            .store(in: &cancellables)
//        
//        // Пример 3: Отслеживание стабильности ориентации
//        deviceManager.orientationPublisher
//            .scan((UIDeviceOrientation.unknown, 0)) { (previous, current) in
//                let count = (previous.0 == current) ? previous.1 + 1 : 0
//                return (current, count)
//            }
//            .filter { $0.1 >= 5 } // Стабильная ориентация 5+ измерений
//            .map { $0.0 }
//            .removeDuplicates()
//            .sink { stableOrientation in
//                print("Стабильная ориентация: \(stableOrientation)")
//            }
//            .store(in: &cancellables)
//    }
//}
