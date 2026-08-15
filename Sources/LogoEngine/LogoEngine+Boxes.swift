import Foundation
import TextMetrics

enum BoxExitPosition: String, Sendable, CaseIterable {
    case ne
    case se
    case nw
    case sw
    case down

    init?(_ raw: String) {
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
        guard let style = queryBorderStyle(.defaultBorderStyle) else {
            return .single
        }
        return style.boxStyle
    }

    private func boxStyle(named styleName: String) -> BoxStyle {
        styleName.isEmpty ? defaultBoxStyle() : BorderStyle.from(styleName).boxStyle
    }

    internal func executeBoxCommand(_ tokens: [String], index: inout Int, mode: BoxDrawMode = .insert) {
        guard index < tokens.count else {
            if let frame = queryCanvasBlockFrame(.canvasBlockFrame) {
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
                var evalIndex = index + 1
                let rawToken = tokens[evalIndex]
                let isQuoted = isQuotedWordToken(rawToken)
                let unquotedRaw = unquote(rawToken)
                let val: String
                if BorderStyle.isStyleToken(unquotedRaw) || BoxAlignment(unquotedRaw) != nil
                    || BoxExitPosition(unquotedRaw) != nil
                {
                    val = unquotedRaw
                } else {
                    val = unquote(evaluateExpression(tokens, index: &evalIndex))
                }
                index = evalIndex

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
            var evalIndex = index + 1
            let rawToken = tokens[evalIndex]
            let isQuoted = isQuotedWordToken(rawToken)
            let unquotedRaw = unquote(rawToken)
            let val: String
            if BorderStyle.isStyleToken(unquotedRaw) || BoxAlignment(unquotedRaw) != nil
                || BoxExitPosition(unquotedRaw) != nil
            {
                val = unquotedRaw
            } else {
                val = unquote(evaluateExpression(tokens, index: &evalIndex))
            }
            index = evalIndex

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

    private func isExpressionPrimitiveToken(_ token: String) -> Bool {
        let clean = token.uppercased()
        if let prim = LogoPrimitive.from(clean), LogoEngine.expressionPrimitives.contains(prim) {
            return true
        }
        return false
    }

    private func parseBoxDimensionArgument(_ tokens: [String], index: inout Int) -> Int? {
        guard index < tokens.count else { return nil }
        let currentToken = tokens[index]

        if isQuotedWordToken(currentToken) || isExpressionPrimitiveToken(currentToken) {
            return nil
        }

        return parseIntExpressionArgument(tokens, index: &index) { token in
            let unquoted = unquote(token)
            return LogoEngine.isStatementCommand(token) || token == "]" || token == ")"
                || BorderStyle.isStyleToken(unquoted) || BoxAlignment(unquoted) != nil
                || BoxExitPosition(unquoted) != nil
        }
    }

    private func consumeNextBoxDimensionArgument(_ tokens: [String], index: inout Int) -> Int? {
        consumeNextIntExpressionArgument(tokens, index: &index) { token in
            let unquoted = unquote(token)
            return LogoEngine.isStatementCommand(token) || token == "]" || token == ")"
                || BorderStyle.isStyleToken(unquoted) || BoxAlignment(unquoted) != nil
                || BoxExitPosition(unquoted) != nil
        }
    }

    private func shouldStopBoxArgumentScan(at token: String) -> Bool {
        if token == "]" || token == ")" { return true }
        let unquoted = unquote(token)
        if BoxAlignment(unquoted) != nil || BorderStyle.isStyleToken(unquoted) || BoxExitPosition(unquoted) != nil {
            return false
        }
        return LogoEngine.isStatementCommand(token)
    }

    private func drawBoxFrame(
        width: Int, height: Int, style: BoxStyle, mode: BoxDrawMode, exitPos: BoxExitPosition = .ne
    ) {
        guard self.delegate != nil else { return }
        let startCol = queryInteger(.currentColumnIndex) ?? 0
        let startLine = queryInteger(.currentLineIndex) ?? 0

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
        let renderer = TextBoxRenderer()
        let renderMode: TextBoxRenderMode = switch mode {
        case .insert: .insert
        case .overlay: .overlay
        }
        let rows = renderer.frameRows(width: width, height: height, style: style)

        for (r, rowStr) in rows.enumerated() {
            let currentLineIndex = startLine + r
            editor.logoEngine(self, performAction: .ensureLineExists(index: currentLineIndex))

            let lineStr = queryString(.lineAt(currentLineIndex)) ?? ""
            let isTop = (r == 0)
            let isBottom = (r == rows.count - 1)

            let newLineText = renderer.mergeRow(
                existingLine: lineStr, startCol: startCol, row: rowStr, isTop: isTop, isBottom: isBottom,
                mode: renderMode)
            editor.logoEngine(self, performAction: .setLine(index: currentLineIndex, text: newLineText))
        }

        updateCursorAfterBox(startLine: startLine, startCol: startCol, width: width, height: height, exitPos: exitPos)
    }

    private func drawBoxAroundText(
        _ text: String, targetWidth: Int?, targetHeight: Int?, align: String, style: BoxStyle, mode: BoxDrawMode,
        exitPos: BoxExitPosition = .ne
    ) {
        guard let editor = self.delegate else { return }
        let renderer = TextBoxRenderer()
        let renderMode: TextBoxRenderMode = switch mode {
        case .insert: .insert
        case .overlay: .overlay
        }
        let rendered = renderer.textBoxRows(
            text: text,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
            alignment: align,
            style: style
        )
        let calcWidth = rendered.width
        let calcHeight = rendered.height

        let startCol = queryInteger(.currentColumnIndex) ?? 0
        let startLine = queryInteger(.currentLineIndex) ?? 0

        for (r, rowStr) in rendered.rows.enumerated() {
            let currentLineIndex = startLine + r
            editor.logoEngine(self, performAction: .ensureLineExists(index: currentLineIndex))

            let isTop = (r == 0)
            let isBottom = (r == calcHeight - 1)

            let existingLine = queryString(.lineAt(currentLineIndex)) ?? ""
            let newLineText = renderer.mergeRow(
                existingLine: existingLine, startCol: startCol, row: rowStr, isTop: isTop, isBottom: isBottom,
                mode: renderMode)
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

        // Mode 2: Line Fill (1 number)
        if let width = widthVal, heightVal == nil {
            let lineStr = queryString(.lineAt(startLine)) ?? ""
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
                let lineStr = queryString(.lineAt(lineIdx)) ?? ""
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

        let totalLines = max(startLine + 1, queryInteger(.lineCount) ?? 0)

        var visited: Set<[Int]> = []
        var queue: [[Int]] = [[startLine, startCol]]
        visited.insert([startLine, startCol])

        let maxRows = min(totalLines + 20, 200)
        let maxCols = 200

        func getCharAt(r: Int, c: Int) -> Character {
            let lineStr = queryString(.lineAt(r)) ?? ""
            return displayCharAt(in: lineStr, visualColumn: c)
        }

        func isBoundary(ch: Character) -> Bool {
            BoxBorderCharacters.isBorder(ch)
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
            var lineStr = queryString(.lineAt(r)) ?? ""
            for span in spans.reversed() {
                let width = span.end - span.start + 1
                let replacement = fillStringWithPattern(pattern: fillPattern, targetWidth: width)
                lineStr = replaceDisplayColumns(
                    in: lineStr, startCol: span.start, width: width, replacement: replacement)
            }
            editor.logoEngine(self, performAction: .setLine(index: r, text: lineStr))
        }
    }

    internal func executeInsetCommand(_ tokens: [String], index: inout Int) {
        guard let editor = self.delegate else { return }
        guard index < tokens.count else { return }

        var widthVal: Int? = nil
        var heightVal: Int? = nil
        var insetText = ""

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
                insetText = unquote(evaluateExpression(tokens, index: &evalIndex))
                index = evalIndex
            }
        } else {
            insetText = unquote(evaluateExpression(tokens, index: &index))
        }

        if insetText.isEmpty { return }

        let startCol = queryInteger(.currentColumnIndex) ?? 0
        let startLine = queryInteger(.currentLineIndex) ?? 0

        // Mode 3: 1D Line Inset (1 number)
        if let width = widthVal, heightVal == nil {
            let lineStr = queryString(.lineAt(startLine)) ?? ""
            let textWidth = insetText.displayWidth
            let offset = max(0, (width - textWidth) / 2)
            let paddedText =
                String(repeating: " ", count: offset) + insetText
                + String(repeating: " ", count: max(0, width - offset - textWidth))
            let newText = replaceDisplayColumns(in: lineStr, startCol: startCol, width: width, replacement: paddedText)

            editor.logoEngine(self, performAction: .ensureLineExists(index: startLine))
            editor.logoEngine(self, performAction: .setLine(index: startLine, text: newText))
            editor.logoEngine(self, performAction: .updateColumnIndex(startCol + width))
            return
        }

        // Mode 2: 2D Box Area Inset (2 numbers)
        if let width = widthVal, let height = heightVal {
            let textLines = insetText.replacingOccurrences(of: "\\n", with: "\n").components(separatedBy: "\n")
            let startRow = max(0, (height - textLines.count) / 2)

            for r in 0..<height {
                let lineIdx = startLine + r
                editor.logoEngine(self, performAction: .ensureLineExists(index: lineIdx))
                let lineStr = queryString(.lineAt(lineIdx)) ?? ""

                let replacementText: String
                if r >= startRow && (r - startRow) < textLines.count {
                    let lineContent = textLines[r - startRow]
                    let textWidth = lineContent.displayWidth
                    let offset = max(0, (width - textWidth) / 2)
                    replacementText =
                        String(repeating: " ", count: offset) + lineContent
                        + String(repeating: " ", count: max(0, width - offset - textWidth))
                } else {
                    replacementText = String(repeating: " ", count: width)
                }

                let newText = replaceDisplayColumns(
                    in: lineStr, startCol: startCol, width: width, replacement: replacementText)
                editor.logoEngine(self, performAction: .setLine(index: lineIdx, text: newText))
            }

            editor.logoEngine(self, performAction: .updateLineIndex(startLine + height))
            editor.logoEngine(self, performAction: .updateColumnIndex(startCol + width))
            return
        }

        // Mode 1: Auto Box Bounds Detection (No numbers)
        performBoxInset(startLine: startLine, startCol: startCol, insetText: insetText)
    }

    private func performBoxInset(startLine: Int, startCol: Int, insetText: String) {
        guard let editor = self.delegate else { return }

        func getCharAt(r: Int, c: Int) -> Character {
            let lineStr = queryString(.lineAt(r)) ?? ""
            return displayCharAt(in: lineStr, visualColumn: c)
        }

        // Find top boundary
        var topLine: Int? = nil
        for r in stride(from: startLine, through: 0, by: -1) {
            let ch = getCharAt(r: r, c: startCol)
            if BoxBorderCharacters.isTop(ch) {
                topLine = r
                break
            }
        }

        // Find bottom boundary
        var bottomLine: Int? = nil
        let lineCount = queryInteger(.lineCount) ?? (startLine + 10)
        for r in startLine..<min(lineCount + 50, startLine + 100) {
            let ch = getCharAt(r: r, c: startCol)
            if BoxBorderCharacters.isBottom(ch) {
                bottomLine = r
                break
            }
        }

        // Find left boundary
        var leftCol: Int? = nil
        for c in stride(from: startCol, through: 0, by: -1) {
            let ch = getCharAt(r: startLine, c: c)
            if BoxBorderCharacters.isSide(ch) {
                leftCol = c
                break
            }
        }

        // Find right boundary
        var rightCol: Int? = nil
        for c in startCol...min(200, startCol + 150) {
            let ch = getCharAt(r: startLine, c: c)
            if BoxBorderCharacters.isSide(ch) {
                rightCol = c
                break
            }
        }

        guard let tLine = topLine, let bLine = bottomLine, let lCol = leftCol, let rCol = rightCol,
            bLine > tLine + 1, rCol > lCol + 1
        else {
            let lineStr = queryString(.lineAt(startLine)) ?? ""
            let textWidth = insetText.displayWidth
            let offset = max(0, (40 - textWidth) / 2)
            let replacement = String(repeating: " ", count: offset) + insetText
            let newText = replaceDisplayColumns(
                in: lineStr, startCol: startCol, width: replacement.displayWidth, replacement: replacement)
            editor.logoEngine(self, performAction: .setLine(index: startLine, text: newText))
            return
        }

        let innerTop = tLine + 1
        let innerBottom = bLine - 1
        let innerLeft = lCol + 1
        let innerRight = rCol - 1
        let innerWidth = innerRight - innerLeft + 1
        let innerHeight = innerBottom - innerTop + 1

        let textLines = insetText.replacingOccurrences(of: "\\n", with: "\n").components(separatedBy: "\n")
        let startRowInInner = max(0, (innerHeight - textLines.count) / 2)

        for r in 0..<innerHeight {
            let currentLineIdx = innerTop + r
            editor.logoEngine(self, performAction: .ensureLineExists(index: currentLineIdx))
            let lineStr = queryString(.lineAt(currentLineIdx)) ?? ""

            let replacementText: String
            if r >= startRowInInner && (r - startRowInInner) < textLines.count {
                let lineContent = textLines[r - startRowInInner]
                let textWidth = lineContent.displayWidth
                let offset = max(0, (innerWidth - textWidth) / 2)
                replacementText =
                    String(repeating: " ", count: offset) + lineContent
                    + String(repeating: " ", count: max(0, innerWidth - offset - textWidth))
            } else {
                replacementText = String(repeating: " ", count: innerWidth)
            }

            let newText = replaceDisplayColumns(
                in: lineStr, startCol: innerLeft, width: innerWidth, replacement: replacementText)
            editor.logoEngine(self, performAction: .setLine(index: currentLineIdx, text: newText))
        }

        let targetLine = innerTop + startRowInInner
        let targetTextWidth = (textLines.first?.displayWidth) ?? insetText.displayWidth
        let targetCol = innerLeft + max(0, (innerWidth - targetTextWidth) / 2) + targetTextWidth

        editor.logoEngine(self, performAction: .updateLineIndex(targetLine))
        editor.logoEngine(self, performAction: .updateColumnIndex(targetCol))
    }
}
