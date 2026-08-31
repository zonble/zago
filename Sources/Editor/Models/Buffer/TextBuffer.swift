import Foundation
import SpellChecker
import TextMetrics
import TextTransform

/// Manages text buffer lines and cursor operations.
class TextBuffer: SpellCheckableBuffer {
    let id: String = UUID().uuidString
    var lines: [String] = [""]
    var filePath: String?
    var loadErrorDescription: String?
    var isModified: Bool = false

    /// Real buffer cursor position (measured in Character / Grapheme Clusters).
    /// lineIndex: 0-indexed line number
    /// columnIndex: 0-indexed column offset
    var lineIndex: Int = 0
    var columnIndex: Int = 0

    // Runtime mode state belongs to the buffer/editor view, not to the process.
    var baseMode: EditorBaseMode = .text
    var overlayMode: EditorOverlayMode = .none
    var canvasVisualColumn: Int = 0
    var canvasHorizontalOffset: Int = 0
    var topVLineIndex: Int = 0
    var isTableModeActive: Bool = false
    var currentTableCell: TableCell? = nil
    var selectionMark: (line: Int, column: Int)? = nil
    var canvasBlockMark: (line: Int, visualColumn: Int)? = nil
    var canvasBlockMarkEnd: (line: Int, visualColumn: Int)? = nil
    var activeSearchMatch: SearchMatch? = nil
    var viewShowRuler: Bool = false
    var viewShowLineNumbers: Bool = true
    var viewShowSubLineNumbers: Bool = false
    var viewIsZeroMode: Bool = false
    var viewShowIndicator: Bool = false
    var viewWrapColumn: Int? = nil
    var borderStyle: BorderStyle = .single
    var isBorderRounded: Bool = false
    var arrowStyle: ArrowStyle = .solid
    var lineEnding: LineEnding = .lf
    var hasTrailingNewline: Bool = false
    var undoStack: [UndoSnapshot] = []
    var redoStack: [UndoSnapshot] = []
    var maxUndoStackSize: Int = 100

    private var isReadOnlyStored: Bool = false
    var isReadOnly: Bool {
        get { isReadOnlyStored }
        set { isReadOnlyStored = newValue }
    }
    var isLargeFileMode: Bool = false
    var fileSize: Int64 = 0
    var allowsLogoExecution: Bool { true }
    var isDirectoryBuffer: Bool { false }
    var isScratchBuffer: Bool {
        guard let path = filePath else { return true }
        return path.hasPrefix("*")
    }

    var onLineCountChanged: ((_ aboveLine: Int, _ delta: Int) -> Void)?

    init(filePath: String? = nil) {
        self.filePath = filePath
    }

    static func getOrderedRange(
        mark1: (line: Int, column: Int),
        mark2: (line: Int, column: Int)
    ) -> (start: (line: Int, column: Int), end: (line: Int, column: Int)) {
        if mark1.line < mark2.line {
            return (start: mark1, end: mark2)
        } else if mark1.line > mark2.line {
            return (start: mark2, end: mark1)
        } else {
            if mark1.column <= mark2.column {
                return (start: mark1, end: mark2)
            } else {
                return (start: mark2, end: mark1)
            }
        }
    }

    var fileEncoding: String.Encoding = .utf8

    /// Key handler for specialized buffer types. Returns true if handled.
    func handleKey(_ key: Key, editor: Editor) -> Bool {
        return false
    }

    @discardableResult
    func trimTrailingWhitespace() -> Bool {
        let trimmedLines = lines.map { line in
            String(line.reversed().drop(while: { $0 == " " || $0 == "\t" }).reversed())
        }
        guard trimmedLines != lines else { return false }
        lines = trimmedLines
        clampCursor()
        isModified = true
        return true
    }

