import UIKit
import Combine

class ThemeSelectionCell: UITableViewCell {
    static let identifier = "ThemeSelectionCell"
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var themeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var previewView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        bindTheme()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(previewView)
        contentView.addSubview(themeLabel)
        contentView.addSubview(checkmarkImageView)
        
        NSLayoutConstraint.activate([
            previewView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            previewView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            previewView.widthAnchor.constraint(equalToConstant: 24),
            previewView.heightAnchor.constraint(equalToConstant: 24),
            
            themeLabel.leadingAnchor.constraint(equalTo: previewView.trailingAnchor, constant: 12),
            themeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            themeLabel.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -8),
            
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func bindTheme() {
        // Используем Combine для автоматического обновления ячейки при изменении темы
        ThemeManager.shared.themePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                self?.applyTheme(theme)
            }
            .store(in: &cancellables)
    }
    
    func configure(with themeType: ThemeType, isSelected: Bool) {
        themeLabel.text = themeType.displayName
        checkmarkImageView.isHidden = !isSelected
        
        // Устанавливаем цвет preview в зависимости от темы
        switch themeType {
        case .light:
            previewView.backgroundColor = .systemBackground
            previewView.layer.borderWidth = 1
            previewView.layer.borderColor = UIColor.systemGray4.cgColor
        case .dark:
            previewView.backgroundColor = .systemGray6
            previewView.layer.borderWidth = 0
        case .custom:
            previewView.backgroundColor = UIColor.hex("343248")
            previewView.layer.borderWidth = 0
        }
    }
    
    func applyTheme(_ theme: Theme) {
//        backgroundColor = theme.backgroundColor
//        themeLabel.textColor = theme.textColor
//        checkmarkImageView.tintColor = theme.accentColor
    }
}
