import Config

/// Maps ANSI / VT100 escape sequence strings and control codes to normalized `Key` values.
public enum ANSIKeyMapping {
    private static let sequenceTable: [String: Key] = [
        // Function keys (F1 ~ F12)
        "11": .f1, "11~": .f1,
        "12": .f2, "12~": .f2,
        "13": .f3, "13~": .f3,
        "14": .f4, "14~": .f4,
        "15": .f5, "15~": .f5,
        "17": .f6, "17~": .f6,
        "18": .f7, "18~": .f7,
        "19": .f8, "19~": .f8,
        "20": .f9, "20~": .f9,
        "21": .f10, "21~": .f10,
        "23": .f11, "23~": .f11,
        "24": .f12, "24~": .f12,

        // Editing & Navigation
        "3": .delete, "3~": .delete,
        "5": .pageUp, "5~": .pageUp,
        "6": .pageDown, "6~": .pageDown,

        // Shift + Arrow & Home/End Navigation
        "1;2D": .shiftArrowLeft, "2D": .shiftArrowLeft,
        "1;2C": .shiftArrowRight, "2C": .shiftArrowRight,
        "1;2A": .shiftArrowUp, "2A": .shiftArrowUp,
        "1;2B": .shiftArrowDown, "2B": .shiftArrowDown,
        "1;2H": .shiftHome, "2H": .shiftHome, "1;2~": .shiftHome, "2~": .shiftHome,
        "1;2F": .shiftEnd, "2F": .shiftEnd, "4;2~": .shiftEnd,

        // Backtab / Shift + Tab
        "Z": .backtab, "1;2Z": .backtab, "2Z": .backtab, "9;2u": .backtab,

        // Alt + Arrow Navigation
        "1;3D": .altArrowLeft, "3D": .altArrowLeft,
        "1;3C": .altArrowRight, "3C": .altArrowRight,
        "1;3A": .altArrowUp, "3A": .altArrowUp,
        "1;3B": .altArrowDown, "3B": .altArrowDown,

        // Ctrl + Arrow Navigation
        "1;5A": .ctrlArrowUp,
        "1;5B": .ctrlArrowDown,

        // Ctrl + Shift + Arrow & Shortcuts
        "1;6D": .ctrlShiftArrowLeft, "6D": .ctrlShiftArrowLeft,
        "1;6C": .ctrlShiftArrowRight, "6C": .ctrlShiftArrowRight,
        "1;6A": .ctrlShiftArrowUp, "6A": .ctrlShiftArrowUp,
        "1;6B": .ctrlShiftArrowDown, "6B": .ctrlShiftArrowDown,
        "1;6f": .ctrlShift("f"), "1;6F": .ctrlShift("f"), "102;6u": .ctrlShift("f"), "70;6u": .ctrlShift("f"),
        "1;6b": .ctrlShift("b"), "98;6u": .ctrlShift("b"), "66;6u": .ctrlShift("b"),

        // Ctrl + Left/Right Word Navigation
        "1;5D": .ctrl("B"), "5D": .ctrl("B"),
        "1;5C": .ctrl("F"), "5C": .ctrl("F"),
    ]

    private static let singleCharCSITable: [UInt8: Key] = [
        UInt8(ascii: "A"): .arrowUp,
        UInt8(ascii: "B"): .arrowDown,
        UInt8(ascii: "C"): .arrowRight,
        UInt8(ascii: "D"): .arrowLeft,
        UInt8(ascii: "a"): .shiftArrowUp,
        UInt8(ascii: "b"): .shiftArrowDown,
        UInt8(ascii: "c"): .shiftArrowRight,
        UInt8(ascii: "d"): .shiftArrowLeft,
        UInt8(ascii: "H"): .home,
        UInt8(ascii: "F"): .end,
        UInt8(ascii: "Z"): .backtab,
    ]

    private static let singleCharSS3Table: [UInt8: Key] = [
        UInt8(ascii: "H"): .home,
        UInt8(ascii: "F"): .end,
        UInt8(ascii: "P"): .f1,
        UInt8(ascii: "Q"): .f2,
        UInt8(ascii: "R"): .f3,
        UInt8(ascii: "S"): .f4,
    ]

    /// Maps ASCII control codes (e.g. 13 -> .enter, 9 -> .tab, 1...26 -> Ctrl+A..Z) to `Key`.
    public static func resolveControlCode(_ code: UInt32) -> Key? {
        switch code {
        case 13: return .enter
        case 9: return .tab
        case 8: return .ctrlBackspace
        case 127: return .backspace
        case 30: return .mark
        case 31: return .ctrl("/")
        case 1...26:
            if let scalar = UnicodeScalar(code + 64) {
                return .ctrl(Character(scalar))
            }
            return nil
        default:
            return nil
        }
    }

    /// Resolves single-character CSI sequence (e.g. `ESC [ A` -> `.arrowUp`, `ESC [ a` -> `.shiftArrowUp`).
    public static func resolveCSISingleChar(_ byte: UInt8) -> Key? {
        singleCharCSITable[byte]
    }

    /// Resolves single-character SS3 sequence (e.g. `ESC O P` -> `.f1`, `ESC O H` -> `.home`).
    public static func resolveSS3Code(_ byte: UInt8) -> Key {
        singleCharSS3Table[byte] ?? .esc
    }

    /// Resolves an ANSI sequence string (e.g. "11~", "1;2D") to a normalized `Key`.
    public static func resolve(_ sequence: String) -> Key {
        sequenceTable[sequence] ?? .unknown
    }
}
