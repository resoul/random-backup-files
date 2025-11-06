import AsyncDisplayKit
import Combine
import FontManager
import DeviceManager

enum LoginNodeEvent {
    case registration
    case login
    case forgotPassword
}

final class LoginNode: AuthNode, UIGestureRecognizerDelegate {
    let events = PassthroughSubject<LoginNodeEvent, Never>()

    // MARK: - Keyboard handling properties
    private var keyboardHeight: CGFloat = 0
    private var isKeyboardVisible = false
    private var availableHeight: CGFloat = 0

    // MARK: - Scroll Node
    private let scrollNode = ASScrollNode()
    private let contentNode = ASDisplayNode()

    //MARK: - UI Components
    //MARK: TODO: create TextNode
    private lazy var needAccountText: ASTextNode = {
        let text = ASTextNode()
        text.attributedText = NSAttributedString(
            string: "Need An Account - ",
            attributes: [
                .font: UIFont.poppinsWithFallback(.regular, size: 16),
                .foregroundColor: themeManager.currentTheme.authPresentationData.textColor
            ]
        )

        return text
    }()

    private lazy var loginText: ASTextNode = {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let text = ASTextNode()
        text.attributedText = NSAttributedString(
            string: "Log in to your SMTP account",
            attributes: [
                .font: UIFont.poppinsWithFallback(.bold, size: 19, fallback: .bold),
                .foregroundColor: themeManager.currentTheme.authPresentationData.headlineColor,
                .paragraphStyle: paragraph
            ]
        )

        return text
    }()

    private lazy var registrationTextButton: AuthTextButtonNode = {
        let btn = AuthTextButtonNode(
            text: "Register Here",
            textColor: themeManager.currentTheme.authPresentationData.textLinkColor,
            textSize: 15
        )

        btn.addTarget(self, action: #selector(handleRegistrationTap), forControlEvents: .touchUpInside)

        return btn
    }()

    private lazy var forgotPasswordTextButton: AuthTextButtonNode = {
        let btn = AuthTextButtonNode(
            text: "Forgot Password",
            textColor: themeManager.currentTheme.authPresentationData.textLinkColor,
            textSize: 15,
            isUnderlined: false,
            alignment: .left
        )

        btn.style.alignSelf = .start
        btn.addTarget(self, action: #selector(handleForgotPasswordTap), forControlEvents: .touchUpInside)

        return btn
    }()

    private lazy var submitButton: AuthSubmitButtonNode = {
        let btn = AuthSubmitButtonNode(
            text: "Login"
        )

        btn.addTarget(self, action: #selector(handleLoginTap), forControlEvents: .touchUpInside)

        return btn
    }()

    private lazy var usernameField = AuthEmailInputFieldNode()
    private lazy var passwordField = AuthPasswordInputFieldNode(labelText: "Password")

    // MARK: - Publishers
    var emailTextPublisher: AnyPublisher<String, Never> {
        usernameField.textDidChange.eraseToAnyPublisher()
    }

    var passwordTextPublisher: AnyPublisher<String, Never> {
        passwordField.textDidChange.eraseToAnyPublisher()
    }

    // MARK: - Initialization
    private var tapGesture: UITapGestureRecognizer?

    func setLoginButtonEnabled(_ isEnabled: Bool) {
        submitButton.setButtonEnabled(isEnabled)
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            submitButton.setTitle(
                "Logging in...",
                with: UIFont.poppinsWithFallback(.bold, size: 16, fallback: .bold),
                with: .white,
                for: .normal
            )
            submitButton.isEnabled = false
        } else {
            submitButton.setTitle(
                "Login",
                with: UIFont.poppinsWithFallback(.bold, size: 16, fallback: .bold),
                with: .white,
                for: .normal
            )
        }
    }

    @objc
    private func handleRegistrationTap() {
        events.send(.registration)
    }

    @objc
    private func handleLoginTap() {
        events.send(.login)
    }

    @objc
    private func handleForgotPasswordTap() {
        events.send(.forgotPassword)
    }

    override init() {
        super.init()
        setupGestureRecognizer()
        setupKeyboardObservers()
        setupScrollNode()
    }

    // MARK: - Setup Methods
    private func setupScrollNode() {
        scrollNode.automaticallyManagesSubnodes = true
        scrollNode.automaticallyManagesContentSize = true
        scrollNode.view.showsVerticalScrollIndicator = false
        scrollNode.view.showsHorizontalScrollIndicator = false
        scrollNode.view.keyboardDismissMode = .onDrag

        // Добавляем content node как subnode к scroll node
        contentNode.automaticallyManagesSubnodes = true
        scrollNode.addSubnode(contentNode)

        // Добавляем scroll node как основной subnode
        automaticallyManagesSubnodes = true
        addSubnode(scrollNode)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchPoint = touch.location(in: view)
        let usernameFrame = usernameField.frame
        let inputFrame = passwordField.frame

        return !inputFrame.contains(touchPoint) && !usernameFrame.contains(touchPoint)
    }

    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }
    private func setupGestureRecognizer() {
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture?.cancelsTouchesInView = false
        tapGesture?.delegate = self
        view.addGestureRecognizer(tapGesture!)
    }

    private func setupKeyboardObservers() {
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
    }

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }

        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let viewBottom = view.bounds.maxY

