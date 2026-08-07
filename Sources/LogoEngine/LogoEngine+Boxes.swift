import Foundation
import TextMetrics

public enum BoxExitPosition: String, Sendable, CaseIterable {
    case ne
    case se
    case nw
    case sw
    case down

    public init?(_ raw: String) {
        let clean = raw.lowercased().filter { $0.isLetter || $0.isNumber }
        switch clean {
        case "ne", "atne", "topright":
            self = .ne
        case "se", "atse", "bottomright":
            self = .se
        case "nw", "atnw", "topleft":
            self = .nw
        case "sw", "atsw", "bottomleft":
            self = .sw
        case "down", "atdown", "bottom", "s", "south":
            self = .down
        default:
            return nil
        }
    }
}

extension LogoEngine {
    internal enum BoxDrawMode {
        case insert
        case overlay
    }

    private func defaultBoxStyle() -> BoxStyle {
        guard let style = delegate?.logoEngine(self, queryState: .defaultBorderStyle) as? BorderStyle else {
            return .single
        }
        return style.boxStyle
    }

    private func boxStyle(named styleName: String) -> BoxStyle {
        styleName.isEmpty ? defaultBoxStyle() : BorderStyle.from(styleName).boxStyle
    }

    internal func executeBoxCommand(_ tokens: [String], index: inout Int, mode: BoxDrawMode = .insert) {
        guard index < tokens.count else {
            if let frame = delegate?.logoEngine(self, queryState: .canvasBlockFrame) as? LogoCanvasBlockFrame {
                drawBoxFrameAt(
                    startLine: frame.lineIndex,
                    startCol: frame.visualColumn,
                    width: max(3, min(frame.width, 200)),
                    height: max(2, min(frame.height, 100)),
                    style: defaultBoxStyle(),
                    mode: mode
                )
                return
            }
            drawBoxFrame(width: 20, height: 5, style: defaultBoxStyle(), mode: mode)
            return
        }

        // Mode 1: BOX width [height] ["text"] [align] [style] [exitPos]
        if let w = parseBoxDimensionArgument(tokens, index: &index) {
            let width = max(3, min(w, 200))
            var height: Int? = nil
            var textContent: String? = nil
            var align = "left"
            var hasExplicitAlign = false
            var styleName = ""
            var exitPos: BoxExitPosition = .ne

            if index + 1 < tokens.count {
                var heightIndex = index + 1
                if let h = parseBoxDimensionArgument(tokens, index: &heightIndex) {
                    index = heightIndex
                    height = max(2, min(h, 100))
                }
            }

            while index + 1 < tokens.count {
                let nextToken = tokens[index + 1]
                if shouldStopBoxArgumentScan(at: nextToken) { break }
                index += 1
                let rawToken = tokens[index]
                let isQuoted = isQuotedWordToken(rawToken)
                let val = unquote(rawToken)

                if let parsedExit = (!isQuoted || val.lowercased().hasPrefix("at:")) ? BoxExitPosition(val) : nil {
                    exitPos = parsedExit
                } else if let parsedAlign = BoxAlignment(val) {
                    align = parsedAlign.rawValue
                    hasExplicitAlign = true
                } else if BorderStyle.isStyleToken(val) {
                    styleName = val
                } else if textContent == nil {
                    textContent = val
                }
            }

            if let text = textContent {
                if !hasExplicitAlign {
                    align = "center"
                }
                drawBoxAroundText(
                    text, targetWidth: width, targetHeight: height, align: align, style: boxStyle(named: styleName),
                    mode: mode, exitPos: exitPos)
            } else {
                drawBoxFrame(
                    width: width, height: height ?? 5, style: boxStyle(named: styleName), mode: mode, exitPos: exitPos)
            }
            return
        }

        // Mode 2: BOX "text" [width] [align/style/exit]
        let textContent = evaluateExpression(tokens, index: &index)
        var targetWidth: Int? = nil
        var align = "left"
        var styleName = ""
        var exitPos: BoxExitPosition = .ne

        if index + 1 < tokens.count {
            var widthIndex = index + 1
            if let width = parseBoxDimensionArgument(tokens, index: &widthIndex) {
                index = widthIndex
                targetWidth = max(3, min(width, 200))
                align = "center"
            }
        }

        while index + 1 < tokens.count {
            let nextToken = tokens[index + 1]
            if shouldStopBoxArgumentScan(at: nextToken) { break }
            index += 1
            let rawToken = tokens[index]
            let isQuoted = isQuotedWordToken(rawToken)
            let val = unquote(rawToken)

            if let parsedExit = (!isQuoted || val.lowercased().hasPrefix("at:")) ? BoxExitPosition(val) : nil {
                exitPos = parsedExit
            } else if let parsedAlign = BoxAlignment(val) {
                align = parsedAlign.rawValue
            } else if BorderStyle.isStyleToken(val) {
                styleName = val
            }
        }

        drawBoxAroundText(
            textContent, targetWidth: targetWidth, targetHeight: nil, align: align, style: boxStyle(named: styleName),
            mode: mode, exitPos: exitPos)
    }

