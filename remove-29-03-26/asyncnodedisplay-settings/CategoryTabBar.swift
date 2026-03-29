import UIKit

protocol CategoryTabBarDelegate: AnyObject {
    func categoryTabBar(_ bar: CategoryTabBar, didSelect category: FilmixCategory)
    func categoryTabBar(_ bar: CategoryTabBar, didSelectGenre genre: FilmixGenre, in category: FilmixCategory)
    func categoryTabBar(_ bar: CategoryTabBar, didSubmitSearch query: String)
    func categoryTabBarDidSelectSettings(_ bar: CategoryTabBar)
}

// MARK: - CategoryTabBar

final class CategoryTabBar: UIView {

    weak var delegate: CategoryTabBarDelegate?

    // MARK: - Heights
    static let mainRowHeight:  CGFloat = 76
    static let genreRowHeight: CGFloat = 58
    static let searchRowHeight: CGFloat = 64
    static var collapsedHeight: CGFloat { mainRowHeight }
    static var expandedHeight:  CGFloat { mainRowHeight + genreRowHeight }
    static var searchExpandedHeight: CGFloat { mainRowHeight + searchRowHeight }

    private let categories = FilmixCategory.all
    private var selectedIndex = 0
    private var tabButtons: [CategoryTabButton] = []

    // Genre row state
    private var genreButtons: [GenreTabButton] = []
    private var selectedGenreIndex: Int? = nil
    private var currentGenres: [FilmixGenre] = []

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
        sv.axis = .horizontal
        sv.spacing = 6
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let settingsButton: CategorySettingsButton = {
        let b = CategorySettingsButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let searchShortcutButton: CategorySearchButton = {
        let b = CategorySearchButton()
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
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let genreStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 6
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
        v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.layer.cornerRadius = 12
        v.layer.cornerCurve = .continuous
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(white: 1, alpha: 0.12).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let searchIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iv.tintColor = UIColor(white: 0.45, alpha: 1)
        iv.contentMode = .scaleAspectFit
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
        tf.returnKeyType = .search
        tf.autocorrectionType = .no
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
        build()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build

    private func build() {
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

        // Category tab buttons
        for (i, cat) in categories.enumerated() {
            let btn = CategoryTabButton(title: cat.title, icon: cat.icon)
            btn.tag = i
            btn.isActiveTab = (i == 0)
            let index = i
            btn.onSelect = { [weak self] in
                guard let self else { return }
                if index == self.selectedIndex {
                    // Tapped active tab — deselect genre / reset search
                    if self.categories[index].isSearch {
                        self.searchTextField.text = ""
                        self.searchClearButton.isHidden = true
                    } else {
                        self.deselectGenre()
                        self.delegate?.categoryTabBar(self, didSelect: self.categories[index])
                    }
                    return
                }
                self.tabButtons[self.selectedIndex].isActiveTab = false
                self.selectedIndex = index
                self.tabButtons[index].isActiveTab = true

                let category = self.categories[index]
                if category.isSearch {
                    self.showSearchRow(animated: true)
                } else {
                    self.hideSearchRow(animated: true)
                    self.showGenres(for: category)
                    self.delegate?.categoryTabBar(self, didSelect: category)
                }
            }
            stackView.addArrangedSubview(btn)
            tabButtons.append(btn)
        }

        settingsButton.onSelect = { [weak self] in
            guard let self else { return }
            self.delegate?.categoryTabBarDidSelectSettings(self)
        }

        searchShortcutButton.onSelect = { [weak self] in
            guard let self else { return }
            self.activateSearch()
        }

        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)

        genreRowHeightConstraint = genreRow.heightAnchor.constraint(equalToConstant: 0)
        searchRowHeightConstraint = searchRow.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            // Main row
            mainRow.topAnchor.constraint(equalTo: topAnchor),
            mainRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainRow.heightAnchor.constraint(equalToConstant: Self.mainRowHeight),

            // Settings button — far left
            settingsButton.leadingAnchor.constraint(equalTo: mainRow.leadingAnchor, constant: 24),
            settingsButton.centerYAnchor.constraint(equalTo: mainRow.centerYAnchor),

            // Category tabs
            stackView.leadingAnchor.constraint(equalTo: settingsButton.trailingAnchor, constant: 20),
            stackView.centerYAnchor.constraint(equalTo: mainRow.centerYAnchor),

            // Search shortcut button — far right
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

            // Bottom separator
            separatorBottom.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorBottom.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorBottom.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorBottom.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    // MARK: - Genre Row Management

    private func showGenres(for category: FilmixCategory) {
        selectedGenreIndex = nil
        currentGenres = category.genres

        genreStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        genreButtons.removeAll()

        if category.genres.isEmpty {
            setGenreRowVisible(false, animated: true)
            return
        }

        for (i, genre) in category.genres.enumerated() {
            let btn = GenreTabButton(title: genre.title)
            btn.isActiveTab = false
            let index = i
            btn.onSelect = { [weak self] in
                guard let self else { return }
                if let prev = self.selectedGenreIndex {
                    self.genreButtons[safe: prev]?.isActiveTab = false
                }
                self.selectedGenreIndex = index
                self.genreButtons[safe: index]?.isActiveTab = true
                self.delegate?.categoryTabBar(self, didSelectGenre: self.currentGenres[index], in: self.categories[self.selectedIndex])
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

    // MARK: - Search Row Management

    private func showSearchRow(animated: Bool) {
        isSearchActive = true
        // Hide genre row first
        genreRowHeightConstraint.constant = 0
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

    // MARK: - Search actions

    @objc private func searchTextChanged() {
        let text = searchTextField.text ?? ""
        searchClearButton.isHidden = text.isEmpty
    }

    @objc private func clearSearchTapped() {
        searchTextField.text = ""
        searchClearButton.isHidden = true
        // Notify with empty to clear results
        delegate?.categoryTabBar(self, didSubmitSearch: "")
    }

    // MARK: - Programmatic selection

    func select(index: Int) {
        guard index < categories.count, index != selectedIndex else { return }
        tabButtons[selectedIndex].isActiveTab = false
        selectedIndex = index
        tabButtons[selectedIndex].isActiveTab = true
        let category = categories[index]
        if category.isSearch {
            showSearchRow(animated: false)
        } else {
            hideSearchRow(animated: false)
            showGenres(for: category)
        }
    }

    /// Called when search shortcut button (magnifying glass) is tapped
    func activateSearch() {
        // If already in search mode — just focus the text field
        if isSearchActive {
            searchTextField.becomeFirstResponder()
            return
        }
        isSearchActive = true
        tabButtons[safe: selectedIndex]?.isActiveTab = false
        genreRowHeightConstraint.constant = 0
        searchRowHeightConstraint.constant = Self.searchRowHeight

        UIView.animate(withDuration: 0.28, delay: 0,
                       usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.superview?.layoutIfNeeded()
        } completion: { _ in
            self.searchTextField.becomeFirstResponder()
        }

        // Notify delegate so RootController switches to search mode
        delegate?.categoryTabBar(self, didSelect: FilmixCategory(
            title: "Поиск", url: "", icon: "magnifyingglass", isSearch: true
        ))
    }

    var hasGenres: Bool { !currentGenres.isEmpty }
    var currentIsSearch: Bool { isSearchActive }
}

// MARK: - UITextFieldDelegate

extension CategoryTabBar: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let query = textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        textField.resignFirstResponder()
        if !query.isEmpty {
            delegate?.categoryTabBar(self, didSubmitSearch: query)
        }
        return true
    }
}
