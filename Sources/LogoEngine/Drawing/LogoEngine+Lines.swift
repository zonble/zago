import Foundation
import TextMetrics

extension LogoEngine {
    internal func executeLineCommand(_ tokens: [String], index: inout Int) {
        guard let editor = self.delegate else { return }
        var length = 40
        var styleChar: Character = "─"
        var hasExplicitLength = false
        var arrowMode: LineArrowMode = .none

        if index < tokens.count {
            parseLineArguments(
                tokens, index: &index, maxLength: 200, defaultLength: 40,
                setLength: { value in
                    length = value
                    hasExplicitLength = true
                },
                setStyle: { style in
                    styleChar = BorderStyle.from(style).horizontalLineCharacter
                },
                setArrowMode: { mode in
                    arrowMode = mode
                },
                setArrowHeadStyle: { arrowStyle in
                    editor.logoEngine(self, performAction: .setArrowStyle(arrowStyle.rawValue))
                }
            )
        } else {
            index -= 1
        }

        let startCol = queryInteger(.currentColumnIndex) ?? 0
        let startLine = queryInteger(.currentLineIndex) ?? 0

        if !hasExplicitLength {
            executeAutoLineCommand(startLine: startLine, startCol: startCol, styleChar: styleChar, arrowMode: arrowMode)
            return
        }

        editor.logoEngine(self, performAction: .ensureLineExists(index: startLine))

        var lineText = queryString(.lineAt(startLine)) ?? ""

        for i in 0..<length {
            let col = startCol + i
            let moveMask = (i == 0) ? 2 : ((i == length - 1) ? 8 : 10)
            let existing = DisplayText.character(atVisualColumn: col, in: lineText)
            let char = LineRenderer.character(
                existing: existing, styleChar: styleChar, moveMask: moveMask,
                direction: .right, isStart: i == 0, isEnd: i == length - 1, arrowMode: arrowMode,
                arrowStyle: currentArrowStyle, automatic: false)
            lineText = DisplayText.replacingColumns(in: lineText, startCol: col, width: 1, with: String(char))
        }

        editor.logoEngine(self, performAction: .setLine(index: startLine, text: lineText))
        editor.logoEngine(self, performAction: .updateColumnIndex(startCol + length))
    }

    internal func executeVlineCommand(_ tokens: [String], index: inout Int) {
        guard let editor = self.delegate else { return }
        var height = 5
        var styleChar: Character = "│"
        var hasExplicitHeight = false
        var arrowMode: LineArrowMode = .none

        if index < tokens.count {
            parseLineArguments(
                tokens, index: &index, maxLength: 100, defaultLength: 5,
                setLength: { value in
                    height = value
                    hasExplicitHeight = true
                },
                setStyle: { style in
                    styleChar = BorderStyle.from(style).verticalLineCharacter
                },
                setArrowMode: { mode in
                    arrowMode = mode
                },
                setArrowHeadStyle: { arrowStyle in
                    editor.logoEngine(self, performAction: .setArrowStyle(arrowStyle.rawValue))
                }
            )
        } else {
            index -= 1
        }

        let startCol = queryInteger(.currentColumnIndex) ?? 0
        let startLine = queryInteger(.currentLineIndex) ?? 0

        if !hasExplicitHeight {
            executeAutoVlineCommand(
                startLine: startLine, startCol: startCol, styleChar: styleChar, arrowMode: arrowMode)
            return
        }

        for r in 0..<height {
            let line = startLine + r
            editor.logoEngine(self, performAction: .ensureLineExists(index: line))

            let lineStr = queryString(.lineAt(line)) ?? ""

            let moveMask = (r == 0) ? 4 : ((r == height - 1) ? 1 : 5)
            let existing = DisplayText.character(atVisualColumn: startCol, in: lineStr)
            let char = LineRenderer.character(
                existing: existing, styleChar: styleChar, moveMask: moveMask,
                direction: .down, isStart: r == 0, isEnd: r == height - 1, arrowMode: arrowMode,
                arrowStyle: currentArrowStyle, automatic: false)
            let lineText = DisplayText.replacingColumns(in: lineStr, startCol: startCol, width: 1, with: String(char))

            editor.logoEngine(self, performAction: .setLine(index: line, text: lineText))
        }

        editor.logoEngine(self, performAction: .updateLineIndex(startLine + max(0, height - 1)))
        editor.logoEngine(self, performAction: .updateColumnIndex(startCol))
    }

