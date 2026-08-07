import Foundation
import LogoEngine
import TextMetrics

enum CanvasDrawDirection {
    case up
    case down
    case left
    case right

    var delta: (line: Int, column: Int) {
        switch self {
        case .up: return (-1, 0)
        case .down: return (1, 0)
        case .left: return (0, -1)
        case .right: return (0, 1)
        }
    }

    var mask: UInt8 {
        switch self {
        case .up: return 1
        case .right: return 2
        case .down: return 4
        case .left: return 8
        }
    }

    var opposite: CanvasDrawDirection {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }
}

// MARK: - Pure Canvas Mask Utility Functions

func canvasMask(for character: Character?, style _: BorderStyle = .single) -> UInt8 {
    guard let character else { return 0 }
    switch character {
    case "─", "═", "-": return CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask
    case "│", "║", "|": return CanvasDrawDirection.up.mask | CanvasDrawDirection.down.mask
    case "┌", "╔", "╭": return CanvasDrawDirection.right.mask | CanvasDrawDirection.down.mask
    case "┐", "╗", "╮": return CanvasDrawDirection.left.mask | CanvasDrawDirection.down.mask
    case "└", "╚", "╰": return CanvasDrawDirection.up.mask | CanvasDrawDirection.right.mask
    case "┘", "╝", "╯": return CanvasDrawDirection.up.mask | CanvasDrawDirection.left.mask
    case "├", "╠":
        return CanvasDrawDirection.up.mask | CanvasDrawDirection.right.mask | CanvasDrawDirection.down.mask
    case "┤", "╣":
        return CanvasDrawDirection.up.mask | CanvasDrawDirection.down.mask | CanvasDrawDirection.left.mask
    case "┬", "╦":
        return CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask | CanvasDrawDirection.down.mask
    case "┴", "╩":
        return CanvasDrawDirection.up.mask | CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask
    case "┼", "╬", "+": return 15
    case "→", ">": return CanvasDrawDirection.left.mask
    case "←", "<": return CanvasDrawDirection.right.mask
    case "↑", "^": return CanvasDrawDirection.down.mask
    case "↓", "v": return CanvasDrawDirection.up.mask
    default: return 0
    }
}

func lineCharacter(forMask mask: UInt8, style: BorderStyle) -> Character {
    let normalizedMask = mask == 0 ? CanvasDrawDirection.right.mask : mask
    let chars = style.tableCharacters

    if style == .ascii {
        switch normalizedMask {
        case CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask,
            CanvasDrawDirection.left.mask,
            CanvasDrawDirection.right.mask:
            return Character(chars.horizontal)
        case CanvasDrawDirection.up.mask | CanvasDrawDirection.down.mask,
            CanvasDrawDirection.up.mask,
            CanvasDrawDirection.down.mask:
            return Character(chars.vertical)
        default:
            return "+"
        }
    }

    switch normalizedMask {
    case CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask,
        CanvasDrawDirection.left.mask,
        CanvasDrawDirection.right.mask:
        return Character(chars.horizontal)
    case CanvasDrawDirection.up.mask | CanvasDrawDirection.down.mask,
        CanvasDrawDirection.up.mask,
        CanvasDrawDirection.down.mask:
        return Character(chars.vertical)
    case CanvasDrawDirection.right.mask | CanvasDrawDirection.down.mask:
        return Character(chars.topLeft)
    case CanvasDrawDirection.left.mask | CanvasDrawDirection.down.mask:
        return Character(chars.topRight)
    case CanvasDrawDirection.up.mask | CanvasDrawDirection.right.mask:
        return Character(chars.bottomLeft)
    case CanvasDrawDirection.up.mask | CanvasDrawDirection.left.mask:
        return Character(chars.bottomRight)
    case CanvasDrawDirection.up.mask | CanvasDrawDirection.right.mask | CanvasDrawDirection.down.mask:
        return Character(chars.midLeft)
    case CanvasDrawDirection.up.mask | CanvasDrawDirection.down.mask | CanvasDrawDirection.left.mask:
        return Character(chars.midRight)
    case CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask | CanvasDrawDirection.down.mask:
        return Character(chars.topJoin)
    case CanvasDrawDirection.up.mask | CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask:
        return Character(chars.bottomJoin)
    default:
        return Character(chars.midJoin)
    }
}

