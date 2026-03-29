import UIKit

// MARK: - TVTabBarViewDelegate
// Переименован: CategoryTabBarDelegate → TVTabBarViewDelegate
// FilmixCategory → ProviderCategory
// FilmixGenre    → ProviderGenre

protocol TVTabBarViewDelegate: AnyObject {
    func tvTabBarView(_ bar: TVTabBarView, didSelect category: ProviderCategory)
    func tvTabBarView(_ bar: TVTabBarView, didSelectGenre genre: ProviderGenre, in category: ProviderCategory)
    func tvTabBarView(_ bar: TVTabBarView, didSubmitSearch query: String)
    func tvTabBarViewDidSelectSettings(_ bar: TVTabBarView)
}

// MARK: - TVTabBarView
// Переименован: CategoryTabBar → TVTabBarView
// Весь UI-код сохранён 1-в-1, только типы переименованы

final class TVTabBarView: UIView {

    weak var delegate: TVTabBarViewDelegate?

    // MARK: - Heights
    static let mainRowHeight:        CGFloat = 76
    static let genreRowHeight:       CGFloat = 58
    static let searchRowHeight:      CGFloat = 64
    static var collapsedHeight:      CGFloat { mainRowHeight }
    static var expandedHeight:       CGFloat { mainRowHeight + genreRowHeight }
    static var searchExpandedHeight: CGFloat { mainRowHeight + searchRowHeight }

    // Переименован: FilmixCategory → ProviderCategory
    private var categories: [ProviderCategory] = []
    private var selectedIndex = 0
    // Переименован: CategoryTabButton → TVTabButton
    private var tabButtons: [TVTabButton] = []

    // Genre row state
    // Переименован: GenreTabButton → TVGenreButton
    private var genreButtons:       [TVGenreButton] = []
    private var selectedGenreIndex: Int?             = nil
    // Переименован: FilmixGenre → ProviderGenre
    private var currentGenres: [ProviderGenre] = []

    // Search row state
    private var isSearchActive = false

    // MARK: - Main row

