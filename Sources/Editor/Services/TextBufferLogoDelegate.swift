import Diagram
import Drawing
import Foundation
import LogoEngine

/// Pure buffer-level LogoEngineDelegate implementation operating directly on a TextBuffer.
final class TextBufferLogoDelegate: LogoEngineDelegate, @unchecked Sendable {
    var buffer: TextBuffer
    var defaultBorderStyle: BorderStyle
    var defaultArrowStyle: ArrowStyle
    var tabSize: Int
    var hooks: LogoUIHooks

    init(
        buffer: TextBuffer,
        defaultBorderStyle: BorderStyle = .single,
        defaultArrowStyle: ArrowStyle = .solid,
        tabSize: Int = 4,
        hooks: LogoUIHooks = .empty
    ) {
        self.buffer = buffer
        self.defaultBorderStyle = defaultBorderStyle
        self.defaultArrowStyle = defaultArrowStyle
        self.tabSize = tabSize
        self.hooks = hooks
    }

    public func logoEngine(_ engine: LogoEngine, performAction action: LogoEditorAction) {
        switch action {
        case .saveUndoSnapshot:
            hooks.onSaveUndoSnapshot?()

        case .clampCursor:
            buffer.clampCursor()

        case .insertText(let text):
            buffer.insertString(text)
            hooks.onAppendOutput?(text)

        case .insertNewline:
            buffer.insertNewline()

        case .setStatusMessage(let msg):
            hooks.onSetStatusMessage?(msg)
            hooks.onAppendOutput?(msg)

        case .deleteChar:
            buffer.delete()

        case .backspaceChar:
            buffer.backspace()

        case .deleteLine:
            deleteCurrentLine()

        case .joinLine(let separator):
            joinCurrentLine(separator: separator)

        case .replaceText(let old, let new):
            replaceText(old: old, new: new)

        case .indentLines(let levels):
            indentSelectedOrCurrentLines(levels: levels)

        case .outdentLines(let levels):
            outdentSelectedOrCurrentLines(levels: levels)

        case .createTable(let rows, let cols, let cellWidth, let borderStyle, let rounded):
            createTable(rows: rows, cols: cols, cellWidth: cellWidth, borderStyle: borderStyle, rounded: rounded)

        case .setBorderStyle(let style):
            if let s = BorderStyle(style) {
                defaultBorderStyle = s
            }

        case .setArrowStyle(let style):
            if let a = ArrowStyle(style) {
                defaultArrowStyle = a
            }

        case .nextBorderStyle:
            hooks.onDispatchCommand?(action)

        case .moveCursorVirtual(let delta):
            moveCursorVirtual(deltaRow: delta)

        case .moveLeft, .moveRight, .moveHome, .moveEnd,
            .editMark, .editCut, .editUncut, .editJustify:
            hooks.onDispatchCommand?(action)

        case .markModified:
            buffer.isModified = true

        case .updateLineIndex(let lineIndex):
            while buffer.lines.count <= lineIndex {
                buffer.lines.append("")
            }
            buffer.lineIndex = max(0, lineIndex)

        case .updateColumnIndex(let columnIndex):
            let lineStr =
                (buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count)
                ? buffer.lines[buffer.lineIndex] : ""
            let maxDisplayWidth = lineStr.displayWidth
            if columnIndex <= maxDisplayWidth {
                buffer.columnIndex = lineStr.characterOffset(forVisualColumn: max(0, columnIndex))
            } else {
                buffer.columnIndex = lineStr.count + (columnIndex - maxDisplayWidth)
            }

        case .setLine(let index, let text):
            if index >= 0 && index < buffer.lines.count {
                buffer.lines[index] = text
            }

        case .ensureLineExists(let index):
            while buffer.lines.count <= index {
                buffer.lines.append("")
            }

        case .refreshScreen:
            hooks.onRefreshScreen?()

        case .fillCanvasBlock(let text):
            _ = hooks.onFillCanvasBlock?(text)

        case .fillTableCell:
            break

        case .gotoLine(let row):
            goToLocation(line: row + 1, column: nil)

        case .gotoCol(let col):
            goToLocation(line: buffer.lineIndex + 1, column: col + 1)

        case .clearBuffer:
            buffer.lines = [""]
            buffer.lineIndex = 0
            buffer.columnIndex = 0
            buffer.isModified = true
        }
    }

