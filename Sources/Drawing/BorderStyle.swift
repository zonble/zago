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

    public init(
        topLeft: String, topJoin: String, topRight: String,
        midLeft: String, midJoin: String, midRight: String,
        bottomLeft: String, bottomJoin: String, bottomRight: String,
        horizontal: String, vertical: String
    ) {
        self.topLeft = topLeft
        self.topJoin = topJoin
        self.topRight = topRight
        self.midLeft = midLeft
        self.midJoin = midJoin
        self.midRight = midRight
        self.bottomLeft = bottomLeft
        self.bottomJoin = bottomJoin
        self.bottomRight = bottomRight
        self.horizontal = horizontal
        self.vertical = vertical
    }
}

/// Unified source-of-truth for border, junction, and corner characters across the entire editor, drawing engine, and Logo engine.
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
                tc.bottomLeft, tc.bottomJoin, tc.bottomRight,
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

/// Shared border style used by LOGO boxes, editor tables, canvas drawing, and menu state.
public enum BorderStyle: String, CaseIterable, Codable, Sendable {
    case single = "single"
    case heavy = "heavy"
    case double = "double"
    case ascii = "ascii"
    case tripleDash = "triple-dash"
    case heavyTripleDash = "heavy-triple-dash"
    case quadrupleDash = "quadruple-dash"
    case heavyQuadrupleDash = "heavy-quadruple-dash"
    case doubleDash = "double-dash"
    case heavyDoubleDash = "heavy-double-dash"

    public init?(_ token: String) {
        let clean = token.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).lowercased()
        switch clean {
        case "single":
            self = .single
        case "heavy":
            self = .heavy
        case "double":
            self = .double
        case "ascii":
            self = .ascii
        case "double-dash":
            self = .doubleDash
        case "heavy-double-dash":
            self = .heavyDoubleDash
        case "triple-dash":
            self = .tripleDash
        case "heavy-triple-dash":
            self = .heavyTripleDash
        case "quad-dash", "quadruple-dash":
            self = .quadrupleDash
        case "heavy-quad-dash", "heavy-quadruple-dash":
            self = .heavyQuadrupleDash
        default:
            return nil
        }
    }

    public static func from(_ token: String) -> BorderStyle {
        BorderStyle(token) ?? .single
    }

    public static func isStyleToken(_ token: String) -> Bool {
        BorderStyle(token) != nil || StyleDSL.parseBoxStyle(token) != nil || StyleDSL.parseLineStyle(token) != nil
    }

    public var boxStyle: BoxStyle {
        boxStyle(rounded: false)
    }

    public func boxStyle(rounded: Bool) -> BoxStyle {
        BoxStyle.style(for: self, rounded: rounded)
    }

    public var tableCharacters: TableBorderCharacters {
        tableCharacters(rounded: false)
    }

    public func tableCharacters(rounded: Bool) -> TableBorderCharacters {
        let base: TableBorderCharacters
        switch self {
        case .heavy:
            base = TableBorderCharacters(
                topLeft: "┏", topJoin: "┳", topRight: "┓",
                midLeft: "┣", midJoin: "╋", midRight: "┫",
                bottomLeft: "┗", bottomJoin: "┻", bottomRight: "┛",
                horizontal: "━", vertical: "┃")
        case .double:
            base = TableBorderCharacters(
                topLeft: "╔", topJoin: "╦", topRight: "╗",
                midLeft: "╠", midJoin: "╬", midRight: "╣",
                bottomLeft: "╚", bottomJoin: "╩", bottomRight: "╝",
                horizontal: "═", vertical: "║")
        case .ascii:
            base = TableBorderCharacters(
                topLeft: "+", topJoin: "+", topRight: "+",
                midLeft: "+", midJoin: "+", midRight: "+",
                bottomLeft: "+", bottomJoin: "+", bottomRight: "+",
                horizontal: "-", vertical: "|")
        case .single:
            base = TableBorderCharacters(
                topLeft: "┌", topJoin: "┬", topRight: "┐",
                midLeft: "├", midJoin: "┼", midRight: "┤",
                bottomLeft: "└", bottomJoin: "┴", bottomRight: "┘",
                horizontal: "─", vertical: "│")
        case .tripleDash:
            base = BorderStyle.single.tableCharacters.withLines(horizontal: "┄", vertical: "┆")
        case .heavyTripleDash:
            base = BorderStyle.heavy.tableCharacters.withLines(horizontal: "┅", vertical: "┇")
        case .quadrupleDash:
            base = BorderStyle.single.tableCharacters.withLines(horizontal: "┈", vertical: "┊")
        case .heavyQuadrupleDash:
            base = BorderStyle.heavy.tableCharacters.withLines(horizontal: "┉", vertical: "┋")
        case .doubleDash:
            base = BorderStyle.single.tableCharacters.withLines(horizontal: "╌", vertical: "╎")
        case .heavyDoubleDash:
            base = BorderStyle.heavy.tableCharacters.withLines(horizontal: "╍", vertical: "╏")
        }

        if rounded {
            if self == .ascii {
                return TableBorderCharacters(
                    topLeft: "/", topJoin: base.topJoin, topRight: "\\",
                    midLeft: base.midLeft, midJoin: base.midJoin, midRight: base.midRight,
                    bottomLeft: "\\", bottomJoin: base.bottomJoin, bottomRight: "/",
                    horizontal: base.horizontal, vertical: base.vertical)
            } else {
                return TableBorderCharacters(
                    topLeft: "╭", topJoin: base.topJoin, topRight: "╮",
                    midLeft: base.midLeft, midJoin: base.midJoin, midRight: base.midRight,
                    bottomLeft: "╰", bottomJoin: base.bottomJoin, bottomRight: "╯",
                    horizontal: base.horizontal, vertical: base.vertical)
            }
        }
        return base
    }

    /// The character used by a horizontal line command for this style.
    public var horizontalLineCharacter: Character {
        tableCharacters.horizontal.first ?? "─"
    }

    /// The character used by a vertical line command for this style.
    public var verticalLineCharacter: Character {
        tableCharacters.vertical.first ?? "│"
    }

    public var isDashed: Bool {
        switch self {
        case .tripleDash, .heavyTripleDash, .quadrupleDash, .heavyQuadrupleDash, .doubleDash, .heavyDoubleDash:
            true
        default:
            false
        }
    }
}