    private let mainRow: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis      = .horizontal
        sv.spacing   = 6
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // Переименован: CategorySettingsButton → TVSettingsButton
    private let settingsButton: TVSettingsButton = {
        let b = TVSettingsButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // Переименован: CategorySearchButton → TVSearchShortcutButton
    private let searchShortcutButton: TVSearchShortcutButton = {
        let b = TVSearchShortcutButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let separatorBottom: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.07)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Genre row

    private let genreRow: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let genreScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator   = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let genreStack: UIStackView = {
        let sv = UIStackView()
        sv.axis      = .horizontal
        sv.spacing   = 6
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let genreSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.07)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var genreRowHeightConstraint: NSLayoutConstraint!

    // MARK: - Search row

    private let searchRow: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let searchContainer: UIView = {
        let v = UIView()
        v.backgroundColor      = UIColor(white: 1, alpha: 0.08)
        v.layer.cornerRadius   = 12
        v.layer.cornerCurve    = .continuous
        v.layer.borderWidth    = 1
        v.layer.borderColor    = UIColor(white: 1, alpha: 0.12).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let searchIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iv.tintColor    = UIColor(white: 0.45, alpha: 1)
        iv.contentMode  = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    lazy var searchTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        tf.textColor = .white
        tf.tintColor = .white
        tf.attributedPlaceholder = NSAttributedString(
            string: "Поиск фильмов и сериалов...",
            attributes: [.foregroundColor: UIColor(white: 0.30, alpha: 1)]
        )
        tf.returnKeyType       = .search
        tf.autocorrectionType  = .no
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private lazy var searchClearButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "xmark.circle.fill")
        config.baseForegroundColor = UIColor(white: 0.40, alpha: 1)
        let b = UIButton(configuration: config)
        b.isHidden = true
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(clearSearchTapped), for: .touchUpInside)
        return b
    }()

    private let searchSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.07)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var searchRowHeightConstraint: NSLayoutConstraint!

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        buildLayout()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - buildLayout (было: build)

    private func buildLayout() {
        addSubview(mainRow)
        addSubview(genreRow)
        addSubview(searchRow)
        addSubview(separatorBottom)

        mainRow.addSubview(stackView)
        mainRow.addSubview(settingsButton)
        mainRow.addSubview(searchShortcutButton)

        genreRow.addSubview(genreScrollView)
        genreScrollView.addSubview(genreStack)
        genreRow.addSubview(genreSeparator)

        searchRow.addSubview(searchContainer)
        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchTextField)
        searchContainer.addSubview(searchClearButton)
        searchRow.addSubview(searchSeparator)

        settingsButton.onSelect = { [weak self] in
            guard let self else { return }
            self.deselectAllCategoryTabs()
            self.settingsButton.setActive(true)
            self.hideSearchRow(animated: true)
            self.setGenreRowVisible(false, animated: true)
            self.delegate?.tvTabBarViewDidSelectSettings(self)
        }

        searchShortcutButton.onSelect = { [weak self] in
            guard let self else { return }
            self.activateSearch()
        }

        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)

        genreRowHeightConstraint  = genreRow.heightAnchor.constraint(equalToConstant: 0)
        searchRowHeightConstraint = searchRow.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            // Main row
            mainRow.topAnchor.constraint(equalTo: topAnchor),
            mainRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainRow.heightAnchor.constraint(equalToConstant: Self.mainRowHeight),

            settingsButton.leadingAnchor.constraint(equalTo: mainRow.leadingAnchor, constant: 24),
            settingsButton.centerYAnchor.constraint(equalTo: mainRow.centerYAnchor),

            stackView.leadingAnchor.constraint(equalTo: settingsButton.trailingAnchor, constant: 20),
            stackView.centerYAnchor.constraint(equalTo: mainRow.centerYAnchor),

            searchShortcutButton.trailingAnchor.constraint(equalTo: mainRow.trailingAnchor, constant: -24),
            searchShortcutButton.centerYAnchor.constraint(equalTo: mainRow.centerYAnchor),

            // Genre row
            genreRow.topAnchor.constraint(equalTo: mainRow.bottomAnchor),
            genreRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            genreRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            genreRowHeightConstraint,

            genreScrollView.topAnchor.constraint(equalTo: genreRow.topAnchor),
            genreScrollView.leadingAnchor.constraint(equalTo: genreRow.leadingAnchor),
            genreScrollView.trailingAnchor.constraint(equalTo: genreRow.trailingAnchor),
            genreScrollView.bottomAnchor.constraint(equalTo: genreRow.bottomAnchor),

            genreStack.topAnchor.constraint(equalTo: genreScrollView.topAnchor),
            genreStack.leadingAnchor.constraint(equalTo: genreScrollView.leadingAnchor, constant: 72),
            genreStack.trailingAnchor.constraint(equalTo: genreScrollView.trailingAnchor, constant: -72),
            genreStack.bottomAnchor.constraint(equalTo: genreScrollView.bottomAnchor),
            genreStack.heightAnchor.constraint(equalTo: genreScrollView.heightAnchor),

            genreSeparator.leadingAnchor.constraint(equalTo: genreRow.leadingAnchor),
            genreSeparator.trailingAnchor.constraint(equalTo: genreRow.trailingAnchor),
            genreSeparator.bottomAnchor.constraint(equalTo: genreRow.bottomAnchor),
            genreSeparator.heightAnchor.constraint(equalToConstant: 1),

            // Search row
            searchRow.topAnchor.constraint(equalTo: mainRow.bottomAnchor),
            searchRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            searchRowHeightConstraint,

            searchContainer.leadingAnchor.constraint(equalTo: searchRow.leadingAnchor, constant: 80),
            searchContainer.trailingAnchor.constraint(equalTo: searchRow.trailingAnchor, constant: -80),
            searchContainer.centerYAnchor.constraint(equalTo: searchRow.centerYAnchor, constant: -2),
            searchContainer.heightAnchor.constraint(equalToConstant: 48),

            searchIcon.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 16),
            searchIcon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),

            searchTextField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 12),
            searchTextField.trailingAnchor.constraint(equalTo: searchClearButton.leadingAnchor, constant: -8),
            searchTextField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),

            searchClearButton.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -12),
            searchClearButton.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchClearButton.widthAnchor.constraint(equalToConstant: 30),
            searchClearButton.heightAnchor.constraint(equalToConstant: 30),

            searchSeparator.leadingAnchor.constraint(equalTo: searchRow.leadingAnchor),
            searchSeparator.trailingAnchor.constraint(equalTo: searchRow.trailingAnchor),
            searchSeparator.bottomAnchor.constraint(equalTo: searchRow.bottomAnchor),
            searchSeparator.heightAnchor.constraint(equalToConstant: 1),

            separatorBottom.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorBottom.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorBottom.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorBottom.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    // MARK: - configure(categories:)
    //
    // Было: private let categories = FilmixCategory.all  ← хардкод внутри view
    // Стало: публичный метод — категории приходят снаружи из Domain (ProviderCategory)
    // Вызывается из TVTabBarViewController после получения данных от репозитория

    func configure(categories: [ProviderCategory]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        tabButtons.removeAll()
        self.categories = categories
        selectedIndex   = 0

        for (i, cat) in categories.enumerated() {
            let btn = TVTabButton(title: cat.title, icon: cat.icon)
            btn.tag        = i
            btn.isActiveTab = (i == 0)
            let index = i
            btn.onSelect = { [weak self] in
                guard let self else { return }
                self.settingsButton.setActive(false)
                if index == self.selectedIndex {
                    if self.categories[safe: index]?.isSearch == true {
                        self.searchTextField.text  = ""
                        self.searchClearButton.isHidden = true
                    } else {
                        self.deselectGenre()
                        if let cat = self.categories[safe: index] {
                            self.delegate?.tvTabBarView(self, didSelect: cat)
                        }
                    }
                    return
                }
                self.tabButtons[safe: self.selectedIndex]?.isActiveTab = false
                self.selectedIndex = index
                self.tabButtons[safe: index]?.isActiveTab = true

                guard let category = self.categories[safe: index] else { return }
                if category.isSearch {
                    self.showSearchRow(animated: true)
                } else {
                    self.hideSearchRow(animated: true)
                    self.showGenres(for: category)
                    self.delegate?.tvTabBarView(self, didSelect: category)
                }
            }
            stackView.addArrangedSubview(btn)
            tabButtons.append(btn)
        }
        settingsButton.setActive(false)
    }

    // MARK: - Genre Row

    private func showGenres(for category: ProviderCategory) {
        selectedGenreIndex = nil
        currentGenres      = category.genres

        genreStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        genreButtons.removeAll()

        guard !category.genres.isEmpty else {
            setGenreRowVisible(false, animated: true)
            return
        }

        for (i, genre) in category.genres.enumerated() {
            let btn = TVGenreButton(title: genre.title)
            btn.isActiveTab = false
            let index = i
            btn.onSelect = { [weak self] in
                guard let self else { return }
                if let prev = self.selectedGenreIndex {
                    self.genreButtons[safe: prev]?.isActiveTab = false
                }
                self.selectedGenreIndex = index
                self.genreButtons[safe: index]?.isActiveTab = true
                guard let cat = self.categories[safe: self.selectedIndex] else { return }
                self.delegate?.tvTabBarView(self, didSelectGenre: self.currentGenres[index], in: cat)
            }
            genreStack.addArrangedSubview(btn)
            genreButtons.append(btn)
        }

        setGenreRowVisible(true, animated: true)
        genreScrollView.setContentOffset(.zero, animated: false)
    }

    private func deselectGenre() {
        if let prev = selectedGenreIndex {
            genreButtons[safe: prev]?.isActiveTab = false
        }
        selectedGenreIndex = nil
    }

    private func setGenreRowVisible(_ visible: Bool, animated: Bool) {
        let targetH: CGFloat = visible ? Self.genreRowHeight : 0
        guard genreRowHeightConstraint.constant != targetH else { return }
        genreRowHeightConstraint.constant = targetH
        if animated {
            UIView.animate(withDuration: 0.28, delay: 0,
                           usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
                self.superview?.layoutIfNeeded()
            }
        } else {
            superview?.layoutIfNeeded()
        }
    }

    // MARK: - Search Row

    private func showSearchRow(animated: Bool) {
        isSearchActive = true
        genreRowHeightConstraint.constant  = 0
        searchRowHeightConstraint.constant = Self.searchRowHeight
        if animated {
            UIView.animate(withDuration: 0.28, delay: 0,
                           usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
                self.superview?.layoutIfNeeded()
            } completion: { _ in
                self.searchTextField.becomeFirstResponder()
            }
        } else {
            superview?.layoutIfNeeded()
            searchTextField.becomeFirstResponder()
        }
    }

    private func hideSearchRow(animated: Bool) {
        guard isSearchActive else { return }
        isSearchActive = false
        searchTextField.resignFirstResponder()
        searchTextField.text = ""
        searchClearButton.isHidden = true
        searchRowHeightConstraint.constant = 0
        tabButtons[safe: selectedIndex]?.isActiveTab = true
        if animated {
            UIView.animate(withDuration: 0.28, delay: 0,
                           usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
                self.superview?.layoutIfNeeded()
            }
        } else {
            superview?.layoutIfNeeded()
        }
    }

    @objc private func searchTextChanged() {
        searchClearButton.isHidden = (searchTextField.text ?? "").isEmpty
    }

    @objc private func clearSearchTapped() {
        searchTextField.text = ""
        searchClearButton.isHidden = true
        delegate?.tvTabBarView(self, didSubmitSearch: "")
    }

    // MARK: - Programmatic selection

    func select(index: Int) {
        guard index < categories.count, index != selectedIndex else { return }
        tabButtons[safe: selectedIndex]?.isActiveTab = false
        selectedIndex = index
        tabButtons[safe: selectedIndex]?.isActiveTab = true
        guard let category = categories[safe: index] else { return }
        if category.isSearch {
            showSearchRow(animated: false)
        } else {
            hideSearchRow(animated: false)
            showGenres(for: category)
        }
    }

    func activateSearch() {
        if isSearchActive {
            searchTextField.becomeFirstResponder()
            return
        }
        isSearchActive = true
        deselectAllCategoryTabs()
        settingsButton.setActive(false)
        genreRowHeightConstraint.constant  = 0
        searchRowHeightConstraint.constant = Self.searchRowHeight

        UIView.animate(withDuration: 0.28, delay: 0,
                       usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.superview?.layoutIfNeeded()
        } completion: { _ in
            self.searchTextField.becomeFirstResponder()
        }

        delegate?.tvTabBarView(self, didSelect: ProviderCategory(
            id: "search", title: "Поиск", icon: "magnifyingglass",
            url: nil, genres: [], isSearch: true
        ))
    }

    var hasGenres:       Bool { !currentGenres.isEmpty }
    var currentIsSearch: Bool { isSearchActive }

    private func deselectAllCategoryTabs() {
        tabButtons.forEach { $0.isActiveTab = false }
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        tabButtons.first.map { [$0] } ?? [settingsButton]
    }
}

