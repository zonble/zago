import Foundation

extension LogoEngine {
    /// Tokenizes a macro script into individual string tokens, respecting quotes, comments, operators, and brackets.
    public func tokenize(_ script: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        let delims: Set<Character> = ["[", "]", "{", "}", "(", ")", "+", "-", "*", "/", "%", "^"]

        var i = script.startIndex
        while i < script.endIndex {
            let ch = script[i]
            if ch == "\"" {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                current.append(ch)

                if hasClosingQuoteOnSameLine(script: script, fromIndex: script.index(after: i)) {
                    i = script.index(after: i)
                    while i < script.endIndex {
                        let innerCh = script[i]
                        current.append(innerCh)
                        if innerCh == "\"" { break }
                        i = script.index(after: i)
                    }
                    tokens.append(current)
                    current = ""
                } else {
                    i = script.index(after: i)
                    while i < script.endIndex && !script[i].isWhitespace && !delims.contains(script[i]) {
                        current.append(script[i])
                        i = script.index(after: i)
                    }
                    tokens.append(current)
                    current = ""
                    continue
                }
            } else if ch == ";" {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                i = script.index(after: i)
                while i < script.endIndex && !script[i].isNewline {
                    i = script.index(after: i)
                }
                continue
            } else if delims.contains(ch) {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                tokens.append(String(ch))
            } else if ch.isWhitespace {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            } else {
                current.append(ch)
            }
            i = script.index(after: i)
        }

        if !current.isEmpty {
            tokens.append(current)
        }

        return tokenizeInfixOperators(tokens)
    }

    private func hasClosingQuoteOnSameLine(script: String, fromIndex: String.Index) -> Bool {
        var idx = fromIndex
        while idx < script.endIndex {
            let ch = script[idx]
            if ch == "\n" || ch == "\r" { return false }
            if ch == "\"" { return true }
            idx = script.index(after: idx)
        }
        return false
    }

    private func tokenizeInfixOperators(_ rawTokens: [String]) -> [String] {
        var result: [String] = []

        for token in rawTokens {
            if token.hasPrefix("\"") && token.hasSuffix("\"") && token.count > 1 {
                result.append(token)
                continue
            }

            var current = ""
            var i = token.startIndex

            while i < token.endIndex {
                let ch = token[i]
                let remaining = String(token[i...])

                if remaining.hasPrefix("==") || remaining.hasPrefix("!=") || remaining.hasPrefix("<=") || remaining.hasPrefix(">=") {
                    if !current.isEmpty {
                        result.append(current)
                        current = ""
                    }
                    let op = String(remaining.prefix(2))
                    result.append(op)
                    i = token.index(i, offsetBy: 2)
                    continue
                } else if ch == "=" || ch == "<" || ch == ">" {
                    if !current.isEmpty {
                        result.append(current)
                        current = ""
                    }
                    result.append(String(ch))
                } else {
                    current.append(ch)
                }
                i = token.index(after: i)
            }

            if !current.isEmpty {
                result.append(current)
            }
        }

        return result
    }
}
