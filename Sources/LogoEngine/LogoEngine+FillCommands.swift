import Foundation
import TextMetrics

extension LogoEngine {
    internal func executeFillCommand(_ tokens: [String], index: inout Int) {
        guard let editor = self.delegate else { return }
        guard index < tokens.count else { return }

        var widthVal: Int? = nil
        var heightVal: Int? = nil
        var fillPattern = ""

        if let w = parseIntExpressionArgument(tokens, index: &index, isBoundary: shouldStopFillArgumentScan) {
            widthVal = w
            if index + 1 < tokens.count {
                var heightIndex = index + 1
                if let h = parseIntExpressionArgument(
                    tokens, index: &heightIndex, isBoundary: shouldStopFillArgumentScan)
                {
                    index = heightIndex
                    heightVal = h
                }
            }
            if index + 1 < tokens.count {
                var evalIndex = index + 1
                fillPattern = unquote(evaluateExpression(tokens, index: &evalIndex))
                index = evalIndex
            }
        } else {
            fillPattern = unquote(evaluateExpression(tokens, index: &index))
        }

        if fillPattern.isEmpty {
            editor.logoEngine(self, performAction: .setStatusMessage("Fill text required"))
            hasSetStatusMessage = true
            return
        }

        if queryBool(.hasTableCell) == true {
            editor.logoEngine(self, performAction: .fillTableCell(fillPattern))
            hasSetStatusMessage = true
            return
        }

        if queryBool(.hasCanvasBlockMark) == true {
            editor.logoEngine(self, performAction: .fillCanvasBlock(fillPattern))
            hasSetStatusMessage = true
            return
        }

        let startCol = queryInteger(.currentColumnIndex) ?? 0
        let startLine = queryInteger(.currentLineIndex) ?? 0

        if let width = widthVal, heightVal == nil {
            let lineStr = queryString(.lineAt(startLine)) ?? ""
            let filledLine = TextFillRenderer.tiled(fillPattern, toDisplayWidth: width)
            let newText = DisplayText.replacingColumns(
                in: lineStr, startCol: startCol, width: width, with: filledLine)

            editor.logoEngine(self, performAction: .ensureLineExists(index: startLine))
            editor.logoEngine(self, performAction: .setLine(index: startLine, text: newText))
            editor.logoEngine(self, performAction: .updateColumnIndex(startCol + filledLine.displayWidth))
            return
        }

        if let width = widthVal, let height = heightVal {
            let filledLine = TextFillRenderer.tiled(fillPattern, toDisplayWidth: width)
            let boxWidth = filledLine.displayWidth
            for row in 0..<height {
                let lineIdx = startLine + row
                editor.logoEngine(self, performAction: .ensureLineExists(index: lineIdx))
                let lineStr = queryString(.lineAt(lineIdx)) ?? ""
                let newText = DisplayText.replacingColumns(
                    in: lineStr, startCol: startCol, width: width, with: filledLine)
                editor.logoEngine(self, performAction: .setLine(index: lineIdx, text: newText))
            }
            editor.logoEngine(self, performAction: .updateLineIndex(startLine + height))
            editor.logoEngine(self, performAction: .updateColumnIndex(startCol + boxWidth))
            return
        }

        performFloodFill(startLine: startLine, startCol: startCol, fillPattern: fillPattern)
    }

    internal func shouldStopFillArgumentScan(at token: String) -> Bool {
        LogoEngine.isStatementCommand(token) || token == "]" || token == ")"
    }

    private func performFloodFill(startLine: Int, startCol: Int, fillPattern: String) {
        guard let editor = self.delegate else { return }

        let totalLines = max(startLine + 1, queryInteger(.lineCount) ?? 0)
        let maxRows = min(totalLines + 20, 200)
        let lines = (0..<maxRows).map { queryString(.lineAt($0)) ?? "" }
        let result = TextFillRenderer.floodFill(
            lines: lines, startLine: startLine, startColumn: startCol)

        if result.escaped || result.reachedLimit {
            editor.logoEngine(
                self,
                performAction: .setStatusMessage("[ Fill requires an enclosed region or explicit size ]"))
            hasSetStatusMessage = true
            return
        }

        let spansByLine = Dictionary(grouping: result.spans, by: \.line)
        for (line, spans) in spansByLine {
            editor.logoEngine(self, performAction: .ensureLineExists(index: line))
            var lineText = queryString(.lineAt(line)) ?? ""
            for span in spans.sorted(by: { $0.startColumn > $1.startColumn }) {
                let width = span.endColumn - span.startColumn + 1
                let replacement = TextFillRenderer.tiled(fillPattern, toDisplayWidth: width)
                lineText = DisplayText.replacingColumns(
                    in: lineText, startCol: span.startColumn, width: width, with: replacement)
            }
            editor.logoEngine(self, performAction: .setLine(index: line, text: lineText))
        }
    }
}
