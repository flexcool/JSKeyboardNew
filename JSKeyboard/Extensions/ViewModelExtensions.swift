import UIKit

// MARK: - DataManager 扩展：VC 可以直接访问
extension TextTabViewController {
    var manager: DataManager = DataManager.shared
}

extension ClipboardTabViewController {
    var manager: DataManager = DataManager.shared
}

extension JSTabViewController {
    var manager: DataManager = DataManager.shared
}

extension SettingsTabViewController {
    var manager: DataManager = DataManager.shared
}