    func replaceContents(
        _ text: String, filePath: String? = nil, isModified: Bool = false, defaultLineEnding: LineEnding = .lf
    ) {
        self.lineEnding = LineEnding.detect(in: text, fallback: defaultLineEnding)
        self.hasTrailingNewline = text.hasSuffix("\r\n") || text.hasSuffix("\n") || text.hasSuffix("\r")
        let normalized =
            text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let fileLines = normalized.components(separatedBy: "\n")
        if hasTrailingNewline && fileLines.count > 1 && fileLines.last == "" {
            self.lines = Array(fileLines.dropLast())
        } else {
            self.lines = fileLines.isEmpty ? [""] : fileLines
        }
        self.filePath = filePath ?? self.filePath
        self.isModified = isModified
    }

    /// Inserts multi-line or single-line string content at current cursor position.
    func insertString(_ text: String) {
        ensureBounds()
        let textLines = text.components(separatedBy: .newlines)
        if textLines.isEmpty { return }

        if textLines.count == 1 {
            let singleLine = textLines[0]
            var currentLine = lines[lineIndex]
            let idx =
                currentLine.index(currentLine.startIndex, offsetBy: columnIndex, limitedBy: currentLine.endIndex)
                ?? currentLine.endIndex
            currentLine.insert(contentsOf: singleLine, at: idx)
            lines[lineIndex] = currentLine
            columnIndex += singleLine.count
        } else {
            let currentLine = lines[lineIndex]
            let idx =
                currentLine.index(currentLine.startIndex, offsetBy: columnIndex, limitedBy: currentLine.endIndex)
                ?? currentLine.endIndex

            let leftPart = String(currentLine[..<idx])
            let rightPart = String(currentLine[idx...])

            var newMiddleLines: [String] = []
            newMiddleLines.append(leftPart + textLines[0])
            if textLines.count > 2 {
                for l in textLines[1..<(textLines.count - 1)] {
                    newMiddleLines.append(l)
                }
            }
            let lastLine = textLines.last!
            newMiddleLines.append(lastLine + rightPart)

            lines.replaceSubrange(lineIndex...lineIndex, with: newMiddleLines)
            lineIndex = lineIndex + textLines.count - 1
            columnIndex = lastLine.count
        }
        isModified = true
    }

    /// Cuts text range from start (line, col) to end (line, col) and returns cut text.
    func textRange(
        start: (line: Int, col: Int),
        end: (line: Int, col: Int)
    ) -> String {
        guard start.line >= 0, start.line < lines.count, end.line >= 0, end.line < lines.count else { return "" }
        guard start.line <= end.line else { return "" }

        if start.line == end.line {
            let line = lines[start.line]
            let startCol = max(0, min(start.col, line.count))
            let endCol = max(startCol, min(end.col, line.count))
            let sIdx = line.index(line.startIndex, offsetBy: startCol)
            let eIdx = line.index(line.startIndex, offsetBy: endCol)
            return String(line[sIdx..<eIdx])
        }

        let startLineStr = lines[start.line]
        let endLineStr = lines[end.line]
        let startCol = max(0, min(start.col, startLineStr.count))
        let endCol = max(0, min(end.col, endLineStr.count))
        let sIdx = startLineStr.index(startLineStr.startIndex, offsetBy: startCol)
        let eIdx = endLineStr.index(endLineStr.startIndex, offsetBy: endCol)

        var copiedLines: [String] = [String(startLineStr[sIdx...])]
        if start.line + 1 < end.line {
            copiedLines.append(contentsOf: lines[(start.line + 1)..<end.line])
        }
        copiedLines.append(String(endLineStr[..<eIdx]))
        return copiedLines.joined(separator: "\n")
    }

