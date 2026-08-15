import Foundation
import TextMetrics

extension LogoEngine {
    internal func executeInsetCommand(_ tokens: [String], index: inout Int) {
        guard let editor = self.delegate else { return }
        guard index < tokens.count else { return }

        let arguments = consumeSizedTextArguments(tokens, index: &index)
        let widthVal = arguments.width
        let heightVal = arguments.height
        let insetText = arguments.text

        if insetText.isEmpty { return }

        let startCol = queryInteger(.currentColumnIndex) ?? 0
        let startLine = queryInteger(.currentLineIndex) ?? 0

        if let width = widthVal, heightVal == nil {
            let lineStr = queryString(.lineAt(startLine)) ?? ""
            let textWidth = insetText.displayWidth
            let offset = max(0, (width - textWidth) / 2)
            let paddedText =
                String(repeating: " ", count: offset) + insetText
                + String(repeating: " ", count: max(0, width - offset - textWidth))
            let newText = DisplayText.replacingColumns(
                in: lineStr, startCol: startCol, width: width, with: paddedText)

            editor.logoEngine(self, performAction: .ensureLineExists(index: startLine))
            editor.logoEngine(self, performAction: .setLine(index: startLine, text: newText))
            editor.logoEngine(self, performAction: .updateColumnIndex(startCol + width))
            return
        }

        if let width = widthVal, let height = heightVal {
            let layout = TextBoxRenderer().insetRows(text: insetText, width: width, height: height)
            for (row, replacementText) in layout.rows.enumerated() {
                let lineIdx = startLine + row
                editor.logoEngine(self, performAction: .ensureLineExists(index: lineIdx))
                let lineStr = queryString(.lineAt(lineIdx)) ?? ""
                let newText = DisplayText.replacingColumns(
                    in: lineStr, startCol: startCol, width: width, with: replacementText)
                editor.logoEngine(self, performAction: .setLine(index: lineIdx, text: newText))
            }

            editor.logoEngine(self, performAction: .updateLineIndex(startLine + height))
            editor.logoEngine(self, performAction: .updateColumnIndex(startCol + width))
            return
        }

        performBoxInset(startLine: startLine, startCol: startCol, insetText: insetText)
    }

    private func performBoxInset(startLine: Int, startCol: Int, insetText: String) {
        guard let editor = self.delegate else { return }

        let lineCount = queryInteger(.lineCount) ?? (startLine + 10)
        let scanLineCount = min(lineCount + 50, startLine + 100)
        let lines = (0..<scanLineCount).map { queryString(.lineAt($0)) ?? "" }
        guard let bounds = BoxRegionDetector.findBounds(
            in: lines, startLine: startLine, startColumn: startCol,
            maxColumn: min(200, startCol + 150)), bounds.isUsable
        else {
            let lineStr = queryString(.lineAt(startLine)) ?? ""
            let textWidth = insetText.displayWidth
            let offset = max(0, (40 - textWidth) / 2)
            let replacement = String(repeating: " ", count: offset) + insetText
            let newText = DisplayText.replacingColumns(
                in: lineStr, startCol: startCol, width: replacement.displayWidth, with: replacement)
            editor.logoEngine(self, performAction: .setLine(index: startLine, text: newText))
            return
        }

        let innerTop = bounds.topLine + 1
        let innerBottom = bounds.bottomLine - 1
        let innerLeft = bounds.leftColumn + 1
        let innerRight = bounds.rightColumn - 1
        let innerWidth = innerRight - innerLeft + 1
        let innerHeight = innerBottom - innerTop + 1
        let layout = TextBoxRenderer().insetRows(
            text: insetText, width: innerWidth, height: innerHeight)

        for (row, replacementText) in layout.rows.enumerated() {
            let currentLineIdx = innerTop + row
            editor.logoEngine(self, performAction: .ensureLineExists(index: currentLineIdx))
            let lineStr = queryString(.lineAt(currentLineIdx)) ?? ""
            let newText = DisplayText.replacingColumns(
                in: lineStr, startCol: innerLeft, width: innerWidth, with: replacementText)
            editor.logoEngine(self, performAction: .setLine(index: currentLineIdx, text: newText))
        }

        editor.logoEngine(self, performAction: .updateLineIndex(innerTop + layout.targetRow))
        editor.logoEngine(self, performAction: .updateColumnIndex(innerLeft + layout.targetColumn))
    }
}
