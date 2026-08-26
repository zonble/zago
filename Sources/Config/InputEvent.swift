import Foundation

/// Top-level terminal input event (key press, mouse interaction, or external file open command).
public enum InputEvent: Equatable, Hashable, Sendable {
    case key(Key)
    case mouse(MouseEvent)
    case openFile(String)
}

/// Represents mouse interactions captured by the terminal driver.
public struct MouseEvent: Equatable, Hashable, Sendable {
    public enum Action: Equatable, Hashable, Sendable {
        case press(Button)
        case release(Button)
        case drag(Button)
        case scrollUp
        case scrollDown
    }

    public enum Button: Equatable, Hashable, Sendable {
        case left
        case middle
        case right
    }

    public let action: Action
    public let col: Int      // Native 1-based column (1..cols) matching SGR 1006
    public let row: Int      // Native 1-based row (1..rows) matching SGR 1006
    public let shift: Bool
    public let alt: Bool
    public let ctrl: Bool

    public init(
        action: Action,
        col: Int,
        row: Int,
        shift: Bool = false,
        alt: Bool = false,
        ctrl: Bool = false
    ) {
        self.action = action
        self.col = col
        self.row = row
        self.shift = shift
        self.alt = alt
        self.ctrl = ctrl
    }
}