    /// Cuts text range from start (line, col) to end (line, col) and returns cut text.
    func cutRange(
        start: (line: Int, col: Int),
        end: (line: Int, col: Int)
    ) -> String {
        ensureBounds()
        guard start.line <= end.line else { return "" }

        if start.line == end.line {
            var line = lines[start.line]
            let startCol = max(0, min(start.col, line.count))
            let endCol = max(startCol, min(end.col, line.count))
            let sIdx = line.index(line.startIndex, offsetBy: startCol)
            let eIdx = line.index(line.startIndex, offsetBy: endCol)
            let cutText = String(line[sIdx..<eIdx])
            line.removeSubrange(sIdx..<eIdx)
            lines[start.line] = line
            lineIndex = start.line
            columnIndex = startCol
            isModified = true
            return cutText
        } else {
            let startLineStr = lines[start.line]
            let endLineStr = lines[end.line]

            let startCol = max(0, min(start.col, startLineStr.count))
            let endCol = max(0, min(end.col, endLineStr.count))

            let sIdx = startLineStr.index(startLineStr.startIndex, offsetBy: startCol)
            let eIdx = endLineStr.index(endLineStr.startIndex, offsetBy: endCol)

            let firstLineCut = String(startLineStr[sIdx...])
            let lastLineCut = String(endLineStr[..<eIdx])

            var cutLines: [String] = [firstLineCut]
            if start.line + 1 < end.line {
                cutLines.append(contentsOf: lines[(start.line + 1)..<end.line])
            }
            cutLines.append(lastLineCut)

            let remainingStart = String(startLineStr[..<sIdx])
            let remainingEnd = String(endLineStr[eIdx...])

            lines[start.line] = remainingStart + remainingEnd
            if start.line + 1 <= end.line {
                lines.removeSubrange((start.line + 1)...end.line)
            }
            lineIndex = start.line
            columnIndex = startCol
            isModified = true
            return cutLines.joined(separator: "\n")
        }
    }

    /// Inserts a character at the current cursor position.
    func insert(character ch: Character) {
        ensureBounds()
        var currentLine = lines[lineIndex]
        let index =
            currentLine.index(currentLine.startIndex, offsetBy: columnIndex, limitedBy: currentLine.endIndex)
            ?? currentLine.endIndex
        currentLine.insert(ch, at: index)
        lines[lineIndex] = currentLine
        columnIndex += 1
        isModified = true
    }

    /// Inserts a newline at the current cursor position, optionally continuing list items for Markdown/AsciiDoc/Org buffers.
    func insertNewline(enableListAutoIndent: Bool = false) {
        ensureBounds()
        let currentLine = lines[lineIndex]
        let index =
            currentLine.index(currentLine.startIndex, offsetBy: columnIndex, limitedBy: currentLine.endIndex)
            ?? currentLine.endIndex

        let leftPart = String(currentLine[..<index])
        let rightPart = String(currentLine[index...])

        if enableListAutoIndent, let listInfo = parseListPrefix(leftPart) {
            if listInfo.isEmptyItem && rightPart.isEmpty {
                // Empty item termination: clear list prefix on current line and convert to normal empty newline
                lines[lineIndex] = String(listInfo.leadingWhitespace)
                lines.insert(String(listInfo.leadingWhitespace), at: lineIndex + 1)
                lineIndex += 1
                columnIndex = listInfo.leadingWhitespace.count
                isModified = true
                return
            } else if !listInfo.isEmptyItem {
                lines[lineIndex] = leftPart
                let nextLine = listInfo.nextPrefix + rightPart
                lines.insert(nextLine, at: lineIndex + 1)
                lineIndex += 1
                columnIndex = listInfo.nextPrefix.count
                isModified = true
                return
            }
        }

        lines[lineIndex] = leftPart
        lines.insert(rightPart, at: lineIndex + 1)
        onLineCountChanged?(lineIndex + 2, 1)

        lineIndex += 1
        columnIndex = 0
        isModified = true
    }

    private struct ListPrefixInfo {
        let leadingWhitespace: String
        let itemPrefix: String
        let nextPrefix: String
        let isEmptyItem: Bool
        let isBlockquote: Bool
        let explicitContinuationPrefix: String?

