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

        return switch normalized {
        case "up", "arrow-up", "arrowdown": .arrowUp
        case "down", "arrow-down": .arrowDown
        case "left", "arrow-left", "arrowleft": .arrowLeft
        case "right", "arrow-right", "arrowright": .arrowRight
        case "home": .home
        case "end": .end
        case "pageup", "page-up", "pgup": .pageUp
        case "pagedown", "page-down", "pgdn": .pageDown
        case "backspace", "bs": .backspace
        case "ctrl-backspace", "ctrl-bs", "c-backspace", "c-bs": .ctrlBackspace
        case "delete", "del": .delete
        case "enter", "return": .enter
        case "tab": .tab
        case "shift-tab", "backtab", "s-tab": .backtab
        case "mark": .mark
        case "esc", "escape": .esc
        case "shift-left", "shift-arrow-left": .shiftArrowLeft
        case "shift-right", "shift-arrow-right": .shiftArrowRight
        case "shift-up", "shift-arrow-up": .shiftArrowUp
        case "shift-down", "shift-arrow-down": .shiftArrowDown
        case "shift-home", "s-home": .shiftHome
        case "shift-end", "s-end": .shiftEnd
        case "f1": .f1
        case "f2": .f2
        case "f3": .f3
        case "f4": .f4
        case "f5": .f5
        case "f6": .f6
        case "f7": .f7
        case "f8": .f8
        case "f9": .f9
        case "f10": .f10
        case "f11": .f11
        case "f12": .f12
        default:
            if normalized.count == 1, let ch = normalized.first {
                .char(ch)
            } else {
                nil
            }
        }
    }
}
