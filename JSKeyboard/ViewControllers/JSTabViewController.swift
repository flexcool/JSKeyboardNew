import UIKit

class JSTabViewController: UIViewController {
    
    private let manager = DataManager.shared
    private var functions: [JSFunction] { manager.settings.jsPredefinedFunctions }
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var parameterTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "JavaScript"
        view.backgroundColor = .systemBackground
        
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(JSFunctionCell.self, forCellReuseIdentifier: "JSFunctionCell")
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .systemBackground
    }
    
    // 输出到键盘
    func insertText(_ text: String) {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let keyboardVC = scene.windows.first?.rootViewController?.presentedViewController as? KeyboardViewController {
            keyboardVC.insertText(text)
        }
    }
    
    func showParameterInput(for function: JSFunction) {
        let alert = UIAlertController(title: function.name, message: "输入参数值", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = function.parameterName
            textField.text = function.parameterDefault
            self.parameterTextField = textField
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "执行", style: .default) { _ in
            let paramValue = alert.textFields?.first?.text ?? function.parameterDefault
            let output = self.buildJSOutput(for: function, parameter: paramValue)
            self.insertText(output)
        })
        
        present(alert, animated: true)
    }
    
    private func buildJSOutput(for fn: JSFunction, parameter: String) -> String {
        if !fn.hasParameter {
            return fn.code
        }
        // 替换模板中的参数占位符
        var code = fn.code
        code = code.replacingOccurrences(of: "$" + fn.parameterName, with: parameter)
        // 如果参数是字符串，加上引号
        if parameter.contains("\"") || parameter.contains("'") || parameter.contains(" ") {
            code = code.replacingOccurrences(of: parameter, with: "\"\(parameter)\"", options: .literal)
        }
        return code
    }
}

// MARK: - UITableViewDataSource
extension JSTabViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return functions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JSFunctionCell", for: indexPath) as! JSFunctionCell
        let fn = functions[indexPath.row]
        cell.configure(name: fn.name, hasParam: fn.hasParameter, paramDesc: fn.parameterName)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension JSTabViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fn = functions[indexPath.row]
        if fn.hasParameter {
            showParameterInput(for: fn)
        } else {
            insertText(fn.code)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Cell
class JSFunctionCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let badgeLabel = UILabel()
    private let codePreview = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .systemBackground
        
        nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        badgeLabel.font = UIFont.systemFont(ofSize: 10)
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 4
        badgeLabel.clipsToBounds = true
        badgeLabel.isHidden = true
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        codePreview.font = UIFont.monospacedSystemFont(ofSize: 11)
        codePreview.textColor = .secondaryLabel
        codePreview.numberOfLines = 1
        codePreview.translatesAutoresizingMaskIntoConstraints = false
        
        let badgeStack = UIStackView(arrangedSubviews: [nameLabel, badgeLabel])
        badgeStack.axis = .horizontal
        badgeStack.spacing = 8
        badgeStack.alignment = .center
        
        let mainStack = UIStackView(arrangedSubviews: [badgeStack, codePreview])
        mainStack.axis = .vertical
        mainStack.spacing = 4
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(name: String, hasParam: Bool, paramDesc: String) {
        nameLabel.text = name
        if hasParam {
            badgeLabel.text = "📥 \(paramDesc)"
            badgeLabel.isHidden = false
            badgeLabel.backgroundColor = .systemBlue.withAlphaComponent(0.2)
            badgeLabel.textColor = .systemBlue
        } else {
            badgeLabel.isHidden = true
        }
        // 简单预览
        codePreview.text = name.contains("(") ? "" : "无参数，直接输出"
    }
}
