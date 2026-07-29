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

    public var description: String {
        switch self {
        case .string(let str): return str
        case .list(let items): return "[" + items.map { $0.description }.joined(separator: " ") + "]"
        case .array(let items): return "{" + items.map { $0.description }.joined(separator: " ") + "}"
        }
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
            if s.hasPrefix("\"") { s.removeFirst() }
            if s.hasSuffix("\"") { s.removeLast() }
            return .string(s)
        }
    }

    private static func hasMatchingMultiWordClosingQuote(in str: String, startingAt quoteIdx: String.Index) -> Bool {
        var idx = str.index(after: quoteIdx)
        var prevChar: Character = "\""
        var depth = 0
        var foundSpace = false

        while idx < str.endIndex {
            let c = str[idx]
            if (c == "[" || c == "{") && depth >= 0 {
                depth += 1
            } else if (c == "]" || c == "}") && depth > 0 {
                depth -= 1
            } else if c.isWhitespace && depth == 0 {
                foundSpace = true
            } else if c == "\"" && depth == 0 {
                let nextIdx = str.index(after: idx)
                let nextChar: Character = nextIdx < str.endIndex ? str[nextIdx] : " "
                let isNewOpeningQuote = (prevChar.isWhitespace || prevChar == "[" || prevChar == "{") && (nextChar.isLetter || nextChar.isNumber || nextChar == ":" || nextChar == "\"")

                if isNewOpeningQuote && foundSpace {
                    return false
                }
                if !isNewOpeningQuote && foundSpace {
                    return true
                }
            }
            prevChar = c
            idx = str.index(after: idx)
        }
        return false
    }

    private static func tokenizeListContent(_ str: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var depth = 0
        var inMultiWordString = false

        var idx = str.startIndex
        while idx < str.endIndex {
            let ch = str[idx]
            if ch == "\"" {
                if !inMultiWordString && hasMatchingMultiWordClosingQuote(in: str, startingAt: idx) {
                    inMultiWordString = true
                    current.append(ch)
                } else if inMultiWordString {
                    inMultiWordString = false
                    current.append(ch)
                } else {
                    current.append(ch)
                }
            } else if (ch == "[" || ch == "{") && !inMultiWordString {
                depth += 1
                current.append(ch)
            } else if (ch == "]" || ch == "}") && !inMultiWordString {
                depth -= 1
                current.append(ch)
            } else if ch.isWhitespace && depth == 0 && !inMultiWordString {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            } else {
                current.append(ch)
            }
            idx = str.index(after: idx)
        }
        if !current.isEmpty {
            tokens.append(current)
        }
        return tokens
    }
}