    private func parseBoxDimensionArgument(_ tokens: [String], index: inout Int) -> Int? {
        parseIntExpressionArgument(tokens, index: &index) { token in
            let unquoted = unquote(token)
            return LogoEngine.isStatementCommand(token) || token == "]" || token == ")"
                || BorderStyle.isStyleToken(unquoted) || BoxAlignment(unquoted) != nil
                || BoxExitPosition(unquoted) != nil
        }
    }

    private func shouldStopBoxArgumentScan(at token: String) -> Bool {
        if token == "]" || token == ")" { return true }
        if BoxAlignment(token) != nil || BorderStyle.isStyleToken(token) || BoxExitPosition(token) != nil {
            return false
        }
        return LogoEngine.isKeyword(token)
    }

    private func drawBoxFrame(
        width: Int, height: Int, style: BoxStyle, mode: BoxDrawMode, exitPos: BoxExitPosition = .ne
    ) {
        guard let editor = self.delegate else { return }
        let startCol = (editor.logoEngine(self, queryState: .currentColumnIndex) as? Int) ?? 0
        let startLine = (editor.logoEngine(self, queryState: .currentLineIndex) as? Int) ?? 0

        drawBoxFrameAt(
            startLine: startLine,
            startCol: startCol,
            width: width,
            height: height,
            style: style,
            mode: mode,
            exitPos: exitPos
        )
    }

    private func drawBoxFrameAt(
        startLine: Int,
        startCol: Int,
        width: Int,
        height: Int,
        style: BoxStyle,
        mode: BoxDrawMode,
        exitPos: BoxExitPosition = .ne
    ) {
        guard let editor = self.delegate else { return }

        for r in 0..<height {
            let currentLineIndex = startLine + r
            editor.logoEngine(self, performAction: .ensureLineExists(index: currentLineIndex))

            let lineStr = (editor.logoEngine(self, queryState: .lineAt(currentLineIndex)) as? String) ?? ""
            let isTop = (r == 0)
            let isBottom = (r == height - 1)
            var rowStr = ""

            for c in 0..<width {
                let isLeft = (c == 0)
                let isRight = (c == width - 1)

                var ch: Character = " "

                if isTop && isLeft {
                    ch = style.topLeft
                } else if isTop && isRight {
                    ch = style.topRight
                } else if isBottom && isLeft {
                    ch = style.bottomLeft
                } else if isBottom && isRight {
                    ch = style.bottomRight
                } else if isTop {
                    ch = style.topChar
                } else if isBottom {
                    ch = style.bottomChar
                } else if isLeft || isRight {
                    ch = style.sideChar
                }

                rowStr.append(ch)
            }

            let newLineText = buildRowText(
                existingLine: lineStr, startCol: startCol, rowStr: rowStr, isTop: isTop, isBottom: isBottom,
                mode: mode)
            editor.logoEngine(self, performAction: .setLine(index: currentLineIndex, text: newLineText))
        }

        updateCursorAfterBox(startLine: startLine, startCol: startCol, width: width, height: height, exitPos: exitPos)
    }

