import UIKit

class TabSettingsCell: UITableViewCell {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let enableSwitch = UISwitch()
    private let dragHandle = UIImageView()
    
    private var tabItem: TabItem?
    var onToggle: ((TabItem, Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(enableSwitch)
        contentView.addSubview(dragHandle)
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue
        
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = .label
        
        enableSwitch.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        
        dragHandle.image = UIImage(systemName: "line.3.horizontal")
        dragHandle.tintColor = .systemGray3
        dragHandle.contentMode = .scaleAspectFit
        
        // Отключаем автовыбор
        selectionStyle = .none
    }
    
    private func setupConstraints() {
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        enableSwitch.translatesAutoresizingMaskIntoConstraints = false
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Icon
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Title
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: enableSwitch.leadingAnchor, constant: -12),
            
            // Switch
            enableSwitch.trailingAnchor.constraint(equalTo: dragHandle.leadingAnchor, constant: -12),
            enableSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // Drag handle
            dragHandle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dragHandle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dragHandle.widthAnchor.constraint(equalToConstant: 20),
            dragHandle.heightAnchor.constraint(equalToConstant: 20),
            
            // Cell height
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }
    
    func configure(with tab: TabItem) {
        self.tabItem = tab
        
        iconImageView.image = UIImage(systemName: tab.icon)
        titleLabel.text = tab.title
        enableSwitch.isOn = tab.isEnabled
        
        // Визуальное состояние в зависимости от enabled
        updateVisualState(enabled: tab.isEnabled)
    }
    
    private func updateVisualState(enabled: Bool) {
        alpha = enabled ? 1.0 : 0.6
        titleLabel.textColor = enabled ? .label : .secondaryLabel
        iconImageView.tintColor = enabled ? .systemBlue : .systemGray3
    }
    
    @objc private func switchToggled() {
        guard var tab = tabItem else { return }
        tab.isEnabled = enableSwitch.isOn
        self.tabItem = tab
        
        // Обновляем визуальное состояние с анимацией
        UIView.animate(withDuration: 0.2) {
            self.updateVisualState(enabled: tab.isEnabled)
        }
        
        onToggle?(tab, enableSwitch.isOn)
    }
}
