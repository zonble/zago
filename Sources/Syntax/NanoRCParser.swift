import Foundation

/// Parser for loading system and user GNU Nano `.nanorc` syntax highlighting definitions.
public final class NanoRCParser {
    public init() {}

    /// Loads system and user `.nanorc` files into the provided languages array.
    public func loadNanoRC(into languages: inout [LanguageSyntax]) {
        let candidatePaths = [
            FileManager.default.homeDirectoryForCurrentUser.path + "/.nanorc",
            "/etc/nanorc",
            "/opt/homebrew/share/nanorc",
            "/opt/homebrew/share/nano",
            "/usr/share/nano",
            "/usr/local/share/nano",
        ]

        for path in candidatePaths {
            if path.hasSuffix(".nanorc") {
                if FileManager.default.fileExists(atPath: path) {
                    parseNanoRCFile(at: path, into: &languages)
                }
            } else if FileManager.default.fileExists(atPath: path) {
                if let files = try? FileManager.default.contentsOfDirectory(atPath: path) {
                    for f in files where f.hasSuffix(".nanorc") {
                        parseNanoRCFile(at: (path as NSString).appendingPathComponent(f), into: &languages)
                    }
                }
            }
        }
    }

    /// Parses a single .nanorc file and appends created LanguageSyntax to array.
    public func parseNanoRCFile(at path: String, into languages: inout [LanguageSyntax]) {
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
                processIncludePath(includePath, into: &languages)
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

    private func processIncludePath(_ pathPattern: String, into languages: inout [LanguageSyntax]) {
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
                let files = try? FileManager.default.contentsOfDirectory(atPath: dirPath)
            {
                for f in files where f.hasSuffix(suffix) {
                    let fullPath = (dirPath as NSString).appendingPathComponent(f)
                    parseNanoRCFile(at: fullPath, into: &languages)
                }
            }
        } else if FileManager.default.fileExists(atPath: expandedPath) {
            parseNanoRCFile(at: expandedPath, into: &languages)
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
            if ch == "\"" || ch == "'" {
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
}
