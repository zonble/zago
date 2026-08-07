import Foundation

public struct UndoSnapshot: Equatable {
    public let lines: [String]
    public let lineIndex: Int
    public let columnIndex: Int
    public let selectionMarkLine: Int?
    public let selectionMarkCol: Int?
    public let canvasVisualColumn: Int?
    public let isModified: Bool

    public init(
        lines: [String],
        lineIndex: Int,
        columnIndex: Int,
        selectionMark: (line: Int, column: Int)? = nil,
        canvasVisualColumn: Int? = nil,
        isModified: Bool
    ) {
        self.lines = lines
        self.lineIndex = lineIndex
        self.columnIndex = columnIndex
        self.selectionMarkLine = selectionMark?.line
        self.selectionMarkCol = selectionMark?.column
        self.canvasVisualColumn = canvasVisualColumn
        self.isModified = isModified
    }

    public var selectionMark: (line: Int, column: Int)? {
        guard let selectionMarkLine, let selectionMarkCol else { return nil }
        return (line: selectionMarkLine, column: selectionMarkCol)
    }
}

extension TextBuffer {
    /// Saves a snapshot of the buffer state and cursor position before mutation.
    public func saveUndoSnapshot(canvasVisualColumn: Int? = nil) {
        activeSearchMatch = nil
        let snapshot = UndoSnapshot(
            lines: lines,
            lineIndex: lineIndex,
            columnIndex: columnIndex,
            selectionMark: selectionMark,
            canvasVisualColumn: canvasVisualColumn,
            isModified: isModified
        )
        if undoStack.last != snapshot {
            undoStack.append(snapshot)
            if undoStack.count > maxUndoStackSize {
                undoStack.removeFirst()
            }
        }
    }

    /// Pops the last snapshot from the undo stack and restores lines, cursor position, selection mark, and isModified state.
    /// Returns the popped snapshot if successful.
    @discardableResult
    public func performUndo() -> UndoSnapshot? {
        guard let snapshot = undoStack.popLast() else {
            return nil
        }
        lines = snapshot.lines
        lineIndex = max(0, min(snapshot.lineIndex, lines.count - 1))
        columnIndex = max(0, min(snapshot.columnIndex, lines[lineIndex].count))
        selectionMark = snapshot.selectionMark
        isModified = snapshot.isModified
        return snapshot
    }
}