        init(
            leadingWhitespace: String,
            itemPrefix: String,
            nextPrefix: String,
            isEmptyItem: Bool,
            isBlockquote: Bool = false,
            explicitContinuationPrefix: String? = nil
        ) {
            self.leadingWhitespace = leadingWhitespace
            self.itemPrefix = itemPrefix
            self.nextPrefix = nextPrefix
            self.isEmptyItem = isEmptyItem
            self.isBlockquote = isBlockquote
            self.explicitContinuationPrefix = explicitContinuationPrefix
        }

        var continuationPrefix: String {
            explicitContinuationPrefix
                ?? (leadingWhitespace + String(repeating: " ", count: itemPrefix.count - leadingWhitespace.count))
        }
    }

    private func parseListPrefix(_ text: String) -> ListPrefixInfo? {
        let leading = String(text.prefix(while: { $0 == " " || $0 == "\t" }))
        let rest = String(text.dropFirst(leading.count))

        // 1. Task List: - [ ] or - [x] or * [ ] or * [x]
        if rest.hasPrefix("- [ ] ") || rest.hasPrefix("- [x] ") || rest.hasPrefix("* [ ] ") || rest.hasPrefix("* [x] ")
        {
            let afterPrefix = rest.dropFirst(6)
            let isEmpty = afterPrefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return ListPrefixInfo(
                leadingWhitespace: leading,
                itemPrefix: leading + String(rest.prefix(6)),
                nextPrefix: leading + "- [ ] ",
                isEmptyItem: isEmpty
            )
        }

        // 2. Ordered List: e.g. "1. ", "12. "
        if let match = rest.range(of: "^[0-9]+\\.\\s+", options: .regularExpression) {
            let prefixStr = String(rest[match])
            let numStr = prefixStr.trimmingCharacters(in: .whitespacesAndNewlines).dropLast()
            if let num = Int(numStr) {
                let afterPrefix = rest[match.upperBound...]
                let isEmpty = afterPrefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                return ListPrefixInfo(
                    leadingWhitespace: leading,
                    itemPrefix: leading + prefixStr,
                    nextPrefix: leading + "\(num + 1). ",
                    isEmptyItem: isEmpty
                )
            }
        }

        // 3. Bullet List: - , * , +
        if rest.hasPrefix("- ") || rest.hasPrefix("* ") || rest.hasPrefix("+ ") {
            let symbol = String(rest.prefix(2))
            let afterPrefix = rest.dropFirst(2)
            let isEmpty = afterPrefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return ListPrefixInfo(
                leadingWhitespace: leading,
                itemPrefix: leading + symbol,
                nextPrefix: leading + symbol,
                isEmptyItem: isEmpty
            )
        }

        // 4. Blockquote: > or >> or > >
        if rest.hasPrefix(">") {
            let quoteMarker = String(rest.prefix(while: { $0 == ">" || $0 == " " || $0 == "\t" }))
            let normalizedMarker = quoteMarker.hasSuffix(" ") ? quoteMarker : quoteMarker + " "
            let afterPrefix = rest.dropFirst(quoteMarker.count)
            let isEmpty = afterPrefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let fullPrefix = leading + (isEmpty ? quoteMarker : normalizedMarker)
            let contPrefix = leading + normalizedMarker
            return ListPrefixInfo(
                leadingWhitespace: leading,
                itemPrefix: fullPrefix,
                nextPrefix: contPrefix,
                isEmptyItem: isEmpty,
                isBlockquote: true,
                explicitContinuationPrefix: contPrefix
            )
        }

        return nil
    }

    /// Moves cursor forward by one word (M+F).
    func moveWordForward() {
        ensureBounds()
        let currentLine = lines[lineIndex]

        if columnIndex >= currentLine.count {
            if lineIndex < lines.count - 1 {
                lineIndex += 1
                columnIndex = 0
            }
            return
        }

        columnIndex = TextAnalyzer.nextWordIndex(in: currentLine, from: columnIndex)
    }

    /// Moves cursor backward by one word (M+B).
    func moveWordBackward() {
        ensureBounds()

        if columnIndex == 0 {
            if lineIndex > 0 {
                lineIndex -= 1
                columnIndex = lines[lineIndex].count
            }
            return
        }

        let currentLine = lines[lineIndex]
        columnIndex = TextAnalyzer.previousWordIndex(in: currentLine, from: columnIndex)
    }

