import Foundation

public struct ShellSyntaxDefinition: SyntaxDefinition {
    public let name = "Shell"
    public let fileExtensions = ["sh", "bash", "zsh"]

    public var rules: [SyntaxRule] {
        [
            makeRule("#.*$", .comment),
            makeRule("\"[^\"]*\"|'[^']*'", .string),
            makeRule(
                "\\b(if|then|else|elif|fi|case|esac|for|while|until|do|done|in|function|return|exit|export|local|echo|set|unset)\\b",
                .keyword),
            makeRule("\\$[A-Za-z0-9_]+|\\$\\{[^\\}]+\\}", .typeOrAttribute),
        ].compactMap { $0 }
    }
}
