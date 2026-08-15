import Foundation

extension LogoEngine {
    internal func executeAutoLineCommand(startLine: Int, startCol: Int, styleChar: Character, arrowMode: LineArrowMode) {
        guard let editor = self.delegate else { return }
        var lineText = queryString(.lineAt(startLine)) ?? ""

        let prevCol = startCol - 1
        let connectLeft =
            prevCol >= 0 && !arrowMode.hasBackwardArrow
            && isLineCharacter(DisplayText.character(atVisualColumn: prevCol, in: lineText))
        if connectLeft {
            let existingPrev = DisplayText.character(atVisualColumn: prevCol, in: lineText)
            let fusedPrev = fuseLineCharacter(existing: existingPrev, defaultNewChar: styleChar, moveMask: 2)
            lineText = DisplayText.replacingColumns(
                in: lineText, startCol: prevCol, width: 1, with: String(fusedPrev))
            editor.logoEngine(self, performAction: .setLine(index: startLine, text: lineText))
        }

        var targetOffset: Int? = nil
        var targetChar: Character? = nil
        for offset in 1..<200 {
            let existing = DisplayText.character(atVisualColumn: startCol + offset, in: lineText)
            if existing != " " {
                targetOffset = offset
                targetChar = existing
                break
            }
        }

        let drawableOffsets: [Int]
        if let target = targetOffset {
            let shouldFuse = !arrowMode.hasForwardArrow && isLineCharacter(targetChar ?? " ")
            let maxOffset = shouldFuse ? target : target - 1
            drawableOffsets = maxOffset >= 0 ? Array(0...maxOffset) : []
        } else {
            drawableOffsets = Array(0..<10)
        }
        guard !drawableOffsets.isEmpty else { return }

        editor.logoEngine(self, performAction: .ensureLineExists(index: startLine))
        lineText = queryString(.lineAt(startLine)) ?? ""
        let lastOffset = drawableOffsets[drawableOffsets.count - 1]
        for offset in drawableOffsets {
            let col = startCol + offset
            var moveMask = horizontalMoveMask(offset: offset, lastOffset: lastOffset)
            if offset == 0 && connectLeft { moveMask = 10 }
            let existing = DisplayText.character(atVisualColumn: col, in: lineText)
            let char = LineRenderer.character(
                existing: existing, styleChar: styleChar, moveMask: moveMask,
                direction: .right, isStart: offset == 0 && (!connectLeft || arrowMode.hasBackwardArrow),
                isEnd: offset == lastOffset, arrowMode: arrowMode,
                arrowStyle: currentArrowStyle, automatic: true)
            lineText = DisplayText.replacingColumns(
                in: lineText, startCol: col, width: 1, with: String(char))
        }

        editor.logoEngine(self, performAction: .setLine(index: startLine, text: lineText))
        editor.logoEngine(self, performAction: .updateColumnIndex(startCol + drawableOffsets.count))
    }

    internal func executeAutoVlineCommand(
        startLine: Int, startCol: Int, styleChar: Character, arrowMode: LineArrowMode
    ) {
        guard let editor = self.delegate else { return }

        let prevLine = startLine - 1
        let connectAbove =
            prevLine >= 0 && !arrowMode.hasBackwardArrow
            && isLineCharacter(getLineCharAt(line: prevLine, col: startCol))
        if connectAbove {
            let prevStr = queryString(.lineAt(prevLine)) ?? ""
            let existingPrev = DisplayText.character(atVisualColumn: startCol, in: prevStr)
            let fusedPrev = fuseLineCharacter(existing: existingPrev, defaultNewChar: styleChar, moveMask: 4)
            let updatedPrev = DisplayText.replacingColumns(
                in: prevStr, startCol: startCol, width: 1, with: String(fusedPrev))
            editor.logoEngine(self, performAction: .setLine(index: prevLine, text: updatedPrev))
        }

        var targetOffset: Int? = nil
        var targetChar: Character? = nil
        for offset in 1..<100 {
            let existing = getLineCharAt(line: startLine + offset, col: startCol)
            if existing != " " {
                targetOffset = offset
                targetChar = existing
                break
            }
        }

        let drawableOffsets: [Int]
        if let target = targetOffset {
            let shouldFuse = !arrowMode.hasForwardArrow && isLineCharacter(targetChar ?? " ")
            let maxOffset = shouldFuse ? target : target - 1
            drawableOffsets = maxOffset >= 0 ? Array(0...maxOffset) : []
        } else {
            drawableOffsets = Array(0..<5)
        }
        guard !drawableOffsets.isEmpty else { return }

        let lastOffset = drawableOffsets[drawableOffsets.count - 1]
        for offset in drawableOffsets {
            let line = startLine + offset
            editor.logoEngine(self, performAction: .ensureLineExists(index: line))
            let lineStr = queryString(.lineAt(line)) ?? ""
            var moveMask = verticalMoveMask(offset: offset, lastOffset: lastOffset)
            if offset == 0 && connectAbove { moveMask = 5 }
            let existing = DisplayText.character(atVisualColumn: startCol, in: lineStr)
            let char = LineRenderer.character(
                existing: existing, styleChar: styleChar, moveMask: moveMask,
                direction: .down, isStart: offset == 0 && (!connectAbove || arrowMode.hasBackwardArrow),
                isEnd: offset == lastOffset, arrowMode: arrowMode,
                arrowStyle: currentArrowStyle, automatic: true)
            let lineText = DisplayText.replacingColumns(
                in: lineStr, startCol: startCol, width: 1, with: String(char))
            editor.logoEngine(self, performAction: .setLine(index: line, text: lineText))
        }

        editor.logoEngine(self, performAction: .updateLineIndex(startLine + max(0, drawableOffsets.count - 1)))
        editor.logoEngine(self, performAction: .updateColumnIndex(startCol))
    }

    private func horizontalMoveMask(offset: Int, lastOffset: Int) -> Int {
        if lastOffset == 0 { return 10 }
        if offset == 0 { return 2 }
        if offset == lastOffset { return 8 }
        return 10
    }

    private func verticalMoveMask(offset: Int, lastOffset: Int) -> Int {
        if lastOffset == 0 { return 5 }
        if offset == 0 { return 4 }
        if offset == lastOffset { return 1 }
        return 5
    }
}