    private func parseLineArguments(
        _ tokens: [String],
        index: inout Int,
        maxLength: Int,
        defaultLength: Int,
        setLength: (Int) -> Void,
        setStyle: (String) -> Void,
        setArrowMode: (LineArrowMode) -> Void,
        setArrowHeadStyle: ((ArrowStyle) -> Void)? = nil
    ) {
        var consumedAny = false
        var cursor = index
        var lastConsumedIndex = index - 1

        while cursor < tokens.count {
            let token = tokens[cursor]
            if token == "]" || token == ")" { break }

            var evalIndex = cursor
            let evalRaw = unquote(evaluateExpression(tokens, index: &evalIndex))
            let upper = evalRaw.uppercased()

            if let lineDsl = StyleDSL.parseLineStyle(evalRaw) {
                setStyle(lineDsl.border.rawValue)
                if lineDsl.arrowMode != .none {
                    setArrowMode(lineDsl.arrowMode)
                }
                if let arrowStyle = lineDsl.endArrowStyle ?? lineDsl.startArrowStyle {
                    setArrowHeadStyle?(arrowStyle)
                }
                consumedAny = true
                cursor = evalIndex
                lastConsumedIndex = cursor
            } else if let arrowMode = LineArrowMode(token: upper) {
                setArrowMode(arrowMode)
                consumedAny = true
                cursor = evalIndex
                lastConsumedIndex = cursor
            } else if let arrowHeadStyle = ArrowStyle(evalRaw) {
                setArrowHeadStyle?(arrowHeadStyle)
                consumedAny = true
                cursor = evalIndex
                lastConsumedIndex = cursor
            } else if BorderStyle.isStyleToken(evalRaw) || upper == "ASCII" || upper == "DOUBLE" || upper == "SINGLE" {
                setStyle(upper.lowercased())
                consumedAny = true
                cursor = evalIndex
                lastConsumedIndex = cursor
            } else if !self.isStatementCommand(token) {
                var intEvalIndex = cursor
                if let parsedLength = parseIntExpressionArgument(
                    tokens, index: &intEvalIndex, isBoundary: isLineArgumentBoundary)
                {
                    setLength(max(1, min(parsedLength, maxLength)))
                    consumedAny = true
                    cursor = intEvalIndex
                    lastConsumedIndex = cursor
                } else if isQuotedWordToken(token) {
                    consumedAny = true
                    lastConsumedIndex = cursor
                    break
                } else {
                    break
                }
            } else {
                break
            }

            cursor += 1
        }

        index = consumedAny ? lastConsumedIndex : index - 1
    }

    private func isLineArgumentBoundary(_ token: String) -> Bool {
        let unquoted = unquote(token)
        return self.isStatementCommand(token) || token == "]" || token == ")"
            || LineArrowMode(token: unquoted.uppercased()) != nil
            || BorderStyle.isStyleToken(unquoted)
            || pluginRegistry.resolveKeyword(unquoted, domain: .borderStyle) != nil
            || ArrowStyle.isStyleToken(unquoted)
    }

    internal var currentArrowStyle: ArrowStyle {
        queryArrowStyle(.defaultArrowStyle) ?? .solid
    }

    internal func executeNewlineCommand(_ tokens: [String], index: inout Int) {
        guard let editor = self.delegate else { return }
        var count = 1
        let argumentIndex = index
        if let parsedCount = parseIntExpressionArgument(tokens, index: &index, isBoundary: isLineArgumentBoundary) {
            count = max(1, min(parsedCount, 50))
        } else {
            index = argumentIndex - 1
        }

        for _ in 0..<count {
            editor.logoEngine(self, performAction: .insertNewline)
        }
    }
}