    private func drawBoxAroundText(
        _ text: String, targetWidth: Int?, targetHeight: Int?, align: String, style: BoxStyle, mode: BoxDrawMode,
        exitPos: BoxExitPosition = .ne
    ) {
        guard let editor = self.delegate else { return }
        let rawLines = text.replacingOccurrences(of: "\\n", with: "\n").components(separatedBy: "\n")
        let maxVisualWidth = rawLines.map { $0.displayWidth }.max() ?? 0
        let calcWidth = targetWidth ?? (maxVisualWidth + 4)
        let innerWidth = max(1, calcWidth - 2)

        var textLines: [String] = []
        for rLine in rawLines {
            textLines.append(contentsOf: wrapTextLine(rLine, maxWidth: innerWidth))
        }

        let calcHeight = max(targetHeight ?? 0, textLines.count + 2)

        let startCol = (editor.logoEngine(self, queryState: .currentColumnIndex) as? Int) ?? 0
        let startLine = (editor.logoEngine(self, queryState: .currentLineIndex) as? Int) ?? 0

        for r in 0..<calcHeight {
            let currentLineIndex = startLine + r
            editor.logoEngine(self, performAction: .ensureLineExists(index: currentLineIndex))

            let isTop = (r == 0)
            let isBottom = (r == calcHeight - 1)

            let rowStr: String
            if isTop {
                rowStr =
                    String(style.topLeft) + String(repeating: style.topChar, count: innerWidth) + String(style.topRight)
            } else if isBottom {
                rowStr =
                    String(style.bottomLeft) + String(repeating: style.bottomChar, count: innerWidth)
                    + String(style.bottomRight)
            } else {
                let lineStr = (r >= 1 && (r - 1) < textLines.count) ? textLines[r - 1] : ""
                let textWidth = lineStr.displayWidth
                let textOffset: Int
                if align == "center" || align == "centre" {
                    textOffset = max(0, (innerWidth - textWidth) / 2)
                } else if align == "right" {
                    textOffset = max(0, innerWidth - textWidth)
                } else {
                    textOffset = (innerWidth > textWidth) ? 1 : 0
                }

                let leftSpaces = String(repeating: " ", count: textOffset)
                let rightSpacesCount = max(0, innerWidth - textOffset - textWidth)
                let rightSpaces = String(repeating: " ", count: rightSpacesCount)
                rowStr = String(style.sideChar) + leftSpaces + lineStr + rightSpaces + String(style.sideChar)
            }

            let existingLine = (editor.logoEngine(self, queryState: .lineAt(currentLineIndex)) as? String) ?? ""
            let newLineText = buildRowText(
                existingLine: existingLine, startCol: startCol, rowStr: rowStr, isTop: isTop, isBottom: isBottom,
                mode: mode)
            editor.logoEngine(self, performAction: .setLine(index: currentLineIndex, text: newLineText))
        }

        updateCursorAfterBox(
            startLine: startLine, startCol: startCol, width: calcWidth, height: calcHeight, exitPos: exitPos)
    }

    private func updateCursorAfterBox(startLine: Int, startCol: Int, width: Int, height: Int, exitPos: BoxExitPosition)
    {
        guard let editor = self.delegate else { return }
        switch exitPos {
        case .ne:
            editor.logoEngine(self, performAction: .updateLineIndex(startLine))
            editor.logoEngine(self, performAction: .updateColumnIndex(startCol + width))
        case .se:
            editor.logoEngine(self, performAction: .updateLineIndex(startLine + height - 1))
            editor.logoEngine(self, performAction: .updateColumnIndex(startCol + width))
        case .nw:
            editor.logoEngine(self, performAction: .updateLineIndex(startLine))
            editor.logoEngine(self, performAction: .updateColumnIndex(startCol))
        case .sw:
            editor.logoEngine(self, performAction: .updateLineIndex(startLine + height - 1))
            editor.logoEngine(self, performAction: .updateColumnIndex(startCol))
        case .down:
            editor.logoEngine(self, performAction: .ensureLineExists(index: startLine + height))
            editor.logoEngine(self, performAction: .updateLineIndex(startLine + height))
            editor.logoEngine(self, performAction: .updateColumnIndex(startCol))
        }
    }

