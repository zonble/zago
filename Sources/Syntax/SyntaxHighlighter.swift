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

/// Language syntax specification containing file extension matchers, tokenization rules, and feature hooks.
public struct LanguageSyntax: Sendable {
    /// Human-readable display name of the language (e.g. "Markdown", "Swift", "Python").
    public let name: String

    /// Array of matching file extension strings without leading dots (e.g. ["md", "markdown"]).
    public let extensions: [String]

    /// List of regex tokenization rules used for ANSI color highlighting.
    public let rules: [SyntaxRule]

    /// Optional polymorphic closure for detecting embedded code block language names in markup files.
    public let embeddedLanguageDetector: (@Sendable ([String], Int) -> String?)?

    /// Optional polymorphic closure for formatting and aligning text tables in markup files.
    public let tableFormatter: (@Sendable ([String], Int, Int) -> TableFormatResult?)?

    /// Optional polymorphic closure for navigating table cells via Tab / Shift+Tab in markup files.
    public let tableNavigator: (@Sendable ([String], Int, Int, Bool) -> TableNavigationResult?)?

    /// Whether this syntax specification supports structure tree extraction (Document Outline / Heading navigation).
    public let supportsDocumentOutline: Bool

    /// Optional polymorphic closure for parsing document headings into a DocumentOutline tree.
    public let outlineParser: (@Sendable ([String]) -> DocumentOutline?)?

    /// Whether this syntax specification supports Markdown-style list auto-indentation and continuation on Enter.
    public let supportsListAutoIndent: Bool

    public init(
        name: String,
        extensions: [String],
        rules: [SyntaxRule],
        embeddedLanguageDetector: (@Sendable ([String], Int) -> String?)? = nil,
        tableFormatter: (@Sendable ([String], Int, Int) -> TableFormatResult?)? = nil,
        tableNavigator: (@Sendable ([String], Int, Int, Bool) -> TableNavigationResult?)? = nil,
        supportsDocumentOutline: Bool = false,
        outlineParser: (@Sendable ([String]) -> DocumentOutline?)? = nil,
        supportsListAutoIndent: Bool = false
    ) {
        self.name = name
        self.extensions = extensions
        self.rules = rules
        self.embeddedLanguageDetector = embeddedLanguageDetector
        self.tableFormatter = tableFormatter
        self.tableNavigator = tableNavigator
        self.supportsDocumentOutline = supportsDocumentOutline
        self.outlineParser = outlineParser
        self.supportsListAutoIndent = supportsListAutoIndent
    }
}

/// Syntax Highlighting Engine managing language rules, regex tokenization, and ANSI color formatting.
public final class SyntaxHighlighter {
    private var languages: [LanguageSyntax] = []
    private let cacheLock = NSLock()
    private var tokenCache: [String: [SyntaxTokenType]] = [:]

    public init() {
        setupBuiltInLanguages()
        loadNanoRC()
    }

    /// Clears the syntax tokenization cache.
    public func clearCache() {
        cacheLock.lock()
        tokenCache.removeAll()
        cacheLock.unlock()
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
            CodeBlockPlainTextSyntaxDefinition(),
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
        let clean = langName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }

        return languages.first { lang in
            lang.name.lowercased() == clean
                || lang.extensions.contains { ext in
                    ext.lowercased() == clean
                }
        }
    }

    /// Determines LanguageSyntax for a specific buffer line, accounting for embedded code blocks polymorphically.
    public func getSyntaxForLine(
        filePath: String?,
        isDirectoryBuffer: Bool,
        lines: [String],
        bufferLineIndex: Int,
        isEnabled: Bool
    ) -> LanguageSyntax? {
        guard isEnabled else { return nil }
        if isDirectoryBuffer {
            return DirectorySyntax.syntax
        }
        guard let defaultSyntax = detectLanguage(for: filePath) else { return nil }

        if let detector = defaultSyntax.embeddedLanguageDetector,
            let embeddedLangName = detector(lines, bufferLineIndex)
        {
            if let embeddedSyntax = findLanguage(named: embeddedLangName) {
                return embeddedSyntax
            }
            return findLanguage(named: "CodeBlockPlainText")
        }
        return defaultSyntax
    }

    /// Convenience wrapper delegating embedded language detection to the matched LanguageSyntax detector.
    public func detectEmbeddedLanguage(in lines: [String], bufferLineIndex: Int, fileExtension: String)
        -> LanguageSyntax?
    {
        guard let defaultSyntax = detectLanguage(for: "file.\(fileExtension)") else { return nil }
        if let detector = defaultSyntax.embeddedLanguageDetector,
            let embeddedLangName = detector(lines, bufferLineIndex)
        {
            return findLanguage(named: embeddedLangName) ?? findLanguage(named: "CodeBlockPlainText")
        }
        return nil
    }

    /// Returns token type map for each character in line based on syntax rules.
    public func tokenTypes(for line: String, syntax: LanguageSyntax) -> [SyntaxTokenType] {
        guard !line.isEmpty else { return [] }
        let cacheKey = "\(syntax.name):\(line)"

        cacheLock.lock()
        if let cached = tokenCache[cacheKey] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

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

        cacheLock.lock()
        if tokenCache.count > 5000 {
            tokenCache.removeAll()
        }
        tokenCache[cacheKey] = tokenMap
        cacheLock.unlock()

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
