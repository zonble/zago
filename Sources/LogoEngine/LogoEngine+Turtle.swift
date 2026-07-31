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

    internal func executeTurtleMove(steps: Int, directionHeading: Int) {
        guard steps > 0, let editor = self.delegate else { return }
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
            let currLine = (editor.logoEngine(self, queryState: .currentLineIndex) as? Int) ?? 0
            let currCol = (editor.logoEngine(self, queryState: .currentColumnIndex) as? Int) ?? 0
            let nextLine = currLine + dRow
            let nextCol = currCol + dCol
            let nextIsInsideMinimumBounds = nextLine >= 0 && nextCol >= 0

            if !nextIsInsideMinimumBounds && step == 0 {
                break
            }

            if isPenDown {
                editor.logoEngine(self, performAction: .ensureLineExists(index: currLine))
                let lineStr = (editor.logoEngine(self, queryState: .lineAt(currLine)) as? String) ?? ""
                var lineChars = Array(lineStr)
                while lineChars.count <= currCol {
                    lineChars.append(" ")
                }
                let existingChar = lineChars[currCol]
                let defaultNewChar: Character = (dRow != 0) ? "│" : "─"
                let isTerminalStep = step == steps - 1 || !nextIsInsideMinimumBounds
                let maskToApply = (step == 0) ? exitBit : (isTerminalStep ? entryBit : (exitBit | entryBit))
                let fusedChar = fuseCharContextual(line: currLine, col: currCol, existing: existingChar, defaultNewChar: defaultNewChar, moveMask: maskToApply)
                lineChars[currCol] = fusedChar
                editor.logoEngine(self, performAction: .setLine(index: currLine, text: String(lineChars)))
                editor.logoEngine(self, performAction: .markModified)
            }

            if step < steps - 1 {
                guard nextIsInsideMinimumBounds else { break }
                editor.logoEngine(self, performAction: .updateLineIndex(nextLine))
                editor.logoEngine(self, performAction: .updateColumnIndex(nextCol))
            }
        }
    }

    internal func getLineCharAt(line: Int, col: Int) -> Character {
        guard let editor = self.delegate else { return " " }
        let totalLines = (editor.logoEngine(self, queryState: .lineCount) as? Int) ?? 0
        guard line >= 0 && line < totalLines else { return " " }
        let lineStr = (editor.logoEngine(self, queryState: .lineAt(line)) as? String) ?? ""
        let lineChars = Array(lineStr)
        guard col >= 0 && col < lineChars.count else { return " " }
        return lineChars[col]
    }

    internal func setLineCharAt(line: Int, col: Int, char: Character) {
        guard let editor = self.delegate else { return }
        editor.logoEngine(self, performAction: .ensureLineExists(index: line))
        let lineStr = (editor.logoEngine(self, queryState: .lineAt(line)) as? String) ?? ""
        var lineChars = Array(lineStr)
        while lineChars.count <= col {
            lineChars.append(" ")
        }
        lineChars[col] = char
        editor.logoEngine(self, performAction: .setLine(index: line, text: String(lineChars)))
        editor.logoEngine(self, performAction: .markModified)
    }

    internal func getMaskForChar(_ ch: Character) -> Int {
        return LogoEngine.singleMasks[ch] ?? LogoEngine.doubleMasks[ch] ?? 0
    }

    internal func isMaskChar(_ ch: Character) -> Bool {
        return LogoEngine.singleMasks[ch] != nil || LogoEngine.doubleMasks[ch] != nil
    }

    internal func getEffectiveMask(line: Int, col: Int, existingChar: Character) -> Int {
        var mask = getMaskForChar(existingChar)
        guard mask != 0 else { return 0 }

        if mask == 10 {
            let rightCh = getLineCharAt(line: line, col: col + 1)
            let leftCh = getLineCharAt(line: line, col: col - 1)
            if !isMaskChar(rightCh) { mask &= ~2 }
            if !isMaskChar(leftCh) { mask &= ~8 }
        } else if mask == 5 {
            let downCh = getLineCharAt(line: line + 1, col: col)
            let upCh = getLineCharAt(line: line - 1, col: col)
            if !isMaskChar(downCh) { mask &= ~4 }
            if !isMaskChar(upCh) { mask &= ~1 }
        }

        return mask
    }

    internal func fuseCharContextual(line: Int, col: Int, existing: Character, defaultNewChar: Character, moveMask: Int) -> Character {
        let existingMask = getEffectiveMask(line: line, col: col, existingChar: existing)
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