    private func buildRowText(
        existingLine: String,
        startCol: Int,
        rowStr: String,
        isTop: Bool,
        isBottom: Bool,
        mode: BoxDrawMode
    ) -> String {
        switch mode {
        case .insert:
            return buildInsertedRowText(
                existingLine: existingLine, startCol: startCol, rowStr: rowStr, isTop: isTop, isBottom: isBottom)
        case .overlay:
            return buildOverlayRowText(
                existingLine: existingLine, startCol: startCol, rowStr: rowStr, isTop: isTop, isBottom: isBottom)
        }
    }

    private func buildInsertedRowText(existingLine: String, startCol: Int, rowStr: String, isTop: Bool, isBottom: Bool)
        -> String
    {
        var prefix = ""
        var suffix = ""
        var firstOverlap: Character? = nil

        var currentW = 0
        for (offset, ch) in existingLine.enumerated() {
            let w = ch.displayWidth
            if currentW + w <= startCol {
                prefix.append(ch)
            } else {
                firstOverlap = ch
                let suffixIndex = existingLine.index(existingLine.startIndex, offsetBy: offset)
                suffix = String(existingLine[suffixIndex...])
                break
            }
            currentW += w
        }

        if prefix.displayWidth < startCol {
            prefix += String(repeating: " ", count: startCol - prefix.displayWidth)
        }

        var resultRow = ""
        var currentVisualCol = 0

        for ch in rowStr {
            let w = ch.displayWidth
            let isLeft = (currentVisualCol == 0)
            let isRight = (currentVisualCol + w == rowStr.displayWidth)

            var moveMask = 0
            if isTop && isLeft {
                moveMask = 6
            } else if isTop && isRight {
                moveMask = 12
            } else if isBottom && isLeft {
                moveMask = 3
            } else if isBottom && isRight {
                moveMask = 9
            } else if isTop {
                moveMask = 10
            } else if isBottom {
                moveMask = 10
            } else if isLeft || isRight {
                moveMask = 5
            }

            if currentVisualCol == 0, moveMask != 0, let existingCh = firstOverlap {
                let fused = fuseChar(existing: existingCh, defaultNewChar: ch, moveMask: moveMask)
                resultRow.append(fused)
            } else {
                resultRow.append(ch)
            }

            currentVisualCol += w
        }

        return prefix + resultRow + suffix
    }

    private func buildOverlayRowText(existingLine: String, startCol: Int, rowStr: String, isTop: Bool, isBottom: Bool)
        -> String
    {
        var prefix = ""
        var suffix = ""
        var existingBoxRegion: [Character] = []
        let rowWidth = rowStr.displayWidth

        var currentW = 0
        for ch in existingLine {
            let w = ch.displayWidth
            if currentW + w <= startCol {
                prefix.append(ch)
            } else if currentW < startCol + rowWidth {
                existingBoxRegion.append(ch)
            } else {
                suffix.append(ch)
            }
            currentW += w
        }

        if prefix.displayWidth < startCol {
            prefix += String(repeating: " ", count: startCol - prefix.displayWidth)
        }

        var resultRow = ""
        var currentVisualCol = 0

        for ch in rowStr {
            let w = ch.displayWidth
            let isLeft = (currentVisualCol == 0)
            let isRight = (currentVisualCol + w == rowWidth)

            var moveMask = 0
            if isTop && isLeft {
                moveMask = 6
            } else if isTop && isRight {
                moveMask = 12
            } else if isBottom && isLeft {
                moveMask = 3
            } else if isBottom && isRight {
                moveMask = 9
            } else if isTop {
                moveMask = 10
            } else if isBottom {
                moveMask = 10
            } else if isLeft || isRight {
                moveMask = 5
            }

            if moveMask != 0 && !existingBoxRegion.isEmpty {
                var regionW = 0
                var matchChar: Character? = nil
                for eCh in existingBoxRegion {
                    let eW = eCh.displayWidth
                    if regionW == currentVisualCol {
                        matchChar = eCh
                        break
                    }
                    regionW += eW
                }
                if let existingCh = matchChar {
                    let fused = fuseChar(existing: existingCh, defaultNewChar: ch, moveMask: moveMask)
                    resultRow.append(fused)
                } else {
                    resultRow.append(ch)
                }
            } else {
                resultRow.append(ch)
            }

            currentVisualCol += w
        }

        return prefix + resultRow + suffix
    }

