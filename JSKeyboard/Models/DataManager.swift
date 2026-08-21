import UIKit

// MARK: - 管理器类
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
    
    // MARK: - Categories
    func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: "textCategories"),
           let decoded = try? JSONDecoder().decode([TextCategory].self, from: data) {
            categories = decoded
        } else {
            // 默认分类
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
    
    // MARK: - Clipboard
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
        // 限制数量
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
