import UIKit
import Combine

// MARK: - MoviesViewController

final class MoviesViewController: BaseScreenViewController<MoviesViewModel> {

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.load()

        viewModel.$movies
            .receive(on: RunLoop.main)
            .sink { [weak self] movies in
                _ = movies
            }
            .store(in: &cancellables)
    }
}

// MARK: - SeriesViewController

final class SeriesViewController: BaseScreenViewController<SeriesViewModel> {

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.load()

        viewModel.$movies
            .receive(on: RunLoop.main)
            .sink { [weak self] movies in
                _ = movies
            }
            .store(in: &cancellables)
    }
}

// MARK: - CartoonsViewController

final class CartoonsViewController: BaseScreenViewController<CartoonsViewModel> {

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.load()

        viewModel.$movies
            .receive(on: RunLoop.main)
            .sink { [weak self] movies in
                _ = movies
            }
            .store(in: &cancellables)
    }
}

// MARK: - FavoritesViewController

final class FavoritesViewController: BaseScreenViewController<FavoritesViewModel> {

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.load()

        viewModel.$movies
            .receive(on: RunLoop.main)
            .sink { [weak self] movies in
                _ = movies
            }
            .store(in: &cancellables)
    }
}

// MARK: - WatchingViewController

final class WatchingViewController: BaseScreenViewController<WatchingViewModel> {

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.load()

        viewModel.$movies
            .receive(on: RunLoop.main)
            .sink { [weak self] movies in
                _ = movies
            }
            .store(in: &cancellables)
    }
}

// MARK: - SearchViewController

final class SearchViewController: BaseScreenViewController<SearchViewModel> {

    private lazy var searchBar: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater           = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder          = "Поиск фильмов, сериалов..."
        sc.searchBar.tintColor            = Theme.Colors.accent
        return sc
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // tvOS: UISearchController встраивается через parent VC
        addChild(searchBar.searchResultsController ?? UIViewController())

        viewModel.$results
            .receive(on: RunLoop.main)
            .sink { [weak self] results in
                _ = results
                // TODO: обновить коллекцию результатов
            }
            .store(in: &cancellables)
    }
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.query = searchController.searchBar.text ?? ""
    }
}

// MARK: - SettingsViewController

final class SettingsViewController: BaseScreenViewController<SettingsViewModel> {

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.backgroundColor          = .clear
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.dataSource               = self
        tv.delegate                 = self
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let sections: [(title: String, rows: [String])] = [
        ("Источник",    ["Провайдер"]),
        ("Аккаунт",     ["Войти / Сменить аккаунт"]),
        ("О приложении", ["Версия", "Очистить кэш"]),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        var config = cell.defaultContentConfiguration()
        var row = sections[indexPath.section].rows[indexPath.row]

        // Версия — подставляем
        if row == "Версия" {
            row = "Версия \(viewModel.appVersion)"
        }

        config.text                  = row
        config.textProperties.font   = Theme.Fonts.body()
        config.textProperties.color  = Theme.Colors.textPrimary
        cell.contentConfiguration    = config
        cell.backgroundColor         = UIColor(white: 1, alpha: 0.06)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // TODO: обработать нажатия настроек
    }
}