func arrowHead(for direction: CanvasDrawDirection, style: BorderStyle) -> Character {
    if style == .ascii {
        switch direction {
        case .up: return "^"
        case .down: return "v"
        case .left: return "<"
        case .right: return ">"
        }
    }

    switch direction {
    case .up: return "↑"
    case .down: return "↓"
    case .left: return "←"
    case .right: return "→"
    }
}

func isCanvasDrawableCharacter(_ character: Character?, style: BorderStyle) -> Bool {
    guard let character else { return true }
    return character == " " || character == "\t" || canvasMask(for: character, style: style) != 0
}

func oppositeMask(for direction: CanvasDrawDirection) -> UInt8 {
    switch direction {
    case .up: return CanvasDrawDirection.down.mask
    case .down: return CanvasDrawDirection.up.mask
    case .left: return CanvasDrawDirection.right.mask
    case .right: return CanvasDrawDirection.left.mask
    }
}

// MARK: - CanvasModeController

/// Controller handling Canvas Mode drawing keys, box drawing, and visual column navigation.
public final class CanvasModeController: KeyInputHandler {
    public weak var editor: Editor?

    public init(editor: Editor? = nil) {
        self.editor = editor
    }

    /// KeyInputHandler protocol implementation.
    public func handleKey(_ key: Key) -> Bool {
        guard let editor, editor.isCanvasModeActive && !editor.isTableModeActive else { return false }

        let direction: CanvasDrawDirection
        let drawsArrow: Bool
        switch key {
        case .pageUp:
            editor.saveUndoSnapshot()
            editor.clearActiveMark()
            let pageStep = max(1, editor.terminal.getWindowSize().rows - (editor.displayConfig.showRuler ? 5 : 4))
            let originalCanvasColumn = editor.canvasVisualColumn
            editor.buffer.lineIndex = max(0, editor.buffer.lineIndex - pageStep)
            editor.canvasVisualColumn = originalCanvasColumn
            editor.syncCanvasCursorToBuffer()
            return true
        case .pageDown:
            editor.saveUndoSnapshot()
            editor.clearActiveMark()
            let pageStep = max(1, editor.terminal.getWindowSize().rows - (editor.displayConfig.showRuler ? 5 : 4))
            let targetLine = min(editor.buffer.lines.count - 1, editor.buffer.lineIndex + pageStep)
            let originalCanvasColumn = editor.canvasVisualColumn
            editor.buffer.lineIndex = max(0, targetLine)
            editor.canvasVisualColumn = originalCanvasColumn
            editor.syncCanvasCursorToBuffer()
            return true
        case .shiftArrowLeft:
            direction = .left
            drawsArrow = false
        case .shiftArrowRight:
            direction = .right
            drawsArrow = false
        case .shiftArrowUp:
            direction = .up
            drawsArrow = false
        case .shiftArrowDown:
            direction = .down
            drawsArrow = false
        case .ctrlShiftArrowLeft:
            direction = .left
            drawsArrow = true
        case .ctrlShiftArrowRight:
            direction = .right
            drawsArrow = true
        case .ctrlShiftArrowUp:
            direction = .up
            drawsArrow = true
        case .ctrlShiftArrowDown:
            direction = .down
            drawsArrow = true
        default:
            return false
        }

        editor.saveUndoSnapshot()
        editor.clearActiveMark()
        drawCanvasStep(direction: direction, drawsArrow: drawsArrow)
        return true
    }

