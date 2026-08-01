import Foundation
import LogoEngine

public struct LogoSyntaxDefinition: SyntaxDefinition {
    public let name = "LOGO"
    public let fileExtensions = ["logo", "lg", ".zagorc", ".serc"]

    private static let keywordPattern: String = {
        let lineSubkeywords = [
            "ARROW", "RIGHTARROW", "DOWNARROW",
            "BACKARROW", "LEFTARROW", "UPARROW",
            "BOTHARROW", "BOTH", "BIDIR",
        ]
        let aliases = (LogoPrimitive.keywordAliases + lineSubkeywords)
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
        return "(?i)(?<![A-Za-z0-9_.?])(\(aliases))(?![A-Za-z0-9_.?])"
    }()

    public var rules: [SyntaxRule] {
        [
            // LOGO quoted words ("word), multi-word strings ("hello world"), and single-quoted text.
            makeRule("\"[^\"\n]*\"(?![A-Za-z0-9:\"])|\"[^\"\\s\\[\\]\\{\\}\\(\\)]+|'[^']*'", .string),
            // LOGO & config file comments (#, ;, //)
            makeRule("(?<!:)#.*$|;.*$|//.*$", .comment),
            makeRule(Self.keywordPattern, .keyword),
            // Variables (:var_name) and loop/template counter (:#)
            makeRule(":(#|[a-zA-Z0-9_]+)", .typeOrAttribute),
            // Numbers
            makeRule("\\b\\d+\\b", .number),
        ].compactMap { $0 }
    }
}
