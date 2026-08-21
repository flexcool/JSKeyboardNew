import UIKit

// MARK: - 键盘视图委托协议
protocol JSKeyboardViewDelegate: AnyObject {
    func keyboardView(_ view: JSKeyboardView, didRequestInsertText text: String)
    func keyboardViewDidRequestDeleteBackward(_ view: JSKeyboardView)
    func keyboardViewDidRequestReturn(_ view: JSKeyboardView)
    func keyboardViewDidRequestDone(_ view: JSKeyboardView)
}

// MARK: - 数据管理器
class DataManager {
    static let shared = DataManager()
    
    var categories: [TextCategory] = []
    var clipboardEntries: [ClipboardEntry] = []
    var settings: AppSettings
    
    private init() {
        self.settings = AppSettings.load()
        loadCategories()
        loadClipboard()
    }
    
    func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: "textCategories"),
           let decoded = try? JSONDecoder().decode([TextCategory].self, from: data) {
            categories = decoded
        } else {
            categories = [
                TextCategory(name: "常用", entries: [
                    TextEntry(label: "复制代码", content: "// 复制此内容\nlet result = \"Hello World\""),
                    TextEntry(label: "占位符", content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
                ]),
                TextCategory(name: "代码片段", entries: [
                    TextEntry(label: "for循环", content: "for (let i = 0; i < items.length; i++) {\n    console.log(items[i]);\n}"),
                    TextEntry(label: "forEach", content: "items.forEach(item => {\n    // TODO\n});")
                ]),
                TextCategory(name: "快捷短语", entries: [
                    TextEntry(label: "你好", content: "你好！"),
                    TextEntry(label: "谢谢", content: "感谢你的帮助！")
                ])
            ]
            saveCategories()
        }
    }
    
    func saveCategories() {
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: "textCategories")
        }
    }
    
    func addCategory(name: String) {
        categories.append(TextCategory(name: name))
        saveCategories()
    }
    
    func deleteCategory(at index: Int) {
        guard index < categories.count else { return }
        categories.remove(at: index)
        saveCategories()
    }
    
    func addEntry(categoryIndex: Int, entry: TextEntry) {
        guard categoryIndex < categories.count else { return }
        categories[categoryIndex].entries.append(entry)
        saveCategories()
    }
    
    func deleteEntry(categoryIndex: Int, entryIndex: Int) {
        guard categoryIndex < categories.count, entryIndex < categories[categoryIndex].entries.count else { return }
        categories[categoryIndex].entries.remove(at: entryIndex)
        saveCategories()
    }
    
    func loadClipboard() {
        if let data = UserDefaults.standard.data(forKey: "clipboardEntries"),
           let decoded = try? JSONDecoder().decode([ClipboardEntry].self, from: data) {
            clipboardEntries = decoded
        }
    }
    
    func saveClipboard() {
        if let data = try? JSONEncoder().encode(clipboardEntries) {
            UserDefaults.standard.set(data, forKey: "clipboardEntries")
        }
    }
    
    func addToClipboard(text: String, label: String = "") {
        let entry = ClipboardEntry(text: text, label: label)
        clipboardEntries.insert(entry, at: 0)
        if clipboardEntries.count > settings.maxClipboardHistory {
            clipboardEntries = Array(clipboardEntries.prefix(settings.maxClipboardHistory))
        }
        saveClipboard()
    }
    
    func deleteClipboardEntry(at index: Int) {
        guard index < clipboardEntries.count else { return }
        clipboardEntries.remove(at: index)
        saveClipboard()
    }
    
    func clearClipboard() {
        clipboardEntries.removeAll()
        saveClipboard()
    }
    
    func incrementUseCount(index: Int) {
        guard index < clipboardEntries.count else { return }
        clipboardEntries[index].useCount += 1
        saveClipboard()
    }
}

// MARK: - 模型
struct TextCategory: Identifiable, Codable {
    var id = UUID()
    var name: String
    var entries: [TextEntry]
    init(name: String, entries: [TextEntry] = []) { self.name = name; self.entries = entries }
}

struct TextEntry: Identifiable, Codable {
    var id = UUID()
    var label: String
    var content: String
    init(label: String, content: String) { self.label = label; self.content = content }
}

