import Foundation

public struct SwiftSyntaxDefinition: SyntaxDefinition {
    public let name = "Swift"
    public let fileExtensions = ["swift"]

    public var rules: [SyntaxRule] {
        [
            makeRule("\"[^\"]*\"", .string),
            makeRule("//.*$", .comment),
            makeRule(
                "\\b(func|class|struct|enum|let|var|if|else|guard|switch|case|default|for|in|while|do|try|catch|throw|return|import|public|private|internal|fileprivate|static|override|init|self|Self|super|as|is|where|defer|async|await|actor)\\b",
                .keyword),
            makeRule("@\\w+|\\b[A-Z]\\w*\\b", .typeOrAttribute),
            makeRule("\\b(true|false|nil|[0-9]+)\\b", .number),
        ].compactMap { $0 }
    }
}
