import Foundation

/// TokenType categories for syntax highlighting colors.
public enum SyntaxTokenType {
    case keyword
    case string
    case comment
    case number
    case typeOrAttribute
    case normal

    /// Returns ANSI color escape sequence for token type.
    public var ansiColor: String {
        switch self {
        case .keyword: return "\u{1B}[1;36m"  // Bold Cyan
        case .string: return "\u{1B}[32m"  // Green
        case .comment: return "\u{1B}[90m"  // Dim Gray
        case .number: return "\u{1B}[33m"  // Yellow
        case .typeOrAttribute: return "\u{1B}[94m"  // Bright Blue
        case .normal: return "\u{1B}[0m"
        }
    }
}

/// Represents a syntax rule with regex pattern and token type.
public struct SyntaxRule: @unchecked Sendable {
    public let pattern: NSRegularExpression
    public let tokenType: SyntaxTokenType

    public init?(patternStr: String, tokenType: SyntaxTokenType) {
        guard let regex = try? NSRegularExpression(pattern: patternStr, options: []) else { return nil }
        self.pattern = regex
        self.tokenType = tokenType
    }
}

/// Language syntax specification containing file extension matchers and rules.
public struct LanguageSyntax: Sendable {
    public let name: String
    public let extensions: [String]
    public let rules: [SyntaxRule]

    public init(name: String, extensions: [String], rules: [SyntaxRule]) {
        self.name = name
        self.extensions = extensions
        self.rules = rules
    }
}

/// Syntax Highlighting Engine managing language rules, regex tokenization, and ANSI color formatting.
public final class SyntaxHighlighter {
    private var languages: [LanguageSyntax] = []

    public init() {
        setupBuiltInLanguages()
        loadNanoRC()
    }

    /// Sets up built-in syntax rules for Swift, Python, C/C++, JSON, Markdown, Shell, LOGO, Diagrams, etc.
    private func setupBuiltInLanguages() {
        let definitions: [SyntaxDefinition] = [
            SwiftSyntaxDefinition(),
            PythonSyntaxDefinition(),
            CSyntaxDefinition(),
            JSONSyntaxDefinition(),
            YAMLSyntaxDefinition(),
            TOMLSyntaxDefinition(),
            INISyntaxDefinition(),
            MarkdownSyntaxDefinition(),
            ShellSyntaxDefinition(),
            ReSTSyntaxDefinition(),
            OrgModeSyntaxDefinition(),
            LogoSyntaxDefinition(),
            MermaidSyntaxDefinition(),
            DotSyntaxDefinition(),
            PlantUMLSyntaxDefinition(),
            AsciiDocSyntaxDefinition(),
            WikiSyntaxDefinition(),
            VhsSyntaxDefinition(),
        ]
        for def in definitions {
            languages.append(def.buildLanguageSyntax())
        }
    }

    /// Loads system and user .nanorc files using NanoRCParser.
    public func loadNanoRC() {
        NanoRCParser().loadNanoRC(into: &languages)
    }

    /// Parses a .nanorc file at specific path using NanoRCParser.
    public func parseNanoRCFile(at path: String) {
        NanoRCParser().parseNanoRCFile(at: path, into: &languages)
    }

    /// Auto-detects matching LanguageSyntax based on file path or extension.
    public func detectLanguage(for filePath: String?) -> LanguageSyntax? {
        guard let path = filePath, !path.isEmpty else { return nil }
        let ext = (path as NSString).pathExtension.lowercased()
        let filename = (path as NSString).lastPathComponent.lowercased()

        return languages.first { lang in
            lang.extensions.contains(ext) || lang.extensions.contains(filename)
        }
    }

    /// Finds matching LanguageSyntax dynamically by language name or file extension.
    public func findLanguage(named langName: String) -> LanguageSyntax? {
        let clean = langName.lowercased().trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard !clean.isEmpty else { return nil }

        return languages.first { lang in
            lang.name.lowercased() == clean || lang.extensions.contains { ext in
                ext.lowercased() == clean
            }
        }
    }

    /// Returns token type map for each character in line based on syntax rules.
    public func tokenTypes(for line: String, syntax: LanguageSyntax) -> [SyntaxTokenType] {
        guard !line.isEmpty else { return [] }
        var tokenMap = [SyntaxTokenType](repeating: .normal, count: line.count)
        let nsLine = line as NSString

        for rule in syntax.rules {
            let matches = rule.pattern.matches(
                in: line, options: [], range: NSRange(location: 0, length: nsLine.length))
            for match in matches {
                let range = match.range
                for idx in range.location..<(range.location + range.length) {
                    if idx < tokenMap.count && tokenMap[idx] == .normal {
                        tokenMap[idx] = rule.tokenType
                    }
                }
            }
        }
        return tokenMap
    }

    /// Highlights a line of text by applying matching syntax color ANSI codes.
    public func highlight(line: String, syntax: LanguageSyntax) -> String {
        guard !line.isEmpty else { return line }

        let tokenMap = tokenTypes(for: line, syntax: syntax)
        var result = ""
        var currentToken = SyntaxTokenType.normal
        let chars = Array(line)

        for (idx, ch) in chars.enumerated() {
            let token = tokenMap[idx]
            if token != currentToken {
                if currentToken != .normal {
                    result += "\u{1B}[0m"
                }
                if token != .normal {
                    result += token.ansiColor
                }
                currentToken = token
            }
            result.append(ch)
        }

        if currentToken != .normal {
            result += "\u{1B}[0m"
        }

        return result
    }
}
