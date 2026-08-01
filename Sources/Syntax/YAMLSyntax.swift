import Foundation

public struct YAMLSyntaxDefinition: SyntaxDefinition {
    public let name = "YAML"
    public let fileExtensions = ["yaml", "yml"]

    public var rules: [SyntaxRule] {
        [
            makeRule(#""(?:\\.|[^"\\])*"|'(?:''|[^'])*'"#, .string),
            makeRule(#"#.*$"#, .comment),
            makeRule(#"^\s*---\s*$|^\s*\.\.\.\s*$"#, .keyword),
            makeRule(#"^\s*-\s+"#, .number),
            makeRule(#"^\s*[^:#\[\]\{\},]+(?=\s*:)"#, .keyword),
            makeRule(#":\s*[|>][-+]?"#, .typeOrAttribute),
            makeRule(#"\b(true|false|null|Null|NULL|yes|no|on|off)\b"#, .typeOrAttribute),
            makeRule(#"\b[-+]?[0-9]+(?:\.[0-9]+)?\b"#, .number),
            makeRule(#"[&*][A-Za-z0-9_-]+"#, .typeOrAttribute),
        ].compactMap { $0 }
    }
}
