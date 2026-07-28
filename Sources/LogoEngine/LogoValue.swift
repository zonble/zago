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

    private static func tokenizeListContent(_ str: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var depth = 0
        var inQuotes = false

        for ch in str {
            if ch == "\"" {
                inQuotes.toggle()
                current.append(ch)
            } else if (ch == "[" || ch == "{") && !inQuotes {
                depth += 1
                current.append(ch)
            } else if (ch == "]" || ch == "}") && !inQuotes {
                depth -= 1
                current.append(ch)
            } else if ch == " " && depth == 0 && !inQuotes {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty {
            tokens.append(current)
        }
        return tokens
    }
}