extension TableBorderCharacters {
    fileprivate func withLines(horizontal: String, vertical: String) -> TableBorderCharacters {
        TableBorderCharacters(
            topLeft: topLeft, topJoin: topJoin, topRight: topRight,
            midLeft: midLeft, midJoin: midJoin, midRight: midRight,
            bottomLeft: bottomLeft, bottomJoin: bottomJoin, bottomRight: bottomRight,
            horizontal: horizontal, vertical: vertical)
    }
}

public struct BoxStyle: Sendable {
    public let topLeft: Character
    public let topChar: Character
    public let topRight: Character
    public let sideChar: Character
    public let bottomLeft: Character
    public let bottomChar: Character
    public let bottomRight: Character

    public init(
        topLeft: Character, topChar: Character, topRight: Character,
        sideChar: Character, bottomLeft: Character, bottomChar: Character, bottomRight: Character
    ) {
        self.topLeft = topLeft
        self.topChar = topChar
        self.topRight = topRight
        self.sideChar = sideChar
        self.bottomLeft = bottomLeft
        self.bottomChar = bottomChar
        self.bottomRight = bottomRight
    }

    public static let single = BoxStyle(
        topLeft: "┌", topChar: "─", topRight: "┐", sideChar: "│", bottomLeft: "└", bottomChar: "─", bottomRight: "┘")
    public static let heavy = BoxStyle(
        topLeft: "┏", topChar: "━", topRight: "┓", sideChar: "┃", bottomLeft: "┗", bottomChar: "━", bottomRight: "┛")
    public static let double = BoxStyle(
        topLeft: "╔", topChar: "═", topRight: "╗", sideChar: "║", bottomLeft: "╚", bottomChar: "═", bottomRight: "╝")
    public static let ascii = BoxStyle(
        topLeft: "+", topChar: "-", topRight: "+", sideChar: "|", bottomLeft: "+", bottomChar: "-", bottomRight: "+")
    public static let tripleDash = BoxStyle(
        topLeft: "┌", topChar: "┄", topRight: "┐", sideChar: "┆", bottomLeft: "└", bottomChar: "┄", bottomRight: "┘")
    public static let heavyTripleDash = BoxStyle(
        topLeft: "┏", topChar: "┅", topRight: "┓", sideChar: "┇", bottomLeft: "┗", bottomChar: "┅", bottomRight: "┛")
    public static let quadrupleDash = BoxStyle(
        topLeft: "┌", topChar: "┈", topRight: "┐", sideChar: "┊", bottomLeft: "└", bottomChar: "┈", bottomRight: "┘")
    public static let heavyQuadrupleDash = BoxStyle(
        topLeft: "┏", topChar: "┉", topRight: "┓", sideChar: "┋", bottomLeft: "┗", bottomChar: "┉", bottomRight: "┛")
    public static let doubleDash = BoxStyle(
        topLeft: "┌", topChar: "╌", topRight: "┐", sideChar: "╎", bottomLeft: "└", bottomChar: "╌", bottomRight: "┘")
    public static let heavyDoubleDash = BoxStyle(
        topLeft: "┏", topChar: "╍", topRight: "┓", sideChar: "╏", bottomLeft: "┗", bottomChar: "╍", bottomRight: "┛")

