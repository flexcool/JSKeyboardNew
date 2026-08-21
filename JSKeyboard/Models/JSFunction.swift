import Foundation

struct JSFunction: Identifiable, Codable {
    var id = UUID()
    var name: String
    var code: String
    var hasParameter: Bool
    var parameterName: String
    var parameterDefault: String
    
    init(name: String, code: String, hasParameter: Bool = false, parameterName: String = "param", parameterDefault: String = "") {
        self.name = name
        self.code = code
        self.hasParameter = hasParameter
        self.parameterName = parameterName
        self.parameterDefault = parameterDefault
    }
}
