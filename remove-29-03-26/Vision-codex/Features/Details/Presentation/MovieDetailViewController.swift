import UIKit

final class MovieDetailViewController: BaseDetailViewController {

    private var translations: [FilmixTranslation] = []
    private var activeTranslation: FilmixTranslation?
    private var translationRowViews: [MovieTranslationRow] = []
    private let translationsViewModel: MovieTranslationsViewModel
    private let qualityPreferenceRepository: QualityPreferenceRepository

    // MARK: - Panel views

    private let panelDivider: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let controlBar: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private lazy var studioPicker: StudioPickerButton = {
        let b = StudioPickerButton(accentColor: movie.accentColor.lighter(by: 0.5))
        b.onTap = { [weak self] in self?.showStudioPicker() }
        return b
    }()

    private let translationsSpinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = UIColor(white: 0.5, alpha: 1); v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private lazy var qualityButton: QualityPreferenceButton = {
        let b = QualityPreferenceButton()
        b.configure(quality: qualityPreferenceRepository.globalPreferredQuality)
        b.onTap = { [weak self] in self?.showQualityPicker() }
        return b
    }()

    private let tabSeparator: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.07)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let translationsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 8; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "Нет доступных озвучек"
        l.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        l.textColor = UIColor(white: 0.35, alpha: 1)
        l.textAlignment = .center
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    init(
        movie: Movie,
        loadMovieDetailUseCase: LoadMovieDetailUseCaseProtocol = AppDIContainer.shared.makeLoadMovieDetailUseCase(),
        translationsViewModel: MovieTranslationsViewModel = AppDIContainer.shared.makeMovieTranslationsViewModel(),
        qualityPreferenceRepository: QualityPreferenceRepository = AppDIContainer.shared.makeQualityPreferenceRepository()
    ) {
        self.translationsViewModel = translationsViewModel
        self.qualityPreferenceRepository = qualityPreferenceRepository
        super.init(movie: movie, loadMovieDetailUseCase: loadMovieDetailUseCase)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        buildMovieLayout()
        qualityButton.configure(quality: qualityPreferenceRepository.globalPreferredQuality)
    }

    // MARK: - Layout

    private func buildMovieLayout() {
        contentView.addSubview(panelDivider)
        contentView.addSubview(controlBar)
        controlBar.addSubview(studioPicker)
        controlBar.addSubview(translationsSpinner)
        controlBar.addSubview(qualityButton)
        contentView.addSubview(tabSeparator)
        contentView.addSubview(translationsStack)
        contentView.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            panelDivider.topAnchor.constraint(equalTo: myListBtn.bottomAnchor, constant: 28),
            panelDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            panelDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),
            panelDivider.heightAnchor.constraint(equalToConstant: 1),

            controlBar.topAnchor.constraint(equalTo: panelDivider.bottomAnchor, constant: 20),
            controlBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            controlBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),
            controlBar.heightAnchor.constraint(equalToConstant: 54),

            studioPicker.leadingAnchor.constraint(equalTo: controlBar.leadingAnchor),
            studioPicker.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),

            translationsSpinner.leadingAnchor.constraint(equalTo: studioPicker.trailingAnchor, constant: 16),
            translationsSpinner.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),

            qualityButton.trailingAnchor.constraint(equalTo: controlBar.trailingAnchor),
            qualityButton.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),

            tabSeparator.topAnchor.constraint(equalTo: controlBar.bottomAnchor, constant: 12),
            tabSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            tabSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),
            tabSeparator.heightAnchor.constraint(equalToConstant: 1),

            translationsStack.topAnchor.constraint(equalTo: tabSeparator.bottomAnchor, constant: 12),
            translationsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset - 4),
            translationsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -(hInset - 4)),
            translationsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -60),

            emptyLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: tabSeparator.bottomAnchor, constant: 60),
        ])
    }
    
    override func onDetailLoaded(_ detail: FilmixDetail) {
        if detail.isNotMovie {
            translationsSpinner.stopAnimating()
            emptyLabel.text = "Видео недоступно"
            emptyLabel.isHidden = false
        } else {
            fetchTranslations()
        }
    }

    private func fetchTranslations() {
        translationsViewModel.load(movieId: movie.id)
    }

    private func bindViewModel() {
        translationsViewModel.onStateDidChange = { [weak self] state in
            self?.applyTranslationsState(state)
        }
    }

    private func applyTranslationsState(_ state: MovieTranslationsState) {
        if state.isLoading {
            translationsSpinner.startAnimating()
        } else {
            translationsSpinner.stopAnimating()
        }

        translations = state.translations
        activeTranslation = state.activeTranslation

        if let studio = state.activeTranslation?.studio {
            studioPicker.configure(studio: studio)
            buildRows()
        } else {
            emptyLabel.isHidden = !state.hasErrorOrEmpty
        }
    }

    private func buildRows() {
        translationsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        translationRowViews.removeAll()
        emptyLabel.isHidden = true

        guard let t = activeTranslation else { emptyLabel.isHidden = false; return }

        let preferredQuality = qualityPreferenceRepository.globalPreferredQuality
        let order = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]

        if let preferred = preferredQuality, let url = t.streams[preferred] {
            addRow(studio: t.studio, quality: preferred, url: url, accentColor: movie.accentColor.lighter(by: 0.5))
        } else {
            let qualities = order.filter { t.streams[$0] != nil }
            if qualities.isEmpty { emptyLabel.isHidden = false; return }
            for quality in qualities {
                guard let url = t.streams[quality] else { continue }
                addRow(studio: t.studio, quality: quality, url: url, accentColor: movie.accentColor.lighter(by: 0.5))
            }
        }
    }

    private func addRow(studio: String, quality: String, url: String, accentColor: UIColor) {
        let row = MovieTranslationRow(studio: studio, quality: quality, accentColor: accentColor)
        row.onPlay = { [weak self] in
            self?.playMovie(url: url, title: self?.movie.title ?? "",
                            studio: studio, quality: quality)
        }
        translationsStack.addArrangedSubview(row)
        translationRowViews.append(row)
    }

    // MARK: - Studio Picker

    private func showStudioPicker() {
        guard !translations.isEmpty else { return }
        let picker = StudioListViewController(
            translations: translations,
            activeStudio: activeTranslation?.studio ?? "",
            accentColor: movie.accentColor.lighter(by: 0.5)
        )
        picker.onSelect = { [weak self] translation in
            guard let self else { return }
            self.translationsViewModel.select(translation: translation)
        }
        present(picker, animated: true)
    }
    
    private func showQualityPicker() {
        let qualities = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]
        let current = qualityPreferenceRepository.globalPreferredQuality

        var items: [PickerViewController.Item] = [
            .init(primary: "Авто", secondary: "Лучшее доступное", isSelected: current == nil)
        ]
        items += qualities.map { q in
            .init(primary: q, secondary: nil, isSelected: q == current)
        }

        let picker = PickerViewController(title: "Качество по умолчанию", items: items)
        picker.onSelect = { [weak self] index in
            guard let self else { return }
            let selected = index == 0 ? nil : qualities[index - 1]
            self.qualityPreferenceRepository.globalPreferredQuality = selected
            self.qualityButton.configure(quality: selected)
            self.buildRows()
        }
        present(picker, animated: true)
    }
}
