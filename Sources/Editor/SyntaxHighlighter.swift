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
        case .keyword: return "\u{1B}[1;36m"        // Bold Cyan
        case .string: return "\u{1B}[32m"          // Green
        case .comment: return "\u{1B}[90m"         // Dim Gray
        case .number: return "\u{1B}[33m"          // Yellow
        case .typeOrAttribute: return "\u{1B}[94m" // Bright Blue
        case .normal: return "\u{1B}[0m"
        }
    }
}

/// Represents a syntax rule with regex pattern and token type.
public struct SyntaxRule {
    public let pattern: NSRegularExpression
    public let tokenType: SyntaxTokenType

    public init?(patternStr: String, tokenType: SyntaxTokenType) {
        guard let regex = try? NSRegularExpression(pattern: patternStr, options: []) else { return nil }
        self.pattern = regex
        self.tokenType = tokenType
    }
}

/// Language syntax specification containing file extension matchers and rules.
public struct LanguageSyntax {
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

    /// Sets up built-in syntax rules for Swift, Python, C/C++, JSON, Markdown, and Shell.
    private func setupBuiltInLanguages() {
        let definitions: [SyntaxDefinition] = [
            SwiftSyntaxDefinition(),
            PythonSyntaxDefinition(),
            CSyntaxDefinition(),
            JSONSyntaxDefinition(),
            MarkdownSyntaxDefinition(),
            ShellSyntaxDefinition()
        ]
        for def in definitions {
            languages.append(def.buildLanguageSyntax())
        }
    }

    /// Loads system and user .nanorc files (~/.nanorc, /etc/nanorc, /opt/homebrew/share/nanorc/*.nanorc, etc.)
    public func loadNanoRC() {
        let candidatePaths = [
            FileManager.default.homeDirectoryForCurrentUser.path + "/.nanorc",
            "/etc/nanorc",
            "/opt/homebrew/share/nanorc",
            "/opt/homebrew/share/nano",
            "/usr/share/nano",
            "/usr/local/share/nano"
        ]

        for path in candidatePaths {
            if path.hasSuffix(".nanorc") {
                if FileManager.default.fileExists(atPath: path) {
                    parseNanoRCFile(at: path)
                }
            } else if FileManager.default.fileExists(atPath: path) {
                if let files = try? FileManager.default.contentsOfDirectory(atPath: path) {
                    for f in files where f.hasSuffix(".nanorc") {
                        parseNanoRCFile(at: (path as NSString).appendingPathComponent(f))
                    }
                }
            }
        }
    }

    /// Parses a .nanorc file and adds syntax color rules.
    public func parseNanoRCFile(at path: String) {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return }

        var currentLangName: String? = nil
        var currentExtensions: [String] = []
        var currentRules: [SyntaxRule] = []