    public func logoEngine(_ engine: LogoEngine, queryState query: LogoEditorQuery) -> LogoEditorQueryResult? {
        if let extra = hooks.onQueryExtra?(query) {
            return extra
        }

        switch query {
        case .currentLineIndex:
            return .integer(buffer.lineIndex)

        case .currentColumnIndex:
            let lineStr =
                (buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count)
                ? buffer.lines[buffer.lineIndex] : ""
            let charCount = lineStr.count
            if buffer.columnIndex <= charCount {
                return .integer(lineStr.visualColumn(forCharacterOffset: buffer.columnIndex))
            } else {
                return .integer(lineStr.displayWidth + (buffer.columnIndex - charCount))
            }

        case .lineCount:
            return .integer(buffer.lines.count)

        case .lineAt(let index):
            guard index >= 0 && index < buffer.lines.count else { return .string("") }
            return .string(buffer.lines[index])

        case .defaultBorderStyle:
            return .borderStyle(defaultBorderStyle)

        case .defaultArrowStyle:
            return .arrowStyle(defaultArrowStyle)

        case .defaultBorderRounded:
            return .bool(buffer.isBorderRounded)

        case .hasCanvasBlockMark, .canvasBlockFrame, .hasTableCell:
            return nil

        case .bufferList:
            return .strings([buffer.filePath ?? "Untitled"])

        case .currentBufferIndex:
            return .integer(0)

        case .bufferText:
            return .string(buffer.lines.joined(separator: "\n"))

        case .selectionText:
            if let mark = buffer.selectionMark {
                let (start, end) = TextBuffer.getOrderedRange(
                    mark1: mark, mark2: (line: buffer.lineIndex, column: buffer.columnIndex))
                let lines = buffer.lines
                if start.line == end.line && start.line < lines.count {
                    let line = lines[start.line]
                    let sCol = max(0, min(start.column, line.count))
                    let eCol = max(sCol, min(end.column, line.count))
                    return .string(
                        String(
                            line[
                                line.index(
                                    line.startIndex, offsetBy: sCol)..<line.index(line.startIndex, offsetBy: eCol)]
                        ))
                } else if start.line < lines.count && end.line < lines.count {
                    return .string(lines[start.line...end.line].joined(separator: "\n"))
                }
            }
            return .string("")

        case .isModified:
            return .bool(buffer.isModified)

        case .fileName:
            return .string(buffer.filePath ?? "Untitled")
        }
    }

    public func logoEngine(_ engine: LogoEngine, readWordWithPrompt prompt: String) -> String? {
        hooks.onReadWord?(prompt)
    }

    public func logoEngine(_ engine: LogoEngine, readCharWithPrompt prompt: String) -> String? {
        hooks.onReadChar?(prompt)
    }

    // MARK: - Private Buffer Manipulation Helpers

    private func deleteCurrentLine() {
        guard buffer.lines.count > 1 else {
            buffer.lines = [""]
            buffer.lineIndex = 0
            buffer.columnIndex = 0
            buffer.isModified = true
            return
        }
        buffer.lines.remove(at: buffer.lineIndex)
        if buffer.lineIndex >= buffer.lines.count {
            buffer.lineIndex = buffer.lines.count - 1
        }
        buffer.columnIndex = min(buffer.columnIndex, buffer.lines[buffer.lineIndex].count)
        buffer.isModified = true
    }

    private func joinCurrentLine(separator: String) {
        guard buffer.lineIndex + 1 < buffer.lines.count else { return }
        let currentLine = buffer.lines[buffer.lineIndex]
        let nextLine = buffer.lines.remove(at: buffer.lineIndex + 1)
        buffer.lines[buffer.lineIndex] = currentLine + separator + nextLine
        buffer.columnIndex = currentLine.count + separator.count
        buffer.isModified = true
    }

    private func replaceText(old: String, new: String) {
        let cleanOld = old.hasPrefix("\"") ? String(old.dropFirst()) : old
        let cleanNew = new.hasPrefix("\"") ? String(new.dropFirst()) : new
        guard !cleanOld.isEmpty else { return }
        var didReplace = false
        let range = selectedOrCurrentLineRange()
        for lineIndex in range {
            let replaced = buffer.lines[lineIndex].replacingOccurrences(of: cleanOld, with: cleanNew)
            if replaced != buffer.lines[lineIndex] {
                buffer.lines[lineIndex] = replaced
                didReplace = true
            }
        }
        if didReplace {
            buffer.isModified = true
            buffer.selectionMark = nil
        }
    }

