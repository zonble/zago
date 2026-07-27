import Foundation

public struct MarkdownSyntaxDefinition: SyntaxDefinition {
    public let name = "Markdown"
    public let fileExtensions = ["md", "markdown"]

    public var rules: [SyntaxRule] {
        [
            makeRule("^#{1,6}\\s+.*$", .keyword),
            makeRule("`[^`]+`", .string),
            makeRule("\\[[^\\]]+\\]\\([^\\)]+\\)", .typeOrAttribute),
            makeRule("^>.*|^\\s*[*+-]\\s+", .number)
        ].compactMap { $0 }
    }
}
