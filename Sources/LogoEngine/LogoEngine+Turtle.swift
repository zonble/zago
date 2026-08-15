import Foundation

extension LogoEngine {

    internal func executeTurtleMove(steps: Int, heading: LogoHeading) {
        guard steps > 0, let editor = self.delegate else { return }
        let (dRow, dCol, exitBit, entryBit): (Int, Int, Int, Int) = {
            switch heading {
            case .up: return (-1, 0, 1, 4)  // UP: exit UP (1), entry DOWN (4)
            case .right: return (0, 1, 2, 8)  // RIGHT: exit RIGHT (2), entry LEFT (8)
            case .down: return (1, 0, 4, 1)  // DOWN: exit DOWN (4), entry UP (1)
            case .left: return (0, -1, 8, 2)  // LEFT: exit LEFT (8), entry RIGHT (2)
            }
        }()

        guard exitBit != 0 else { return }

        for step in 0..<steps {
            let currLine = queryInteger(.currentLineIndex) ?? 0
            let currCol = queryInteger(.currentColumnIndex) ?? 0
            let nextLine = currLine + dRow
            let nextCol = currCol + dCol
            let nextIsInsideMinimumBounds = nextLine >= 0 && nextCol >= 0

            if !nextIsInsideMinimumBounds && step == 0 {
                break
            }

            if isPenDown {
                editor.logoEngine(self, performAction: .ensureLineExists(index: currLine))
                let lineStr = queryString(.lineAt(currLine)) ?? ""
                let existingChar = DisplayText.character(atVisualColumn: currCol, in: lineStr)
                let defaultNewChar: Character = (dRow != 0) ? "│" : "─"
                let isTerminalStep = step == steps - 1 || !nextIsInsideMinimumBounds
                let maskToApply = (step == 0) ? exitBit : (isTerminalStep ? entryBit : (exitBit | entryBit))
                let fusedChar = LineRenderer.contextualCharacter(
                    existing: existingChar,
                    defaultNewCharacter: defaultNewChar,
                    moveMask: maskToApply,
                    left: getLineCharAt(line: currLine, col: currCol - 1),
                    right: getLineCharAt(line: currLine, col: currCol + 1),
                    up: getLineCharAt(line: currLine - 1, col: currCol),
                    down: getLineCharAt(line: currLine + 1, col: currCol))
                let updatedLineText = DisplayText.replacingColumns(
                    in: lineStr, startCol: currCol, width: 1, with: String(fusedChar))
                editor.logoEngine(self, performAction: .setLine(index: currLine, text: updatedLineText))
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
        guard self.delegate != nil else { return " " }
        let totalLines = queryInteger(.lineCount) ?? 0
        guard line >= 0 && line < totalLines else { return " " }
        let lineStr = queryString(.lineAt(line)) ?? ""
        return DisplayText.character(atVisualColumn: col, in: lineStr)
    }

    internal func setLineCharAt(line: Int, col: Int, char: Character) {
        guard let editor = self.delegate else { return }
        editor.logoEngine(self, performAction: .ensureLineExists(index: line))
        let lineStr = queryString(.lineAt(line)) ?? ""
        let updated = DisplayText.replacingColumns(in: lineStr, startCol: col, width: 1, with: String(char))
        editor.logoEngine(self, performAction: .setLine(index: line, text: updated))
        editor.logoEngine(self, performAction: .markModified)
    }

}