struct ClipboardEntry: Identifiable, Codable {
    var id = UUID()
    var text: String
    var label: String
    var createdAt: Date
    var useCount: Int
    init(text: String, label: String = "") {
        self.text = text
        self.label = label.isEmpty ? String(text.prefix(30)) + (text.count > 30 ? "…" : "") : label
        self.createdAt = Date()
        self.useCount = 0
    }
}

struct JSFunction: Identifiable, Codable {
    var id = UUID()
    var name: String
    var code: String
    var hasParameter: Bool
    var parameterName: String
    var parameterDefault: String
    init(name: String, code: String, hasParameter: Bool = false, parameterName: String = "param", parameterDefault: String = "") {
        self.name = name; self.code = code; self.hasParameter = hasParameter
        self.parameterName = parameterName; self.parameterDefault = parameterDefault
    }
}

struct AppSettings: Codable {
    var fontSize: CGFloat = 16
    var soundEnabled: Bool = true
    var vibrateEnabled: Bool = true
    var autoCopyToClipboard: Bool = false
    var maxClipboardHistory: Int = 50
    var jsPredefinedFunctions: [JSFunction] = [
        JSFunction(name: "alert", code: "alert($param)", hasParameter: true, parameterName: "message", parameterDefault: "Hello"),
        JSFunction(name: "console.log", code: "console.log($param)", hasParameter: true, parameterName: "value", parameterDefault: ""),
        JSFunction(name: "getTimestamp", code: "Date.now()", hasParameter: false),
        JSFunction(name: "random", code: "Math.random()", hasParameter: false),
        JSFunction(name: "uuid", code: "crypto.randomUUID()", hasParameter: false)
    ]
    
    static let shared = AppSettings()
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "appSettings")
        }
    }
    static func load() -> AppSettings {
        if let data = UserDefaults.standard.data(forKey: "appSettings"),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return settings
        }
        return AppSettings()
    }
}

// MARK: - JSKeyboardView
class JSKeyboardView: UIView {
    
    weak var delegate: JSKeyboardViewDelegate?
    private let manager = DataManager.shared
    private var currentTab = 0
    
