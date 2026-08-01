import Foundation
import TextMetrics

extension LogoEngine {
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

        editor.logoEngine(self, performAction: .ensureLineExists(index: startLine))

        var lineText = (editor.logoEngine(self, queryState: .lineAt(startLine)) as? String) ?? ""

        for i in 0..<length {
            let col = startCol + i
            let moveMask = (i == 0) ? 2 : ((i == length - 1) ? 8 : 10)
            let existing = displayCharAt(in: lineText, visualColumn: col)
            let char = explicitHorizontalLineChar(
                existing: existing, styleChar: styleChar, moveMask: moveMask,
                isStart: i == 0, isEnd: i == length - 1, arrowMode: arrowMode)
            lineText = replaceDisplayColumns(in: lineText, startCol: col, width: 1, replacement: String(char))
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
            editor.logoEngine(self, performAction: .ensureLineExists(index: line))

            let lineStr = (editor.logoEngine(self, queryState: .lineAt(line)) as? String) ?? ""

            let moveMask = (r == 0) ? 4 : ((r == height - 1) ? 1 : 5)
            let existing = displayCharAt(in: lineStr, visualColumn: startCol)
            let char = explicitVerticalLineChar(
                existing: existing, styleChar: styleChar, moveMask: moveMask,
                isStart: r == 0, isEnd: r == height - 1, arrowMode: arrowMode)
            let lineText = replaceDisplayColumns(in: lineStr, startCol: startCol, width: 1, replacement: String(char))

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
            } else if !LogoEngine.isKeyword(token) {
                var evalIndex = cursor
                if let parsedLength = parseUnquotedIntArgument(tokens, index: &evalIndex) {
                    setLength(max(1, min(parsedLength, maxLength)))
                    consumedAny = true
                    cursor = evalIndex
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
        var lineText = (editor.logoEngine(self, queryState: .lineAt(startLine)) as? String) ?? ""

        let lastOffset = drawableOffsets[drawableOffsets.count - 1]
        for offset in drawableOffsets {
            let col = startCol + offset

            let moveMask = horizontalMoveMask(offset: offset, lastOffset: lastOffset)
            let existing = displayCharAt(in: lineText, visualColumn: col)
            let char = autoHorizontalLineChar(
                existing: existing, styleChar: styleChar, moveMask: moveMask,
                isStart: offset == 0, isEnd: offset == lastOffset, arrowMode: arrowMode)
            lineText = replaceDisplayColumns(in: lineText, startCol: col, width: 1, replacement: String(char))
        }

        editor.logoEngine(self, performAction: .setLine(index: startLine, text: lineText))
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

            let moveMask = verticalMoveMask(offset: offset, lastOffset: lastOffset)
            let existing = displayCharAt(in: lineStr, visualColumn: startCol)
            let char = autoVerticalLineChar(
                existing: existing, styleChar: styleChar, moveMask: moveMask,
                isStart: offset == 0, isEnd: offset == lastOffset, arrowMode: arrowMode)
            let lineText = replaceDisplayColumns(in: lineStr, startCol: startCol, width: 1, replacement: String(char))

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

    private func displayCharAt(in line: String, visualColumn: Int) -> Character {
        var col = 0
        for ch in line {
            if col == visualColumn {
                return ch
            }
            col += ch.displayWidth
            if col > visualColumn {
                return " "
            }
        }
        return " "
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
                result += String(repeating: " ", count: nextCol - targetCol)
            }
            col = nextCol
        }
        return result
    }

    internal func executeNewlineCommand(_ tokens: [String], index: inout Int) {
        guard let editor = self.delegate else { return }
        var count = 1
        if index < tokens.count {
            let firstToken = tokens[index]

            if !LogoEngine.isKeyword(firstToken) && firstToken != "]" {
                if let parsedCount = parseUnquotedIntArgument(tokens, index: &index) {
                    count = max(1, min(parsedCount, 50))
                } else if LogoEngine.isKeyword(firstToken) || firstToken == "]" {
                    index -= 1
                }
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
}
