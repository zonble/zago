import Drawing
import Foundation
import LogoEngine
import LogoLocalization

public struct LogoSyntaxDefinition: SyntaxDefinition {
    public let name = "LOGO"
    public let fileExtensions = ["logo", "lg"]
    public var commentPrefix: String { "; " }
    public let plugins: [any LogoParserPlugin]

    public init(plugins: [any LogoParserPlugin] = LogoLocalizationRegistry.allDialects) {
        self.plugins = plugins
    }

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
            NSRegularExpression(pattern: #"^\s*(畫框|前進|重複|如果|宣告)\b"#),
        ]) ?? []
    }

    public static func fillerPattern(with plugins: [any LogoParserPlugin] = LogoLocalizationRegistry.allDialects)
        -> String
    {
        var fillerSet = LogoEngine.standardFillerTokens
        for plugin in plugins {
            fillerSet.formUnion(plugin.fillerTokens)
        }
        let sorted = fillerSet.sorted { $0.count > $1.count }
        let escaped = sorted.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
        return "(?i)(?<![\\p{L}\\p{N}_.?])(\(escaped))(?![\\p{L}\\p{N}_.?])"
    }

    public static func keywordPattern(with plugins: [any LogoParserPlugin] = LogoLocalizationRegistry.allDialects)
        -> String
    {
        var allKeywords = Set(LogoPrimitive.keywordAliases + LineArrowMode.allKeywords)
        for plugin in plugins {
            allKeywords.formUnion(plugin.keywordAliases)
        }
        // Exclude filler tokens from keyword pattern so they are uniquely styled
        var fillerSet = LogoEngine.standardFillerTokens
        for plugin in plugins {
            fillerSet.formUnion(plugin.fillerTokens)
        }
        allKeywords.subtract(fillerSet)

        let sorted = allKeywords.sorted { $0.count > $1.count }
        let escaped = sorted.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
        return "(?i)(?<![\\p{L}\\p{N}_.?])(\(escaped))(?![\\p{L}\\p{N}_.?])"
    }

    public static let keywordPattern: String = keywordPattern()

    public var rules: [SyntaxRule] {
        [
            // Full-line comments must win before LOGO quoted-word rules in .zagorc samples.
            makeRule("^\\s*(#|;|//).*$", .comment),
            // LOGO quoted words ("word), multi-word strings ("hello world"), and single-quoted text.
            makeRule("\"[^\"\n]*\"(?![A-Za-z0-9:\"])|\"[^\"\\s\\[\\]\\{\\}\\(\\)]+|'[^']*'", .string),
            // Inline LOGO & config file comments (#, ;, //)
            makeRule("(?<!:)#.*$|;.*$|//.*$", .comment),
            // Variables (:var_name, :數字, :體重) and loop/template counter (:#)
            makeRule(":(#|[\\p{L}\\p{N}_]+)", .typeOrAttribute),
            // Language and dialect keywords (Bold Cyan)
            makeRule(Self.keywordPattern(with: plugins), .keyword),
            // Grammatical filler/noise tokens (Bright Blue)
            makeRule(Self.fillerPattern(with: plugins), .typeOrAttribute),
            // Numbers
            makeRule("\\b\\d+(\\.\\d+)?\\b", .number),
        ].compactMap { $0 }
    }
}