    private let tabButtons: [UIButton] = {
        let icons = ["textformat", "doc.on.clipboard", "curlybraces", "gearshape"]
        let titles = ["文本", "剪贴板", "JS", "设置"]
        var buttons: [UIButton] = []
        for i in 0..<4 {
            let btn = UIButton(type: .system)
            btn.setImage(UIImage(systemName: icons[i]), for: .normal)
            btn.setImage(UIImage(systemName: icons[i] + ".fill"), for: .selected)
            btn.setTitle(titles[i], for: .normal)
            btn.setTitleColor(.secondaryLabel, for: .normal)
            btn.tintColor = .systemBlue
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 10)
            btn.tag = i
            buttons.append(btn)
        }
        return buttons
    }()
    
    private let tabStackView = UIStackView()
    private let scrollView = UIScrollView()
    private let tabsContainer = UIStackView()
    private let toolbar = UIToolbar()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // Tab 栏
        tabStackView.axis = .horizontal
        tabStackView.distribution = .fillEqually
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        for btn in tabButtons {
            btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            tabStackView.addArrangedSubview(btn)
        }
        addSubview(tabStackView)
        
        // 内容区
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        tabsContainer.axis = .horizontal
        tabsContainer.distribution = .equalSpacing
        tabsContainer.spacing = 0
        tabsContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(tabsContainer)
        
        // 各 Tab 内容
        let textVC = buildTextTab()
        let clipboardVC = buildClipboardTab()
        let jsVC = buildJSTab()
        let settingsVC = buildSettingsTab()
        
        [textVC, clipboardVC, jsVC, settingsVC].forEach { tabsContainer.addArrangedSubview($0) }
        
        // 工具栏
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        let spaceBtn = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let deleteBtn = UIBarButtonItem(image: UIImage(systemName: "delete.left"), style: .plain, target: self, action: #selector(deleteTapped))
        toolbar.items = [deleteBtn, spaceBtn, doneBtn]
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toolbar)
        
        NSLayoutConstraint.activate([
            tabStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            tabStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            scrollView.topAnchor.constraint(equalTo: tabStackView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            
            tabsContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            tabsContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            tabsContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            tabsContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            tabsContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 4),
            
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
        
        showTab(0)
    }
    
    private func buildTextTab() -> UIScrollView {
        let sv = UIScrollView()
        sv.backgroundColor = .systemBackground
        let vc = TextTabViewController(manager: manager)
        vc.view.backgroundColor = .systemBackground
        sv.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: sv.topAnchor),
            vc.view.leadingAnchor.constraint(equalTo: sv.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: sv.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: sv.bottomAnchor, constant: -200),
            vc.view.widthAnchor.constraint(equalTo: sv.widthAnchor)
        ])
        vc.insertHandler = { [weak self] text in self?.delegate?.keyboardView(self!, didRequestInsertText: text) }
        return sv
    }
    
    private func buildClipboardTab() -> UIScrollView {
        let sv = UIScrollView()
        sv.backgroundColor = .systemBackground
        let vc = ClipboardTabViewController(manager: manager)
        vc.view.backgroundColor = .systemBackground
        sv.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: sv.topAnchor),
            vc.view.leadingAnchor.constraint(equalTo: sv.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: sv.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: sv.bottomAnchor, constant: -200),
            vc.view.widthAnchor.constraint(equalTo: sv.widthAnchor)
        ])
        vc.insertHandler = { [weak self] text in self?.delegate?.keyboardView(self!, didRequestInsertText: text) }
        return sv
    }
    
    private func buildJSTab() -> UIScrollView {
        let sv = UIScrollView()
        sv.backgroundColor = .systemBackground
        let vc = JSTabViewController(manager: manager)
        vc.view.backgroundColor = .systemBackground
        sv.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: sv.topAnchor),
            vc.view.leadingAnchor.constraint(equalTo: sv.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: sv.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: sv.bottomAnchor, constant: -200),
            vc.view.widthAnchor.constraint(equalTo: sv.widthAnchor)
        ])
        vc.insertHandler = { [weak self] text in self?.delegate?.keyboardView(self!, didRequestInsertText: text) }
        return sv
    }
    
    private func buildSettingsTab() -> UIScrollView {
        let sv = UIScrollView()
        sv.backgroundColor = .systemBackground
        let vc = SettingsTabViewController(manager: manager)
        vc.view.backgroundColor = .systemBackground
        sv.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: sv.topAnchor),
            vc.view.leadingAnchor.constraint(equalTo: sv.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: sv.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: sv.bottomAnchor, constant: -200),
            vc.view.widthAnchor.constraint(equalTo: sv.widthAnchor)
        ])
        return sv
    }
    
    @objc private func tabTapped(_ btn: UIButton) { showTab(btn.tag) }
    
    private func showTab(_ index: Int) {
        currentTab = index
        for (i, btn) in tabButtons.enumerated() {
            btn.isSelected = (i == index)
            btn.tintColor = i == index ? .systemBlue : .secondaryLabel
        }
        scrollView.setContentOffset(CGPoint(x: CGFloat(index) * bounds.width, y: 0), animated: false)
    }
    
    @objc private func doneTapped() { delegate?.keyboardViewDidRequestDone(self) }
    @objc private func deleteTapped() { delegate?.keyboardViewDidRequestDeleteBackward(self) }
}

// MARK: - 简化的 Tab ViewControllers
class TextTabViewController: UIViewController {
    var insertHandler: ((String) -> Void)?
    private let manager: DataManager
    
    init(manager: DataManager) { self.manager = manager; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "文本库"
        setupUI()
    }
    
