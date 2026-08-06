import Foundation

extension Editor {
    public struct UndoSnapshot: Equatable {
        public let lines: [String]
        public let lineIndex: Int
        public let columnIndex: Int
        public let canvasVisualColumn: Int?
        public let isModified: Bool

        public init(
            lines: [String],
            lineIndex: Int,
            columnIndex: Int,
            canvasVisualColumn: Int? = nil,
            isModified: Bool
        ) {
            self.lines = lines
            self.lineIndex = lineIndex
            self.columnIndex = columnIndex
            self.canvasVisualColumn = canvasVisualColumn
            self.isModified = isModified
        }
    }

    /// Saves a snapshot of the buffer and cursor position to the undo stack before mutation.
    public func saveUndoSnapshot() {
        activeSearchMatch = nil
        lastIsPaste = false
        let snapshot = UndoSnapshot(
            lines: buffer.lines,
            lineIndex: buffer.lineIndex,
            columnIndex: buffer.columnIndex,
            canvasVisualColumn: isCanvasModeActive ? canvasVisualColumn : nil,
            isModified: buffer.isModified
        )
        if undoStack.last != snapshot {
            undoStack.append(snapshot)
            if undoStack.count > maxUndoStackSize {
                undoStack.removeFirst()
            }
        }
    }

    /// Performs Undo (^Z).
    public func performUndo() {
        guard let snapshot = undoStack.popLast() else {
            setStatusMessage(l10n["status.already_oldest"])
            return
        }
        buffer.lines = snapshot.lines
        buffer.lineIndex = max(0, min(snapshot.lineIndex, buffer.lines.count - 1))
        buffer.columnIndex = max(0, min(snapshot.columnIndex, buffer.lines[buffer.lineIndex].count))
        if isCanvasModeActive {
            if let visualColumn = snapshot.canvasVisualColumn {
                canvasVisualColumn = max(0, visualColumn)
                syncCanvasCursorToBuffer()
            } else {
                syncCanvasCursorFromBuffer()
            }
        }
        buffer.isModified = snapshot.isModified
        setStatusMessage(l10n["status.undo_performed"])
    }
}