// MARK: - UITextFieldDelegate

extension TVTabBarView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let query = textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        textField.resignFirstResponder()
        if !query.isEmpty {
            delegate?.tvTabBarView(self, didSubmitSearch: query)
        }
        return true
    }
}

// MARK: - TVTabButton
// Переименован: CategoryTabButton → TVTabButton

final class TVTabButton: TVFocusControl {

    var isActiveTab: Bool = false {
        didSet { guard oldValue != isActiveTab else { return }
                 updateLook(animated: true) }
    }

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode  = .scaleAspectFit
        iv.tintColor    = UIColor(white: 0.45, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let label: UILabel = {
        let l = UILabel()
        l.font      = UIFont.systemFont(ofSize: 24, weight: .semibold)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let accentDot: UIView = {
        let v = UIView()
        v.backgroundColor  = .white
        v.layer.cornerRadius = 3
        v.alpha            = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init(title: String, icon: String) {
        super.init(frame: .zero)
        iconView.image = UIImage(systemName: icon)
        label.text     = title

        bgView.removeFromSuperview()
        addSubview(bgView)
        addSubview(iconView)
        addSubview(label)
        addSubview(accentDot)

        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            iconView.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -18),
            label.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            label.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -12),

            accentDot.bottomAnchor.constraint(equalTo: bottomAnchor),
            accentDot.centerXAnchor.constraint(equalTo: centerXAnchor),
            accentDot.widthAnchor.constraint(equalToConstant: 20),
            accentDot.heightAnchor.constraint(equalToConstant: 4),
        ])

