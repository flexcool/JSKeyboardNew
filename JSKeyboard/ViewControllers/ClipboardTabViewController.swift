import UIKit

class ClipboardTabViewController: UIViewController {
    
    private let manager = DataManager.shared
    private var entries: [ClipboardEntry] { manager.clipboardEntries }
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        btn.tintColor = .systemBlue
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    private let clearButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("清空", for: .normal)
        btn.setTitleColor(.systemRed, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "剪贴板"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: refreshButton),
            UIBarButtonItem(customView: clearButton)
        ]
        
        setupTableView()
        setupActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        updateClearButton()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ClipboardCell.self, forCellReuseIdentifier: "ClipboardCell")
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .systemBackground
    }
    
    private func setupActions() {
        refreshButton.addTarget(self, action: #selector(refreshClipboard), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearAll), for: .touchUpInside)
        
        // 监听剪贴板变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onPasteboardChanged),
            name: UIPasteboard.changedNotification,
            object: nil
        )
    }
    
    @objc private func refreshClipboard() {
        tableView.reloadData()
    }
    
    @objc private func clearAll() {
        let alert = UIAlertController(title: "清空剪贴板", message: "确定要删除所有历史记录吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清空", style: .destructive) { _ in
            self.manager.clearClipboard()
            self.tableView.reloadData()
            self.updateClearButton()
        })
        present(alert, animated: true)
    }
    
    @objc private func onPasteboardChanged() {
        // 如果设置了自动保存，则检测新内容
        if DataManager.shared.settings.autoCopyToClipboard {
            if let text = UIPasteboard.general.string, !text.isEmpty {
                manager.addToClipboard(text: text)
                tableView.reloadData()
            }
        }
    }
    
    private func updateClearButton() {
        clearButton.isEnabled = !entries.isEmpty
    }
    
    // 输出到键盘
    func insertText(_ text: String) {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let keyboardVC = scene.windows.first?.rootViewController?.presentedViewController as? KeyboardViewController {
            keyboardVC.insertText(text)
        }
    }
}

// MARK: - UITableViewDataSource
extension ClipboardTabViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ClipboardCell", for: indexPath) as! ClipboardCell
        let entry = entries[indexPath.row]
        cell.configure(text: entry.text, label: entry.label, date: entry.createdAt, count: entry.useCount)
        return cell
    }
    
    func tableView(_ tableView: UITableView, commitEditingStyle forRowAt indexPath: IndexPath) {
        manager.deleteClipboardEntry(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
}

// MARK: - UITableViewDelegate
extension ClipboardTabViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry = entries[indexPath.row]
        insertText(entry.text)
        manager.incrementUseCount(index: indexPath.row)
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { _, _, completionHandler in
            self.manager.deleteClipboardEntry(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - Cell
class ClipboardCell: UITableViewCell {
    private let iconLabel = UILabel()
    private let contentLabel = UILabel()
    private let metaLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        
        iconLabel.text = "📋"
        iconLabel.font = UIFont.systemFont(ofSize: 20)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentLabel.font = UIFont.monospacedSystemFont(ofSize: 13)
        contentLabel.textColor = .label
        contentLabel.numberOfLines = 2
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        metaLabel.font = UIFont.systemFont(ofSize: 11)
        metaLabel.textColor = .secondaryLabel
        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView(arrangedSubviews: [contentLabel, metaLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let rowStack = UIStackView(arrangedSubviews: [iconLabel, stack])
        rowStack.axis = .horizontal
        rowStack.spacing = 12
        rowStack.alignment = .center
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(text: String, label: String, date: Date, count: Int) {
        contentLabel.text = text
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeStr = formatter.string(from: date)
        metaLabel.text = "\(label)  ·  \(timeStr)  ·  ×\(count)"
    }
}
