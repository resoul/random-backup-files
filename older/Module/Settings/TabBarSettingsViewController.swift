import UIKit
import Combine

class TabBarSettingsViewController: UIViewController, BaseController {
    var coordinator: MainCoordinator?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let previewTabBar = UITabBar()
    private let previewContainer = UIView()
    
    private let tabBarManager = TabBarManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupConstraints()
        setupBindings()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Проверяем несохраненные изменения при выходе
        if tabBarManager.hasUnsavedChanges() {
            showUnsavedChangesAlert()
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Tab Bar Settings"
        
        // Navigation bar - добавляем Save кнопку
        let saveButton = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveChanges)
        )
        
        let resetButton = UIBarButtonItem(
            title: "Reset",
            style: .plain,
            target: self,
            action: #selector(resetToDefault)
        )
        
        navigationItem.rightBarButtonItems = [saveButton, resetButton]
        
        // Кнопка Cancel слева
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelChanges)
        )
        
        // Preview container
        previewContainer.backgroundColor = .secondarySystemBackground
        previewContainer.layer.cornerRadius = 12
        previewContainer.layer.shadowColor = UIColor.black.cgColor
        previewContainer.layer.shadowOpacity = 0.1
        previewContainer.layer.shadowOffset = CGSize(width: 0, height: -2)
        previewContainer.layer.shadowRadius = 8
        
        // Preview tab bar
        previewTabBar.backgroundColor = .systemBackground
        previewTabBar.layer.cornerRadius = 8
        previewTabBar.clipsToBounds = true
        
        view.addSubview(previewContainer)
        view.addSubview(tableView)
        previewContainer.addSubview(previewTabBar)
        
        updateSaveButtonState()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isEditing = true
        tableView.allowsSelectionDuringEditing = false
        
        // Регистрация ячейки
        tableView.register(TabSettingsCell.self, forCellReuseIdentifier: "TabSettingsCell")
        
        // Заголовки секций
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 44
    }
    
    private func setupConstraints() {
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewTabBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Preview container
            previewContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            previewContainer.heightAnchor.constraint(equalToConstant: 100),
            
            // Preview tab bar
            previewTabBar.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            previewTabBar.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor),
            previewTabBar.widthAnchor.constraint(equalTo: previewContainer.widthAnchor, multiplier: 0.9),
            previewTabBar.heightAnchor.constraint(equalToConstant: 49),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        // Обновление таблицы при изменении табов
        tabBarManager.allTabsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
                self?.updateSaveButtonState()
            }
            .store(in: &cancellables)
        
        // Обновление preview (только локальный preview, не основной __TabBar)
        tabBarManager.enabledTabsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tabs in
                self?.updatePreviewTabBar(with: tabs)
            }
            .store(in: &cancellables)
    }
    
    private func updateSaveButtonState() {
        let hasChanges = tabBarManager.hasUnsavedChanges()
        navigationItem.rightBarButtonItems?.first?.isEnabled = hasChanges
        
        // Визуальная индикация несохраненных изменений
        if hasChanges {
            title = "Tab Bar Settings *"
        } else {
            title = "Tab Bar Settings"
        }
    }
    
    @objc private func saveChanges() {
        tabBarManager.saveAndApplyChanges()
        updateSaveButtonState()
        
        // Показываем успешное сохранение
        let alert = UIAlertController(
            title: "Saved",
            message: "Tab bar settings have been applied successfully.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func cancelChanges() {
        if tabBarManager.hasUnsavedChanges() {
            showUnsavedChangesAlert()
        } else {
            coordinator?.didCoordinatorFinisn()
        }
    }
    
    private func showUnsavedChangesAlert() {
        let alert = UIAlertController(
            title: "Unsaved Changes",
            message: "You have unsaved changes. What would you like to do?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            self.tabBarManager.saveAndApplyChanges()
            self.navigationController?.popViewController(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in
            self.tabBarManager.discardChanges()
            self.navigationController?.popViewController(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func resetToDefault() {
        let alert = UIAlertController(
            title: "Reset to Default",
            message: "This will reset all tab bar settings to default. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            self.tabBarManager.resetToDefault()
            self.updateSaveButtonState()
        })
        
        present(alert, animated: true)
    }
    
    private func updatePreviewTabBar(with tabs: [TabItem]) {
        previewTabBar.items = tabs.map { tab in
            UITabBarItem(
                title: tab.title,
                image: UIImage(systemName: tab.icon),
                selectedImage: UIImage(systemName: tab.icon + ".fill")
            )
        }
        
        // Анимация обновления
        UIView.transition(with: previewTabBar, duration: 0.3, options: .transitionCrossDissolve) {
            self.previewTabBar.layoutIfNeeded()
        }
    }
}

// MARK: - Table View Data Source & Delegate
extension TabBarSettingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return tabBarManager.enabledTabs.count
        case 1:
            return tabBarManager.allTabs.filter { !$0.isEnabled }.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Active Tabs (\(tabBarManager.enabledTabs.count))"
        case 1:
            return "Available Tabs (\(tabBarManager.allTabs.filter { !$0.isEnabled }.count))"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TabSettingsCell", for: indexPath) as? TabSettingsCell else {
            return UITableViewCell()
        }
        
        let tab: TabItem
        switch indexPath.section {
        case 0:
            tab = tabBarManager.enabledTabs[indexPath.row]
        case 1:
            let disabledTabs = tabBarManager.allTabs.filter { !$0.isEnabled }
            tab = disabledTabs[indexPath.row]
        default:
            return cell
        }
        
        cell.configure(with: tab)
        cell.onToggle = { [weak self] updatedTab, _ in
            self?.tabBarManager.updateTab(updatedTab)
        }
        
        return cell
    }
    
    // MARK: - Reordering
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 // Только активные табы можно сортировать
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Перемещение только внутри секции активных табов
        guard sourceIndexPath.section == 0 && destinationIndexPath.section == 0 else { return }
        
        // Находим индексы в общем массиве
        let sourceTabs = tabBarManager.enabledTabs
        let sourceTab = sourceTabs[sourceIndexPath.row]
        let destinationTab = sourceTabs[destinationIndexPath.row]
        
        guard let sourceGlobalIndex = tabBarManager.allTabs.firstIndex(where: { $0.id == sourceTab.id }),
              let destinationGlobalIndex = tabBarManager.allTabs.firstIndex(where: { $0.id == destinationTab.id }) else {
            return
        }
        
        tabBarManager.moveTab(from: sourceGlobalIndex, to: destinationGlobalIndex)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none // Отключаем удаление, только сортировка
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