        updateLook(animated: false)
    }
    required init?(coder: NSCoder) { fatalError() }

    private func updateLook(animated: Bool) {
        let block = {
            let dim = UIColor(white: 0.45, alpha: 1)
            self.label.textColor    = self.isActiveTab ? .white : dim
            self.label.font         = UIFont.systemFont(ofSize: 24, weight: self.isActiveTab ? .bold : .semibold)
            self.iconView.tintColor = self.isActiveTab ? .white : dim
            self.bgView.backgroundColor = UIColor(white: 1, alpha: self.isActiveTab ? 0.10 : 0)
            self.accentDot.alpha     = self.isActiveTab ? 1 : 0
            self.accentDot.transform = self.isActiveTab
                ? .identity
                : CGAffineTransform(scaleX: 0.4, y: 1)
        }
        if animated {
            UIView.animate(withDuration: 0.22, delay: 0,
                           usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5,
                           animations: block)
        } else { block() }
    }

    override func applyFocusAppearance(focused: Bool) {
        let dim = UIColor(white: 0.45, alpha: 1)
        label.textColor    = focused ? .white : (isActiveTab ? .white : dim)
        iconView.tintColor = focused ? .white : (isActiveTab ? .white : dim)
        bgView.backgroundColor = UIColor(white: 1,
            alpha: focused ? focusedBgAlpha : (isActiveTab ? 0.10 : 0))
    }
}

