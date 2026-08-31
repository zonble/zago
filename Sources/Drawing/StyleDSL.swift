import Foundation

/// Unified parser for Box, Table, Line, and VLine Style DSLs as defined in docs/logo/styles.md.
public enum StyleDSL {
    /// Parses shorthand Style DSL border tokens ("-", "+", "=", "a", "--", "++", "---", "+++", "----", "++++").
    public static func parseBorderDSL(_ token: String) -> BorderStyle? {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).lowercased()
        switch clean {
        case "-":
            return .single
        case "+":
            return .heavy
        case "=":
            return .double
        case "a":
            return .ascii
        case "--":
            return .doubleDash
        case "++":
            return .heavyDoubleDash
        case "---":
            return .tripleDash
        case "+++":
            return .heavyTripleDash
        case "----":
            return .quadrupleDash
        case "++++":
            return .heavyQuadrupleDash
        default:
            if !clean.isEmpty && clean.allSatisfy({ $0 == "=" }) {
                return .double
            }
            if !clean.isEmpty && clean.allSatisfy({ $0 == "-" }) {
                return .single
            }
            return nil
        }
    }

    /// Parses a box or table style DSL or border style name with optional round.
    /// Examples: "-", "-)", "+", "+)", "=", "=)", "A", "a", "a)", "--", "--)", "++", "++)", "---", "---)", "+++", "+++)", "----", "----)", "++++", "++++)"
    public static func parseBoxStyle(_ token: String) -> (border: BorderStyle, rounded: Bool)? {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return nil }

        // Check if ends with ')'
        if clean.hasSuffix(")") {
            let base = String(clean.dropLast())
            if let border = parseBorderDSL(base) ?? BorderStyle(base) {
                return (border, true)
            }
        }

        let lower = clean.lowercased()
        if lower == "round" || lower == "rounded" {
            return (.single, true)
        }
        if lower == "double-round" || lower == "doubleround" || lower == "round-double" {
            return (.double, true)
        }
        if lower == "ascii-round" || lower == "asciiround" {
            return (.ascii, true)
        }

        if let border = parseBorderDSL(clean) ?? BorderStyle(clean) {
            return (border, false)
        }

        return nil
    }

    public struct LineStyleParsed: Sendable {
        public let border: BorderStyle
        public let arrowMode: LineArrowMode
        public let startArrowStyle: ArrowStyle?
        public let endArrowStyle: ArrowStyle?

        public init(
            border: BorderStyle,
            arrowMode: LineArrowMode,
            startArrowStyle: ArrowStyle? = nil,
            endArrowStyle: ArrowStyle? = nil
        ) {
            self.border = border
            self.arrowMode = arrowMode
            self.startArrowStyle = startArrowStyle
            self.endArrowStyle = endArrowStyle
        }
    }

    /// Parses line/vline style DSL like:
    /// "-", "->", "<-", "<->", "<~+|>", "<<+++>>", "++++", "-->", "<++"
    public static func parseLineStyle(_ token: String) -> LineStyleParsed? {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return nil }

        // First check standard border names or DSL tokens without arrows
        if let border = parseBorderDSL(clean) ?? BorderStyle(clean) {
            return LineStyleParsed(border: border, arrowMode: .none, startArrowStyle: nil, endArrowStyle: nil)
        }

        // Try extracting begin arrow and end arrow
        var remaining = clean
        var startArrow: ArrowStyle? = nil
        var endArrow: ArrowStyle? = nil

        let startPrefixes: [(String, ArrowStyle)] = [
            ("<=|", .double),
            ("<+|", .heavy),
            ("<*>", .solidDiamond),
            ("<>", .diamond),
            ("o", .openCircle),
            ("O", .openCircle),
            ("*", .circle),
            ("x", .cross),
            ("X", .cross),
            ("<:", .crow),
            ("<^", .harpoon),
            ("<_", .harpoon),
            ("<~", .stemmed),
            ("<|", .hollow),
            ("<.", .small),
            ("<<", .solid),
            ("<", .ascii),
        ]

        for (prefix, style) in startPrefixes {
            if remaining.hasPrefix(prefix) {
                startArrow = style
                remaining.removeFirst(prefix.count)
                break
            }
        }

        let endSuffixes: [(String, ArrowStyle)] = [
            ("|=>", .double),
            ("|+>", .heavy),
            ("<*>", .solidDiamond),
            ("<>", .diamond),
            ("o", .openCircle),
            ("O", .openCircle),
            ("*", .circle),
            ("x", .cross),
            ("X", .cross),
            (":>", .crow),
            ("^>", .harpoon),
            ("_>", .harpoon),
            ("~>", .stemmed),
            ("|>", .hollow),
            (".>", .small),
            (">>", .solid),
            (">", .ascii),
        ]

        for (suffix, style) in endSuffixes {
            if remaining.hasSuffix(suffix) {
                endArrow = style
                remaining.removeLast(suffix.count)
                break
            }
        }

        if startArrow == nil && endArrow == nil {
            return nil
        }

        let border: BorderStyle
        if remaining.isEmpty {
            border = .single
        } else if let parsedBorder = parseBorderDSL(remaining) ?? BorderStyle(remaining) {
            border = parsedBorder
        } else {
            return nil
        }

        let arrowMode: LineArrowMode
        if startArrow != nil && endArrow != nil {
            arrowMode = .both
        } else if startArrow != nil {
            arrowMode = .backward
        } else if endArrow != nil {
            arrowMode = .forward
        } else {
            arrowMode = .none
        }

        return LineStyleParsed(
            border: border,
            arrowMode: arrowMode,
            startArrowStyle: startArrow,
            endArrowStyle: endArrow
        )
    }
}
