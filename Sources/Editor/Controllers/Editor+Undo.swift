import Foundation

extension Editor {
    public var undoStack: [UndoSnapshot] {
        get { buffer.undoStack }
        set { buffer.undoStack = newValue }
    }

    public var maxUndoStackSize: Int {
        get { buffer.maxUndoStackSize }
        set { buffer.maxUndoStackSize = newValue }
    }

    /// Saves a snapshot of the active buffer and cursor position to the buffer's undo stack before mutation.
    public func saveUndoSnapshot() {
        lastIsPaste = false
        buffer.saveUndoSnapshot(canvasVisualColumn: isCanvasModeActive ? canvasVisualColumn : nil)
    }

    /// Performs Undo (^Z) on active buffer.
    public func performUndo() {
        guard let snapshot = buffer.performUndo() else {
            setStatusMessage(l10n["status.already_oldest"])
            return
        }
        if isCanvasModeActive {
            if let visualColumn = snapshot.canvasVisualColumn {
                canvasVisualColumn = max(0, visualColumn)
                syncCanvasCursorToBuffer()
            } else {
                syncCanvasCursorFromBuffer()
            }
        }
        setStatusMessage(l10n["status.undo_performed"])
    }
}
