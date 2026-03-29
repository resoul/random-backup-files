import UIKit

// Минимальный кэш
class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
}

// Расширение для круглой аватарки
extension UIImage {
    func circularImage(with size: CGSize = CGSize(width: 30, height: 30),
                       borderWidth: CGFloat = 2.0,
                       borderColor: UIColor = .systemBlue) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        let rect = CGRect(origin: .zero, size: size)
        let radius = min(size.width, size.height) / 2
        
        // Круглая область
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        context.addPath(path.cgPath)
        context.clip()
        
        // Рисуем картинку
        self.draw(in: rect)
        
        // Рамка
        context.setStrokeColor(borderColor.cgColor)
        context.setLineWidth(borderWidth)
        context.addEllipse(in: rect.insetBy(dx: borderWidth/2, dy: borderWidth/2))
        context.strokePath()
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

class ExampleTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }
    
    private func setupTabs() {
        let profileVC = UIViewController()
        profileVC.view.backgroundColor = .white
        
        let settingsVC = UIViewController()
        settingsVC.view.backgroundColor = .lightGray
        
        profileVC.tabBarItem = UITabBarItem(title: "Профиль",
                                            image: UIImage(systemName: "person.circle"),
                                            tag: 0)
        
        settingsVC.tabBarItem = UITabBarItem(title: "Настройки",
                                             image: UIImage(systemName: "gear"),
                                             tag: 1)
        
        viewControllers = [profileVC, settingsVC]
        
        // Загружаем аватар
        loadAvatar(into: profileVC.tabBarItem,
                   from: "https://images.pexels.com/photos/33029498/pexels-photo-33029498.jpeg")
    }
    
    private func loadAvatar(into tabBarItem: UITabBarItem, from urlString: String) {
        // Проверка кэша
        if let cached = ImageCache.shared.object(forKey: urlString as NSString) {
            applyAvatar(cached, to: tabBarItem)
            return
        }
        
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                  let image = UIImage(data: data),
                  error == nil else { return }
            
            ImageCache.shared.setObject(image, forKey: urlString as NSString)
            
            DispatchQueue.main.async {
                self.applyAvatar(image, to: tabBarItem)
            }
        }.resume()
    }
    
    private func applyAvatar(_ image: UIImage, to tabBarItem: UITabBarItem) {
        if let circular = image.circularImage() {
            let final = circular.withRenderingMode(.alwaysOriginal)
            tabBarItem.image = final
            tabBarItem.selectedImage = final
            
            // Иногда нужно форсировать перерисовку
            tabBar.setNeedsLayout()
            tabBar.layoutIfNeeded()
        }
    }
}