    /// Performs one step of canvas drawing in the specified direction.
    func drawCanvasStep(direction: CanvasDrawDirection, drawsArrow: Bool) {
        guard let editor else { return }
        guard editor.ensureCanvasLineExists(editor.buffer.lineIndex) else { return }

        let delta = direction.delta
        let targetLine = editor.buffer.lineIndex + delta.line
        let targetColumn = editor.canvasVisualColumn + delta.column
        guard targetLine >= 0, targetColumn >= 0 else { return }
        guard editor.isCanvasLineAllowed(targetLine) else {
            editor.setStatusMessage(editor.l10n["status.canvas_row_limit_exceeded"])
            return
        }
        guard editor.isCanvasColumnAllowed(editor.canvasVisualColumn), editor.isCanvasColumnAllowed(targetColumn) else {
            editor.setStatusMessage(editor.l10n["status.canvas_column_limit_exceeded"])
            return
        }

        let currentLine = editor.buffer.lineIndex
        let currentColumn = editor.canvasVisualColumn
        let style = editor.defaultBorderStyle

        editor.writeCanvasLineSegment(
            lineIndex: currentLine,
            visualColumn: currentColumn,
            direction: direction,
            style: style)

        if editor.ensureCanvasLineExists(targetLine) {
            let targetChar = editor.canvasCharacter(atLine: targetLine, visualColumn: targetColumn)
            if let targetChar, canvasMask(for: targetChar, style: style) != 0 {
                editor.writeCanvasLineSegment(
                    lineIndex: targetLine,
                    visualColumn: targetColumn,
                    direction: direction.opposite,
                    style: style)
            }
        }

        if drawsArrow {
            guard editor.ensureCanvasLineExists(targetLine) else { return }
            editor.writeCanvasCharacterIfDrawable(
                arrowHead(for: direction, style: style),
                lineIndex: targetLine,
                visualColumn: targetColumn,
                style: style)
        }

        editor.buffer.lineIndex = targetLine
        editor.canvasVisualColumn = targetColumn
        editor.syncCanvasCursorToBuffer()
        editor.buffer.isModified = true
    }
}

// MARK: - Editor Canvas Domain Extensions

extension Editor {
    public struct CanvasBlockClipboard: Sendable, Equatable {
        public let width: Int
        public let rows: [String]

        public init(width: Int, rows: [String]) {
            self.width = width
            self.rows = rows
        }
    }

    struct CanvasBlockRectangle: Sendable, Equatable {
        let topLine: Int
        let bottomLine: Int
        let leftColumn: Int
        let rightColumnExclusive: Int

        var width: Int {
            max(0, rightColumnExclusive - leftColumn)
        }
    }

    func syncCanvasCursorFromBuffer() {
        guard buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count else {
            canvasVisualColumn = 0
            return
        }
        let visualColumn = buffer.lines[buffer.lineIndex].visualColumn(forCharacterOffset: buffer.columnIndex)
        if visualColumn >= EditorLimits.maxCanvasAutoExtendColumns {
            canvasVisualColumn = EditorLimits.maxCanvasAutoExtendColumns - 1
            setStatusMessage(l10n["status.canvas_column_limit_exceeded"])
        } else {
            canvasVisualColumn = visualColumn
        }
    }

    func syncCanvasCursorToBuffer() {
        guard ensureCanvasLineExists(buffer.lineIndex),
            canvasVisualColumn < EditorLimits.maxCanvasAutoExtendColumns
        else {
            return
        }
        let line = buffer.lines[buffer.lineIndex]
        buffer.columnIndex = line.characterOffset(forVisualColumn: canvasVisualColumn)
    }