    /// Deletes the character preceding the cursor (Backspace).
    func backspace() {
        ensureBounds()
        if columnIndex > 0 {
            var currentLine = lines[lineIndex]
            let prevIndex = currentLine.index(currentLine.startIndex, offsetBy: columnIndex - 1)
            currentLine.remove(at: prevIndex)
            lines[lineIndex] = currentLine
            columnIndex -= 1
            isModified = true
        } else if lineIndex > 0 {
            // Merge with end of previous line
            let oldLineIdx = lineIndex
            let currentLine = lines.remove(at: lineIndex)
            lineIndex -= 1
            let prevLineLength = lines[lineIndex].count
            lines[lineIndex].append(currentLine)
            columnIndex = prevLineLength
            isModified = true
            onLineCountChanged?(oldLineIdx + 1, -1)
        }
    }

    /// Deletes the current line entirely (Ctrl+Backspace).
    func deleteLine() {
        ensureBounds()
        if lines.count > 1 {
            let oldLineIdx = lineIndex
            lines.remove(at: lineIndex)
            if lineIndex >= lines.count {
                lineIndex = lines.count - 1
            }
            columnIndex = 0
            clampCursor()
            onLineCountChanged?(oldLineIdx + 1, -1)
        } else {
            lines[0] = ""
            lineIndex = 0
            columnIndex = 0
        }
        isModified = true
    }

    /// Deletes the character at the cursor position (Delete).
    func delete() {
        ensureBounds()
        let currentLine = lines[lineIndex]
        if columnIndex < currentLine.count {
            var lineCopy = currentLine
            let targetIndex = lineCopy.index(lineCopy.startIndex, offsetBy: columnIndex)
            lineCopy.remove(at: targetIndex)
            lines[lineIndex] = lineCopy
            isModified = true
        } else if lineIndex < lines.count - 1 {
            // Merge next line into current line
            let deletedLineIdx = lineIndex + 1
            let nextLine = lines.remove(at: lineIndex + 1)
            lines[lineIndex].append(nextLine)
            isModified = true
            onLineCountChanged?(deletedLineIdx + 1, -1)
        }
    }

    /// Clamps cursor position to valid buffer line and column bounds.
    func clampCursor() {
        if lines.isEmpty {
            lines = [""]
        }
        lineIndex = max(0, min(lineIndex, lines.count - 1))
        let currentLineCount = lines[lineIndex].count
        columnIndex = max(0, min(columnIndex, currentLineCount))
    }

    /// Visual Token representation for paragraph reflow.
    private enum VisualToken: Equatable {
        case wide(Character)
        case latin(String)
        case space
    }

    private struct ReflowToken {
        let token: VisualToken
        let sourceRange: Range<Int>
    }

    /// Tokenizes paragraph text into wide characters, Latin words, and spaces with source ranges.
    private static func tokenizeForReflow(_ text: String) -> [ReflowToken] {
        var tokens: [ReflowToken] = []
        var currentLatin = ""
        var latinStart = 0

        for (index, ch) in text.enumerated() {
            if ch.isWhitespace {
                if !currentLatin.isEmpty {
                    tokens.append(ReflowToken(token: .latin(currentLatin), sourceRange: latinStart..<index))
                    currentLatin = ""
                }
                if tokens.last?.token != .space {
                    tokens.append(ReflowToken(token: .space, sourceRange: index..<(index + 1)))
                }
            } else if ch.displayWidth >= 2 {
                if !currentLatin.isEmpty {
                    tokens.append(ReflowToken(token: .latin(currentLatin), sourceRange: latinStart..<index))
                    currentLatin = ""
                }
                tokens.append(ReflowToken(token: .wide(ch), sourceRange: index..<(index + 1)))
            } else {
                if currentLatin.isEmpty {
                    latinStart = index
                }
                currentLatin.append(ch)
            }
        }

        if !currentLatin.isEmpty {
            tokens.append(ReflowToken(token: .latin(currentLatin), sourceRange: latinStart..<text.count))
        }

        if tokens.first?.token == .space { tokens.removeFirst() }
        if tokens.last?.token == .space { tokens.removeLast() }

        return tokens
    }