    private func wrapTextLine(_ text: String, maxWidth: Int) -> [String] {
        guard text.displayWidth > maxWidth && maxWidth > 0 else { return [text] }
        var result: [String] = []
        let words = text.components(separatedBy: " ")
        var currentLine = ""

        for word in words {
            let wordWidth = word.displayWidth
            if wordWidth > maxWidth {
                if !currentLine.isEmpty {
                    result.append(currentLine)
                    currentLine = ""
                }
                var temp = ""
                for ch in word {
                    let chW = ch.displayWidth
                    if temp.displayWidth + chW > maxWidth && !temp.isEmpty {
                        result.append(temp)
                        temp = String(ch)
                    } else {
                        temp.append(ch)
                    }
                }
                if !temp.isEmpty {
                    currentLine = temp
                }
            } else if currentLine.isEmpty {
                currentLine = word
            } else if currentLine.displayWidth + 1 + wordWidth <= maxWidth {
                currentLine += " " + word
            } else {
                result.append(currentLine)
                currentLine = word
            }
        }
        if !currentLine.isEmpty {
            result.append(currentLine)
        }
        return result
    }

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
                index += 1
                fillPattern = unquote(evaluateExpression(tokens, index: &index))
            }
        } else {
            fillPattern = unquote(evaluateExpression(tokens, index: &index))
        }

        if fillPattern.isEmpty {
            editor.logoEngine(self, performAction: .setStatusMessage("Fill text required"))
            hasSetStatusMessage = true
            return
        }

        if (editor.logoEngine(self, queryState: .hasTableCell) as? Bool) == true {
            editor.logoEngine(self, performAction: .fillTableCell(fillPattern))
            hasSetStatusMessage = true
            return
        }

        if (editor.logoEngine(self, queryState: .hasCanvasBlockMark) as? Bool) == true {
            editor.logoEngine(self, performAction: .fillCanvasBlock(fillPattern))
            hasSetStatusMessage = true
            return
        }

        let startCol = (editor.logoEngine(self, queryState: .currentColumnIndex) as? Int) ?? 0
        let startLine = (editor.logoEngine(self, queryState: .currentLineIndex) as? Int) ?? 0

        // Mode 2: Line Fill (1 number)
        if let width = widthVal, heightVal == nil {
            let lineStr = (editor.logoEngine(self, queryState: .lineAt(startLine)) as? String) ?? ""
            let filledLine = fillStringWithPattern(pattern: fillPattern, targetWidth: width)
            let newText = replaceDisplayColumns(
                in: lineStr, startCol: startCol, width: width, replacement: filledLine)

            editor.logoEngine(self, performAction: .ensureLineExists(index: startLine))
            editor.logoEngine(self, performAction: .setLine(index: startLine, text: newText))
            editor.logoEngine(self, performAction: .updateColumnIndex(startCol + filledLine.displayWidth))
            return
        }

        // Mode 3: 2D Box Overlay Fill (2 numbers)
        if let width = widthVal, let height = heightVal {
            let filledLine = fillStringWithPattern(pattern: fillPattern, targetWidth: width)
            let boxWidth = filledLine.displayWidth
            for r in 0..<height {
                let lineIdx = startLine + r
                editor.logoEngine(self, performAction: .ensureLineExists(index: lineIdx))
                let lineStr = (editor.logoEngine(self, queryState: .lineAt(lineIdx)) as? String) ?? ""
                let newText = replaceDisplayColumns(
                    in: lineStr, startCol: startCol, width: width, replacement: filledLine)
                editor.logoEngine(self, performAction: .setLine(index: lineIdx, text: newText))
            }
            editor.logoEngine(self, performAction: .updateLineIndex(startLine + height))
            editor.logoEngine(self, performAction: .updateColumnIndex(startCol + boxWidth))
            return
        }

        // Mode 1: Flood Fill enclosed region (No numbers)
        performFloodFill(startLine: startLine, startCol: startCol, fillPattern: fillPattern)
    }

    private func shouldStopFillArgumentScan(at token: String) -> Bool {
        LogoEngine.isStatementCommand(token) || token == "]" || token == ")"
    }

    private func fillStringWithPattern(pattern: String, targetWidth: Int) -> String {
        pattern.tiledToDisplayWidth(targetWidth)
    }

    private func performFloodFill(startLine: Int, startCol: Int, fillPattern: String) {
        guard let editor = self.delegate else { return }

        let boxBorderChars: Set<Character> = [
            "│", "─", "┌", "┐", "└", "┘", "├", "┤", "┬", "┴", "┼",
            "║", "═", "╔", "╗", "╚", "╝", "╠", "╣", "╦", "╩", "╬",
            "+", "-", "|", "│",
        ]

        let totalLines = max(startLine + 1, (editor.logoEngine(self, queryState: .lineCount) as? Int) ?? 0)

        var visited: Set<[Int]> = []
        var queue: [[Int]] = [[startLine, startCol]]
        visited.insert([startLine, startCol])

        let maxRows = min(totalLines + 20, 200)
        let maxCols = 200

        func getCharAt(r: Int, c: Int) -> Character {
            let lineStr = (editor.logoEngine(self, queryState: .lineAt(r)) as? String) ?? ""
            return displayCharAt(in: lineStr, visualColumn: c)
        }

        func isBoundary(ch: Character) -> Bool {
            return boxBorderChars.contains(ch)
        }

        var cellsToFill: [[Int]] = []
        var escapedRegion = false

        while !queue.isEmpty && cellsToFill.count < 10000 {
            let curr = queue.removeFirst()
            let r = curr[0]
            let c = curr[1]

            let ch = getCharAt(r: r, c: c)
            if isBoundary(ch: ch) {
                continue
            }

            cellsToFill.append([r, c])

            let neighbors = [[r - 1, c], [r + 1, c], [r, c - 1], [r, c + 1]]
            for n in neighbors {
                let nr = n[0]
                let nc = n[1]
                if nr < 0 || nr >= maxRows || nc < 0 || nc >= maxCols {
                    escapedRegion = true
                    continue
                }

                if !visited.contains([nr, nc]) {
                    visited.insert([nr, nc])
                    queue.append([nr, nc])
                }
            }
        }

        if escapedRegion || cellsToFill.count >= 10000 {
            editor.logoEngine(
                self,
                performAction: .setStatusMessage("[ Fill requires an enclosed region or explicit size ]"))
            hasSetStatusMessage = true
            return
        }

        let cellsByRow = Dictionary(grouping: cellsToFill) { $0[0] }
        for (r, rowCells) in cellsByRow {
            let columns = rowCells.map { $0[1] }.sorted()
            var spans: [(start: Int, end: Int)] = []
            for col in columns {
                if let last = spans.last, last.end + 1 == col {
                    spans[spans.count - 1].end = col
                } else {
                    spans.append((start: col, end: col))
                }
            }

            editor.logoEngine(self, performAction: .ensureLineExists(index: r))
            var lineStr = (editor.logoEngine(self, queryState: .lineAt(r)) as? String) ?? ""
            for span in spans.reversed() {
                let width = span.end - span.start + 1
                let replacement = fillStringWithPattern(pattern: fillPattern, targetWidth: width)
                lineStr = replaceDisplayColumns(
                    in: lineStr, startCol: span.start, width: width, replacement: replacement)
            }
            editor.logoEngine(self, performAction: .setLine(index: r, text: lineStr))
        }
    }
}
