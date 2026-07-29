import Foundation

public struct TableBorderCharacters: Sendable {
    public let topLeft: String
    public let topJoin: String
    public let topRight: String
    public let midLeft: String
    public let midJoin: String
    public let midRight: String
    public let bottomLeft: String
    public let bottomJoin: String
    public let bottomRight: String
    public let horizontal: String
    public let vertical: String
}

/// Shared border style used by LOGO boxes, editor tables, and menu state.
public enum BorderStyle: String, CaseIterable, Sendable {
    case single = "single"
    case double = "double"
    case round = "round"
    case doubleRound = "double-round"
    case ascii = "ascii"
    case markdown = "markdown"

    public init?(_ token: String) {
        switch token.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).lowercased() {
        case "single":
            self = .single
        case "double":
            self = .double
        case "round", "rounded":
            self = .round
        case "doubleround", "double-round", "double_round", "rounddouble", "round-double", "round_double":
            self = .doubleRound
        case "ascii":
            self = .ascii
        case "markdown":
            self = .markdown
        default:
            return nil
        }
    }

    public static func from(_ token: String) -> BorderStyle {
        BorderStyle(token) ?? .single
    }

    public static func isStyleToken(_ token: String) -> Bool {
        BorderStyle(token) != nil
    }

    var boxStyle: BoxStyle {
        switch self {
        case .single, .markdown:
            return .single
        case .double:
            return .double
        case .round:
            return .round
        case .doubleRound:
            return .doubleRound
        case .ascii:
            return .ascii
        }
    }

    public var tableCharacters: TableBorderCharacters {
        switch self {
        case .double:
            return TableBorderCharacters(
                topLeft: "╔", topJoin: "╦", topRight: "╗",
                midLeft: "╠", midJoin: "╬", midRight: "╣",
                bottomLeft: "╚", bottomJoin: "╩", bottomRight: "╝",
                horizontal: "═", vertical: "║")
        case .round:
            return TableBorderCharacters(
                topLeft: "╭", topJoin: "┬", topRight: "╮",
                midLeft: "├", midJoin: "┼", midRight: "┤",
                bottomLeft: "╰", bottomJoin: "┴", bottomRight: "╯",
                horizontal: "─", vertical: "│")
        case .doubleRound:
            return TableBorderCharacters(
                topLeft: "╭", topJoin: "╦", topRight: "╮",
                midLeft: "╠", midJoin: "╬", midRight: "╣",
                bottomLeft: "╰", bottomJoin: "╩", bottomRight: "╯",
                horizontal: "═", vertical: "║")
        case .ascii:
            return TableBorderCharacters(
                topLeft: "+", topJoin: "+", topRight: "+",
                midLeft: "+", midJoin: "+", midRight: "+",
                bottomLeft: "+", bottomJoin: "+", bottomRight: "+",
                horizontal: "-", vertical: "|")
        case .single, .markdown:
            return TableBorderCharacters(
                topLeft: "┌", topJoin: "┬", topRight: "┐",
                midLeft: "├", midJoin: "┼", midRight: "┤",
                bottomLeft: "└", bottomJoin: "┴", bottomRight: "┘",
                horizontal: "─", vertical: "│")
        }
    }
}

public struct BoxStyle: Sendable {
    let topLeft: Character
    let topChar: Character
    let topRight: Character
    let sideChar: Character
    let bottomLeft: Character
    let bottomChar: Character
    let bottomRight: Character

    static let single = BoxStyle(topLeft: "┌", topChar: "─", topRight: "┐", sideChar: "│", bottomLeft: "└", bottomChar: "─", bottomRight: "┘")
    static let double = BoxStyle(topLeft: "╔", topChar: "═", topRight: "╗", sideChar: "║", bottomLeft: "╚", bottomChar: "═", bottomRight: "╝")
    static let round  = BoxStyle(topLeft: "╭", topChar: "─", topRight: "╮", sideChar: "│", bottomLeft: "╰", bottomChar: "─", bottomRight: "╯")
    static let doubleRound = BoxStyle(topLeft: "╭", topChar: "═", topRight: "╮", sideChar: "║", bottomLeft: "╰", bottomChar: "═", bottomRight: "╯")
    static let ascii  = BoxStyle(topLeft: "+", topChar: "-", topRight: "+", sideChar: "|", bottomLeft: "+", bottomChar: "-", bottomRight: "+")

    static func from(_ str: String) -> BoxStyle {
        BorderStyle.from(str).boxStyle
    }

    static func isStyleToken(_ token: String) -> Bool {
        BorderStyle.isStyleToken(token)
    }
}

enum BoxAlignment: String, Sendable {
    case left
    case center
    case right

    init?(_ token: String) {
        switch token.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).lowercased() {
        case "left":
            self = .left
        case "center", "centre":
            self = .center
        case "right":
            self = .right
        default:
            return nil
        }
    }
}
