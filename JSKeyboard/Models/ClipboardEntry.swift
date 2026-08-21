import Foundation

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
