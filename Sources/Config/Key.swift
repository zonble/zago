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
    case delete
    case enter
    case tab
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
    case ctrlArrowUp
    case ctrlArrowDown
    case shiftHome
    case shiftEnd
    case ctrlShiftArrowLeft
    case ctrlShiftArrowRight
    case ctrlShiftArrowUp
    case ctrlShiftArrowDown
    case resize
    case unknown
}
