import UIKit

class ModernInteractiveKeyboardViewController: UIViewController {
    
    private let textField = UITextField()
    private var keyboardLayoutGuide: UIKeyboardLayoutGuide!
    private var textFieldBottomConstraint: NSLayoutConstraint!
    private var panGestureRecognizer: UIPanGestureRecognizer?
    private var isKeyboardVisible = false
    private var keyboardHeight: CGFloat = 0
    private var initialKeyboardFrame: CGRect = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupInteractiveKeyboard()
        setupGestureRecognizers()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Настройка TextField с современным стилем
        textField.borderStyle = .none
        textField.placeholder = "Введите текст..."
        textField.delegate = self
        textField.returnKeyType = .done
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.backgroundColor = .secondarySystemBackground
        textField.layer.cornerRadius = 12
        textField.layer.cornerCurve = .continuous
        
        // Добавляем padding для текста
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        textField.rightViewMode = .always
        
        view.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // Используем keyboard layout guide для автоматического управления
        keyboardLayoutGuide = view.keyboardLayoutGuide
        keyboardLayoutGuide.followsUndockedKeyboard = true
        
        textFieldBottomConstraint = textField.bottomAnchor.constraint(
            equalTo: keyboardLayoutGuide.topAnchor,
            constant: -20
        )
        
        NSLayoutConstraint.activate([
            textFieldBottomConstraint,
            textField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            textField.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupInteractiveKeyboard() {
        // Подписываемся на уведомления клавиатуры
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow(_:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
    }
    
    private func setupGestureRecognizers() {
        // Pan gesture с современными настройками
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer?.delegate = self
        panGestureRecognizer?.cancelsTouchesInView = false
        panGestureRecognizer?.delaysTouchesBegan = false
        panGestureRecognizer?.delaysTouchesEnded = false
        view.addGestureRecognizer(panGestureRecognizer!)
        
        // Tap gesture для закрытия клавиатуры
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let animationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }
        
        isKeyboardVisible = true
        keyboardHeight = keyboardFrame.height
        initialKeyboardFrame = keyboardFrame
        
        // Анимируем появление с теми же параметрами что и системная анимация
        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: animationCurve << 16),
            animations: {
                self.view.layoutIfNeeded()
            }
        )
    }
    
    @objc private func keyboardDidShow(_ notification: Notification) {
        // Дополнительные действия после появления клавиатуры
        print("Клавиатура появилась")
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let animationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }
        
        isKeyboardVisible = false
        
        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: animationCurve << 16),
            animations: {
                self.view.layoutIfNeeded()
            }
        )
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard isKeyboardVisible else { return }
        
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        let location = gesture.location(in: view)
        
        // Проверяем, что жест начался не в области textField
        if gesture.state == .began && textField.frame.contains(location) {
            return
        }
        
        switch gesture.state {
        case .began:
            // Добавляем тактильную обратную связь
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
        case .changed:
            handlePanChanged(translation: translation)
            
        case .ended, .cancelled:
            handlePanEnded(translation: translation, velocity: velocity)
            
        default:
            break
        }
    }
    
    private func handlePanChanged(translation: CGPoint) {
        let progress = max(0, min(1, translation.y / keyboardHeight))
        
        if translation.y > 0 {
            // Жест вниз - начинаем скрывать клавиатуру
            animateKeyboardProgress(progress)
        } else {
            // Жест вверх - возвращаем клавиатуру
            let upwardProgress = max(0, 1 + (translation.y / keyboardHeight))
            animateKeyboardProgress(upwardProgress)
        }
    }
    
    private func handlePanEnded(translation: CGPoint, velocity: CGPoint) {
        let progress = max(0, min(1, translation.y / keyboardHeight))
        let velocityThreshold: CGFloat = 300
        let progressThreshold: CGFloat = 0.25
        
        let shouldHide = velocity.y > velocityThreshold ||
                        (abs(velocity.y) < velocityThreshold && progress > progressThreshold)
        
        if shouldHide {
            hideKeyboardWithAnimation()
        } else {
            showKeyboardWithAnimation()
        }
    }
    
    private func animateKeyboardProgress(_ progress: CGFloat) {
        let clampedProgress = max(0, min(1, progress))
        let offset = keyboardHeight * clampedProgress
        
        // Плавно обновляем constraint
        textFieldBottomConstraint.constant = -(20 + offset)
        
        UIView.animate(
            withDuration: 0.1,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut],
            animations: {
                self.view.layoutIfNeeded()
            }
        )
    }
    
    private func hideKeyboardWithAnimation() {
        // Тактильная обратная связь при скрытии
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.3,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: {
                self.textField.resignFirstResponder()
            }
        )
    }
    
    private func showKeyboardWithAnimation() {
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.3,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: {
                self.textFieldBottomConstraint.constant = -20
                self.view.layoutIfNeeded()
            }
        )
    }
    
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        
        // Если тап по textField и клавиатура не видна - показываем клавиатуру
        if textField.frame.contains(location) && !isKeyboardVisible {
            textField.becomeFirstResponder()
        }
        // Если тап вне textField и клавиатура видна - скрываем клавиатуру
        else if !textField.frame.contains(location) && isKeyboardVisible {
            textField.resignFirstResponder()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextFieldDelegate
@available(iOS 15.0, *)
extension ModernInteractiveKeyboardViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Анимированное скрытие при нажатии Done
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.2,
            animations: {
                textField.resignFirstResponder()
            }
        )
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Добавляем визуальный feedback
        UIView.animate(withDuration: 0.2) {
            textField.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Возвращаем исходный размер
        UIView.animate(withDuration: 0.2) {
            textField.transform = .identity
        }
    }
}

extension ModernInteractiveKeyboardViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer {
            // Pan gesture работает только когда клавиатура видна
            return isKeyboardVisible
        }
        return true
    }
}
