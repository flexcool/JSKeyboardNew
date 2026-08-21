import Foundation

struct AppSettings: Codable {
    var fontSize: CGFloat
    var accentColor: String
    var soundEnabled: Bool
    var vibrateEnabled: Bool
    var autoCopyToClipboard: Bool
    var maxClipboardHistory: Int
    var jsPredefinedFunctions: [JSFunction]
    
    init() {
        self.fontSize = 16
        self.accentColor = "#007AFF"
        self.soundEnabled = true
        self.vibrateEnabled = true
        self.autoCopyToClipboard = false
        self.maxClipboardHistory = 50
        
        // 默认 JavaScript 函数
        self.jsPredefinedFunctions = [
            JSFunction(name: "alert", code: "alert(\(rawParameter))", hasParameter: true, parameterName: "message", parameterDefault: "Hello"),
            JSFunction(name: "console.log", code: "console.log(\(rawParameter))", hasParameter: true, parameterName: "value", parameterDefault: ""),
            JSFunction(name: "getTimestamp", code: "Date.now()", hasParameter: false),
            JSFunction(name: "random", code: "Math.random()", hasParameter: false),
            JSFunction(name: "uuid", code: "crypto.randomUUID()", hasParameter: false),
            JSFunction(name: "fetch data", code: "fetch('\(rawParameter)').then(r=>r.json())", hasParameter: true, parameterName: "url", parameterDefault: "https://api.example.com/data")
        ]
    }
    
    private var rawParameter: String {
        return "\(hasParameter ? "$" : "")\(parameterName)"
    }
    
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
