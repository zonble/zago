import Foundation

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
        parse(str) ?? .single
    }

    static func isStyleToken(_ token: String) -> Bool {
        parse(token) != nil
    }

    private static func parse(_ token: String) -> BoxStyle? {
        switch token.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).lowercased() {
        case "single":
            .single
        case "double":
            .double
        case "round", "rounded":
            .round
        case "doubleround", "double-round", "double_round", "rounddouble", "round-double", "round_double":
            .doubleRound
        case "ascii":
            .ascii
        default:
            nil
        }
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
