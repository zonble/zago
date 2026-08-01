import Foundation

public struct TOMLSyntaxDefinition: SyntaxDefinition {
    public let name = "TOML"
    public let fileExtensions = ["toml"]

    public var rules: [SyntaxRule] {
        [
            makeRule(#""(?:\\.|[^"\\])*"|'[^']*'"#, .string),
            makeRule(#"#.*$"#, .comment),
            makeRule(#"^\s*\[\[?[A-Za-z0-9_.-]+\]?\]"#, .keyword),
            makeRule(#"^\s*[A-Za-z0-9_-]+(?=\s*=)"#, .keyword),
            makeRule(#"\b(true|false)\b"#, .typeOrAttribute),
            makeRule(#"\b[-+]?[0-9]+(?:\.[0-9]+)?\b"#, .number),
            makeRule(#"\b[0-9]{4}-[0-9]{2}-[0-9]{2}(?:[Tt ][0-9:.+-]+)?\b"#, .number),
        ].compactMap { $0 }
    }
}
