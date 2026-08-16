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
    var viewWrapColumn: Int? = nil
    var borderStyle: BorderStyle = .single
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

    func replaceContents(_ text: String, filePath: String? = nil, isModified: Bool = false, defaultLineEnding: LineEnding = .lf) {
        self.lineEnding = LineEnding.detect(in: text, fallback: defaultLineEnding)
        self.hasTrailingNewline = text.hasSuffix("\r\n") || text.hasSuffix("\n") || text.hasSuffix("\r")
        let normalized = text
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
            let sIdx = line.index(line.startIndex, offsetBy: min(start.col, line.count))
            let eIdx = line.index(line.startIndex, offsetBy: min(end.col, line.count))
            return String(line[sIdx..<eIdx])
        }

        let startLineStr = lines[start.line]
        let endLineStr = lines[end.line]
        let sIdx = startLineStr.index(startLineStr.startIndex, offsetBy: min(start.col, startLineStr.count))
        let eIdx = endLineStr.index(endLineStr.startIndex, offsetBy: min(end.col, endLineStr.count))

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
            let sIdx = line.index(line.startIndex, offsetBy: min(start.col, line.count))
            let eIdx = line.index(line.startIndex, offsetBy: min(end.col, line.count))
            let cutText = String(line[sIdx..<eIdx])
            line.removeSubrange(sIdx..<eIdx)
            lines[start.line] = line
            lineIndex = start.line
            columnIndex = min(start.col, line.count)
            isModified = true
            return cutText
        } else {
            let startLineStr = lines[start.line]
            let endLineStr = lines[end.line]

            let sIdx = startLineStr.index(startLineStr.startIndex, offsetBy: min(start.col, startLineStr.count))
            let eIdx = endLineStr.index(endLineStr.startIndex, offsetBy: min(end.col, endLineStr.count))

            let firstLineCut = String(startLineStr[sIdx...])
            let lastLineCut = String(endLineStr[..<eIdx])

            var cutLines: [String] = [firstLineCut]
            if start.line + 1 < end.line {
                cutLines.append(contentsOf: lines[(start.line + 1)..<end.line])
            }
            cutLines.append(lastLineCut)

            let remainingStart = String(startLineStr[..<sIdx])
            let remainingEnd = String(endLineStr[eIdx...])

            lines.replaceSubrange(start.line...end.line, with: [remainingStart + remainingEnd])
            lineIndex = start.line
            columnIndex = min(start.col, remainingStart.count)
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

        var continuationPrefix: String {
            leadingWhitespace + String(repeating: " ", count: itemPrefix.count - leadingWhitespace.count)
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

        return nil
    }

    /// Moves cursor forward by one word (M+F).
    func moveWordForward() {
        ensureBounds()
        let currentLine = lines[lineIndex]
        let lineChars = Array(currentLine)

        if columnIndex >= lineChars.count {
            if lineIndex < lines.count - 1 {
                lineIndex += 1
                columnIndex = 0
            }
            return
        }

        var idx = columnIndex

        enum CharCategory {
            case asciiWord
            case cjkScript
            case nonWord
        }

        func category(at i: Int) -> CharCategory {
            let ch = lineChars[i]
            if TextUnicodeClassifier.isCJKScriptCharacter(ch) {
                return .cjkScript
            } else if TextUnicodeClassifier.isASCIIWordCharacter(ch) {
                return .asciiWord
            } else {
                return .nonWord
            }
        }

        while idx < lineChars.count && category(at: idx) == .nonWord {
            idx += 1
        }

        if idx >= lineChars.count {
            columnIndex = lineChars.count
            return
        }

        let cat = category(at: idx)
        if cat == .cjkScript {
            columnIndex = idx + 1
        } else if cat == .asciiWord {
            while idx < lineChars.count && category(at: idx) == .asciiWord {
                idx += 1
            }
            columnIndex = idx
        }
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
        let lineChars = Array(currentLine)
        var idx = min(columnIndex, lineChars.count)

        enum CharCategory {
            case asciiWord
            case cjkScript
            case nonWord
        }

        func category(at i: Int) -> CharCategory {
            let ch = lineChars[i]
            if TextUnicodeClassifier.isCJKScriptCharacter(ch) {
                return .cjkScript
            } else if TextUnicodeClassifier.isASCIIWordCharacter(ch) {
                return .asciiWord
            } else {
                return .nonWord
            }
        }

        while idx > 0 && category(at: idx - 1) == .nonWord {
            idx -= 1
        }

        if idx == 0 {
            columnIndex = 0
            return
        }

        let cat = category(at: idx - 1)
        if cat == .cjkScript {
            columnIndex = idx - 1
        } else if cat == .asciiWord {
            while idx > 0 && category(at: idx - 1) == .asciiWord {
                idx -= 1
            }
            columnIndex = idx
        }
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

    /// Tokenizes paragraph text into wide characters, Latin words, and spaces.
    private static func tokenizeForReflow(_ text: String) -> [VisualToken] {
        var tokens: [VisualToken] = []
        var currentLatin = ""

        for ch in text {
            if ch.isWhitespace {
                if !currentLatin.isEmpty {
                    tokens.append(.latin(currentLatin))
                    currentLatin = ""
                }
                if tokens.last != .space {
                    tokens.append(.space)
                }
            } else if ch.displayWidth >= 2 {
                if !currentLatin.isEmpty {
                    tokens.append(.latin(currentLatin))
                    currentLatin = ""
                }
                tokens.append(.wide(ch))
            } else {
                currentLatin.append(ch)
            }
        }

        if !currentLatin.isEmpty {
            tokens.append(.latin(currentLatin))
        }

        if tokens.first == .space { tokens.removeFirst() }
        if tokens.last == .space { tokens.removeLast() }

        return tokens
    }

    /// Reflows visual tokens into lines bounded by targetWidth display columns.
    private static func reflowVisualTokens(_ tokens: [VisualToken], targetWidth: Int) -> [String] {
        var resultLines: [String] = []
        var currentLine = ""

        for token in tokens {
            switch token {
            case .wide(let ch):
                let w = ch.displayWidth
                if currentLine.displayWidth + w > targetWidth && !currentLine.isEmpty {
                    resultLines.append(currentLine.trimmingCharacters(in: .whitespaces))
                    currentLine = String(ch)
                } else {
                    currentLine.append(ch)
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

            case .space:
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

        return resultLines.isEmpty ? [""] : resultLines
    }

    /// Joins lines of a paragraph into a single continuous text string, respecting CJK word boundaries.
    private static func joinParagraphLines(_ paragraphLines: [String]) -> String {
        var result = ""
        for line in paragraphLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if result.isEmpty {
                result = trimmed
                continue
            }
            guard let lastChar = result.last, let firstChar = trimmed.first else {
                result += trimmed
                continue
            }
            if lastChar.displayWidth >= 2 && firstChar.displayWidth >= 2 {
                result += trimmed
            } else if lastChar.isWhitespace || firstChar.isWhitespace {
                result += trimmed
            } else {
                result += " " + trimmed
            }
        }
        return result
    }

    /// Justifies (reflows) the paragraph at current cursor position (^J) using visual column display widths.
    func justifyParagraph(targetWidth: Int = 72) {
        guard !lines.isEmpty else { return }
        clampCursor()

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
            let paragraphText = TextBuffer.joinParagraphLines([body] + continuationLines)
            let tokens = TextBuffer.tokenizeForReflow(paragraphText)
            let bodyWidth = max(1, targetWidth - listInfo.continuationPrefix.displayWidth)
            let wrappedBody = TextBuffer.reflowVisualTokens(tokens, targetWidth: bodyWidth)
            let newParagraphLines = wrappedBody.enumerated().map { index, line in
                (index == 0 ? listInfo.itemPrefix : listInfo.continuationPrefix) + line
            }

            lines.replaceSubrange(startLine...endLine, with: newParagraphLines)
            lineIndex = min(startLine, lines.count - 1)
            columnIndex = 0
            isModified = true
            return
        }

        // 2. Extract and reflow a regular paragraph using visual display width.
        let paragraphText = TextBuffer.joinParagraphLines(Array(lines[startLine...endLine]))
        let tokens = TextBuffer.tokenizeForReflow(paragraphText)
        let newParagraphLines = TextBuffer.reflowVisualTokens(tokens, targetWidth: targetWidth)

        // 3. Replace original paragraph lines with reflowed lines.
        lines.replaceSubrange(startLine...endLine, with: newParagraphLines)
        lineIndex = min(startLine, lines.count - 1)
        columnIndex = 0
        isModified = true
    }

    private func ensureBounds() {
        clampCursor()
    }
}
