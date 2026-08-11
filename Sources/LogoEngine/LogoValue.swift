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
            let tokens = LogoTokenizer.tokenizeValueList(inner)
            return .list(tokens.map { parse($0) })
        } else if trimmed.hasPrefix("{") && trimmed.hasSuffix("}") {
            let inner = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
            if inner.isEmpty { return .array([]) }
            let tokens = LogoTokenizer.tokenizeValueList(inner)
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

    static func parsePreservingWhitespace(_ raw: String) -> LogoValue {
        guard raw == raw.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return .string(raw)
        }
        return parse(raw)
    }

}
