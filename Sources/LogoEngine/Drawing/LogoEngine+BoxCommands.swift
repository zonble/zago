import Foundation
import TextMetrics

extension LogoEngine {
    internal enum BoxDrawMode {
        case insert
        case overlay
    }

    private func defaultBoxStyle() -> BoxStyle {
        let isRounded = queryBool(.defaultBorderRounded) ?? false
        guard let style = queryBorderStyle(.defaultBorderStyle) else {
            return BorderStyle.single.boxStyle(rounded: isRounded)
        }
        return style.boxStyle(rounded: isRounded)
    }

    private func boxStyle(named styleName: String, isRound: Bool? = nil) -> BoxStyle {
        let defaultRound = queryBool(.defaultBorderRounded) ?? false
        if styleName.isEmpty {
            let defaultStyle = queryBorderStyle(.defaultBorderStyle) ?? BorderStyle.single
            return defaultStyle.boxStyle(rounded: isRound ?? defaultRound)
        }
        if let dsl = StyleDSL.parseBoxStyle(styleName) {
            let round = isRound ?? (styleName.hasSuffix(")") ? dsl.rounded : defaultRound)
            return dsl.border.boxStyle(rounded: round)
        }
        let border = parseBorderStyle(styleName) ?? BorderStyle.from(styleName)
        let round = isRound ?? defaultRound
        return border.boxStyle(rounded: round)
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

        // Mode 1: BOX width [height] ["text"] [align] [style] [exitPos] [round]
        if let w = parseBoxDimensionArgument(tokens, index: &index) {
            let width = max(3, min(w, 200))
            var height: Int? = nil
            var textContent: String? = nil
            var align: BoxAlignment = .left
            var hasExplicitAlign = false
            var styleName = ""
            var isRound: Bool? = nil
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
                if parseBorderStyle(unquotedRaw) != nil || BorderStyle.isStyleToken(unquotedRaw) || BoxAlignment(unquotedRaw) != nil
                    || pluginRegistry.parseExitPosition(unquotedRaw) != nil || BoxExitPosition(unquotedRaw) != nil
                    || StyleDSL.parseBoxStyle(unquotedRaw) != nil || parseBoolean(unquotedRaw) != nil
                {
                    val = unquotedRaw
                } else {
                    val = unquote(evaluateExpression(tokens, index: &evalIndex))
                }
                index = evalIndex

                if let parsedExit = (!isQuoted || val.lowercased().hasPrefix("at:")) ? (pluginRegistry.parseExitPosition(val) ?? BoxExitPosition(val)) : nil {
                    exitPos = parsedExit
                } else if let parsedAlign = BoxAlignment(val) {
                    align = parsedAlign
                    hasExplicitAlign = true
                } else if textContent == nil && isQuoted && val.count == 1 {
                    textContent = val
                } else if let parsedBool = parseBoolean(val) {
                    isRound = parsedBool
                } else if parseBorderStyle(val) != nil || BorderStyle.isStyleToken(val) || StyleDSL.parseBoxStyle(val) != nil {
                    styleName = val
                } else if textContent == nil {
                    textContent = val
                }
            }

            if let text = textContent {
                if !hasExplicitAlign {
                    align = .center
                }
                drawBoxAroundText(
                    text, targetWidth: width, targetHeight: height, align: align, style: boxStyle(named: styleName, isRound: isRound),
                    mode: mode, exitPos: exitPos)
            } else {
                drawBoxFrame(
                    width: width, height: height ?? 5, style: boxStyle(named: styleName, isRound: isRound), mode: mode, exitPos: exitPos)
            }
            return
        }

        // Mode 2: BOX "text" [width] [align/style/exit/round]
        let textContent = evaluateExpression(tokens, index: &index)
        var targetWidth: Int? = nil
        var align: BoxAlignment = .left
        var styleName = ""
        var isRound: Bool? = nil
        var exitPos: BoxExitPosition = .ne

        if index + 1 < tokens.count {
            var widthIndex = index + 1
            if let width = parseBoxDimensionArgument(tokens, index: &widthIndex) {
                index = widthIndex
                targetWidth = max(3, min(width, 200))
                align = .center
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
            if parseBorderStyle(unquotedRaw) != nil || BorderStyle.isStyleToken(unquotedRaw) || BoxAlignment(unquotedRaw) != nil
                || pluginRegistry.parseExitPosition(unquotedRaw) != nil || BoxExitPosition(unquotedRaw) != nil
                || StyleDSL.parseBoxStyle(unquotedRaw) != nil || parseBoolean(unquotedRaw) != nil
            {
                val = unquotedRaw
            } else {
                val = unquote(evaluateExpression(tokens, index: &evalIndex))
            }
            index = evalIndex

            if let parsedExit = (!isQuoted || val.lowercased().hasPrefix("at:")) ? (pluginRegistry.parseExitPosition(val) ?? BoxExitPosition(val)) : nil {
                exitPos = parsedExit
            } else if let parsedAlign = BoxAlignment(val) {
                align = parsedAlign
            } else if let parsedBool = parseBoolean(val) {
                isRound = parsedBool
            } else if parseBorderStyle(val) != nil || BorderStyle.isStyleToken(val) || StyleDSL.parseBoxStyle(val) != nil {
                styleName = val
            }
        }

        drawBoxAroundText(
            textContent, targetWidth: targetWidth, targetHeight: nil, align: align, style: boxStyle(named: styleName, isRound: isRound),
            mode: mode, exitPos: exitPos)
    }

    private func isExpressionPrimitiveToken(_ token: String) -> Bool {
        let clean = token.uppercased()
        if let prim = parsePrimitive(clean), LogoEngine.expressionPrimitives.contains(prim) {
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
            return self.isStatementCommand(token) || token == "]" || token == ")"
                || self.parseBorderStyle(unquoted) != nil || BorderStyle.isStyleToken(unquoted) || BoxAlignment(unquoted) != nil
                || self.pluginRegistry.parseExitPosition(unquoted) != nil || BoxExitPosition(unquoted) != nil
        }
    }

    private func consumeNextBoxDimensionArgument(_ tokens: [String], index: inout Int) -> Int? {
        consumeNextIntExpressionArgument(tokens, index: &index) { token in
            let unquoted = unquote(token)
            return self.isStatementCommand(token) || token == "]" || token == ")"
                || self.parseBorderStyle(unquoted) != nil || BorderStyle.isStyleToken(unquoted) || BoxAlignment(unquoted) != nil
                || self.pluginRegistry.parseExitPosition(unquoted) != nil || BoxExitPosition(unquoted) != nil
        }
    }

    private func shouldStopBoxArgumentScan(at token: String) -> Bool {
        if token == "]" || token == ")" { return true }
        let unquoted = unquote(token)
        if BoxAlignment(unquoted) != nil || parseBorderStyle(unquoted) != nil || BorderStyle.isStyleToken(unquoted)
            || pluginRegistry.parseExitPosition(unquoted) != nil || BoxExitPosition(unquoted) != nil
        {
            return false
        }
        return isStatementCommand(token)
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
        _ text: String, targetWidth: Int?, targetHeight: Int?, align: BoxAlignment, style: BoxStyle, mode: BoxDrawMode,
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
