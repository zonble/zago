import Foundation

public struct INISyntaxDefinition: SyntaxDefinition {
    public let name = "INI"
    public let fileExtensions = ["ini", "conf", "cfg", "properties"]

    public var rules: [SyntaxRule] {
        [
            makeRule(#""(?:\\.|[^"\\])*"|'[^']*'"#, .string),
            makeRule(#"^\s*[#;].*$"#, .comment),
            makeRule(#"^\s*\[[^\]]+\]"#, .keyword),
            makeRule(#"^\s*[A-Za-z0-9_.-]+(?=\s*[:=])"#, .keyword),
            makeRule(#"\b(true|false|yes|no|on|off|null)\b"#, .typeOrAttribute),
            makeRule(#"\b[-+]?[0-9]+(?:\.[0-9]+)?\b"#, .number),
        ].compactMap { $0 }
    }
}
