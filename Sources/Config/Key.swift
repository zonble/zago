import Foundation

/// Represents key input events.
public enum Key: Equatable, Hashable, Sendable {
    case char(Character)
    case ctrl(Character)
    case alt(Character)
    case ctrlShift(Character)
    case arrowUp
    case arrowDown
    case arrowLeft
    case arrowRight
    case home
    case end
    case pageUp
    case pageDown
    case backspace
    case ctrlBackspace
    case altBackspace
    case delete
    case enter
    case altEnter
    case tab
    case altTab
    case backtab
    case mark
    case esc
    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
    case shiftArrowLeft
    case shiftArrowRight
    case shiftArrowUp
    case shiftArrowDown
    case altArrowLeft
    case altArrowRight
    case altArrowUp
    case altArrowDown
    case ctrlArrowLeft
    case ctrlArrowRight
    case ctrlArrowUp
    case ctrlArrowDown
    case shiftHome
    case shiftEnd
    case shiftPageUp
    case shiftPageDown
    case ctrlShiftArrowLeft
    case ctrlShiftArrowRight
    case ctrlShiftArrowUp
    case ctrlShiftArrowDown
    case resize
    case unknown
}

extension Key {
    /// Formatted shortcut label suitable for the bottom Help Bar (e.g. "^S", "M-U", "F1", "Tab", "⇧+Arrow").
    public var helpBarLabel: String {
        switch self {
        case .ctrl(let ch): return "^\(ch.uppercased())"
        case .alt(let ch): return "M+\(ch.uppercased())"
        case .ctrlShift(let ch): return "C+⇧+\(ch.uppercased())"
        case .f1: return "F1"
        case .f2: return "F2"
        case .f3: return "F3"
        case .f4: return "F4"
        case .f5: return "F5"
        case .f6: return "F6"
        case .f7: return "F7"
        case .f8: return "F8"
        case .f9: return "F9"
        case .f10: return "F10"
        case .f11: return "F11"
        case .f12: return "F12"
        case .arrowUp, .arrowDown, .arrowLeft, .arrowRight: return "Arrow"
        case .shiftArrowLeft, .shiftArrowRight, .shiftArrowUp, .shiftArrowDown: return "⇧+Arrow"
        case .ctrlArrowLeft, .ctrlArrowRight, .ctrlArrowUp, .ctrlArrowDown: return "^+Arrow"
        case .ctrlShiftArrowLeft, .ctrlShiftArrowRight: return "C+⇧+←/→"
        case .ctrlShiftArrowUp, .ctrlShiftArrowDown: return "C+⇧+↑/↓"
        case .altArrowLeft, .altArrowRight, .altArrowUp, .altArrowDown: return "M+Arrow"
        case .home: return "Home"
        case .end: return "End"
        case .shiftHome: return "⇧+Home"
        case .shiftEnd: return "⇧+End"
        case .shiftPageUp: return "⇧+PgUp"
        case .shiftPageDown: return "⇧+PgDn"
        case .pageUp: return "PgUp"
        case .pageDown: return "PgDn"
        case .tab: return "Tab"
        case .altTab: return "M+Tab"
        case .backtab: return "⇧+Tab"
        case .enter: return "Enter"
        case .altEnter: return "M+Enter"
        case .esc: return "Esc"
        case .backspace: return "BS"
        case .ctrlBackspace: return "^BS"
        case .altBackspace: return "M+BS"
        case .delete: return "Del"
        case .mark: return "Mark"
        case .char(let ch): return String(ch)
        default: return ""
        }
    }
}
