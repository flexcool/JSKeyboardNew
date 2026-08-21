import UIKit

class KeyboardViewController: UIViewController, JSKeyboardViewDelegate {
    
    private var keyboardView: JSKeyboardView!
    private let manager = DataManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardView = JSKeyboardView(frame: view.bounds)
        keyboardView.delegate = self
        keyboardView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(keyboardView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        keyboardView.frame = view.bounds
    }
    
    // MARK: - JSKeyboardViewDelegate
    func keyboardView(_ view: JSKeyboardView, didRequestInsertText text: String) {
        textDocumentProxy.insertText(text)
        vibrate()
    }
    
    func keyboardViewDidRequestDeleteBackward(_ view: JSKeyboardView) {
        textDocumentProxy.deleteBackward()
    }
    
    func keyboardViewDidRequestReturn(_ view: JSKeyboardView) {
        textDocumentProxy.insertText("\n")
    }
    
    func keyboardViewDidRequestDone(_ view: JSKeyboardView) {
        // 收起键盘
        view.resignFirstResponder()
    }
    
    private func vibrate() {
        if manager.settings.vibrateEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
