import UIKit

class SettingsTabViewController: UIViewController {
    
    private let manager = DataManager.shared
    private var settings: AppSettings {
        get { manager.settings }
        set { manager.settings = newValue; newValue.save() }
    }
    
    // 表格数据源
    private struct SettingItem {
        let title: String
        let subtitle: String?
        let type: SettingType
    }
    
    private enum SettingType {
        case toggle(String, DefaultValue: Bool)
        case segmented(String, items: [String], selected: Int)
        case stepper(String, min: Int, max: Int, value: Int)
    }
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var items: [SettingItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "设置"
        view.backgroundColor = .systemBackground
        setupTableView()
        buildItems()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
    }
    
    private func buildItems() {
        items = [
            // 字体
            SettingItem(title: "字体大小", subtitle: nil, type: .stepper("fontSize", min: 12, max: 24, value: Int(settings.fontSize))),
            // 剪贴板
            SettingItem(title: "自动保存剪贴板", subtitle: nil, type: .toggle("autoCopy", DefaultValue: settings.autoCopyToClipboard)),
            SettingItem(title: "剪贴板历史上限", subtitle: "\(settings.maxClipboardHistory) 条", type: .stepper("maxClipboard", min: 10, max: 200, value: settings.maxClipboardHistory)),
            // 交互
            SettingItem(title: "按键音效", subtitle: nil, type: .toggle("sound", DefaultValue: settings.soundEnabled)),
            SettingItem(title: "按键震动", subtitle: nil, type: .toggle("vibrate", DefaultValue: settings.vibrateEnabled)),
            // 数据管理
            SettingItem(title: "清空剪贴板历史", subtitle: "清除所有记录", type: .custom("clear")),
        ]
    }
    
    // MARK: - 动作
    @objc private func toggleChanged(_ sender: UISwitch) {
        // 通过 tag 判断
        if let tag = sender.tag, let item = items[tag] {
            switch item.type {
            case .toggle(let key, _):
                if key == "autoCopy" { settings.autoCopyToClipboard = sender.isOn }
                if key == "sound" { settings.soundEnabled = sender.isOn }
                if key == "vibrate" { settings.vibrateEnabled = sender.isOn }
            default: break
            }
            settings.save()
        }
    }
    
    @objc private func stepperChanged(_ sender: UIStepper) {
        if let tag = sender.tag, let item = items[tag] {
            let value = Int(sender.value)
            switch item.type {
            case .stepper(let key, _, _, _):
                if key == "fontSize" {
                    settings.fontSize = CGFloat(value)
                    tableView.reloadRows(at: [IndexPath(row: tag, section: 0)], with: .none)
                }
                if key == "maxClipboard" {
                    settings.maxClipboardHistory = value
                    tableView.reloadRows(at: [IndexPath(row: tag, section: 0)], with: .none)
                }
            default: break
            }
            settings.save()
        }
    }
    
    @objc private func clearClipboardHistory() {
        DataManager.shared.clearClipboard()
        let alert = UIAlertController(title: "已清空", message: "剪贴板历史已全部删除", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension SettingsTabViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1  // 字体
        case 1: return 3  // 剪贴板
        case 2: return 2  // 交互
        case 3: return 1  // 数据管理
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "外观"
        case 1: return "剪贴板"
        case 2: return "交互"
        case 3: return "数据管理"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        let item = items[indexPath.row]
        
        // 重新组装 items 的 flat 索引映射到 section+row
        let flatIndex = indexPath.row // 每个 section 只有一个 item 或固定数量
        cell.accessoryView = nil
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.subtitle
        
        // 根据 indexPath 找到对应的 item（通过重算 flat index）
        // 这里简化处理：直接在 cellForRowAt 中根据 section+row 构造
        let fullItem = getFullItem(at: indexPath)
        cell.textLabel?.text = fullItem.title
        cell.detailTextLabel?.text = fullItem.subtitle
        
        switch fullItem.type {
        case .toggle(_, let defaultValue):
            let sw = UISwitch()
            sw.isOn = defaultValue
            sw.tag = getItemFlatIndex(at: indexPath)
            sw.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
            cell.accessoryView = sw
            
        case .stepper(_, let min, let max, let value):
            let stepper = UIStepper()
            stepper.minimumValue = Double(min)
            stepper.maximumValue = Double(max)
            stepper.value = Double(value)
            stepper.tag = getItemFlatIndex(at: indexPath)
            stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
            cell.accessoryView = stepper
            
        case .custom(let action):
            if action == "clear" {
                cell.textLabel?.textColor = .systemRed
                let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
                arrow.tintColor = .systemRed
                cell.accessoryView = arrow
            }
        }
        
        return cell
    }
    
    func getFullItem(at indexPath: IndexPath) -> SettingItem {
        // 将 section+row 映射回 flat items 数组
        var flatIndex = 0
        for section in 0..<4 {
            let count: Int
            switch section {
            case 0: count = 1
            case 1: count = 3
            case 2: count = 2
            case 3: count = 1
            default: count = 0
            }
            if indexPath.section == section {
                return items[flatIndex + indexPath.row]
            }
            flatIndex += count
        }
        return items[0]
    }
    
    func getItemFlatIndex(at indexPath: IndexPath) -> Int {
        var flatIndex = 0
        for section in 0..<indexPath.section {
            let count: Int
            switch section {
            case 0: count = 1
            case 1: count = 3
            case 2: count = 2
            case 3: count = 1
            default: count = 0
            }
            flatIndex += count
        }
        return flatIndex + indexPath.row
    }
}

// MARK: - UITableViewDelegate
extension SettingsTabViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[getItemFlatIndex(at: indexPath)]
        if case .custom(let action) = item.type, action == "clear" {
            clearClipboardHistory()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
