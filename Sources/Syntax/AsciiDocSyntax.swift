import Foundation

public struct AsciiDocSyntaxDefinition: SyntaxDefinition {
    public let name = "AsciiDoc"
    public let fileExtensions = ["adoc", "asciidoc", "ascii"]

    public var rules: [SyntaxRule] {
        [
            makeRule("^=+\\s+.*$", .keyword),
            makeRule("\\[source,\\s*[A-Za-z0-9_+-]+\\]", .keyword),
            makeRule("^----+|^====+|^\\.\\.\\.\\.+|^\\|===+", .comment),
            makeRule("\\b(NOTE|TIP|IMPORTANT|WARNING|CAUTION):", .typeOrAttribute),
            makeRule("^//.*$", .comment),
            makeRule("\\*[^*\\n]+\\*|_[^_\\n]+_|`[^`\\n]+`", .string),
            makeRule("\\b([0-9]+)\\b", .number),
        ].compactMap { $0 }
    }
}
