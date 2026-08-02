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

/// Unified source-of-truth for border, junction, and corner characters across the entire editor and Logo engine.
public struct BorderCharacterSet: Sendable {
    /// All vertical border characters (`│`, `║`, `|`, `/`, `\`).
    public static let verticalBorderChars: Set<Character> = {
        var set = Set(BorderStyle.allCases.compactMap { $0.tableCharacters.vertical.first })
        set.insert("/")
        set.insert("\\")
        return set
    }()

    /// All horizontal border characters (`─`, `═`, `-`).
    public static let horizontalBorderChars: Set<Character> = {
        Set(BorderStyle.allCases.compactMap { $0.tableCharacters.horizontal.first })
    }()

    /// All border corner and T/cross junction characters.
    public static let allJunctionChars: Set<Character> = {
        var set = Set<Character>()
        for style in BorderStyle.allCases {
            let tc = style.tableCharacters
            let cornersAndJoins = [
                tc.topLeft, tc.topJoin, tc.topRight,
                tc.midLeft, tc.midJoin, tc.midRight,
                tc.bottomLeft, tc.bottomJoin, tc.bottomRight
            ]
            for str in cornersAndJoins {
                if let ch = str.first {
                    set.insert(ch)
                }
            }
        }
        set.insert("+")
        set.insert("/")
        set.insert("\\")
        return set
    }()

    /// Union of vertical, horizontal, and junction border characters.
    public static let allBorderChars: Set<Character> = {
        verticalBorderChars.union(horizontalBorderChars).union(allJunctionChars)
    }()

    /// Vertical border characters including all corner and T/cross junctions (for vertical boundary scanning).
    public static let verticalBoundaryChars: Set<Character> = {
        verticalBorderChars.union(allJunctionChars)
    }()

    /// Horizontal border characters including all corner and T/cross junctions (for horizontal boundary scanning).
    public static let horizontalBoundaryChars: Set<Character> = {
        horizontalBorderChars.union(allJunctionChars)
    }()

    /// Returns true if character is any recognized border, junction, or corner character.
    public static func isBorderOrJunction(_ ch: Character) -> Bool {
        allBorderChars.contains(ch)
    }

    /// Returns true if character is a horizontal border character.
    public static func isHorizontal(_ ch: Character) -> Bool {
        horizontalBorderChars.contains(ch)
    }

    /// Returns true if character is a vertical border character.
    public static func isVertical(_ ch: Character) -> Bool {
        verticalBorderChars.contains(ch)
    }

    /// Returns true if character is a junction or corner character.
    public static func isJunction(_ ch: Character) -> Bool {
        allJunctionChars.contains(ch)
    }
}

/// Shared border style used by LOGO boxes, editor tables, and menu state.
public enum BorderStyle: String, CaseIterable, Sendable {
    case single = "single"
    case double = "double"
    case round = "round"
    case doubleRound = "double-round"
    case ascii = "ascii"
    case asciiRound = "ascii-round"

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
        case "asciiround", "ascii-round", "ascii_round", "asciirounded", "ascii-rounded", "ascii_rounded":
            self = .asciiRound
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
        case .single:
            return .single
        case .double:
            return .double
        case .round:
            return .round
        case .doubleRound:
            return .doubleRound
        case .ascii:
            return .ascii
        case .asciiRound:
            return .asciiRound
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
        case .asciiRound:
            return TableBorderCharacters(
                topLeft: "/", topJoin: "+", topRight: "\\",
                midLeft: "+", midJoin: "+", midRight: "+",
                bottomLeft: "\\", bottomJoin: "+", bottomRight: "/",
                horizontal: "-", vertical: "|")
        case .single:
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
    static let asciiRound = BoxStyle(topLeft: "/", topChar: "-", topRight: "\\", sideChar: "|", bottomLeft: "\\", bottomChar: "-", bottomRight: "/")

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
