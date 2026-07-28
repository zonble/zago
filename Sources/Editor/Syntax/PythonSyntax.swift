import Foundation

public struct PythonSyntaxDefinition: SyntaxDefinition {
    public let name = "Python"
    public let fileExtensions = ["py"]

    public var rules: [SyntaxRule] {
        [
            makeRule("#.*$", .comment),
            makeRule("\"\"\"[^\"]*\"\"\"|'''[^']*'''|\"[^\"]*\"|'[^']*'", .string),
            makeRule(
                "\\b(def|class|if|elif|else|while|for|in|try|except|finally|with|as|import|from|return|yield|break|continue|pass|lambda|global|nonlocal|assert|raise|async|await|and|or|not|is)\\b",
                .keyword),
            makeRule("\\b(True|False|None|[0-9]+)\\b", .number),
        ].compactMap { $0 }
    }
}
