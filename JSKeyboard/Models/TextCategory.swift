import Foundation

struct TextCategory: Identifiable, Codable {
    var id = UUID()
    var name: String
    var entries: [TextEntry]
    
    init(name: String, entries: [TextEntry] = []) {
        self.name = name
        self.entries = entries
    }
}

struct TextEntry: Identifiable, Codable {
    var id = UUID()
    var label: String
    var content: String
    
    init(label: String, content: String) {
        self.label = label
        self.content = content
    }
}
