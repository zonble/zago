import Drawing
import Foundation
import LogoEngine

public struct LogoSyntaxDefinition: SyntaxDefinition {
    public let name = "LOGO"
    public let fileExtensions = ["logo", "lg"]
    public var commentPrefix: String { "; " }

    public var headerRules: [NSRegularExpression] {
        (try? [
            NSRegularExpression(pattern: #"^#!\s*/.*\b(logo|zago)\b"#),
            NSRegularExpression(pattern: #"^;\s*.*(logo|zago)"#),
            NSRegularExpression(pattern: #"(?i)^\s*to\s+[a-zA-Z_][a-zA-Z0-9_.]*(\s+:[a-zA-Z0-9_]+)*\s*$"#),
            NSRegularExpression(pattern: #"(?i)^\s*make\s+["':][a-zA-Z0-9_]"#),
            NSRegularExpression(pattern: #"(?i)^\s*repeat\s+(\d+|:[a-zA-Z0-9_]+)\s*\["#),
            NSRegularExpression(pattern: #"(?i)^\s*drawbox\b"#),
            NSRegularExpression(pattern: #"(?i)^\s*box\s+(\d+|"[^"\n]*"|'[^'\n]*'|\[)"#),
            NSRegularExpression(pattern: #"(?i)^\s*table\s+(\d+|\[)"#),
            NSRegularExpression(pattern: #"(?i)^\s*line\s+(\d+|\[|"single|"double|"round|"heavy)"#),
        ]) ?? []
    }

    static let keywordPattern: String = {
        let aliases = (LogoPrimitive.keywordAliases + LineArrowMode.allKeywords)
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
        return "(?i)(?<![A-Za-z0-9_.?])(\(aliases))(?![A-Za-z0-9_.?])"
    }()

    public var rules: [SyntaxRule] {
        [
            // Full-line comments must win before LOGO quoted-word rules in .zagorc samples.
            makeRule("^\\s*(#|;|//).*$", .comment),
            // LOGO quoted words ("word), multi-word strings ("hello world"), and single-quoted text.
            makeRule("\"[^\"\n]*\"(?![A-Za-z0-9:\"])|\"[^\"\\s\\[\\]\\{\\}\\(\\)]+|'[^']*'", .string),
            // Inline LOGO & config file comments (#, ;, //)
            makeRule("(?<!:)#.*$|;.*$|//.*$", .comment),
            makeRule(Self.keywordPattern, .keyword),
            // Variables (:var_name) and loop/template counter (:#)
            makeRule(":(#|[a-zA-Z0-9_]+)", .typeOrAttribute),
            // Numbers
            makeRule("\\b\\d+\\b", .number),
        ].compactMap { $0 }
    }
}
