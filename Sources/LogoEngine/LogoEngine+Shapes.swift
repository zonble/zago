import Foundation
import TextMetrics

extension LogoEngine {
    internal enum BoxDrawMode {
        case insert
        case overlay
    }

    private enum LineArrowMode {
        case none
        case forward
        case backward
        case both

        var hasForwardArrow: Bool {
            self == .forward || self == .both
        }

        var hasBackwardArrow: Bool {
            self == .backward || self == .both
        }
    }

    internal func executeLineCommand(_ tokens: [String], index: inout Int) {
        guard let editor = self.delegate else { return }
        var length = 40
        var styleChar: Character = "─"
        var hasExplicitLength = false
        var arrowMode: LineArrowMode = .none

        if index < tokens.count {
            parseLineArguments(tokens, index: &index, maxLength: 200, defaultLength: 40) { value in
                length = value
                hasExplicitLength = true
            } setStyle: { style in
                styleChar = (style == "double") ? "═" : "-"
            } setArrowMode: { mode in
                arrowMode = mode
            }
        } else {
            index -= 1
        }

        let startCol = (editor.logoEngine(self, queryState: .currentColumnIndex) as? Int) ?? 0
        let startLine = (editor.logoEngine(self, queryState: .currentLineIndex) as? Int) ?? 0

        if !hasExplicitLength {
            executeAutoLineCommand(startLine: startLine, startCol: startCol, styleChar: styleChar, arrowMode: arrowMode)
            return
        }

        editor.logoEngine(self, performAction: .ensureLineExists(index:startLine))

        let startLineStr = (editor.logoEngine(self, queryState: .lineAt(startLine)) as? String) ?? ""
        var currentChars = Array(startLineStr)
        while currentChars.count < startCol {
            currentChars.append(" ")
        }

        for i in 0..<length {
            let col = startCol + i
            let moveMask = (i == 0) ? 2 : ((i == length - 1) ? 8 : 10)
            if col < currentChars.count {
                let existing = currentChars[col]
                currentChars[col] = explicitHorizontalLineChar(
                    existing: existing, styleChar: styleChar, moveMask: moveMask,
                    isStart: i == 0, isEnd: i == length - 1, arrowMode: arrowMode)
            } else {
                currentChars.append(horizontalLineChar(
                    styleChar: styleChar, isStart: i == 0, isEnd: i == length - 1, arrowMode: arrowMode))
            }
        }

        editor.logoEngine(self, performAction: .setLine(index: startLine, text: String(currentChars)))
        editor.logoEngine(self, performAction: .updateColumnIndex(startCol + length))
    }

    internal func executeVlineCommand(_ tokens: [String], index: inout Int) {
        guard let editor = self.delegate else { return }
        var height = 5
        var styleChar: Character = "│"
        var hasExplicitHeight = false
        var arrowMode: LineArrowMode = .none

        if index < tokens.count {
            parseLineArguments(tokens, index: &index, maxLength: 100, defaultLength: 5) { value in
                height = value
                hasExplicitHeight = true
            } setStyle: { style in
                styleChar = (style == "double") ? "║" : "|"
            } setArrowMode: { mode in
                arrowMode = mode
            }
        } else {
            index -= 1
        }

        let startCol = (editor.logoEngine(self, queryState: .currentColumnIndex) as? Int) ?? 0
        let startLine = (editor.logoEngine(self, queryState: .currentLineIndex) as? Int) ?? 0

        if !hasExplicitHeight {
            executeAutoVlineCommand(startLine: startLine, startCol: startCol, styleChar: styleChar, arrowMode: arrowMode)
            return
        }

        for r in 0..<height {
            let line = startLine + r
            editor.logoEngine(self, performAction: .ensureLineExists(index:line))

            let lineStr = (editor.logoEngine(self, queryState: .lineAt(line)) as? String) ?? ""
            var currentChars = Array(lineStr)
            while currentChars.count <= startCol {
                currentChars.append(" ")
            }

            let moveMask = (r == 0) ? 4 : ((r == height - 1) ? 1 : 5)
            let existing = currentChars[startCol]
            currentChars[startCol] = explicitVerticalLineChar(
                existing: existing, styleChar: styleChar, moveMask: moveMask,
                isStart: r == 0, isEnd: r == height - 1, arrowMode: arrowMode)

            editor.logoEngine(self, performAction: .setLine(index: line, text: String(currentChars)))
        }

        editor.logoEngine(self, performAction: .updateLineIndex(startLine + height))
        editor.logoEngine(self, performAction: .updateColumnIndex(startCol))
    }