    func moveCanvasCursor(deltaLine: Int, deltaColumn: Int, extendDownward: Bool = true) {
        let targetLine = buffer.lineIndex + deltaLine
        let targetColumn = canvasVisualColumn + deltaColumn
        guard targetLine >= 0, targetColumn >= 0 else { return }
        guard isCanvasLineAllowed(targetLine) else {
            setStatusMessage(l10n["status.canvas_row_limit_exceeded"])
            return
        }
        guard isCanvasColumnAllowed(targetColumn) else {
            setStatusMessage(l10n["status.canvas_column_limit_exceeded"])
            return
        }
        if extendDownward && deltaLine > 0 {
            guard ensureCanvasLineExists(targetLine) else { return }
        }
        buffer.lineIndex = max(0, min(targetLine, buffer.lines.count - 1))
        canvasVisualColumn = targetColumn
        syncCanvasCursorToBuffer()
    }

    func moveCanvasCursorToLineStart() {
        canvasVisualColumn = 0
        syncCanvasCursorToBuffer()
    }

    func moveCanvasCursorToLineEnd() {
        guard ensureCanvasLineExists(buffer.lineIndex) else { return }
        let lineEnd = buffer.lines[buffer.lineIndex].displayWidth
        if lineEnd >= EditorLimits.maxCanvasAutoExtendColumns {
            canvasVisualColumn = EditorLimits.maxCanvasAutoExtendColumns - 1
            setStatusMessage(l10n["status.canvas_column_limit_exceeded"])
        } else {
            canvasVisualColumn = lineEnd
        }
        syncCanvasCursorToBuffer()
    }

    func insertCanvasCharacter(_ ch: Character) {
        guard ensureCanvasLineExists(buffer.lineIndex),
            isCanvasColumnAllowed(canvasVisualColumn)
        else {
            if !isCanvasColumnAllowed(canvasVisualColumn) {
                setStatusMessage(l10n["status.canvas_column_limit_exceeded"])
            }
            return
        }
        let result = buffer.lines[buffer.lineIndex].writingAtVisualColumn(canvasVisualColumn, character: ch)
        buffer.lines[buffer.lineIndex] = result.text
        canvasVisualColumn = result.visualColumnAfterWrite
        buffer.columnIndex = result.characterOffsetAfterWrite
        buffer.isModified = true
    }

    func insertCanvasString(_ text: String) {
        let startColumn = canvasVisualColumn
        let lines = text.components(separatedBy: .newlines)
        guard !lines.isEmpty else { return }

        for (lineOffset, segment) in lines.enumerated() {
            if lineOffset > 0 {
                buffer.lineIndex += 1
                guard ensureCanvasLineExists(buffer.lineIndex) else { return }
                canvasVisualColumn = startColumn
            }

            for ch in segment {
                insertCanvasCharacter(ch)
            }
        }
    }

    func insertCanvasNewline() {
        let insertIndex = min(buffer.lineIndex + 1, buffer.lines.count)
        guard isCanvasLineAllowed(insertIndex) else {
            setStatusMessage(l10n["status.canvas_row_limit_exceeded"])
            return
        }
        buffer.lines.insert("", at: insertIndex)
        buffer.lineIndex = insertIndex
        canvasVisualColumn = 0
        buffer.isModified = true
        syncCanvasCursorToBuffer()
    }

    func deleteCanvasCharacter() {
        guard ensureCanvasLineExists(buffer.lineIndex) else { return }
        let result = buffer.lines[buffer.lineIndex].clearingAtVisualColumn(canvasVisualColumn)
        buffer.lines[buffer.lineIndex] = result.text
        buffer.columnIndex = result.characterOffsetAfterWrite
        buffer.isModified = true
        syncCanvasCursorToBuffer()
    }

