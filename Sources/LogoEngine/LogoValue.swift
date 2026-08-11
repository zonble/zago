import Foundation

/// Unified data value representation for LOGO (words, lists, and multi-dimensional arrays).
public enum LogoValue: Equatable, CustomStringConvertible {
    case string(String)
    case list([LogoValue])
    case array([LogoValue])

    public var isList: Bool {
        if case .list = self { return true }
        return false
    }

    public var isArray: Bool {
        if case .array = self { return true }
        return false
    }

    public var isWord: Bool {
        if case .string = self { return true }
        return false
    }

    public var isNumber: Bool {
        switch self {
        case .string(let s): return Double(s) != nil
        default: return false
        }
    }

    public var isEmpty: Bool {
        switch self {
        case .string(let s): return s.isEmpty
        case .list(let l): return l.isEmpty
        case .array(let a): return a.isEmpty
        }
    }

    /// Serializes LOGO value into valid LOGO canonical syntax string (using UCBLogo |...| quoting for strings with whitespace/quotes/brackets).
    public func toLogoSyntaxString() -> String {
        switch self {
        case .string(let str):
            return str
        case .list(let items):
            let formatted = items.map { item -> String in
                switch item {
                case .string(let s):
                    let needsVBar = s.contains(" ") || s.contains("\t") || s.contains("\n")
                        || s.contains("\"") || s.contains("[") || s.contains("]") || s.contains("{") || s.contains("}") || s.contains("|")
                    if needsVBar {
                        let escaped = s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "|", with: "\\|")
                        return "|\(escaped)|"
                    }
                    return s
                default:
                    return item.toLogoSyntaxString()
                }
            }
            return "[" + formatted.joined(separator: " ") + "]"
        case .array(let items):
            let formatted = items.map { item -> String in
                switch item {
                case .string(let s):
                    let needsVBar = s.contains(" ") || s.contains("\t") || s.contains("\n")
                        || s.contains("\"") || s.contains("[") || s.contains("]") || s.contains("{") || s.contains("}") || s.contains("|")
                    if needsVBar {
                        let escaped = s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "|", with: "\\|")
                        return "|\(escaped)|"
                    }
                    return s
                default:
                    return item.toLogoSyntaxString()
                }
            }
            return "{" + formatted.joined(separator: " ") + "}"
        }
    }

    public var description: String {
        return toLogoSyntaxString()
    }

    public static func parse(_ raw: String) -> LogoValue {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
            let inner = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
            if inner.isEmpty { return .list([]) }
            let tokens = tokenizeListContent(inner)
            return .list(tokens.map { parse($0) })
        } else if trimmed.hasPrefix("{") && trimmed.hasSuffix("}") {
            let inner = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
            if inner.isEmpty { return .array([]) }
            let tokens = tokenizeListContent(inner)
            return .array(tokens.map { parse($0) })
        } else {
            var s = trimmed
            if s.hasPrefix("|") && s.hasSuffix("|") && s.count >= 2 {
                s.removeFirst()
                s.removeLast()
                s = s.replacingOccurrences(of: "\\|", with: "|").replacingOccurrences(of: "\\\\", with: "\\")
                return .string(s)
            }
            if s.hasPrefix("\"") { s.removeFirst() }
            if s.hasSuffix("\"") { s.removeLast() }
            return .string(s)
        }
    }

    private static func tokenizeListContent(_ str: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var depth = 0
        var inMultiWordString = false
        var inVBarString = false
        var isEscaped = false

        var idx = str.startIndex
        while idx < str.endIndex {
            let ch = str[idx]
            if isEscaped {
                current.append(ch)
                isEscaped = false
                idx = str.index(after: idx)
                continue
            }

            if ch == "\\" {
                current.append(ch)
                isEscaped = true
                idx = str.index(after: idx)
                continue
            }

            if ch == "|" && !inMultiWordString {
                inVBarString.toggle()
                current.append(ch)
            } else if ch == "\"" && !inVBarString {
                if !inMultiWordString && LogoTokenizer.hasMatchingMultiWordClosingQuote(in: str, startingAt: idx) {
                    inMultiWordString = true
                    current.append(ch)
                } else if inMultiWordString {
                    inMultiWordString = false
                    current.append(ch)
                } else {
                    current.append(ch)
                }
            } else if (ch == "[" || ch == "{") && !inMultiWordString && !inVBarString {
                depth += 1
                current.append(ch)
            } else if (ch == "]" || ch == "}") && !inMultiWordString && !inVBarString && depth > 0 {
                depth -= 1
                current.append(ch)
            } else if ch.isWhitespace && depth <= 0 && !inMultiWordString && !inVBarString {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    tokens.append(trimmed)
                    current = ""
                }
            } else {
                current.append(ch)
            }
            idx = str.index(after: idx)
        }
        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            tokens.append(trimmed)
        }
        return tokens
    }
}
