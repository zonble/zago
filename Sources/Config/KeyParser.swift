import Foundation

/// Helper utility parsing key strings (e.g. "ctrl-f", "f1", "up") into Key enum.
public enum KeyParser {
    public static func parse(_ keyStr: String) -> Key? {
        let normalized = keyStr.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty { return nil }

        switch normalized {
        case "ctrl-shift-left", "ctrl-shift-arrow-left", "c-s-left", "c-s-arrow-left": return .ctrlShiftArrowLeft
        case "ctrl-shift-right", "ctrl-shift-arrow-right", "c-s-right", "c-s-arrow-right": return .ctrlShiftArrowRight
        case "ctrl-shift-up", "ctrl-shift-arrow-up", "c-s-up", "c-s-arrow-up": return .ctrlShiftArrowUp
        case "ctrl-shift-down", "ctrl-shift-arrow-down", "c-s-down", "c-s-arrow-down": return .ctrlShiftArrowDown
        default:
            break
        }

        if normalized.hasPrefix("ctrl-shift-") || normalized.hasPrefix("c-s-") {
            let prefixLen = normalized.hasPrefix("ctrl-shift-") ? 11 : 4
            let charStr = String(normalized.dropFirst(prefixLen))
            if let first = charStr.first {
                return .ctrlShift(first)
            }
        }

        if normalized.hasPrefix("ctrl-") || normalized.hasPrefix("^") {
            let charStr =
                normalized.hasPrefix("ctrl-") ? String(normalized.dropFirst(5)) : String(normalized.dropFirst(1))
            if let first = charStr.first {
                return .ctrl(Character(first.lowercased()))
            }
        }

        if normalized.hasPrefix("alt-") || normalized.hasPrefix("meta-") || normalized.hasPrefix("m-") {
            let prefixLen: Int
            if normalized.hasPrefix("alt-") {
                prefixLen = 4
            } else if normalized.hasPrefix("meta-") {
                prefixLen = 5
            } else {
                prefixLen = 2
            }

            let charStr = String(normalized.dropFirst(prefixLen))
            if let first = charStr.first {
                return .alt(first)
            }
        }

        switch normalized {
        case "up", "arrow-up", "arrowdown": return .arrowUp
        case "down", "arrow-down": return .arrowDown
        case "left", "arrow-left", "arrowleft": return .arrowLeft
        case "right", "arrow-right", "arrowright": return .arrowRight
        case "home": return .home
        case "end": return .end
        case "pageup", "page-up", "pgup": return .pageUp
        case "pagedown", "page-down", "pgdn": return .pageDown
        case "backspace", "bs": return .backspace
        case "ctrl-backspace", "ctrl-bs", "c-backspace", "c-bs": return .ctrlBackspace
        case "delete", "del": return .delete
        case "enter", "return": return .enter
        case "tab": return .tab
        case "mark": return .mark
        case "esc", "escape": return .esc
        case "shift-left", "shift-arrow-left": return .shiftArrowLeft
        case "shift-right", "shift-arrow-right": return .shiftArrowRight
        case "shift-up", "shift-arrow-up": return .shiftArrowUp
        case "shift-down", "shift-arrow-down": return .shiftArrowDown
        case "shift-home", "s-home": return .shiftHome
        case "shift-end", "s-end": return .shiftEnd
        case "f1": return .f1
        case "f2": return .f2
        case "f3": return .f3
        case "f4": return .f4
        case "f5": return .f5
        case "f6": return .f6
        case "f7": return .f7
        case "f8": return .f8
        case "f9": return .f9
        case "f10": return .f10
        case "f11": return .f11
        case "f12": return .f12
        default:
            if normalized.count == 1, let ch = normalized.first {
                return .char(ch)
            }
            return nil
        }
    }
}
