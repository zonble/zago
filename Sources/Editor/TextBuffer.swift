import Foundation
import TextMetrics

/// Manages text buffer lines, file I/O, and cursor operations.
public final class TextBuffer {
    public var lines: [String] = [""]
    public var filePath: String?
    public var isModified: Bool = false

    /// Real buffer cursor position (measured in Character / Grapheme Clusters).
    /// lineIndex: 0-indexed line number
    /// columnIndex: 0-indexed column offset
    public var lineIndex: Int = 0
    public var columnIndex: Int = 0

    public init(filePath: String? = nil) {
        self.filePath = filePath
        if let path = filePath {
            loadFile(at: path)
        }
    }

    /// Loads text from a file path.
    public func loadFile(at path: String) {
        let expandedPath = NSString(string: path).expandingTildeInPath
        if let content = try? String(contentsOfFile: expandedPath, encoding: .utf8) {
            let fileLines = content.components(separatedBy: .newlines)
            self.lines = fileLines.isEmpty ? [""] : fileLines
            self.filePath = expandedPath
            self.isModified = false
            self.lineIndex = 0
            self.columnIndex = 0
        } else {
            // Create an empty buffer if file does not exist yet
            self.lines = [""]
            self.filePath = expandedPath
            self.isModified = false
        }
    }

    /// Reloads buffer content from current file path.
    public func reloadFile() throws {
        guard let path = filePath, !path.isEmpty else {
            throw NSError(
                domain: "TextBuffer", code: 2, userInfo: [NSLocalizedDescriptionKey: "No file path specified"])
        }
        let content = try String(contentsOfFile: path, encoding: .utf8)
        let fileLines = content.components(separatedBy: .newlines)
        self.lines = fileLines.isEmpty ? [""] : fileLines
        self.isModified = false
        clampCursor()
    }

    /// Saves buffer text to file.
    public func saveFile(to path: String? = nil) throws {
        let targetPath = path ?? filePath
        guard let savePath = targetPath, !savePath.isEmpty else {
            throw NSError(
                domain: "TextBuffer", code: 1, userInfo: [NSLocalizedDescriptionKey: "No file path specified"])
        }

        let expandedPath = NSString(string: savePath).expandingTildeInPath
        let content = lines.joined(separator: "\n")
        try content.write(toFile: expandedPath, atomically: true, encoding: .utf8)

        self.filePath = expandedPath
        self.isModified = false
    }

    /// Inserts external file content at current cursor position.
    public func insertFile(at path: String) throws -> Int {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let content = try String(contentsOfFile: expandedPath, encoding: .utf8)
        let insertedLines = content.components(separatedBy: .newlines)
        insertString(content)
        return insertedLines.count
    }

    /// Inserts multi-line or single-line string content at current cursor position.
    public func insertString(_ text: String) {
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
    public func textRange(
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
    public func cutRange(
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
    public func insert(character ch: Character) {
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

    /// Inserts a newline at the current cursor position.
    public func insertNewline() {
        ensureBounds()
        let currentLine = lines[lineIndex]
        let index =
            currentLine.index(currentLine.startIndex, offsetBy: columnIndex, limitedBy: currentLine.endIndex)
            ?? currentLine.endIndex

        let leftPart = String(currentLine[..<index])
        let rightPart = String(currentLine[index...])

        lines[lineIndex] = leftPart
        lines.insert(rightPart, at: lineIndex + 1)

        lineIndex += 1
        columnIndex = 0
        isModified = true
    }

    /// Deletes the character preceding the cursor (Backspace).
    public func backspace() {
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
            let currentLine = lines.remove(at: lineIndex)
            lineIndex -= 1
            let prevLineLength = lines[lineIndex].count
            lines[lineIndex].append(currentLine)
            columnIndex = prevLineLength
            isModified = true
        }
    }

    /// Deletes the current line entirely (Ctrl+Backspace).
    public func deleteLine() {
        ensureBounds()
        if lines.count > 1 {
            lines.remove(at: lineIndex)
            if lineIndex >= lines.count {
                lineIndex = lines.count - 1
            }
            columnIndex = 0
            clampCursor()
        } else {
            lines[0] = ""
            lineIndex = 0
            columnIndex = 0
        }
        isModified = true
    }

    /// Deletes the character at the cursor position (Delete).
    public func delete() {
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
            let nextLine = lines.remove(at: lineIndex + 1)
            lines[lineIndex].append(nextLine)
            isModified = true
        }
    }

    /// Clamps cursor position to valid buffer line and column bounds.
    public func clampCursor() {
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

    /// Justifies (reflows) the paragraph at current cursor position (^J) using visual column display widths.
    public func justifyParagraph(targetWidth: Int = 72) {
        guard !lines.isEmpty else { return }
        clampCursor()

        let currentLine = lines[lineIndex]
        if currentLine.trimmingCharacters(in: .whitespaces).isEmpty {
            return
        }

        // 1. Find paragraph start and end line boundaries (separated by empty lines)
        var startLine = lineIndex
        while startLine > 0 && !lines[startLine - 1].trimmingCharacters(in: .whitespaces).isEmpty {
            startLine -= 1
        }

        var endLine = lineIndex
        while endLine < lines.count - 1 && !lines[endLine + 1].trimmingCharacters(in: .whitespaces).isEmpty {
            endLine += 1
        }

        // 2. Extract paragraph text
        let paragraphText = lines[startLine...endLine]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")

        // 3. Tokenize and reflow using visual display width
        let tokens = TextBuffer.tokenizeForReflow(paragraphText)
        let newParagraphLines = TextBuffer.reflowVisualTokens(tokens, targetWidth: targetWidth)

        // 4. Replace original paragraph lines with reflowed lines
        lines.replaceSubrange(startLine...endLine, with: newParagraphLines)
        lineIndex = min(startLine, lines.count - 1)
        columnIndex = 0
        isModified = true
    }

    private func ensureBounds() {
        clampCursor()
    }
}