    public static func style(for border: BorderStyle, rounded: Bool = false) -> BoxStyle {
        switch border {
        case .single:
            return rounded
                ? BoxStyle(topLeft: "╭", topChar: "─", topRight: "╮", sideChar: "│", bottomLeft: "╰", bottomChar: "─", bottomRight: "╯")
                : BoxStyle(topLeft: "┌", topChar: "─", topRight: "┐", sideChar: "│", bottomLeft: "└", bottomChar: "─", bottomRight: "┘")
        case .heavy:
            return rounded
                ? BoxStyle(topLeft: "╭", topChar: "━", topRight: "╮", sideChar: "┃", bottomLeft: "╰", bottomChar: "━", bottomRight: "╯")
                : BoxStyle(topLeft: "┏", topChar: "━", topRight: "┓", sideChar: "┃", bottomLeft: "┗", bottomChar: "━", bottomRight: "┛")
        case .double:
            return rounded
                ? BoxStyle(topLeft: "╭", topChar: "═", topRight: "╮", sideChar: "║", bottomLeft: "╰", bottomChar: "═", bottomRight: "╯")
                : BoxStyle(topLeft: "╔", topChar: "═", topRight: "╗", sideChar: "║", bottomLeft: "╚", bottomChar: "═", bottomRight: "╝")
        case .ascii:
            return rounded
                ? BoxStyle(topLeft: "/", topChar: "-", topRight: "\\", sideChar: "|", bottomLeft: "\\", bottomChar: "-", bottomRight: "/")
                : BoxStyle(topLeft: "+", topChar: "-", topRight: "+", sideChar: "|", bottomLeft: "+", bottomChar: "-", bottomRight: "+")
        case .tripleDash:
            return rounded
                ? BoxStyle(topLeft: "╭", topChar: "┄", topRight: "╮", sideChar: "┆", bottomLeft: "╰", bottomChar: "┄", bottomRight: "╯")
                : BoxStyle(topLeft: "┌", topChar: "┄", topRight: "┐", sideChar: "┆", bottomLeft: "└", bottomChar: "┄", bottomRight: "┘")
        case .heavyTripleDash:
            return rounded
                ? BoxStyle(topLeft: "╭", topChar: "┅", topRight: "╮", sideChar: "┇", bottomLeft: "╰", bottomChar: "┅", bottomRight: "╯")
                : BoxStyle(topLeft: "┏", topChar: "┅", topRight: "┓", sideChar: "┇", bottomLeft: "┗", bottomChar: "┅", bottomRight: "┛")
        case .quadrupleDash:
            return rounded
                ? BoxStyle(topLeft: "╭", topChar: "┈", topRight: "╮", sideChar: "┊", bottomLeft: "╰", bottomChar: "┈", bottomRight: "╯")
                : BoxStyle(topLeft: "┌", topChar: "┈", topRight: "┐", sideChar: "┊", bottomLeft: "└", bottomChar: "┈", bottomRight: "┘")
        case .heavyQuadrupleDash:
            return rounded
                ? BoxStyle(topLeft: "╭", topChar: "┉", topRight: "╮", sideChar: "┋", bottomLeft: "╰", bottomChar: "┉", bottomRight: "╯")
                : BoxStyle(topLeft: "┏", topChar: "┉", topRight: "┓", sideChar: "┋", bottomLeft: "┗", bottomChar: "┉", bottomRight: "┛")
        case .doubleDash:
            return rounded
                ? BoxStyle(topLeft: "╭", topChar: "╌", topRight: "╮", sideChar: "╎", bottomLeft: "╰", bottomChar: "╌", bottomRight: "╯")
                : BoxStyle(topLeft: "┌", topChar: "╌", topRight: "┐", sideChar: "╎", bottomLeft: "└", bottomChar: "╌", bottomRight: "┘")
        case .heavyDoubleDash:
            return rounded
                ? BoxStyle(topLeft: "╭", topChar: "╍", topRight: "╮", sideChar: "╏", bottomLeft: "╰", bottomChar: "╍", bottomRight: "╯")
                : BoxStyle(topLeft: "┏", topChar: "╍", topRight: "┓", sideChar: "╏", bottomLeft: "┗", bottomChar: "╍", bottomRight: "┛")
        }
    }

    public static func from(_ str: String) -> BoxStyle {
        if let dsl = StyleDSL.parseBoxStyle(str) {
            return BoxStyle.style(for: dsl.border, rounded: dsl.rounded)
        }
        return BorderStyle.from(str).boxStyle
    }

    public static func isStyleToken(_ token: String) -> Bool {
        BorderStyle.isStyleToken(token)
    }
}

public enum BoxAlignment: String, Sendable, CaseIterable {
    case left
    case center
    case right

    public init?(_ token: String) {
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

    public static func parse(_ token: String) -> BoxAlignment? {
        BoxAlignment(token)
    }
}
