import Foundation

extension LogoEngine {
    internal static let singleMasks: [Character: Int] = [
        "│": 5, "─": 10, "┌": 6, "┐": 12, "└": 3, "┘": 9,
        "├": 7, "┤": 13, "┬": 14, "┴": 11, "┼": 15,
        "╵": 1, "╶": 2, "╷": 4, "╴": 8
    ]

    internal static let doubleMasks: [Character: Int] = [
        "║": 5, "═": 10, "╔": 6, "╗": 12, "╚": 3, "╝": 9,
        "╠": 7, "╣": 13, "╦": 14, "╩": 11, "╬": 15
    ]

    internal static let singleCharForMask: [Int: Character] = [
        1: "│", 2: "─", 3: "└", 4: "│", 5: "│", 6: "┌", 7: "├",
        8: "─", 9: "┘", 10: "─", 11: "┴", 12: "┐", 13: "┤", 14: "┬", 15: "┼"
    ]

    internal static let doubleCharForMask: [Int: Character] = [
        1: "║", 2: "═", 3: "╚", 4: "║", 5: "║", 6: "╔", 7: "╠",
        8: "═", 9: "╝", 10: "═", 11: "╩", 12: "╗", 13: "╣", 14: "╦", 15: "╬"
    ]

    internal func executeTurtleMove(steps: Int, directionHeading: Int, on editor: LogoEditorContext) {
        guard steps > 0 else { return }
        let (dRow, dCol, exitBit, entryBit): (Int, Int, Int, Int) = {
            switch directionHeading {
            case 0: return (-1, 0, 1, 4)   // UP: exit UP (1), entry DOWN (4)
            case 90: return (0, 1, 2, 8)   // RIGHT: exit RIGHT (2), entry LEFT (8)
            case 180: return (1, 0, 4, 1)  // DOWN: exit DOWN (4), entry UP (1)
            case 270: return (0, -1, 8, 2) // LEFT: exit LEFT (8), entry RIGHT (2)
            default: return (0, 0, 0, 0)
            }
        }()

        guard exitBit != 0 else { return }

        for step in 0..<steps {
            let currLine = editor.lineIndex
            let currCol = editor.columnIndex

            if isPenDown {
                editor.ensureLineExists(at: currLine)
                var lineChars = Array(editor.getLine(at: currLine))
                while lineChars.count <= currCol {
                    lineChars.append(" ")
                }
                let existingChar = lineChars[currCol]
                let defaultNewChar: Character = (dRow != 0) ? "│" : "─"
                let maskToApply = (step == 0) ? exitBit : ((step == steps - 1) ? entryBit : (exitBit | entryBit))
                let fusedChar = fuseCharContextual(editor: editor, line: currLine, col: currCol, existing: existingChar, defaultNewChar: defaultNewChar, moveMask: maskToApply)
                lineChars[currCol] = fusedChar
                editor.setLine(at: currLine, text: String(lineChars))
                editor.markBufferModified()
            }

            if step < steps - 1 {
                let nextLine = max(0, currLine + dRow)
                let nextCol = max(0, currCol + dCol)
                editor.lineIndex = nextLine
                editor.columnIndex = nextCol
            }
        }
    }

    internal func getLineCharAt(_ editor: LogoEditorContext, line: Int, col: Int) -> Character {
        guard line >= 0 && line < editor.lineCount else { return " " }
        let lineChars = Array(editor.getLine(at: line))
        guard col >= 0 && col < lineChars.count else { return " " }
        return lineChars[col]
    }

    internal func setLineCharAt(_ editor: LogoEditorContext, line: Int, col: Int, char: Character) {
        editor.ensureLineExists(at: line)
        var lineChars = Array(editor.getLine(at: line))
        while lineChars.count <= col {
            lineChars.append(" ")
        }
        lineChars[col] = char
        editor.setLine(at: line, text: String(lineChars))
        editor.markBufferModified()
    }

    internal func getMaskForChar(_ ch: Character) -> Int {
        return LogoEngine.singleMasks[ch] ?? LogoEngine.doubleMasks[ch] ?? 0
    }

    internal func isMaskChar(_ ch: Character) -> Bool {
        return LogoEngine.singleMasks[ch] != nil || LogoEngine.doubleMasks[ch] != nil
    }

    internal func getEffectiveMask(editor: LogoEditorContext, line: Int, col: Int, existingChar: Character) -> Int {
        var mask = getMaskForChar(existingChar)
        guard mask != 0 else { return 0 }

        if mask == 10 {
            let rightCh = getLineCharAt(editor, line: line, col: col + 1)
            let leftCh = getLineCharAt(editor, line: line, col: col - 1)
            if !isMaskChar(rightCh) { mask &= ~2 }
            if !isMaskChar(leftCh) { mask &= ~8 }
        } else if mask == 5 {
            let downCh = getLineCharAt(editor, line: line + 1, col: col)
            let upCh = getLineCharAt(editor, line: line - 1, col: col)
            if !isMaskChar(downCh) { mask &= ~4 }
            if !isMaskChar(upCh) { mask &= ~1 }
        }

        return mask
    }

    internal func fuseCharContextual(editor: LogoEditorContext, line: Int, col: Int, existing: Character, defaultNewChar: Character, moveMask: Int) -> Character {
        let existingMask = getEffectiveMask(editor: editor, line: line, col: col, existingChar: existing)
        guard existingMask != 0 else { return defaultNewChar }

        let isDouble = LogoEngine.doubleMasks[existing] != nil || LogoEngine.doubleMasks[defaultNewChar] != nil
        let fusedMask = existingMask | moveMask

        if isDouble {
            return LogoEngine.doubleCharForMask[fusedMask] ?? defaultNewChar
        } else {
            return LogoEngine.singleCharForMask[fusedMask] ?? defaultNewChar
        }
    }

    internal func fuseChar(existing: Character, defaultNewChar: Character, moveMask: Int) -> Character {
        let existingMask = getMaskForChar(existing)
        guard existingMask != 0 else { return defaultNewChar }

        let isDouble = LogoEngine.doubleMasks[existing] != nil || LogoEngine.doubleMasks[defaultNewChar] != nil
        let fusedMask = existingMask | moveMask

        if isDouble {
            return LogoEngine.doubleCharForMask[fusedMask] ?? defaultNewChar
        } else {
            return LogoEngine.singleCharForMask[fusedMask] ?? defaultNewChar
        }
    }
}
