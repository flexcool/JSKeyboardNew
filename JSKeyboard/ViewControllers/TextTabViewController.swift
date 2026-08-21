import UIKit

class TextTabViewController: UIViewController {
    
    private let manager = DataManager.shared
    private var categories: [TextCategory] { manager.categories }
    
    // UI Components
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let addButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("添加分类", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.layer.cornerRadius = 8
        btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "文本库"
        view.backgroundColor = .systemBackground
        setupUI()
        setupTableView()
        setupActions()
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -16),
            
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CategoryCell.self, forCellReuseIdentifier: "CategoryCell")
        tableView.register(TextEntryCell.self, forCellReuseIdentifier: "TextEntryCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
    }
    
    private func setupActions() {
        addButton.addTarget(self, action: #selector(showAddCategory), for: .touchUpInside)
    }
    
    @objc private func showAddCategory() {
        let alert = UIAlertController(title: "新建分类", message: "请输入分类名称", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "分类名称" }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            if let name = alert.textFields?.first?.text, !name.isEmpty {
                self.manager.addCategory(name: name)
                self.tableView.reloadData()
            }
        })
        present(alert, animated: true)
    }
    
    // 输出到键盘
    func insertText(_ text: String) {
        if let keyboardVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController?
            .presentedViewController as? KeyboardViewController {
            keyboardVC.insertText(text)
        }
    }
}

// MARK: - UITableViewDataSource
extension TextTabViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories[section].entries.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return categories[section].name
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextEntryCell", for: indexPath) as! TextEntryCell
        let entry = categories[indexPath.section].entries[indexPath.row]
        cell.label.text = entry.label
        cell.contentLabel.text = entry.content
        return cell
    }
    
    func tableView(_ tableView: UITableView, commitEditingStyle forRowAt indexPath: IndexPath) {
        manager.deleteEntry(categoryIndex: indexPath.section, entryIndex: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
}

// MARK: - UITableViewDelegate
extension TextTabViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry = categories[indexPath.section].entries[indexPath.row]
        insertText(entry.content)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let copyAction = UIAction(title: "复制", image: UIImage(systemName: "doc.on.doc")) { _ in
                UIPasteboard.general.string = self.categories[indexPath.section].entries[indexPath.row].content
            }
            let deleteAction = UIAction(title: "删除", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.manager.deleteEntry(categoryIndex: indexPath.section, entryIndex: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            return UIMenu(children: [copyAction, deleteAction])
        }
    }
}

// MARK: - Cells
class CategoryCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .secondarySystemBackground
    }
    required init?(coder: NSCoder) { fatalError() }
}

class TextEntryCell: UITableViewCell {
    let label = UILabel()
    let contentLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .systemBackground
        
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        contentLabel.font = UIFont.monospacedSystemFont(ofSize: 12)
        contentLabel.textColor = .secondaryLabel
        contentLabel.numberOfLines = 2
        
        let stack = UIStackView(arrangedSubviews: [label, contentLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
