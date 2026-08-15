import Foundation

/// Character classification used when locating and filling drawn boxes.
public enum BoxBorderCharacters {
    public static func isBorder(_ character: Character) -> Bool {
        boxBorderCharacters.contains(character)
    }

    public static func isTop(_ character: Character) -> Bool {
        topBorderCharacters.contains(character)
    }

    public static func isBottom(_ character: Character) -> Bool {
        bottomBorderCharacters.contains(character)
    }

    public static func isSide(_ character: Character) -> Bool {
        sideBorderCharacters.contains(character)
    }

    private static let topBorderCharacters: Set<Character> = [
        "┌", "┬", "┐", "─", "═", "╔", "╦", "╗", "╭", "╮", "+", "-",
    ]

    private static let bottomBorderCharacters: Set<Character> = [
        "└", "┴", "┘", "─", "═", "╚", "╩", "╝", "╰", "╯", "+", "-",
    ]

    private static let sideBorderCharacters: Set<Character> = [
        "│", "║", "|", "├", "┤", "┼", "╠", "╣", "╬", "┌", "┐", "└", "┘",
        "╔", "╗", "╚", "╝", "╭", "╮", "╰", "╯",
    ]

    private static let boxBorderCharacters: Set<Character> = [
        "│", "─", "┌", "┐", "└", "┘", "├", "┤", "┬", "┴", "┼",
        "║", "═", "╔", "╗", "╚", "╝", "╠", "╣", "╦", "╩", "╬",
        "+", "-", "|",
    ]
}
