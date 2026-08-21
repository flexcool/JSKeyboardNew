import UIKit

class KeyboardViewController: UIViewController {
    
    private var keyboardView: JSKeyboardView!
    private let manager = DataManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadExtensionSettings()
        setupUI()
    }
    
    private func loadExtensionSettings() {
        // 从共享 group 读取设置
    }
    
    private func setupUI() {
        keyboardView = JSKeyboardView(frame: view.bounds, manager: manager)
        keyboardView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(keyboardView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        keyboardView.frame = view.bounds
    }
    
    // MARK: - 输入文本
    func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
        vibrateIfEnabled()
    }
    
    func deleteBackward() {
        textDocumentProxy.deleteBackward()
    }
    
    // MARK: - 换行/回车
    func returnKey() {
        textDocumentProxy.insertText("\n")
    }
    
    // MARK: - 切换大小写（如果支持）
    func toggleShift() {
        // TODO: 实现大写锁定
    }
    
    private func vibrateIfEnabled() {
        if manager.settings.vibrateEnabled {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
}
