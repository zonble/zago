import Foundation

public struct ReSTSyntaxDefinition: SyntaxDefinition {
    public let name = "reStructuredText"
    public let fileExtensions = ["rst", "rest"]

    public var rules: [SyntaxRule] {
        [
            // Section Titles / Underlines
            makeRule("^(=+|-+|~+|\\^+|\\*+|#+|\"+)\\s*$", .keyword),
            // Directives & Roles
            makeRule("^\\s*\\.\\.\\s+[a-zA-Z0-9_-]+::|:[a-zA-Z0-9_-]+:", .typeOrAttribute),
            // Inline Code / Literals
            makeRule("``[^`]+``|`[^`]+`", .string),
            // Comments
            makeRule("^\\s*\\.\\.\\s+.*$", .comment),
            // Links / Targets
            makeRule("`[^`]+`_|https?://[^\\s]+|\\[[^\\]]+\\]_", .typeOrAttribute),
            // Field lists / Bullet lists
            makeRule("^\\s*:[a-zA-Z0-9_-]+:|^\\s*[*+-]\\s+", .number)
        ].compactMap { $0 }
    }
}
