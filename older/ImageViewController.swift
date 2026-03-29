import UIKit

class ImageViewController: UIViewController {
    
    private var imageView: UIImageView!
    private var imageViewCenterYConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        setupImageView()
    }
    
    private func setupImageView() {
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.isUserInteractionEnabled = true
        
        // Добавляем изображение (замените на ваше)
        imageView.backgroundColor = .systemGray3
        imageView.image = UIImage(systemName: "photo.fill")?.withTintColor(.systemGray, renderingMode: .alwaysOriginal)
        
        view.addSubview(imageView)
        
        // Констрейнты для изображения
        imageViewCenterYConstraint = imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            imageViewCenterYConstraint
        ])
        
        // Настройка контекстного меню
        setupContextMenu()
    }
    
    private func setupContextMenu() {
        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        imageView.addInteraction(contextMenuInteraction)
    }
    
    // MARK: - Preview Creation
    private func createPreview(for interaction: UIContextMenuInteraction) -> UITargetedPreview {
        // Создаем параметры для preview
        let previewParameters = UIPreviewParameters()
        
        // Устанавливаем цвет фона preview (прозрачный для красивого эффекта)
        previewParameters.backgroundColor = .clear
        
        // Создаем путь с закругленными углами для preview
        let cornerRadius: CGFloat = 16
        let path = UIBezierPath(roundedRect: imageView.bounds, cornerRadius: cornerRadius)
        previewParameters.visiblePath = path
        
        // Устанавливаем тень для preview
        previewParameters.shadowPath = path
        
        // Создаем целевой preview
        let target = UIPreviewTarget(container: view, center: imageView.center)
        
        return UITargetedPreview(view: imageView, parameters: previewParameters, target: target)
    }
    
    private func createDismissalPreview(for interaction: UIContextMenuInteraction) -> UITargetedPreview {
        // Создаем параметры для анимации закрытия
        let previewParameters = UIPreviewParameters()
        previewParameters.backgroundColor = .clear
        
        // Можем изменить форму при закрытии
        let cornerRadius: CGFloat = 12
        let path = UIBezierPath(roundedRect: imageView.bounds, cornerRadius: cornerRadius)
        previewParameters.visiblePath = path
        
        // Целевая позиция для анимации закрытия
        let target = UIPreviewTarget(container: view, center: imageView.center)
        
        return UITargetedPreview(view: imageView, parameters: previewParameters, target: target)
    }
    
    // MARK: - Actions
    private func starAction() {
        print("Star action")
        showToast(message: "Added to favorites")
    }
    
    private func renameAction() {
        print("Rename action")
        presentRenameAlert()
    }
    
    private func deleteAction() {
        print("Delete action")
        presentDeleteAlert()
    }
    
    // MARK: - Helper Methods
    private func presentRenameAlert() {
        let alert = UIAlertController(title: "Rename", message: "Enter a new name", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "New name"
        }
        
        let renameAction = UIAlertAction(title: "Rename", style: .default) { _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                print("New name: \(newName)")
                self.showToast(message: "Renamed to '\(newName)'")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(renameAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func presentDeleteAlert() {
        let alert = UIAlertController(
            title: "Delete Image",
            message: "Are you sure you want to delete this image?",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            print("Image deleted")
            self.showToast(message: "Image deleted")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textColor = .white
        toastLabel.font = UIFont.systemFont(ofSize: 16)
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 8
        toastLabel.clipsToBounds = true
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toastLabel)
        
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            toastLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            toastLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, animations: {
                toastLabel.alpha = 0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}

// MARK: - UIContextMenuInteractionDelegate
extension ImageViewController: UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: {
                // Можно вернуть кастомный preview controller
                return self.createPreviewController()
            }
        ) { _ in
            
            let starAction = UIAction(
                title: "Star",
                image: UIImage(systemName: "star")
            ) { [weak self] _ in
                self?.starAction()
            }
            
            let renameAction = UIAction(
                title: "Rename",
                image: UIImage(systemName: "pencil")
            ) { [weak self] _ in
                self?.renameAction()
            }
            
            let shareAction = UIAction(
                title: "Share",
                image: UIImage(systemName: "square.and.arrow.up")
            ) { [weak self] _ in
                self?.shareAction()
            }
            
            let deleteAction = UIAction(
                title: "Delete",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.deleteAction()
            }
            
            // Группируем действия
            let editActions = UIMenu(title: "Edit", options: .displayInline, children: [renameAction])
            let shareActions = UIMenu(title: "Share", options: .displayInline, children: [shareAction])
            let dangerActions = UIMenu(title: "Danger", options: .displayInline, children: [deleteAction])
            
            return UIMenu(title: "", children: [starAction, editActions, shareActions, dangerActions])
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return createPreview(for: interaction)
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return createDismissalPreview(for: interaction)
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        
        // Добавляем кастомную анимацию при появлении меню
        animator?.addAnimations { [weak self] in
            // Сдвигаем изображение вверх
            self?.imageViewCenterYConstraint.constant = -80
            self?.view.layoutIfNeeded()
            
            // Можно добавить дополнительные эффекты
            self?.imageView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            
            // Добавляем легкое затемнение фона
            self?.view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        }
        
        // Добавляем completion блок
        animator?.addCompletion { [weak self] in
            print("Context menu fully displayed")
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        
        // Анимация при закрытии меню
        animator?.addAnimations { [weak self] in
            // Возвращаем изображение в центр
            self?.imageViewCenterYConstraint.constant = 0
            self?.view.layoutIfNeeded()
            
            // Убираем трансформацию
            self?.imageView.transform = .identity
            
            // Возвращаем исходный цвет фона
            self?.view.backgroundColor = .systemBackground
        }
        
        animator?.addCompletion { [weak self] in
            print("Context menu fully dismissed")
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        
        // Действие при нажатии на preview
        animator.addAnimations { [weak self] in
            // Можно добавить анимацию перехода к детальному просмотру
            self?.showDetailedImageView()
        }
    }
    
    // MARK: - Preview Controller
    private func createPreviewController() -> UIViewController? {
        let previewController = ImagePreviewViewController()
        previewController.image = imageView.image
        previewController.preferredContentSize = CGSize(width: 300, height: 400)
        return previewController
    }
    
    private func shareAction() {
        guard let image = imageView.image else { return }
        
        let activityController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        // Для iPad
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = imageView
            popover.sourceRect = imageView.bounds
        }
        
        present(activityController, animated: true)
    }
    
    private func showDetailedImageView() {
        let detailController = DetailedImageViewController()
        detailController.image = imageView.image
        detailController.modalPresentationStyle = .fullScreen
        present(detailController, animated: true)
    }
}

// MARK: - Preview Controller
class ImagePreviewViewController: UIViewController {
    
    var image: UIImage?
    private var imageView: UIImageView!
    private var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Title
        titleLabel = UILabel()
        titleLabel.text = "Image Preview"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Image
        imageView = UIImageView()
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
    }
}

// MARK: - Detailed View Controller
class DetailedImageViewController: UIViewController {
    
    var image: UIImage?
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Scroll view для зума
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView = UIImageView()
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])
        
        // Жест для закрытия
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissView() {
        dismiss(animated: true)
    }
}

extension DetailedImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