    func backspaceCanvasCharacter() {
        guard canvasVisualColumn > 0 else {
            buffer.deleteLine()
            canvasVisualColumn = 0
            syncCanvasCursorToBuffer()
            return
        }
        guard ensureCanvasLineExists(buffer.lineIndex) else { return }
        let line = buffer.lines[buffer.lineIndex]
        let targetColumn: Int
        if canvasVisualColumn > line.displayWidth {
            targetColumn = canvasVisualColumn - 1
        } else {
            targetColumn = line.snappedVisualColumn(canvasVisualColumn - 1, direction: .backward)
        }

        canvasVisualColumn = max(0, targetColumn)
        let result = buffer.lines[buffer.lineIndex].clearingAtVisualColumn(canvasVisualColumn)
        buffer.lines[buffer.lineIndex] = result.text
        buffer.isModified = true
        syncCanvasCursorToBuffer()
    }

    func ensureCanvasViewport(textWidth: Int) {
        let width = max(1, textWidth)
        if canvasVisualColumn < canvasHorizontalOffset {
            canvasHorizontalOffset = (canvasVisualColumn / width) * width
        } else if canvasVisualColumn >= canvasHorizontalOffset + width {
            canvasHorizontalOffset = (canvasVisualColumn / width) * width
        }
    }

    @discardableResult
    func ensureCanvasLineExists(_ lineIndex: Int) -> Bool {
        guard lineIndex >= 0 else { return false }
        guard isCanvasLineAllowed(lineIndex) else {
            setStatusMessage(l10n["status.canvas_row_limit_exceeded"])
            return false
        }
        var appended = false
        while buffer.lines.count <= lineIndex {
            buffer.lines.append("")
            appended = true
        }
        if appended {
            buffer.isModified = true
        }
        return true
    }

    func isCanvasLineAllowed(_ lineIndex: Int) -> Bool {
        lineIndex >= 0 && lineIndex < EditorLimits.maxCanvasAutoExtendRows
    }

    func isCanvasColumnAllowed(_ visualColumn: Int) -> Bool {
        visualColumn >= 0 && visualColumn < EditorLimits.maxCanvasAutoExtendColumns
    }

    func isCanvasRangeAllowed(topLine: Int, bottomLine: Int, leftColumn: Int, rightColumnExclusive: Int) -> Bool {
        guard isCanvasLineAllowed(topLine), isCanvasLineAllowed(bottomLine) else {
            setStatusMessage(l10n["status.canvas_row_limit_exceeded"])
            return false
        }
        guard leftColumn >= 0, rightColumnExclusive <= EditorLimits.maxCanvasAutoExtendColumns else {
            setStatusMessage(l10n["status.canvas_column_limit_exceeded"])
            return false
        }
        return true
    }

    func currentCanvasBlockRectangle() -> CanvasBlockRectangle? {
        guard let mark = buffer.canvasBlockMark else { return nil }
        let end = buffer.canvasBlockMarkEnd ?? mark
        let top = min(mark.line, end.line)
        let bottom = max(mark.line, end.line)
        let rawLeft = min(mark.visualColumn, end.visualColumn)
        let rawRightInclusive = max(mark.visualColumn, end.visualColumn)
        var left = rawLeft
        var rightExclusive = rawRightInclusive + 1

        for lineIndex in top...bottom {
            guard lineIndex >= 0 && lineIndex < buffer.lines.count else { continue }
            let line = buffer.lines[lineIndex]
            let lineWidth = line.displayWidth
            if rawLeft <= lineWidth {
                left = min(left, line.snappedVisualColumn(rawLeft, direction: .backward))
            }
            if rawRightInclusive + 1 <= lineWidth {
                rightExclusive = max(
                    rightExclusive, line.snappedVisualColumn(rawRightInclusive + 1, direction: .forward))
            }
        }

        return CanvasBlockRectangle(
            topLine: max(0, top),
            bottomLine: max(0, bottom),
            leftColumn: max(0, left),
            rightColumnExclusive: max(left, rightExclusive))
    }

    func isCanvasCellSelected(line: Int, visualColumn: Int) -> Bool {
        guard let rect = currentCanvasBlockRectangle() else { return false }
        return line >= rect.topLine && line <= rect.bottomLine
            && visualColumn >= rect.leftColumn && visualColumn < rect.rightColumnExclusive
    }

