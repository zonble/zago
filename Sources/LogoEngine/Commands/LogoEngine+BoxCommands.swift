import Foundation
import TextMetrics

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
        let renderMode: TextBoxRenderMode =
            switch mode {
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
        let renderMode: TextBoxRenderMode =
            switch mode {
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
}
