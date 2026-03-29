import UIKit
import Combine

class SettingsViewController: BaseThemeableViewController, BaseController {
    var coordinator: MainCoordinator?
    
    private let themeManager = ThemeManager.shared
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ThemeSelectionCell.self, forCellReuseIdentifier: ThemeSelectionCell.identifier)
        return tableView
    }()
    
    private let themes = ThemeType.allCases
    private var selectedTheme: ThemeType = .light
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        selectedTheme = themeManager.currentTheme.type
        
        showCustomAlert(
            title: "Delete chat",
            message: "Are you sure you want to delete all message history with Maryna Ostrovska?",
//            warningText: "This action cannot be undone.",
//            checkboxText: "Also delete for Maryna",
            cancelTitle: "Cancel",
            destructiveTitle: "Delete"
        ) {
            // Cancel action
            print("Cancelled")
        } destructiveAction: {
            // Delete action
            print("Deleted")
        }
    }
    
    private func setupUI() {
        title = "Settings"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // Переопределяем метод применения темы
    override func applyTheme(_ theme: Theme) {
        super.applyTheme(theme)
        
        // Дополнительные настройки для Settings
//        tableView.backgroundColor = theme.backgroundColor
//        tableView.separatorColor = theme.separatorColor
        tableView.reloadData()
    }
    
    @objc private func saveButtonTapped() {
        themeManager.setTheme(selectedTheme)
        
        // Показываем индикатор успешного сохранения
        let alert = UIAlertController(
            title: "Theme Saved",
            message: "Your theme preference has been saved successfully.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableView DataSource & Delegate
extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return themes.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Theme Selection"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ThemeSelectionCell.identifier, for: indexPath) as! ThemeSelectionCell
        let theme = themes[indexPath.row]
        let isSelected = theme == selectedTheme
        cell.configure(with: theme, isSelected: isSelected)
        cell.applyTheme(themeManager.currentTheme)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedTheme = themes[indexPath.row]
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