    private func setupUI() {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.delegate = self; tv.dataSource = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tv)
        NSLayoutConstraint.activate([
            tv.topAnchor.constraint(equalTo: view.topAnchor),
            tv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tv.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

class ClipboardTabViewController: UIViewController {
    var insertHandler: ((String) -> Void)?
    private let manager: DataManager
    init(manager: DataManager) { self.manager = manager; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .systemBackground; title = "剪贴板"
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.delegate = self; tv.dataSource = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tv.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tv)
        NSLayoutConstraint.activate([tv.topAnchor.constraint(equalTo: view.topAnchor), tv.leadingAnchor.constraint(equalTo: view.leadingAnchor), tv.trailingAnchor.constraint(equalTo: view.trailingAnchor), tv.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }
}

class JSTabViewController: UIViewController {
    var insertHandler: ((String) -> Void)?
    private let manager: DataManager
    init(manager: DataManager) { self.manager = manager; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .systemBackground; title = "JavaScript"
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.delegate = self; tv.dataSource = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tv.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tv)
        NSLayoutConstraint.activate([tv.topAnchor.constraint(equalTo: view.topAnchor), tv.leadingAnchor.constraint(equalTo: view.leadingAnchor), tv.trailingAnchor.constraint(equalTo: view.trailingAnchor), tv.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }
}

class SettingsTabViewController: UIViewController {
    private let manager: DataManager
    init(manager: DataManager) { self.manager = manager; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .systemBackground; title = "设置"
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.delegate = self; tv.dataSource = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tv.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tv)
        NSLayoutConstraint.activate([tv.topAnchor.constraint(equalTo: view.topAnchor), tv.leadingAnchor.constraint(equalTo: view.leadingAnchor), tv.trailingAnchor.constraint(equalTo: view.trailingAnchor), tv.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }
}

// MARK: - UITableViewDataSource/Delegate (简化版)
extension TextTabViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { return manager.categories.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return manager.categories[section].entries.count }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return manager.categories[section].name }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let entry = manager.categories[indexPath.section].entries[indexPath.row]
        cell.textLabel?.text = entry.label
        cell.detailTextLabel?.text = entry.content
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        insertHandler?(manager.categories[indexPath.section].entries[indexPath.row].content)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ClipboardTabViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return manager.clipboardEntries.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let entry = manager.clipboardEntries[indexPath.row]
        cell.textLabel?.text = entry.label
        cell.detailTextLabel?.text = entry.text
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        insertHandler?(manager.clipboardEntries[indexPath.row].text)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension JSTabViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return manager.settings.jsPredefinedFunctions.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let fn = manager.settings.jsPredefinedFunctions[indexPath.row]
        cell.textLabel?.text = fn.name
        cell.detailTextLabel?.text = fn.hasParameter ? "📥 \(fn.parameterName)" : "无参数"
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fn = manager.settings.jsPredefinedFunctions[indexPath.row]
        if fn.hasParameter {
            let alert = UIAlertController(title: fn.name, message: "输入参数", preferredStyle: .alert)
            alert.addTextField { $0.text = fn.parameterDefault }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "输出", style: .default) { _ in
                let param = alert.textFields?.first?.text ?? fn.parameterDefault
                var code = fn.code.replacingOccurrences(of: "$" + fn.parameterName, with: param)
                if param.contains(" ") || param.contains("\"") { code = fn.code.replacingOccurrences(of: "$" + fn.parameterName, with: "\"\(param)\"") }
                self.insertHandler?(code)
            })
            UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows }).first(where: { $0.isKeyWindow })?.rootViewController?.present(alert, animated: true)
        } else {
            insertHandler?(fn.code)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SettingsTabViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 5 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let items: [(String, String?)] = [
            ("字体大小", "当前: \(Int(manager.settings.fontSize))"),
            ("按键音效", manager.settings.soundEnabled ? "开启" : "关闭"),
            ("按键震动", manager.settings.vibrateEnabled ? "开启" : "关闭"),
            ("自动保存剪贴板", manager.settings.autoCopyToClipboard ? "开启" : "关闭"),
            ("剪贴板历史上限", "\(manager.settings.maxClipboardHistory) 条")
        ]
        cell.textLabel?.text = items[indexPath.row].0
        cell.detailTextLabel?.text = items[indexPath.row].1
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 简单切换开关逻辑
        switch indexPath.row {
        case 1: manager.settings.soundEnabled.toggle(); manager.settings.save()
        case 2: manager.settings.vibrateEnabled.toggle(); manager.settings.save()
        case 3: manager.settings.autoCopyToClipboard.toggle(); manager.settings.save()
        default: break
        }
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}
