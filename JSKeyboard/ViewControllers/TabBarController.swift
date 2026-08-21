import UIKit

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }
    
    private func setupTabs() {
        let textVC = TextTabViewController()
        let clipboardVC = ClipboardTabViewController()
        let jsVC = JSTabViewController()
        let settingsVC = SettingsTabViewController()
        
        textVC.tabBarItem = UITabBarItem(title: "文本", image: UIImage(systemName: "textformat"), selectedImage: nil)
        clipboardVC.tabBarItem = UITabBarItem(title: "剪贴板", image: UIImage(systemName: "doc.on.clipboard"), selectedImage: nil)
        jsVC.tabBarItem = UITabBarItem(title: "JavaScript", image: UIImage(systemName: "curlybraces"), selectedImage: nil)
        settingsVC.tabBarItem = UITabBarItem(title: "设置", image: UIImage(systemName: "gearshape"), selectedImage: nil)
        
        viewControllers = [textVC, clipboardVC, jsVC, settingsVC]
        
        selectedIndex = 0
    }
}