    /// Reflows visual tokens into lines bounded by targetWidth display columns.
    private static func reflowVisualTokens(_ tokens: [ReflowToken], targetWidth: Int) -> [String] {
        reflowVisualTokensWithCursor(tokens, targetWidth: targetWidth, cursorOffset: -1).lines
    }

    private static func reflowVisualTokensWithCursor(
        _ tokens: [ReflowToken],
        targetWidth: Int,
        cursorOffset: Int
    ) -> (lines: [String], relativeLine: Int, column: Int) {
        var resultLines: [String] = []
        var currentLine = ""
        var targetLine: Int? = nil
        var targetCol: Int? = nil

        for (i, reflowToken) in tokens.enumerated() {
            let isTargetToken: Bool
            if targetLine == nil && cursorOffset >= 0 {
                if reflowToken.sourceRange.contains(cursorOffset) {
                    isTargetToken = true
                } else if cursorOffset == reflowToken.sourceRange.lowerBound {
                    isTargetToken = true
                } else if i == tokens.count - 1 && cursorOffset >= reflowToken.sourceRange.upperBound {
                    isTargetToken = true
                } else {
                    isTargetToken = false
                }
            } else {
                isTargetToken = false
            }

            switch reflowToken.token {
            case .wide(let ch):
                let w = ch.displayWidth
                if currentLine.displayWidth + w > targetWidth && !currentLine.isEmpty {
                    resultLines.append(currentLine.trimmingCharacters(in: .whitespaces))
                    currentLine = String(ch)
                } else {
                    currentLine.append(ch)
                }

                if isTargetToken {
                    targetLine = resultLines.count
                    let offsetInToken = max(0, min(cursorOffset - reflowToken.sourceRange.lowerBound, 1))
                    targetCol = currentLine.count - 1 + offsetInToken
                }

            case .latin(let word):
                let w = word.displayWidth
                let needsSpace: Bool
                if let lastChar = currentLine.last, !lastChar.isWhitespace && lastChar.displayWidth == 1 {
                    needsSpace = true
                } else {
                    needsSpace = false
                }

                let spaceWidth = needsSpace ? 1 : 0
                if currentLine.displayWidth + spaceWidth + w > targetWidth && !currentLine.isEmpty {
                    resultLines.append(currentLine.trimmingCharacters(in: .whitespaces))
                    currentLine = word
                } else {
                    if needsSpace {
                        currentLine.append(" ")
                    }
                    currentLine.append(word)
                }

                if isTargetToken {
                    targetLine = resultLines.count
                    let offsetInToken = max(0, min(cursorOffset - reflowToken.sourceRange.lowerBound, word.count))
                    targetCol = (currentLine.count - word.count) + offsetInToken
                }

            case .space:
                if isTargetToken {
                    targetLine = resultLines.count
                    targetCol = currentLine.count
                }
                if !currentLine.isEmpty && !currentLine.hasSuffix(" ") {
                    if currentLine.displayWidth + 1 <= targetWidth {
                        currentLine.append(" ")
                    }
                }
            }
        }

        if !currentLine.trimmingCharacters(in: .whitespaces).isEmpty {
            resultLines.append(currentLine.trimmingCharacters(in: .whitespaces))
        }

        let finalLines = resultLines.isEmpty ? [""] : resultLines
        let relLine = min(targetLine ?? (finalLines.count - 1), finalLines.count - 1)
        let col = min(targetCol ?? finalLines[relLine].count, finalLines[relLine].count)

        return (finalLines, relLine, col)
    }

