import UIKit

// 输出回调闭包类型
typealias InsertTextHandler = (String) -> Void

class JSKeyboardView: UIView {
    
    private let manager: DataManager
    private var currentTab = 0
    
    // Tab 按钮
    private var tabButtons: [UIButton] = []
    private var tabStackView: UIStackView!
    
    // 内容滚动区域
    private var contentViewStack: UIScrollView!
    
    // 底部工具栏
    private let toolbar: UIToolbar = {
        let tb = UIToolbar()
        tb.barStyle = .default
        tb.translucent = true
        return tb
    }()
    
    init(frame: CGRect, manager: DataManager) {
        self.manager = manager
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // Tab 标签栏
        tabStackView = UIStackView()
        tabStackView.axis = .horizontal
        tabStackView.distribution = .fillEqually
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tabStackView)
        
        let tabs: [(String, String)] = [
            ("textformat", "文本"),
            ("doc.on.clipboard", "剪贴板"),
            ("curlybraces", "JS"),
            ("gearshape", "设置")
        ]
        
        for (icon, title) in tabs {
            let btn = UIButton(type: .system)
            btn.setImage(UIImage(systemName: icon), for: .normal)
            btn.setImage(UIImage(systemName: icon + ".fill"), for: .selected)
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(.secondaryLabel, for: .normal)
            btn.tintColor = .systemBlue
            btn.imageView?.contentMode = .scaleAspectFit
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 10)
            btn.tag = tabButtons.count
            btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            tabButtons.append(btn)
            tabStackView.addArrangedSubview(btn)
        }
        
        // 内容滚动区域
        contentViewStack = UIScrollView()
        contentViewStack.showsVerticalScrollIndicator = false
        contentViewStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentViewStack)
        
        // 创建各 Tab 内容的 ScrollView
        let tabsContainer = UIStackView()
        tabsContainer.axis = .horizontal
        tabsContainer.distribution = .equalSpacing
        tabsContainer.spacing = 0
        tabsContainer.translatesAutoresizingMaskIntoConstraints = false
        contentViewStack.addSubview(tabsContainer)
        
        // 各 Tab 内容视图
        let textScrollView = buildTextTab()
        let clipboardScrollView = buildClipboardTab()
        let jsScrollView = buildJSTab()
        let settingsScrollView = buildSettingsTab()
        
        let allScrollViews: [UIScrollView] = [textScrollView, clipboardScrollView, jsScrollView, settingsScrollView]
        for scrollView in allScrollViews {
            tabsContainer.addArrangedSubview(scrollView)
        }
        
        NSLayoutConstraint.activate([
            tabsContainer.topAnchor.constraint(equalTo: contentViewStack.topAnchor),
            tabsContainer.leadingAnchor.constraint(equalTo: contentViewStack.leadingAnchor),
            tabsContainer.trailingAnchor.constraint(equalTo: contentViewStack.trailingAnchor),
            tabsContainer.bottomAnchor.constraint(equalTo: contentViewStack.bottomAnchor),
            tabsContainer.widthAnchor.constraint(equalTo: contentViewStack.widthAnchor, multiplier: 4)
        ])
        
        // 底部工具栏
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
            
            contentViewStack.topAnchor.constraint(equalTo: tabStackView.bottomAnchor),
            contentViewStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentViewStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentViewStack.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
        
        showTab(0)
    }
    
    // MARK: - Tab 构建
    private func buildTextTab() -> UIScrollView {
        let vc = TextTabViewController()
        vc.manager = manager
        let container = UIScrollView()
        container.backgroundColor = .systemBackground
        container.tag = 0
        
        vc.view.backgroundColor = .systemBackground
        container.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: container.topAnchor),
            vc.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -200),
            vc.view.widthAnchor.constraint(equalTo: container.widthAnchor)
        ])
        
        addChild(vc)
        vc.didMove(toParent: self)
        
        vc.insertTextHandler = { [weak self] text in
            self?.insertText(text)
        }
        
        return container
    }
    
    private func buildClipboardTab() -> UIScrollView {
        let vc = ClipboardTabViewController()
        vc.manager = manager
        let container = UIScrollView()
        container.backgroundColor = .systemBackground
        container.tag = 1
        
        vc.view.backgroundColor = .systemBackground
        container.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: container.topAnchor),
            vc.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -200),
            vc.view.widthAnchor.constraint(equalTo: container.widthAnchor)
        ])
        
        addChild(vc)
        vc.didMove(toParent: self)
        
        vc.insertTextHandler = { [weak self] text in
            self?.insertText(text)
        }
        
        return container
    }
    
    private func buildJSTab() -> UIScrollView {
        let vc = JSTabViewController()
        vc.manager = manager
        let container = UIScrollView()
        container.backgroundColor = .systemBackground
        container.tag = 2
        
        vc.view.backgroundColor = .systemBackground
        container.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: container.topAnchor),
            vc.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -200),
            vc.view.widthAnchor.constraint(equalTo: container.widthAnchor)
        ])
        
        addChild(vc)
        vc.didMove(toParent: self)
        
        vc.insertTextHandler = { [weak self] text in
            self?.insertText(text)
        }
        
        return container
    }
    
    private func buildSettingsTab() -> UIScrollView {
        let vc = SettingsTabViewController()
        vc.manager = manager
        let container = UIScrollView()
        container.backgroundColor = .systemBackground
        container.tag = 3
        
        vc.view.backgroundColor = .systemBackground
        container.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: container.topAnchor),
            vc.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -200),
            vc.view.widthAnchor.constraint(equalTo: container.widthAnchor)
        ])
        
        addChild(vc)
        vc.didMove(toParent: self)
        
        return container
    }
    
    // MARK: - 操作
    @objc private func tabTapped(_ sender: UIButton) {
        showTab(sender.tag)
    }
    
    private func showTab(_ index: Int) {
        currentTab = index
        for (i, btn) in tabButtons.enumerated() {
            btn.isSelected = (i == index)
            btn.tintColor = i == index ? .systemBlue : .secondaryLabel
        }
        let offset = CGFloat(index) * bounds.width
        contentViewStack.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
    }
    
    @objc private func doneTapped() {
        textDocumentProxy.insertText("")
    }
    
    @objc private func deleteTapped() {
        textDocumentProxy.deleteBackward()
    }
    
    // MARK: - 输出
    func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}

// MARK: - 向 VC 注入回调
extension TextTabViewController {
    var insertTextHandler: InsertTextHandler?
    override func insertText(_ text: String) {
        insertTextHandler?(text)
    }
}

extension ClipboardTabViewController {
    var insertTextHandler: InsertTextHandler?
    override func insertText(_ text: String) {
        insertTextHandler?(text)
    }
}

extension JSTabViewController {
    var insertTextHandler: InsertTextHandler?
    override func insertText(_ text: String) {
        insertTextHandler?(text)
    }
}