    private func selectedOrCurrentLineRange() -> ClosedRange<Int> {
        if let mark = buffer.selectionMark {
            let (start, end) = TextBuffer.getOrderedRange(
                mark1: mark, mark2: (line: buffer.lineIndex, column: buffer.columnIndex))
            let startLine = max(0, min(start.line, buffer.lines.count - 1))
            let endLine = max(0, min(end.line, buffer.lines.count - 1))
            return startLine...endLine
        }
        let line = max(0, min(buffer.lineIndex, buffer.lines.count - 1))
        return line...line
    }

    private func indentSelectedOrCurrentLines(levels: Int) {
        let count = max(1, levels)
        let prefix = String(repeating: " ", count: max(1, tabSize) * count)
        for lineIndex in selectedOrCurrentLineRange() {
            buffer.lines[lineIndex] = prefix + buffer.lines[lineIndex]
        }
        buffer.columnIndex += prefix.count
        buffer.isModified = true
    }

    private func outdentSelectedOrCurrentLines(levels: Int) {
        let targetCount = max(1, tabSize) * max(1, levels)
        for lineIndex in selectedOrCurrentLineRange() {
            var line = buffer.lines[lineIndex]
            var removed = 0
            while removed < targetCount, line.first == " " {
                line.removeFirst()
                removed += 1
            }
            buffer.lines[lineIndex] = line
            if lineIndex == buffer.lineIndex {
                buffer.columnIndex = max(0, buffer.columnIndex - removed)
            }
        }
        buffer.isModified = true
    }

    private func moveCursorVirtual(deltaRow: Int) {
        let targetLine = max(0, min(buffer.lines.count - 1, buffer.lineIndex + deltaRow))
        buffer.lineIndex = targetLine
        buffer.clampCursor()
    }

    private func goToLocation(line: Int, column: Int?) {
        let targetLine = max(0, min(buffer.lines.count - 1, line - 1))
        buffer.lineIndex = targetLine
        if let col = column {
            let lineStr = buffer.lines[targetLine]
            buffer.columnIndex = max(0, min(lineStr.count, col - 1))
        } else {
            buffer.columnIndex = 0
        }
        buffer.clampCursor()
    }

    private func createTable(
        rows: Int,
        cols: Int,
        cellWidth requestedCellWidth: Int?,
        borderStyle: BorderStyle? = nil,
        rounded: Bool? = nil
    ) {
        let rowCount = max(TableLimits.minRows, min(rows, TableLimits.maxRows))
        let colCount = max(TableLimits.minCols, min(cols, TableLimits.maxCols))
        let cellWidth = max(
            TableLimits.minCellWidth,
            min(requestedCellWidth ?? TableLimits.defaultCellWidth, TableLimits.maxCellWidth)
        )

        let style = borderStyle ?? defaultBorderStyle
        let isRound = rounded ?? buffer.isBorderRounded
        let chars = style.tableCharacters(rounded: isRound)
        let h = String(repeating: chars.horizontal, count: cellWidth)
        let content = String(repeating: " ", count: cellWidth)
        var tableLines: [String] = []
        tableLines.append(
            chars.topLeft + Array(repeating: h, count: colCount).joined(separator: chars.topJoin) + chars.topRight)
        for row in 0..<rowCount {
            tableLines.append(
                chars.vertical + Array(repeating: content, count: colCount).joined(separator: chars.vertical)
                    + chars.vertical)
            if row < rowCount - 1 {
                tableLines.append(
                    chars.midLeft + Array(repeating: h, count: colCount).joined(separator: chars.midJoin)
                        + chars.midRight)
            }
        }
        tableLines.append(
            chars.bottomLeft + Array(repeating: h, count: colCount).joined(separator: chars.bottomJoin)
                + chars.bottomRight)

        let insertIdx = buffer.lineIndex
        for (i, line) in tableLines.enumerated() {
            if insertIdx + i < buffer.lines.count {
                buffer.lines.insert(line, at: insertIdx + i)
            } else {
                buffer.lines.append(line)
            }
        }
        buffer.isModified = true
    }
}