    private func parseLineArguments(
        _ tokens: [String],
        index: inout Int,
        maxLength: Int,
        defaultLength: Int,
        setLength: (Int) -> Void,
        setStyle: (String) -> Void,
        setArrowMode: (LineArrowMode) -> Void
    ) {
        var consumedAny = false
        var cursor = index
        var lastConsumedIndex = index - 1

        while cursor < tokens.count {
            let token = tokens[cursor]
            if token == "]" || token == ")" { break }

            let raw = unquote(token)
            let upper = raw.uppercased()

            if let arrowMode = lineArrowMode(for: upper) {
                setArrowMode(arrowMode)
                consumedAny = true
                lastConsumedIndex = cursor
            } else if upper == "DOUBLE" || upper == "ASCII" {
                setStyle(upper.lowercased())
                consumedAny = true
                lastConsumedIndex = cursor
            } else if !LogoEngine.isKeyword(token) || token.hasPrefix("\"") {
                var evalIndex = cursor
                let value = evaluateExpression(tokens, index: &evalIndex)
                if let parsedLength = Int(value) {
                    setLength(max(1, min(parsedLength, maxLength)))
                    consumedAny = true
                    cursor = evalIndex
                    lastConsumedIndex = cursor
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

    private func lineArrowMode(for uppercasedToken: String) -> LineArrowMode? {
        switch uppercasedToken {
        case "ARROW", "RIGHTARROW", "DOWNARROW":
            return .forward
        case "BACKARROW", "LEFTARROW", "UPARROW":
            return .backward
        case "BOTHARROW", "BOTH", "BIDIR":
            return .both
        default:
            return nil
        }
    }

    private func executeAutoLineCommand(startLine: Int, startCol: Int, styleChar: Character, arrowMode: LineArrowMode) {
        guard let editor = self.delegate else { return }
        let maxSearchLength = 200
        var targetOffset: Int? = nil
        var targetChar: Character? = nil

        for offset in 0..<maxSearchLength {
            let col = startCol + offset
            let existing = getLineCharAt(line: startLine, col: col)

            if offset == 0 {
                continue
            }

            if existing != " " {
                targetOffset = offset
                targetChar = existing
                break
            }
        }

        let drawableOffsets: [Int]
        if let target = targetOffset {
            let isMask = isMaskChar(targetChar ?? " ")
            let shouldFuse = !arrowMode.hasForwardArrow && isMask
            let maxOffset = shouldFuse ? target : target - 1
            if maxOffset >= 0 {
                drawableOffsets = Array(0...maxOffset)
            } else {
                drawableOffsets = []
            }
        } else {
            drawableOffsets = Array(0..<10)
        }

        guard !drawableOffsets.isEmpty else { return }

        editor.logoEngine(self, performAction: .ensureLineExists(index: startLine))
        let startLineStr = (editor.logoEngine(self, queryState: .lineAt(startLine)) as? String) ?? ""
        var currentChars = Array(startLineStr)
        while currentChars.count < startCol {
            currentChars.append(" ")
        }

        let lastOffset = drawableOffsets[drawableOffsets.count - 1]
        for offset in drawableOffsets {
            let col = startCol + offset
            while currentChars.count <= col {
                currentChars.append(" ")
            }

            let moveMask = horizontalMoveMask(offset: offset, lastOffset: lastOffset)
            let existing = currentChars[col]
            currentChars[col] = autoHorizontalLineChar(
                existing: existing, styleChar: styleChar, moveMask: moveMask,
                isStart: offset == 0, isEnd: offset == lastOffset, arrowMode: arrowMode)
        }

        editor.logoEngine(self, performAction: .setLine(index: startLine, text: String(currentChars)))
        editor.logoEngine(self, performAction: .updateColumnIndex(startCol + drawableOffsets.count))
    }

    private func executeAutoVlineCommand(startLine: Int, startCol: Int, styleChar: Character, arrowMode: LineArrowMode) {
        guard let editor = self.delegate else { return }
        let maxSearchHeight = 100
        var targetOffset: Int? = nil
        var targetChar: Character? = nil

        for offset in 0..<maxSearchHeight {
            let line = startLine + offset
            let existing = getLineCharAt(line: line, col: startCol)

            if offset == 0 {
                continue
            }

            if existing != " " {
                targetOffset = offset
                targetChar = existing
                break
            }
        }

        let drawableOffsets: [Int]
        if let target = targetOffset {
            let isMask = isMaskChar(targetChar ?? " ")
            let shouldFuse = !arrowMode.hasForwardArrow && isMask
            let maxOffset = shouldFuse ? target : target - 1
            if maxOffset >= 0 {
                drawableOffsets = Array(0...maxOffset)
            } else {
                drawableOffsets = []
            }
        } else {
            drawableOffsets = Array(0..<5)
        }

        guard !drawableOffsets.isEmpty else { return }

        let lastOffset = drawableOffsets[drawableOffsets.count - 1]
        for offset in drawableOffsets {
            let line = startLine + offset
            editor.logoEngine(self, performAction: .ensureLineExists(index: line))

            let lineStr = (editor.logoEngine(self, queryState: .lineAt(line)) as? String) ?? ""
            var currentChars = Array(lineStr)
            while currentChars.count <= startCol {
                currentChars.append(" ")
            }

            let moveMask = verticalMoveMask(offset: offset, lastOffset: lastOffset)
            let existing = currentChars[startCol]
            currentChars[startCol] = autoVerticalLineChar(
                existing: existing, styleChar: styleChar, moveMask: moveMask,
                isStart: offset == 0, isEnd: offset == lastOffset, arrowMode: arrowMode)

            editor.logoEngine(self, performAction: .setLine(index: line, text: String(currentChars)))
        }

        editor.logoEngine(self, performAction: .updateLineIndex(startLine + drawableOffsets.count))
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

    private func explicitHorizontalLineChar(
        existing: Character,
        styleChar: Character,
        moveMask: Int,
        isStart: Bool,
        isEnd: Bool,
        arrowMode: LineArrowMode
    ) -> Character {
        if isStart, arrowMode.hasBackwardArrow { return horizontalBackwardArrow(styleChar: styleChar) }
        if isEnd, arrowMode.hasForwardArrow { return horizontalForwardArrow(styleChar: styleChar) }
        return fuseChar(existing: existing, defaultNewChar: styleChar, moveMask: moveMask)
    }

    private func explicitVerticalLineChar(
        existing: Character,
        styleChar: Character,
        moveMask: Int,
        isStart: Bool,
        isEnd: Bool,
        arrowMode: LineArrowMode
    ) -> Character {
        if isStart, arrowMode.hasBackwardArrow { return verticalBackwardArrow(styleChar: styleChar) }
        if isEnd, arrowMode.hasForwardArrow { return verticalForwardArrow(styleChar: styleChar) }
        return fuseChar(existing: existing, defaultNewChar: styleChar, moveMask: moveMask)
    }

    private func autoHorizontalLineChar(
        existing: Character,
        styleChar: Character,
        moveMask: Int,
        isStart: Bool,
        isEnd: Bool,
        arrowMode: LineArrowMode
    ) -> Character {
        if isMaskChar(existing) {
            return fuseChar(existing: existing, defaultNewChar: styleChar, moveMask: moveMask)
        }
        if isStart, arrowMode.hasBackwardArrow { return horizontalBackwardArrow(styleChar: styleChar) }
        if isEnd, arrowMode.hasForwardArrow { return horizontalForwardArrow(styleChar: styleChar) }
        return fuseChar(existing: existing, defaultNewChar: styleChar, moveMask: moveMask)
    }

    private func autoVerticalLineChar(
        existing: Character,
        styleChar: Character,
        moveMask: Int,
        isStart: Bool,
        isEnd: Bool,
        arrowMode: LineArrowMode
    ) -> Character {
        if isMaskChar(existing) {
            return fuseChar(existing: existing, defaultNewChar: styleChar, moveMask: moveMask)
        }
        if isStart, arrowMode.hasBackwardArrow { return verticalBackwardArrow(styleChar: styleChar) }
        if isEnd, arrowMode.hasForwardArrow { return verticalForwardArrow(styleChar: styleChar) }
        return fuseChar(existing: existing, defaultNewChar: styleChar, moveMask: moveMask)
    }

    private func horizontalLineChar(styleChar: Character, isStart: Bool, isEnd: Bool, arrowMode: LineArrowMode) -> Character {
        if isStart, arrowMode.hasBackwardArrow { return horizontalBackwardArrow(styleChar: styleChar) }
        if isEnd, arrowMode.hasForwardArrow { return horizontalForwardArrow(styleChar: styleChar) }
        return styleChar
    }

    private func horizontalForwardArrow(styleChar: Character) -> Character {
        styleChar == "-" ? ">" : "→"
    }

    private func horizontalBackwardArrow(styleChar: Character) -> Character {
        styleChar == "-" ? "<" : "←"
    }

    private func verticalForwardArrow(styleChar: Character) -> Character {
        styleChar == "|" ? "v" : "↓"
    }

    private func verticalBackwardArrow(styleChar: Character) -> Character {
        styleChar == "|" ? "^" : "↑"
    }

    internal func executeNewlineCommand(_ tokens: [String], index: inout Int) {
        guard let editor = self.delegate else { return }
        var count = 1
        if index < tokens.count {
            let firstToken = tokens[index]

            if !LogoEngine.isKeyword(firstToken) && firstToken != "]" {
                let valStr = evaluateExpression(tokens, index: &index)
                count = max(1, min(Int(valStr) ?? 1, 50))
            } else {
                index -= 1
            }
        } else {
            index -= 1
        }

        for _ in 0..<count {
            editor.logoEngine(self, performAction: .insertNewline)
        }
    }

    internal func executeBoxCommand(_ tokens: [String], index: inout Int, mode: BoxDrawMode = .insert) {
        guard index < tokens.count else {
            drawBoxFrame(width: 20, height: 5, style: .single, mode: mode)
            return
        }

        let firstToken = tokens[index]

        // Mode 1: BOX width [height] ["text"] [align] [style]
        if let w = Int(unquote(firstToken)) {
            let width = max(3, min(w, 200))
            var height: Int? = nil
            var textContent: String? = nil
            var align = "left"
            var styleName = ""

            if index + 1 < tokens.count {
                let secondUpper = tokens[index + 1].uppercased()
                if let h = Int(unquote(secondUpper)) {
                    index += 1
                    height = max(2, min(h, 100))
                }
            }

            while index + 1 < tokens.count {
                let nextToken = tokens[index + 1]
                if shouldStopBoxArgumentScan(at: nextToken) { break }
                index += 1
                let val = unquote(tokens[index])

                if let parsedAlign = BoxAlignment(val) {
                    align = parsedAlign.rawValue
                } else if BoxStyle.isStyleToken(val) {
                    styleName = val
                } else if textContent == nil {
                    textContent = val
                }
            }

            if let text = textContent {
                drawBoxAroundText(text, targetWidth: width, targetHeight: height, align: align, style: BoxStyle.from(styleName), mode: mode)
            } else {
                drawBoxFrame(width: width, height: height ?? 5, style: BoxStyle.from(styleName), mode: mode)
            }
            return
        }

        // Mode 2: BOX "text" [align/style] [style/align]
        let textContent = evaluateExpression(tokens, index: &index)
        var align = "left"
        var styleName = ""

        while index + 1 < tokens.count {
            let nextToken = tokens[index + 1]
            if shouldStopBoxArgumentScan(at: nextToken) { break }
            index += 1
            let val = unquote(tokens[index])

            if let parsedAlign = BoxAlignment(val) {
                align = parsedAlign.rawValue
            } else if BoxStyle.isStyleToken(val) {
                styleName = val
            }
        }

        drawBoxAroundText(textContent, targetWidth: nil, targetHeight: nil, align: align, style: BoxStyle.from(styleName), mode: mode)
    }

    private func shouldStopBoxArgumentScan(at token: String) -> Bool {
        if token == "]" || token == ")" { return true }
        if BoxAlignment(token) != nil || BoxStyle.isStyleToken(token) { return false }
        return LogoEngine.isKeyword(token)
    }

    private func drawBoxFrame(width: Int, height: Int, style: BoxStyle, mode: BoxDrawMode) {
        guard let editor = self.delegate else { return }
        let startCol = (editor.logoEngine(self, queryState: .currentColumnIndex) as? Int) ?? 0
        let startLine = (editor.logoEngine(self, queryState: .currentLineIndex) as? Int) ?? 0

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

                if isTop && isLeft { ch = style.topLeft }
                else if isTop && isRight { ch = style.topRight }
                else if isBottom && isLeft { ch = style.bottomLeft }
                else if isBottom && isRight { ch = style.bottomRight }
                else if isTop { ch = style.topChar }
                else if isBottom { ch = style.bottomChar }
                else if isLeft || isRight { ch = style.sideChar }

                rowStr.append(ch)
            }

            let newLineText = buildRowText(
                existingLine: lineStr, startCol: startCol, rowStr: rowStr, isTop: isTop, isBottom: isBottom,
                mode: mode)
            editor.logoEngine(self, performAction: .setLine(index: currentLineIndex, text: newLineText))
        }

        editor.logoEngine(self, performAction: .updateLineIndex(startLine + height - 1))
        editor.logoEngine(self, performAction: .updateColumnIndex(startCol + width))
    }

    private func drawBoxAroundText(_ text: String, targetWidth: Int?, targetHeight: Int?, align: String, style: BoxStyle, mode: BoxDrawMode) {
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
                rowStr = String(style.topLeft) + String(repeating: style.topChar, count: innerWidth) + String(style.topRight)
            } else if isBottom {
                rowStr = String(style.bottomLeft) + String(repeating: style.bottomChar, count: innerWidth) + String(style.bottomRight)
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

        editor.logoEngine(self, performAction: .updateLineIndex(startLine + calcHeight - 1))
        editor.logoEngine(self, performAction: .updateColumnIndex(startCol + calcWidth))
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
            return buildInsertedRowText(existingLine: existingLine, startCol: startCol, rowStr: rowStr, isTop: isTop, isBottom: isBottom)
        case .overlay:
            return buildOverlayRowText(existingLine: existingLine, startCol: startCol, rowStr: rowStr, isTop: isTop, isBottom: isBottom)
        }
    }

    private func buildInsertedRowText(existingLine: String, startCol: Int, rowStr: String, isTop: Bool, isBottom: Bool) -> String {
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
            if isTop && isLeft { moveMask = 6 }
            else if isTop && isRight { moveMask = 12 }
            else if isBottom && isLeft { moveMask = 3 }
            else if isBottom && isRight { moveMask = 9 }
            else if isTop { moveMask = 10 }
            else if isBottom { moveMask = 10 }
            else if isLeft || isRight { moveMask = 5 }

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

    private func buildOverlayRowText(existingLine: String, startCol: Int, rowStr: String, isTop: Bool, isBottom: Bool) -> String {
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
            if isTop && isLeft { moveMask = 6 }
            else if isTop && isRight { moveMask = 12 }
            else if isBottom && isLeft { moveMask = 3 }
            else if isBottom && isRight { moveMask = 9 }
            else if isTop { moveMask = 10 }
            else if isBottom { moveMask = 10 }
            else if isLeft || isRight { moveMask = 5 }

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

        let firstValStr = unquote(tokens[index])

        var widthVal: Int? = nil
        var heightVal: Int? = nil
        var fillPattern = ""

        if let w = Int(firstValStr) {
            widthVal = w
            if index + 1 < tokens.count {
                let secondValStr = unquote(tokens[index + 1])
                if let h = Int(secondValStr) {
                    index += 1
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

        if fillPattern.isEmpty { fillPattern = " " }

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

    private func fillStringWithPattern(pattern: String, targetWidth: Int) -> String {
        guard targetWidth > 0 else { return "" }
        var result = ""
        var currentWidth = 0

        while currentWidth < targetWidth {
            let patWidth = pattern.displayWidth
            if patWidth == 0 { break }

            if currentWidth + patWidth <= targetWidth {
                result += pattern
                currentWidth += patWidth
            } else {
                let gap = targetWidth - currentWidth
                result += String(repeating: " ", count: gap)
                currentWidth += gap
            }
        }
        return result
    }

    private func replaceDisplayColumns(in line: String, startCol: Int, width: Int, replacement: String) -> String {
        let prefix = displayPrefix(in: line, before: startCol)
        let suffix = displaySuffix(in: line, after: startCol + width)
        let paddedPrefix = prefix + String(repeating: " ", count: max(0, startCol - prefix.displayWidth))
        return paddedPrefix + replacement + suffix
    }

    private func displayPrefix(in line: String, before targetCol: Int) -> String {
        var result = ""
        var col = 0
        for ch in line {
            let nextCol = col + ch.displayWidth
            if nextCol <= targetCol {
                result.append(ch)
            } else {
                break
            }
            col = nextCol
        }
        return result
    }

    private func displaySuffix(in line: String, after targetCol: Int) -> String {
        var result = ""
        var col = 0
        for ch in line {
            let nextCol = col + ch.displayWidth
            if col >= targetCol {
                result.append(ch)
            } else if nextCol > targetCol {
                let overflow = nextCol - targetCol
                result += String(repeating: " ", count: overflow)
            }
            col = nextCol
        }
        return result
    }

    private func performFloodFill(startLine: Int, startCol: Int, fillPattern: String) {
        guard let editor = self.delegate else { return }

        let boxBorderChars: Set<Character> = [
            "│", "─", "┌", "┐", "└", "┘", "├", "┤", "┬", "┴", "┼",
            "║", "═", "╔", "╗", "╚", "╝", "╠", "╣", "╦", "╩", "╬",
            "+", "-", "|", "│"
        ]

        let totalLines = max(startLine + 1, (editor.logoEngine(self, queryState: .lineCount) as? Int) ?? 0)

        var visited: Set<[Int]> = []
        var queue: [[Int]] = [[startLine, startCol]]
        visited.insert([startLine, startCol])

        let maxRows = min(totalLines + 20, 200)
        let maxCols = 200

        var lineMap: [Int: [Character]] = [:]

        func getCharAt(r: Int, c: Int) -> Character {
            if lineMap[r] == nil {
                let lineStr = (editor.logoEngine(self, queryState: .lineAt(r)) as? String) ?? ""
                lineMap[r] = Array(lineStr)
            }
            let chars = lineMap[r]!
            if c >= 0 && c < chars.count {
                return chars[c]
            }
            return " "
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