        let lines = content.components(separatedBy: .newlines)
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }

            if line.hasPrefix("include ") {
                let includePath = line.dropFirst(8).trimmingCharacters(in: CharacterSet(charactersIn: "\" '"))
                processIncludePath(includePath)
                continue
            }

            if line.hasPrefix("syntax ") {
                if let name = currentLangName, !currentRules.isEmpty {
                    languages.append(LanguageSyntax(name: name, extensions: currentExtensions, rules: currentRules))
                }

                let parts = parseQuotedTokens(String(line.dropFirst(7)))
                if !parts.isEmpty {
                    currentLangName = parts[0]
                    currentExtensions = []
                    currentRules = []

                    for idx in 1..<parts.count {
                        let pat = parts[idx]
                        let ext = pat.replacingOccurrences(of: "\\.", with: "")
                                     .replacingOccurrences(of: "$", with: "")
                                     .replacingOccurrences(of: "^", with: "")
                                     .replacingOccurrences(of: "\\", with: "")
                        if !ext.isEmpty {
                            currentExtensions.append(ext)
                        }
                    }
                }
                continue
            }

            if line.hasPrefix("color ") || line.hasPrefix("icolor ") {
                let isColor = line.hasPrefix("color ")
                let body = line.dropFirst(isColor ? 6 : 7).trimmingCharacters(in: .whitespaces)
                let parts = parseQuotedTokens(String(body))
                if parts.count >= 2 {
                    let colorName = parts[0].lowercased()
                    let regexPattern = parts[1]

                    let tokenType = mapColorNameToTokenType(colorName)
                    if let rule = SyntaxRule(patternStr: regexPattern, tokenType: tokenType) {
                        currentRules.append(rule)
                    }
                }
            }
        }

        if let name = currentLangName, !currentRules.isEmpty {
            languages.append(LanguageSyntax(name: name, extensions: currentExtensions, rules: currentRules))
        }
    }

    private func processIncludePath(_ pathPattern: String) {
        var expandedPath = pathPattern
        if expandedPath.hasPrefix("~") {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            expandedPath = home + expandedPath.dropFirst(1)
        }

        if expandedPath.contains("*") {
            let dirPath = (expandedPath as NSString).deletingLastPathComponent
            let pattern = (expandedPath as NSString).lastPathComponent
            let suffix = pattern.replacingOccurrences(of: "*", with: "")

            if FileManager.default.fileExists(atPath: dirPath),
               let files = try? FileManager.default.contentsOfDirectory(atPath: dirPath) {
                for f in files where f.hasSuffix(suffix) {
                    let fullPath = (dirPath as NSString).appendingPathComponent(f)
                    parseNanoRCFile(at: fullPath)
                }
            }
        } else if FileManager.default.fileExists(atPath: expandedPath) {
            parseNanoRCFile(at: expandedPath)
        }
    }

    private func mapColorNameToTokenType(_ colorStr: String) -> SyntaxTokenType {
        let primaryColor = colorStr.components(separatedBy: ",").first ?? colorStr
        let c = primaryColor.lowercased()

        if c.contains("cyan") || c.contains("magenta") {
            return .keyword
        } else if c.contains("green") {
            return .string
        } else if c.contains("black") || c.contains("gray") {
            return .comment
        } else if c.contains("yellow") || c.contains("red") {
            return .number
        } else if c.contains("blue") || c.contains("white") {
            return .typeOrAttribute
        }
        return .keyword
    }

    private func parseQuotedTokens(_ str: String) -> [String] {
        var tokens: [String] = []
        var currentToken = ""
        var inQuote = false
        var quoteChar: Character? = nil

        for ch in str {
            if (ch == "\"" || ch == "'") {
                if !inQuote {
                    inQuote = true
                    quoteChar = ch
                } else if quoteChar == ch {
                    inQuote = false
                    quoteChar = nil
                    tokens.append(currentToken)
                    currentToken = ""
                } else {
                    currentToken.append(ch)
                }
            } else if ch == " " && !inQuote {
                if !currentToken.isEmpty {
                    tokens.append(currentToken)
                    currentToken = ""
                }
            } else {
                currentToken.append(ch)
            }
        }
        if !currentToken.isEmpty {
            tokens.append(currentToken)
        }
        return tokens
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

    /// Highlights a line of text by applying matching syntax color ANSI codes.
    public func highlight(line: String, syntax: LanguageSyntax) -> String {
        guard !line.isEmpty else { return line }

        var tokenMap = [SyntaxTokenType](repeating: .normal, count: line.count)
        let nsLine = line as NSString

        for rule in syntax.rules {
            let matches = rule.pattern.matches(in: line, options: [], range: NSRange(location: 0, length: nsLine.length))
            for match in matches {
                let range = match.range
                for idx in range.location..<(range.location + range.length) {
                    if idx < tokenMap.count && tokenMap[idx] == .normal {
                        tokenMap[idx] = rule.tokenType
                    }
                }
            }
        }

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
