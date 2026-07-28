import Foundation
import LogoEngine

public struct LogoSyntaxDefinition: SyntaxDefinition {
    public let name = "LOGO"
    public let fileExtensions = ["logo", "lg", ".serc"]

    private static let keywordPattern: String = {
        let aliases = LogoPrimitive.keywordAliases
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
        return "(?<![A-Za-z0-9_.?])(\(aliases))(?![A-Za-z0-9_.?])"
    }()

    public var rules: [SyntaxRule] {
        [
            makeRule(Self.keywordPattern, .keyword),
            // Variables (:var_name)
            makeRule(":[a-zA-Z0-9_]+", .typeOrAttribute),
            // Strings in double or single quotes
            makeRule("\"[^\"]*\"|'[^']*'", .string),
            // Numbers
            makeRule("\\b\\d+\\b", .number),
            // Comments (# comment, ; comment, // comment)
            makeRule("#.*$|;.*$|//.*$", .comment),
        ].compactMap { $0 }
    }
}