    /// Joins lines of a paragraph into a single continuous text string, respecting CJK word boundaries.
    private static func joinParagraphLines(_ paragraphLines: [String]) -> String {
        joinParagraphLinesWithCursor(paragraphLines, cursorLine: -1, cursorCol: -1).joined
    }

    private static func joinParagraphLinesWithCursor(
        _ paragraphLines: [String],
        cursorLine: Int,
        cursorCol: Int
    ) -> (joined: String, cursorOffset: Int) {
        var result = ""
        var targetOffset: Int? = nil

        for (i, line) in paragraphLines.enumerated() {
            let col = i == cursorLine ? max(0, min(cursorCol, line.count)) : line.count
            let leadingSpaces = line.prefix(while: { $0.isWhitespace }).count
            let lineOffset = max(0, col - leadingSpaces)
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty { continue }

            if result.isEmpty {
                if i == cursorLine {
                    targetOffset = min(lineOffset, trimmedLine.count)
                }
                result = trimmedLine
            } else {
                guard let lastChar = result.last, let firstChar = trimmedLine.first else {
                    result += trimmedLine
                    continue
                }
                let separator: String
                if lastChar.displayWidth >= 2 && firstChar.displayWidth >= 2 {
                    separator = ""
                } else if lastChar.isWhitespace || firstChar.isWhitespace {
                    separator = ""
                } else {
                    separator = " "
                }
                result += separator
                if i == cursorLine && targetOffset == nil {
                    targetOffset = result.count + min(lineOffset, trimmedLine.count)
                }
                result += trimmedLine
            }
        }

        return (result, targetOffset ?? result.count)
    }

