import Foundation

public enum CanvasDrawDirection: Sendable {
    case up
    case down
    case left
    case right

    public var delta: (line: Int, column: Int) {
        switch self {
        case .up: (-1, 0)
        case .down: (1, 0)
        case .left: (0, -1)
        case .right: (0, 1)
        }
    }

    public var mask: UInt8 {
        switch self {
        case .up: 1
        case .right: 2
        case .down: 4
        case .left: 8
        }
    }

    public var opposite: CanvasDrawDirection {
        switch self {
        case .up: .down
        case .down: .up
        case .left: .right
        case .right: .left
        }
    }
}

public func canvasMask(for character: Character?, style _: BorderStyle = .single) -> UInt8 {
    guard let character else { return 0 }
    return switch character {
    case "─", "═", "-": CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask
    case "│", "║", "|": CanvasDrawDirection.up.mask | CanvasDrawDirection.down.mask
    case "┌", "╔", "╭": CanvasDrawDirection.right.mask | CanvasDrawDirection.down.mask
    case "┐", "╗", "╮": CanvasDrawDirection.left.mask | CanvasDrawDirection.down.mask
    case "└", "╚", "╰": CanvasDrawDirection.up.mask | CanvasDrawDirection.right.mask
    case "┘", "╝", "╯": CanvasDrawDirection.up.mask | CanvasDrawDirection.left.mask
    case "├", "╠": CanvasDrawDirection.up.mask | CanvasDrawDirection.right.mask | CanvasDrawDirection.down.mask
    case "┤", "╣": CanvasDrawDirection.up.mask | CanvasDrawDirection.down.mask | CanvasDrawDirection.left.mask
    case "┬", "╦": CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask | CanvasDrawDirection.down.mask
    case "┴", "╩": CanvasDrawDirection.up.mask | CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask
    case "┼", "╬", "+": 15
    case "→", ">", "▶", "►", "▷", "▸": CanvasDrawDirection.left.mask
    case "←", "<", "◀", "◄", "◁", "◂": CanvasDrawDirection.right.mask
    case "↑", "^", "▲", "△", "▴": CanvasDrawDirection.down.mask
    case "↓", "v", "▼", "▽", "▾": CanvasDrawDirection.up.mask
    default: 0
    }
}

public func lineCharacter(forMask mask: UInt8, style: BorderStyle) -> Character {
    let normalizedMask = mask == 0 ? CanvasDrawDirection.right.mask : mask
    let chars = style.tableCharacters

    if style == .ascii {
        return switch normalizedMask {
        case CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask,
            CanvasDrawDirection.left.mask,
            CanvasDrawDirection.right.mask:
            Character(chars.horizontal)
        case CanvasDrawDirection.up.mask | CanvasDrawDirection.down.mask,
            CanvasDrawDirection.up.mask,
            CanvasDrawDirection.down.mask:
            Character(chars.vertical)
        default:
            "+"
        }
    }

    return switch normalizedMask {
    case CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask,
        CanvasDrawDirection.left.mask,
        CanvasDrawDirection.right.mask:
        Character(chars.horizontal)
    case CanvasDrawDirection.up.mask | CanvasDrawDirection.down.mask,
        CanvasDrawDirection.up.mask,
        CanvasDrawDirection.down.mask:
        Character(chars.vertical)
    case CanvasDrawDirection.right.mask | CanvasDrawDirection.down.mask:
        Character(chars.topLeft)
    case CanvasDrawDirection.left.mask | CanvasDrawDirection.down.mask:
        Character(chars.topRight)
    case CanvasDrawDirection.up.mask | CanvasDrawDirection.right.mask:
        Character(chars.bottomLeft)
    case CanvasDrawDirection.up.mask | CanvasDrawDirection.left.mask:
        Character(chars.bottomRight)
    case CanvasDrawDirection.up.mask | CanvasDrawDirection.right.mask | CanvasDrawDirection.down.mask:
        Character(chars.midLeft)
    case CanvasDrawDirection.up.mask | CanvasDrawDirection.down.mask | CanvasDrawDirection.left.mask:
        Character(chars.midRight)
    case CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask | CanvasDrawDirection.down.mask:
        Character(chars.topJoin)
    case CanvasDrawDirection.up.mask | CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask:
        Character(chars.bottomJoin)
    default:
        Character(chars.midJoin)
    }
}

public func arrowHead(
    for direction: CanvasDrawDirection,
    style: BorderStyle,
    arrowStyle: ArrowStyle = .solid
) -> Character {
    if style == .ascii {
        return switch direction {
        case .up: "^"
        case .down: "v"
        case .left: "<"
        case .right: ">"
        }
    }

    return switch arrowStyle {
    case .solid:
        switch direction {
        case .up: "▲"
        case .down: "▼"
        case .left: "◀"
        case .right: "▶"
        }
    case .stemmed:
        switch direction {
        case .up: "↑"
        case .down: "↓"
        case .left: "←"
        case .right: "→"
        }
    case .hollow:
        switch direction {
        case .up: "△"
        case .down: "▽"
        case .left: "◁"
        case .right: "▷"
        }
    case .small:
        switch direction {
        case .up: "▴"
        case .down: "▾"
        case .left: "◂"
        case .right: "▸"
        }
    }
}

public func isCanvasDrawableCharacter(_ character: Character?, style: BorderStyle) -> Bool {
    guard let character else { return true }
    return character == " " || character == "\t" || canvasMask(for: character, style: style) != 0
}

public func oppositeMask(for direction: CanvasDrawDirection) -> UInt8 {
    switch direction {
    case .up: CanvasDrawDirection.down.mask
    case .down: CanvasDrawDirection.up.mask
    case .left: CanvasDrawDirection.right.mask
    case .right: CanvasDrawDirection.left.mask
    }
}