    @discardableResult
    func copyCanvasBlock() -> Bool {
        guard let rect = currentCanvasBlockRectangle(), rect.width > 0 else {
            setStatusMessage(l10n["status.no_block_marked"])
            return false
        }

        var rows: [String] = []
        for lineIndex in rect.topLine...rect.bottomLine {
            let line = lineIndex < buffer.lines.count ? buffer.lines[lineIndex] : ""
            rows.append(line.visualSlice(startVisualColumn: rect.leftColumn, width: rect.width).text)
        }

        canvasBlockClipboard = CanvasBlockClipboard(width: rect.width, rows: rows)
        setStatusMessage(l10n["status.copied_block"])
        return true
    }

    func cutCanvasBlock() {
        guard let rect = currentCanvasBlockRectangle(), rect.width > 0 else {
            setStatusMessage(l10n["status.no_block_marked"])
            return
        }
        guard
            isCanvasRangeAllowed(
                topLine: rect.topLine,
                bottomLine: rect.bottomLine,
                leftColumn: rect.leftColumn,
                rightColumnExclusive: rect.rightColumnExclusive
            )
        else { return }

        var rows: [String] = []
        for lineIndex in rect.topLine...rect.bottomLine {
            guard ensureCanvasLineExists(lineIndex) else { return }
            let line = buffer.lines[lineIndex]
            rows.append(line.visualSlice(startVisualColumn: rect.leftColumn, width: rect.width).text)
            buffer.lines[lineIndex] = line.removingVisualColumns(start: rect.leftColumn, width: rect.width)
                .trimmingTrailingSpaces()
        }

        canvasBlockClipboard = CanvasBlockClipboard(width: rect.width, rows: rows)
        buffer.lineIndex = rect.topLine
        canvasVisualColumn = rect.leftColumn
        syncCanvasCursorToBuffer()
        clearActiveMark()
        buffer.isModified = true
        setStatusMessage(l10n["status.cut_text"])
    }

    func pasteCanvasBlock() {
        guard let clipboard = canvasBlockClipboard, clipboard.width > 0, !clipboard.rows.isEmpty else {
            setStatusMessage(l10n["status.clipboard_empty"])
            return
        }

        let startLine = buffer.lineIndex
        let startColumn = canvasVisualColumn
        let endLine = startLine + clipboard.rows.count - 1
        let endColumn = startColumn + clipboard.width
        guard
            isCanvasRangeAllowed(
                topLine: startLine,
                bottomLine: endLine,
                leftColumn: startColumn,
                rightColumnExclusive: endColumn
            )
        else { return }

        saveUndoSnapshot()
        for (rowOffset, rowText) in clipboard.rows.enumerated() {
            let targetLine = startLine + rowOffset
            guard ensureCanvasLineExists(targetLine) else { return }
            buffer.lines[targetLine] = buffer.lines[targetLine].insertingAtVisualColumn(startColumn, text: rowText)
        }

        buffer.lineIndex = startLine
        canvasVisualColumn = startColumn
        syncCanvasCursorToBuffer()
        clearActiveMark()
        buffer.isModified = true
        setStatusMessage(l10n["status.uncut_text"])
    }

    func fillCanvasBlock(with fillText: String) -> Bool {
        guard let rect = currentCanvasBlockRectangle(), rect.width > 0 else { return false }
        guard
            isCanvasRangeAllowed(
                topLine: rect.topLine,
                bottomLine: rect.bottomLine,
                leftColumn: rect.leftColumn,
                rightColumnExclusive: rect.rightColumnExclusive
            )
        else { return true }
        guard !fillText.isEmpty else {
            setStatusMessage(l10n["status.fill_text_required"])
            return true
        }

        saveUndoSnapshot()
        let replacement = fillText.repeatedToDisplayWidth(rect.width)
        for lineIndex in rect.topLine...rect.bottomLine {
            guard ensureCanvasLineExists(lineIndex) else { return true }
            var line = buffer.lines[lineIndex].removingVisualColumns(start: rect.leftColumn, width: rect.width)
            line = line.insertingAtVisualColumn(rect.leftColumn, text: replacement)
            buffer.lines[lineIndex] = line.trimmingTrailingSpaces()
        }
        clearActiveMark()
        buffer.isModified = true
        setStatusMessage(l10n["status.filled_block"])
        syncCanvasCursorToBuffer()
        return true
    }

