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
                if parseBorderStyle(unquotedRaw) != nil || BorderStyle.isStyleToken(unquotedRaw)
                    || BoxAlignment(unquotedRaw) != nil
                    || pluginRegistry.parseExitPosition(unquotedRaw) != nil || BoxExitPosition(unquotedRaw) != nil
                    || StyleDSL.parseBoxStyle(unquotedRaw) != nil || parseBoxRoundArgument(unquotedRaw) != nil
                {
                    val = unquotedRaw
                } else {
                    val = unquote(evaluateExpression(tokens, index: &evalIndex))
                }
                index = evalIndex

                if let parsedExit = (!isQuoted || val.lowercased().hasPrefix("at:"))
                    ? (pluginRegistry.parseExitPosition(val) ?? BoxExitPosition(val)) : nil
                {
                    exitPos = parsedExit
                } else if let parsedAlign = BoxAlignment(val) {
                    align = parsedAlign
                    hasExplicitAlign = true
                } else if textContent == nil && isQuoted && val.count == 1 {
                    textContent = val
                } else if let parsedBool = parseBoxRoundArgument(val) {
                    isRound = parsedBool
                } else if parseBorderStyle(val) != nil || BorderStyle.isStyleToken(val)
                    || StyleDSL.parseBoxStyle(val) != nil
                {
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
                    text, targetWidth: width, targetHeight: height, align: align,
                    style: boxStyle(named: styleName, isRound: isRound),
                    mode: mode, exitPos: exitPos)
            } else {
                drawBoxFrame(
                    width: width, height: height ?? 5, style: boxStyle(named: styleName, isRound: isRound), mode: mode,
                    exitPos: exitPos)
            }
            return
        }

        // Mode 2: BOX "text" [width] [align/style/exit/round]
        let textContent = evaluateExpression(tokens, index: &index)
        var targetWidth: Int? = nil
        var targetHeight: Int? = nil
        var startLine: Int? = nil
        var startCol: Int? = nil
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

        if targetWidth == nil {
            if let frame = queryCanvasBlockFrame(.canvasBlockFrame) {
                startLine = frame.lineIndex
                startCol = frame.visualColumn
                targetWidth = max(3, min(frame.width, 200))
                targetHeight = max(2, min(frame.height, 100))
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
            if parseBorderStyle(unquotedRaw) != nil || BorderStyle.isStyleToken(unquotedRaw)
                || BoxAlignment(unquotedRaw) != nil
                || pluginRegistry.parseExitPosition(unquotedRaw) != nil || BoxExitPosition(unquotedRaw) != nil
                || StyleDSL.parseBoxStyle(unquotedRaw) != nil || parseBoxRoundArgument(unquotedRaw) != nil
            {
                val = unquotedRaw
            } else {
                val = unquote(evaluateExpression(tokens, index: &evalIndex))
            }
            index = evalIndex

            if let parsedExit = (!isQuoted || val.lowercased().hasPrefix("at:"))
                ? (pluginRegistry.parseExitPosition(val) ?? BoxExitPosition(val)) : nil
            {
                exitPos = parsedExit
            } else if let parsedAlign = BoxAlignment(val) {
                align = parsedAlign
            } else if let parsedBool = parseBoxRoundArgument(val) {
                isRound = parsedBool
            } else if parseBorderStyle(val) != nil || BorderStyle.isStyleToken(val)
                || StyleDSL.parseBoxStyle(val) != nil
            {
                styleName = val
            }
        }

        drawBoxAroundText(
            textContent,
            startLine: startLine,
            startCol: startCol,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
            align: align,
            style: boxStyle(named: styleName, isRound: isRound),
            mode: mode,
            exitPos: exitPos
        )
    }

    private func parseBoxRoundArgument(_ token: String) -> Bool? {
        let clean = token.lowercased()
        if clean == "round" || clean == "rounded" { return true }
        return parseBoolean(token)
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
                || self.parseBorderStyle(unquoted) != nil || BorderStyle.isStyleToken(unquoted)
                || BoxAlignment(unquoted) != nil
                || self.pluginRegistry.parseExitPosition(unquoted) != nil || BoxExitPosition(unquoted) != nil
        }
    }

    private func consumeNextBoxDimensionArgument(_ tokens: [String], index: inout Int) -> Int? {
        consumeNextIntExpressionArgument(tokens, index: &index) { token in
            let unquoted = unquote(token)
            return self.isStatementCommand(token) || token == "]" || token == ")"
                || self.parseBorderStyle(unquoted) != nil || BorderStyle.isStyleToken(unquoted)
                || BoxAlignment(unquoted) != nil
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
        _ text: String,
        startLine: Int? = nil,
        startCol: Int? = nil,
        targetWidth: Int?,
        targetHeight: Int?,
        align: BoxAlignment,
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
        let rendered = renderer.textBoxRows(
            text: text,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
            alignment: align,
            style: style
        )
        let calcWidth = rendered.width
        let calcHeight = rendered.height

        let effectiveStartCol = startCol ?? (queryInteger(.currentColumnIndex) ?? 0)
        let effectiveStartLine = startLine ?? (queryInteger(.currentLineIndex) ?? 0)

        for (r, rowStr) in rendered.rows.enumerated() {
            let currentLineIndex = effectiveStartLine + r
            editor.logoEngine(self, performAction: .ensureLineExists(index: currentLineIndex))

            let isTop = (r == 0)
            let isBottom = (r == calcHeight - 1)

            let existingLine = queryString(.lineAt(currentLineIndex)) ?? ""
            let newLineText = renderer.mergeRow(
                existingLine: existingLine, startCol: effectiveStartCol, row: rowStr, isTop: isTop, isBottom: isBottom,
                mode: renderMode)
            editor.logoEngine(self, performAction: .setLine(index: currentLineIndex, text: newLineText))
        }

        updateCursorAfterBox(
            startLine: effectiveStartLine, startCol: effectiveStartCol, width: calcWidth, height: calcHeight,
            exitPos: exitPos)
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

    internal func executeFrameCommand(_ tokens: [String], index: inout Int) {
        var width: Int? = nil
        var height: Int? = nil
        var startLine: Int? = nil
        var startCol: Int? = nil
        var scanIndex = index

        if index < tokens.count {
            var wIndex = index
            if let w = parseBoxDimensionArgument(tokens, index: &wIndex) {
                if wIndex + 1 < tokens.count {
                    var hIndex = wIndex + 1
                    if let h = parseBoxDimensionArgument(tokens, index: &hIndex) {
                        index = hIndex
                        scanIndex = hIndex + 1
                        width = max(2, min(w, 200))
                        height = max(2, min(h, 100))
                    }
                }
            }
        }

        if width == nil || height == nil {
            if let frame = queryCanvasBlockFrame(.canvasBlockFrame) {
                startLine = frame.lineIndex
                startCol = frame.visualColumn
                width = max(2, min(frame.width, 200))
                height = max(2, min(frame.height, 100))
                scanIndex = index
            } else {
                return
            }
        }

        guard let finalWidth = width, let finalHeight = height else { return }

        var styleName = ""
        var isRound: Bool? = nil
        var exitPos: BoxExitPosition = .ne

        while scanIndex < tokens.count {
            let nextToken = tokens[scanIndex]
            if shouldStopBoxArgumentScan(at: nextToken) { break }
            var evalIndex = scanIndex
            let rawToken = tokens[evalIndex]
            let isQuoted = isQuotedWordToken(rawToken)
            let unquotedRaw = unquote(rawToken)
            let val: String
            if parseBorderStyle(unquotedRaw) != nil || BorderStyle.isStyleToken(unquotedRaw)
                || BoxAlignment(unquotedRaw) != nil
                || pluginRegistry.parseExitPosition(unquotedRaw) != nil || BoxExitPosition(unquotedRaw) != nil
                || StyleDSL.parseBoxStyle(unquotedRaw) != nil || parseBoxRoundArgument(unquotedRaw) != nil
            {
                val = unquotedRaw
            } else {
                val = unquote(evaluateExpression(tokens, index: &evalIndex))
            }
            index = evalIndex
            scanIndex = evalIndex + 1

            if let parsedExit = (!isQuoted || val.lowercased().hasPrefix("at:"))
                ? (pluginRegistry.parseExitPosition(val) ?? BoxExitPosition(val)) : nil
            {
                exitPos = parsedExit
            } else if let parsedBool = parseBoxRoundArgument(val) {
                isRound = parsedBool
            } else if parseBorderStyle(val) != nil || BorderStyle.isStyleToken(val)
                || StyleDSL.parseBoxStyle(val) != nil
            {
                styleName = val
            }
        }

        drawPerimeterFrame(
            startLine: startLine,
            startCol: startCol,
            width: finalWidth,
            height: finalHeight,
            style: boxStyle(named: styleName, isRound: isRound),
            exitPos: exitPos
        )
    }

    private func drawPerimeterFrame(
        startLine: Int? = nil,
        startCol: Int? = nil,
        width: Int,
        height: Int,
        style: BoxStyle,
        exitPos: BoxExitPosition = .ne
    ) {
        guard let editor = self.delegate else { return }
        let effectiveStartCol = startCol ?? (queryInteger(.currentColumnIndex) ?? 0)
        let effectiveStartLine = startLine ?? (queryInteger(.currentLineIndex) ?? 0)
        let renderer = TextBoxRenderer()

        let topRowStr: String
        let bottomRowStr: String
        if width <= 2 {
            topRowStr = String(style.topLeft) + (width == 2 ? String(style.topRight) : "")
            bottomRowStr = String(style.bottomLeft) + (width == 2 ? String(style.bottomRight) : "")
        } else {
            topRowStr =
                String(style.topLeft) + String(repeating: style.topChar, count: width - 2) + String(style.topRight)
            bottomRowStr =
                String(style.bottomLeft) + String(repeating: style.bottomChar, count: width - 2)
                + String(style.bottomRight)
        }

        for r in 0..<height {
            let currentLineIndex = effectiveStartLine + r
            editor.logoEngine(self, performAction: .ensureLineExists(index: currentLineIndex))
            let lineStr = queryString(.lineAt(currentLineIndex)) ?? ""

            let newLineText: String
            if r == 0 {
                newLineText = renderer.mergeRow(
                    existingLine: lineStr, startCol: effectiveStartCol, row: topRowStr, isTop: true, isBottom: false,
                    mode: .overlay)
            } else if r == height - 1 {
                newLineText = renderer.mergeRow(
                    existingLine: lineStr, startCol: effectiveStartCol, row: bottomRowStr, isTop: false, isBottom: true,
                    mode: .overlay)
            } else {
                var updatedLine = DisplayText.replacingColumns(
                    in: lineStr, startCol: effectiveStartCol, width: 1, with: String(style.sideChar))
                if width >= 2 {
                    updatedLine = DisplayText.replacingColumns(
                        in: updatedLine, startCol: effectiveStartCol + width - 1, width: 1, with: String(style.sideChar)
                    )
                }
                newLineText = updatedLine
            }
            editor.logoEngine(self, performAction: .setLine(index: currentLineIndex, text: newLineText))
        }

        updateCursorAfterBox(
            startLine: effectiveStartLine, startCol: effectiveStartCol, width: width, height: height, exitPos: exitPos)
    }
}