// MARK: - TVSettingsButton
// Переименован: CategorySettingsButton → TVSettingsButton

final class TVSettingsButton: TVFocusControl {

    private(set) var isActive: Bool = false

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.image       = UIImage(systemName: "gearshape.fill")
        iv.contentMode = .scaleAspectFit
        iv.tintColor   = UIColor(white: 0.45, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let accentDot: UIView = {
        let v = UIView()
        v.backgroundColor    = .white
        v.layer.cornerRadius = 2
        v.alpha              = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(iconView)
        addSubview(accentDot)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 26),
            iconView.heightAnchor.constraint(equalToConstant: 26),
            bgView.widthAnchor.constraint(equalToConstant: 52),
            bgView.heightAnchor.constraint(equalToConstant: 48),
            accentDot.bottomAnchor.constraint(equalTo: bottomAnchor),
            accentDot.centerXAnchor.constraint(equalTo: centerXAnchor),
            accentDot.widthAnchor.constraint(equalToConstant: 16),
            accentDot.heightAnchor.constraint(equalToConstant: 3),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func setActive(_ active: Bool) {
        isActive = active
        UIView.animate(withDuration: 0.22, delay: 0,
                       usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5) {
            self.iconView.tintColor     = active ? .white : UIColor(white: 0.45, alpha: 1)
            self.bgView.backgroundColor = UIColor(white: 1, alpha: active ? 0.10 : 0)
            self.accentDot.alpha        = active ? 1 : 0
            self.accentDot.transform    = active ? .identity : CGAffineTransform(scaleX: 0.4, y: 1)
        }
    }

    override func applyFocusAppearance(focused: Bool) {
        iconView.tintColor     = focused ? .white : (isActive ? .white : UIColor(white: 0.45, alpha: 1))
        bgView.backgroundColor = UIColor(white: 1, alpha: focused ? focusedBgAlpha : (isActive ? 0.10 : 0))
    }
}

// MARK: - TVGenreButton
// Переименован: GenreTabButton → TVGenreButton

final class TVGenreButton: TVFocusControl {

    var isActiveTab: Bool = false {
        didSet { guard oldValue != isActiveTab else { return }
                 updateLook(animated: true) }
    }

    private let label: UILabel = {
        let l = UILabel()
        l.font      = UIFont.systemFont(ofSize: 20, weight: .semibold)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let accentDot: UIView = {
        let v = UIView()
        v.backgroundColor  = .white
        v.layer.cornerRadius = 2.5
        v.alpha            = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init(title: String) {
        super.init(frame: .zero)
        label.text = title
        bgView.removeFromSuperview()

        addSubview(bgView)
        addSubview(label)
        addSubview(accentDot)
        bgView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            label.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),

            accentDot.bottomAnchor.constraint(equalTo: bottomAnchor),
            accentDot.centerXAnchor.constraint(equalTo: centerXAnchor),
            accentDot.widthAnchor.constraint(equalToConstant: 16),
            accentDot.heightAnchor.constraint(equalToConstant: 3),
        ])