    func writeCanvasLineSegment(
        lineIndex: Int,
        visualColumn: Int,
        direction: CanvasDrawDirection,
        style: BorderStyle
    ) {
        let existingCharacter = canvasCharacter(atLine: lineIndex, visualColumn: visualColumn)
        guard isCanvasDrawableCharacter(existingCharacter, style: style) else { return }

        var mask = canvasMask(
            for: existingCharacter,
            style: style)
        mask |= direction.mask

        if adjacentCanvasLineContinues(lineIndex: lineIndex, visualColumn: visualColumn, direction: .up, style: style) {
            mask |= CanvasDrawDirection.up.mask
        }
        if adjacentCanvasLineContinues(lineIndex: lineIndex, visualColumn: visualColumn, direction: .down, style: style)
        {
            mask |= CanvasDrawDirection.down.mask
        }
        if adjacentCanvasLineContinues(lineIndex: lineIndex, visualColumn: visualColumn, direction: .left, style: style)
        {
            mask |= CanvasDrawDirection.left.mask
        }
        if adjacentCanvasLineContinues(
            lineIndex: lineIndex, visualColumn: visualColumn, direction: .right, style: style)
        {
            mask |= CanvasDrawDirection.right.mask
        }

        writeCanvasCharacter(
            lineCharacter(forMask: mask, style: style), lineIndex: lineIndex, visualColumn: visualColumn)
    }

    private func adjacentCanvasLineContinues(
        lineIndex: Int,
        visualColumn: Int,
        direction: CanvasDrawDirection,
        style: BorderStyle
    ) -> Bool {
        let delta = direction.delta
        let adjacentLine = lineIndex + delta.line
        let adjacentColumn = visualColumn + delta.column
        guard adjacentLine >= 0, adjacentLine < buffer.lines.count, adjacentColumn >= 0 else { return false }

        let adjacentMask = canvasMask(
            for: canvasCharacter(atLine: adjacentLine, visualColumn: adjacentColumn),
            style: style)
        return (adjacentMask & oppositeMask(for: direction)) != 0
    }

    func canvasCharacter(atLine lineIndex: Int, visualColumn: Int) -> Character? {
        guard lineIndex >= 0, lineIndex < buffer.lines.count else { return nil }
        let slice = buffer.lines[lineIndex].visualSlice(startVisualColumn: visualColumn, width: 1)
        return slice.text.first
    }

    private func writeCanvasCharacter(_ character: Character, lineIndex: Int, visualColumn: Int) {
        guard ensureCanvasLineExists(lineIndex) else { return }
        guard isCanvasColumnAllowed(visualColumn) else {
            setStatusMessage(l10n["status.canvas_column_limit_exceeded"])
            return
        }
        let result = buffer.lines[lineIndex].writingAtVisualColumn(visualColumn, character: character)
        buffer.lines[lineIndex] = result.text
    }

    func writeCanvasCharacterIfDrawable(
        _ character: Character,
        lineIndex: Int,
        visualColumn: Int,
        style: BorderStyle
    ) {
        let existingCharacter = canvasCharacter(atLine: lineIndex, visualColumn: visualColumn)
        guard isCanvasDrawableCharacter(existingCharacter, style: style) else { return }
        writeCanvasCharacter(character, lineIndex: lineIndex, visualColumn: visualColumn)
    }
}