        keyboardHeight = max(0, viewBottom - keyboardFrameInView.minY)
        isKeyboardVisible = true

        let safeAreaInsets = DeviceManager.shared.getSafeAreaInsets()
        availableHeight = view.bounds.height - safeAreaInsets.top - keyboardHeight

        animateLayoutUpdate(duration: animationDuration)
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            self.scrollToActiveFieldIfNeeded()
        }
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        let keyboardAnimationDuration = UIResponder.keyboardAnimationDurationUserInfoKey
        guard let animationDuration = notification.userInfo?[keyboardAnimationDuration] as? TimeInterval else {
            return
        }

        keyboardHeight = 0
        isKeyboardVisible = false

        animateLayoutUpdate(duration: animationDuration)
    }

    private func scrollToActiveFieldIfNeeded() {
        var activeField: ASDisplayNode?
        if usernameField.isFirstResponder() {
            activeField = usernameField
        } else {
            activeField = passwordField
        }

        guard let field = activeField else { return }
        let fieldFrame = field.frame
        let scrollViewBounds = scrollNode.view.bounds
        let fieldBottom = fieldFrame.maxY + 20
        let visibleBottom = scrollViewBounds.maxY

        if fieldBottom > visibleBottom {
            let offset = fieldBottom - visibleBottom
            let newContentOffset = CGPoint(
                x: scrollNode.view.contentOffset.x,
                y: scrollNode.view.contentOffset.y + offset
            )

            scrollNode.view.setContentOffset(newContentOffset, animated: true)
        }
    }

    private func animateLayoutUpdate(duration: TimeInterval) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseInOut],
            animations: {
                // Принудительно пересчитываем layout
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        )
    }

    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        removeKeyboardObservers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        var safeAreaInsets = DeviceManager.shared.getSafeAreaInsets()
        let scrollHeight: CGFloat
        if isKeyboardVisible && availableHeight > 0 {
            scrollHeight = availableHeight
        } else {
            scrollHeight = constrainedSize.max.height - safeAreaInsets.top - safeAreaInsets.bottom
        }

        scrollNode.style.preferredSize = CGSize(
            width: constrainedSize.max.width,
            height: scrollHeight
        )

        //=======================================//
        let footer = ASStackLayoutSpec.horizontal()
        footer.spacing = 4
        footer.alignItems = .center
        footer.children = [needAccountText, registrationTextButton]
        footer.style.alignSelf = .center

        let mainContent = ASStackLayoutSpec.vertical()
        mainContent.spacing = 3
        mainContent.alignItems = .stretch
        mainContent.children = [
            getHeaderLayout(),
            getAuthFormLayout(elements: [
                self.loginText,
                self.usernameField,
                self.passwordField,
                self.forgotPasswordTextButton,
                self.submitButton
            ])
        ]

        // Создаем основной layout с контентом и footer
        let contentLayout = ASStackLayoutSpec.vertical()
        contentLayout.justifyContent = .spaceBetween
        contentLayout.alignItems = .stretch
        contentLayout.children = [mainContent, footer]

        // Минимальная высота равна доступной высоте scroll view
        let minHeight = max(constrainedSize.min.height, availableHeight > 0 ? availableHeight : 600)
        contentLayout.style.minHeight = ASDimension(unit: .points, value: minHeight)

        scrollNode.layoutSpecBlock = { _, _ in
            return ASInsetLayoutSpec(
                insets: UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16),
                child: contentLayout
            )
        }



        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(
                top: safeAreaInsets.top,
                left: safeAreaInsets.left,
                bottom: isKeyboardVisible ? keyboardHeight : safeAreaInsets.bottom,
                right: safeAreaInsets.right
            ),
            child: scrollNode
        )



//        let footer = ASStackLayoutSpec.horizontal()
//        footer.spacing = 4
//        footer.alignItems = .center
//        footer.children = [needAccountText, registrationTextButton]
//        footer.style.alignSelf = .center
//
//        let layout = ASStackLayoutSpec.vertical()
//        layout.spacing = 3
//        layout.justifyContent = .spaceBetween
//        layout.alignItems = .stretch
//        layout.children = [
//            getHeaderLayout(),
//            getAuthFormLayout(elements: [
//                self.loginText,
//                self.usernameField,
//                self.passwordField,
//                self.forgotPasswordTextButton,
//                self.submitButton
//            ]),
//            footer
//        ]
//
//
//        if isKeyboardVisible {
//            // Добавляем дополнительный отступ от клавиатуры
//            let keyboardPadding: CGFloat = 20
//            safeAreaInsets.bottom = keyboardHeight + keyboardPadding
//        }
//
//        return ASInsetLayoutSpec(
//            insets: safeAreaInsets,
//            child: layout
//        )
    }
}
