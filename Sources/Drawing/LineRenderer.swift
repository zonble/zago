import Foundation

public enum LineArrowMode: Sendable {
    case none
    case forward
    case backward
    case both

    public var hasForwardArrow: Bool { self == .forward || self == .both }
    public var hasBackwardArrow: Bool { self == .backward || self == .both }

    public init?(token: String) {
        switch token.uppercased() {
        case "ARROW", "RIGHTARROW", "DOWNARROW": self = .forward
        case "BACKARROW", "LEFTARROW", "UPARROW": self = .backward
        case "BOTHARROW", "BOTH", "BIDIR": self = .both
        default: return nil
        }
    }
}

/// Pure character selection for Logo line commands.
public enum LineRenderer {
    public static func contextualCharacter(
        existing: Character,
        defaultNewCharacter: Character,
        moveMask: Int,
        left: Character,
        right: Character,
        up: Character,
        down: Character
    ) -> Character {
        var existingMask = Int(canvasMask(for: existing))
        guard existingMask != 0 else { return defaultNewCharacter }

        if existingMask == 10 {
            if !isLineCharacter(right) { existingMask &= ~2 }
            if !isLineCharacter(left) { existingMask &= ~8 }
        } else if existingMask == 5 {
            if !isLineCharacter(down) { existingMask &= ~4 }
            if !isLineCharacter(up) { existingMask &= ~1 }
        }

        return fuseLineCharacter(
            existing: existing,
            defaultNewCharacter: defaultNewCharacter,
            addingMask: UInt8(moveMask),
            existingMask: UInt8(existingMask))
    }

    public static func character(
        existing: Character,
        styleChar: Character,
        moveMask: Int,
        direction: CanvasDrawDirection,
        isStart: Bool,
        isEnd: Bool,
        arrowMode: LineArrowMode,
        arrowStyle: ArrowStyle,
        automatic: Bool
    ) -> Character {
        if automatic && isLineCharacter(existing) {
            return fuseLineCharacter(existing: existing, defaultNewChar: styleChar, moveMask: moveMask)
        }
        if isStart && arrowMode.hasBackwardArrow {
            return arrowHead(for: direction.opposite, style: borderStyle(for: styleChar), arrowStyle: arrowStyle)
        }
        if isEnd && arrowMode.hasForwardArrow {
            return arrowHead(for: direction, style: borderStyle(for: styleChar), arrowStyle: arrowStyle)
        }
        return fuseLineCharacter(existing: existing, defaultNewChar: styleChar, moveMask: moveMask)
    }

    private static func borderStyle(for styleChar: Character) -> BorderStyle {
        switch styleChar {
        case "-", "|": return .ascii
        case "═", "║": return .double
        case "━", "┃": return .heavy
        case "┄", "┆": return .tripleDash
        case "┅", "┇": return .heavyTripleDash
        case "┈", "┊": return .quadrupleDash
        case "┉", "┋": return .heavyQuadrupleDash
        case "╌", "╎": return .doubleDash
        case "╍", "╏": return .heavyDoubleDash
        default: return .single
        }
    }
}