    /// Justifies (reflows) the paragraph at current cursor position (^J) using visual column display widths.
    func justifyParagraph(targetWidth: Int = 72) {
        guard !lines.isEmpty else { return }
        clampCursor()

        let origLineIndex = lineIndex
        let origColumnIndex = columnIndex

        let currentLine = lines[lineIndex]
        if currentLine.trimmingCharacters(in: .whitespaces).isEmpty {
            return
        }

        // 1. Find paragraph boundaries, or the individual list item boundaries.
        var startLine = lineIndex
        while startLine > 0 && !lines[startLine - 1].trimmingCharacters(in: .whitespaces).isEmpty {
            startLine -= 1
        }

        var endLine = lineIndex
        while endLine < lines.count - 1 && !lines[endLine + 1].trimmingCharacters(in: .whitespaces).isEmpty {
            endLine += 1
        }

        var listInfo: ListPrefixInfo?
        var listItemStart = lineIndex
        while listItemStart >= startLine {
            if let info = parseListPrefix(lines[listItemStart]) {
                listInfo = info
                break
            }
            listItemStart -= 1
        }

        if let listInfo {
            if listInfo.isBlockquote {
                startLine = lineIndex
                while startLine > 0,
                    let prevInfo = parseListPrefix(lines[startLine - 1]),
                    prevInfo.isBlockquote,
                    !lines[startLine - 1].trimmingCharacters(in: .whitespaces).isEmpty
                {
                    startLine -= 1
                }

                endLine = lineIndex
                while endLine < lines.count - 1,
                    let nextInfo = parseListPrefix(lines[endLine + 1]),
                    nextInfo.isBlockquote,
                    !lines[endLine + 1].trimmingCharacters(in: .whitespaces).isEmpty
                {
                    endLine += 1
                }

                var rawBodyLines: [String] = []
                for idx in startLine...endLine {
                    let line = lines[idx]
                    if let info = parseListPrefix(line), info.isBlockquote {
                        rawBodyLines.append(String(line.dropFirst(info.itemPrefix.count)))
                    } else {
                        rawBodyLines.append(line)
                    }
                }

                let relativeCursorLine = origLineIndex - startLine
                let currentLinePrefixCount = parseListPrefix(lines[origLineIndex])?.itemPrefix.count ?? 0
                let relativeCursorCol = max(0, origColumnIndex - currentLinePrefixCount)

                let (paragraphText, cursorOffset) = TextBuffer.joinParagraphLinesWithCursor(
                    rawBodyLines,
                    cursorLine: relativeCursorLine,
                    cursorCol: relativeCursorCol
                )
                let tokens = TextBuffer.tokenizeForReflow(paragraphText)
                let bodyWidth = max(1, targetWidth - listInfo.continuationPrefix.displayWidth)
                let (wrappedBody, relLine, bodyCol) = TextBuffer.reflowVisualTokensWithCursor(
                    tokens,
                    targetWidth: bodyWidth,
                    cursorOffset: cursorOffset
                )
                let newParagraphLines = wrappedBody.map { line in
                    listInfo.continuationPrefix + line
                }

                lines.replaceSubrange(startLine...endLine, with: newParagraphLines)

                lineIndex = min(startLine + relLine, lines.count - 1)
                clampCursor()
                columnIndex = min(listInfo.continuationPrefix.count + bodyCol, lines[lineIndex].count)
                isModified = true
                return
            }

            startLine = listItemStart
            endLine = startLine
            while endLine < lines.count - 1,
                !lines[endLine + 1].trimmingCharacters(in: .whitespaces).isEmpty,
                parseListPrefix(lines[endLine + 1]) == nil
            {
                endLine += 1
            }

            let firstLine = lines[startLine]
            let body = String(firstLine.dropFirst(listInfo.itemPrefix.count))
            let continuationLines = endLine > startLine ? Array(lines[(startLine + 1)...endLine]) : []
            let relativeCursorLine = origLineIndex - startLine
            let relativeCursorCol =
                relativeCursorLine == 0
                ? max(0, origColumnIndex - listInfo.itemPrefix.count)
                : origColumnIndex

            let (paragraphText, cursorOffset) = TextBuffer.joinParagraphLinesWithCursor(
                [body] + continuationLines,
                cursorLine: relativeCursorLine,
                cursorCol: relativeCursorCol
            )
            let tokens = TextBuffer.tokenizeForReflow(paragraphText)
            let bodyWidth = max(1, targetWidth - listInfo.continuationPrefix.displayWidth)
            let (wrappedBody, relLine, bodyCol) = TextBuffer.reflowVisualTokensWithCursor(
                tokens,
                targetWidth: bodyWidth,
                cursorOffset: cursorOffset
            )
            let newParagraphLines = wrappedBody.enumerated().map { index, line in
                (index == 0 ? listInfo.itemPrefix : listInfo.continuationPrefix) + line
            }

            lines.replaceSubrange(startLine...endLine, with: newParagraphLines)

            lineIndex = min(startLine + relLine, lines.count - 1)
            clampCursor()
            let prefix = relLine == 0 ? listInfo.itemPrefix : listInfo.continuationPrefix
            columnIndex = min(prefix.count + bodyCol, lines[lineIndex].count)
            isModified = true
            return
        }

        // 2. Extract and reflow a regular paragraph using visual display width.
        let rawParagraphLines = Array(lines[startLine...endLine])
        let relativeCursorLine = origLineIndex - startLine
        let (paragraphText, cursorOffset) = TextBuffer.joinParagraphLinesWithCursor(
            rawParagraphLines,
            cursorLine: relativeCursorLine,
            cursorCol: origColumnIndex
        )
        let tokens = TextBuffer.tokenizeForReflow(paragraphText)
        let (newParagraphLines, relLine, col) = TextBuffer.reflowVisualTokensWithCursor(
            tokens,
            targetWidth: targetWidth,
            cursorOffset: cursorOffset
        )

        // 3. Replace original paragraph lines with reflowed lines.
        lines.replaceSubrange(startLine...endLine, with: newParagraphLines)

        lineIndex = min(startLine + relLine, lines.count - 1)
        clampCursor()
        columnIndex = min(col, lines[lineIndex].count)
        isModified = true
    }

    private func ensureBounds() {
        clampCursor()
    }
}