        updateLook(animated: false)
    }
    required init?(coder: NSCoder) { fatalError() }

    private func updateLook(animated: Bool) {
        let block = {
            self.label.textColor = self.isActiveTab ? .white : UIColor(white: 0.45, alpha: 1)
            self.label.font      = UIFont.systemFont(ofSize: 20, weight: self.isActiveTab ? .bold : .semibold)
            self.bgView.backgroundColor = UIColor(white: 1, alpha: self.isActiveTab ? 0.10 : 0)
            self.accentDot.alpha     = self.isActiveTab ? 1 : 0
            self.accentDot.transform = self.isActiveTab
                ? .identity
                : CGAffineTransform(scaleX: 0.4, y: 1)
        }
        if animated {
            UIView.animate(withDuration: 0.22, delay: 0,
                           usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5,
                           animations: block)
        } else { block() }
    }

    override func applyFocusAppearance(focused: Bool) {
        label.textColor = focused ? .white : (isActiveTab ? .white : UIColor(white: 0.45, alpha: 1))
        bgView.backgroundColor = UIColor(white: 1,
            alpha: focused ? focusedBgAlpha : (isActiveTab ? 0.10 : 0))
    }
}

// MARK: - TVSearchShortcutButton
// Переименован: CategorySearchButton → TVSearchShortcutButton

final class TVSearchShortcutButton: TVFocusControl {

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.image       = UIImage(systemName: "magnifyingglass")
        iv.contentMode = .scaleAspectFit
        iv.tintColor   = UIColor(white: 0.45, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let label: UILabel = {
        let l = UILabel()
        l.text      = "Search"
        l.font      = UIFont.systemFont(ofSize: 24, weight: .semibold)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(iconView)
        addSubview(label)
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -18),
            label.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            label.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -12),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func applyFocusAppearance(focused: Bool) {
        let dim = UIColor(white: 0.45, alpha: 1)
        label.textColor    = focused ? .white : dim
        iconView.tintColor = focused ? .white : dim
    }
}

// MARK: - TVFocusControl
// Сохранён без изменений — базовый класс для всех кнопок

class TVFocusControl: UIControl {

    var onSelect:       (() -> Void)?
    var focusScale:     CGFloat = 1.05
    var normalBgAlpha:  CGFloat = 0
    var focusedBgAlpha: CGFloat = 0.18
    var pressedBgAlpha: CGFloat = 0.25

    let bgView: UIView = {
        let v = UIView()
        v.layer.cornerRadius       = 12
        v.layer.cornerCurve        = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(bgView)
        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        bgView.backgroundColor = UIColor(white: 1, alpha: normalBgAlpha)
    }
    required init?(coder: NSCoder) { fatalError() }

    override var canBecomeFocused: Bool { true }

    func applyFocusAppearance(focused: Bool) {}

    override func didUpdateFocus(in context: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bgView.backgroundColor = UIColor(white: 1,
                alpha: self.isFocused ? self.focusedBgAlpha : self.normalBgAlpha)
            self.transform = self.isFocused
                ? CGAffineTransform(scaleX: self.focusScale, y: self.focusScale)
                : .identity
            self.applyFocusAppearance(focused: self.isFocused)
        }, completion: nil)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesBegan(presses, with: event); return
        }
        UIView.animate(withDuration: 0.08) {
            self.bgView.backgroundColor = UIColor(white: 1, alpha: self.pressedBgAlpha)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesEnded(presses, with: event); return
        }
        UIView.animate(withDuration: 0.12) {
            self.bgView.backgroundColor = UIColor(white: 1,
                alpha: self.isFocused ? self.focusedBgAlpha : self.normalBgAlpha)
        }
        onSelect?()
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.12) {
            self.bgView.backgroundColor = UIColor(white: 1,
                alpha: self.isFocused ? self.focusedBgAlpha : self.normalBgAlpha)
        }
        super.pressesCancelled(presses, with: event)
    }
}

// MARK: - Array safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension UIColor {
    func lighter(by f: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: min(r + (1-r)*f, 1), green: min(g + (1-g)*f, 1), blue: min(b + (1-b)*f, 1), alpha: a)
    }
}
