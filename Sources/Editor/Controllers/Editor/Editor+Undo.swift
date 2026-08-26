import Foundation

extension Editor {
    var undoStack: [UndoSnapshot] {
        get { buffer.undoStack }
        set { buffer.undoStack = newValue }
    }

    var maxUndoStackSize: Int {
        get { buffer.maxUndoStackSize }
        set { buffer.maxUndoStackSize = newValue }
    }

    /// Saves a snapshot of the active buffer and cursor position to the buffer's undo stack before mutation.
    func saveUndoSnapshot() {
        lastIsPaste = false
        buffer.saveUndoSnapshot(canvasVisualColumn: isCanvasModeActive ? canvasVisualColumn : nil)
    }

    /// Performs Undo (^Z) on active buffer.
    func performUndo() {
        guard
            let snapshot = buffer.performUndo(
                canvasVisualColumn: isCanvasModeActive ? canvasVisualColumn : nil
            )
        else {
            reportOperationResult(.noOp(message: l10n["status.already_oldest"]))
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
        updateGitDiff()
        reportOperationResult(.succeeded(message: l10n["status.undo_performed"]))
    }

    /// Performs Redo (Ctrl+Shift+Z) on active buffer.
    func performRedo() {
        guard
            let snapshot = buffer.performRedo(
                canvasVisualColumn: isCanvasModeActive ? canvasVisualColumn : nil
            )
        else {
            reportOperationResult(.noOp(message: l10n["status.already_newest"]))
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
        updateGitDiff()
        reportOperationResult(.succeeded(message: l10n["status.redo_performed"]))
    }
}
