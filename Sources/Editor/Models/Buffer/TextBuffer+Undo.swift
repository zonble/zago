import Foundation

enum ActionAuthor: Equatable, Codable, Sendable {
    case user
    case logoScript(name: String?)
    case aiAgent(id: String, name: String, reason: String)
}

/// Represents an immutable snapshot of buffer text, cursor coordinates, and UI mode states for Undo/Redo operations.
///
/// ### Architecture & Swift Copy-On-Write (COW) Performance
/// 1. **Absolute State Correctness**:
///    In an editor featuring 2D Canvas drawing, multi-line Markdown table reformatting, and LOGO macro
///    transformations, snapshot-based undo guarantees 100% mathematical correctness and avoids the complex
///    character-offset desync issues common to operational transform (OT) or differential patch engines.
///
/// 2. **Swift Copy-On-Write (COW) Optimization**:
///    - `lines: [String]` is a Swift value type backed by reference-counted buffer storage.
///    - Initializing an `UndoSnapshot` with `buffer.lines` is an $O(1)$ pointer reference count increment;
///      it does *not* perform deep string allocations for unchanged text.
///    - Unmodified lines across up to 100 snapshot frames share identical backing string buffers in memory.
///    - Only lines that are mutated trigger copy-on-write allocation for their individual buffers.
///    - Memory consumption per snapshot is primarily limited to the array pointer spine (~8 bytes per line),
///      making snapshot-based undo lightweight and predictable for typical source code, Markdown, and diagram files.
struct UndoSnapshot: Equatable, Codable {
    let lines: [String]
    let lineIndex: Int
    let columnIndex: Int
    let selectionMarkLine: Int?
    let selectionMarkCol: Int?
    let canvasVisualColumn: Int?
    let isModified: Bool
    let isTableModeActive: Bool
    let currentTableCell: TableCell?
    let author: ActionAuthor
    let timestamp: Date

    init(
        lines: [String],
        lineIndex: Int,
        columnIndex: Int,
        selectionMark: (line: Int, column: Int)? = nil,
        canvasVisualColumn: Int? = nil,
        isModified: Bool,
        isTableModeActive: Bool = false,
        currentTableCell: TableCell? = nil,
        author: ActionAuthor = .user,
        timestamp: Date = Date()
    ) {
        self.lines = lines
        self.lineIndex = lineIndex
        self.columnIndex = columnIndex
        self.selectionMarkLine = selectionMark?.line
        self.selectionMarkCol = selectionMark?.column
        self.canvasVisualColumn = canvasVisualColumn
        self.isModified = isModified
        self.isTableModeActive = isTableModeActive
        self.currentTableCell = currentTableCell
        self.author = author
        self.timestamp = timestamp
    }

    var selectionMark: (line: Int, column: Int)? {
        guard let selectionMarkLine, let selectionMarkCol else { return nil }
        return (line: selectionMarkLine, column: selectionMarkCol)
    }

    static func == (lhs: UndoSnapshot, rhs: UndoSnapshot) -> Bool {
        lhs.lines == rhs.lines && lhs.lineIndex == rhs.lineIndex && lhs.columnIndex == rhs.columnIndex
            && lhs.selectionMarkLine == rhs.selectionMarkLine && lhs.selectionMarkCol == rhs.selectionMarkCol
            && lhs.canvasVisualColumn == rhs.canvasVisualColumn && lhs.isModified == rhs.isModified
            && lhs.isTableModeActive == rhs.isTableModeActive && lhs.currentTableCell == rhs.currentTableCell
            && lhs.author == rhs.author
    }
}

extension TextBuffer {
    private func makeUndoSnapshot(
        canvasVisualColumn: Int? = nil,
        author: ActionAuthor = .user
    ) -> UndoSnapshot {
        UndoSnapshot(
            lines: lines,
            lineIndex: lineIndex,
            columnIndex: columnIndex,
            selectionMark: selectionMark,
            canvasVisualColumn: canvasVisualColumn,
            isModified: isModified,
            isTableModeActive: isTableModeActive,
            currentTableCell: currentTableCell,
            author: author
        )
    }

    private func append(_ snapshot: UndoSnapshot, to stack: inout [UndoSnapshot]) {
        guard stack.last != snapshot else { return }
        stack.append(snapshot)
        if stack.count > maxUndoStackSize {
            stack.removeFirst()
        }
    }

    private func restore(_ snapshot: UndoSnapshot) {
        lines = snapshot.lines
        lineIndex = max(0, min(snapshot.lineIndex, lines.count - 1))
        columnIndex = max(0, min(snapshot.columnIndex, lines[lineIndex].count))
        selectionMark = snapshot.selectionMark
        isModified = snapshot.isModified
        isTableModeActive = snapshot.isTableModeActive
        currentTableCell = snapshot.currentTableCell
    }

    /// Saves a snapshot of the buffer state and cursor position before mutation.
    func saveUndoSnapshot(canvasVisualColumn: Int? = nil, author: ActionAuthor = .user) {
        activeSearchMatch = nil
        let snapshot = makeUndoSnapshot(canvasVisualColumn: canvasVisualColumn, author: author)
        if undoStack.last != snapshot {
            append(snapshot, to: &undoStack)
            redoStack.removeAll()
        }
    }

    /// Pops the last snapshot from the undo stack and restores lines, cursor position, selection mark, and isModified state.
    /// Returns the popped snapshot if successful.
    @discardableResult
    func performUndo(canvasVisualColumn: Int? = nil) -> UndoSnapshot? {
        guard let snapshot = undoStack.popLast() else {
            return nil
        }
        let current = makeUndoSnapshot(canvasVisualColumn: canvasVisualColumn, author: snapshot.author)
        append(current, to: &redoStack)
        restore(snapshot)
        return snapshot
    }

    /// Restores the most recently undone snapshot while preserving the current state for undo.
    @discardableResult
    func performRedo(canvasVisualColumn: Int? = nil) -> UndoSnapshot? {
        guard let snapshot = redoStack.popLast() else {
            return nil
        }
        let current = makeUndoSnapshot(canvasVisualColumn: canvasVisualColumn, author: snapshot.author)
        append(current, to: &undoStack)
        restore(snapshot)
        return snapshot
    }
}
