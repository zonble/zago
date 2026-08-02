import Foundation
import LogoEngine
import TextMetrics

private enum CanvasDrawDirection {
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
}

extension Editor {
    struct CanvasBlockRectangle: Sendable, Equatable {
        let topLine: Int
        let bottomLine: Int
        let leftColumn: Int
        let rightColumnExclusive: Int

        var width: Int {
            max(0, rightColumnExclusive - leftColumn)
        }
    }

    func processCanvasDrawingKey(_ key: Key) -> Bool {
        guard isCanvasModeActive, !isTableModeActive else { return false }

        let direction: CanvasDrawDirection
        let drawsArrow: Bool
        switch key {
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

        saveUndoSnapshot()
        clearActiveMark()
        drawCanvasStep(direction: direction, drawsArrow: drawsArrow)
        return true
    }

    func syncCanvasCursorFromBuffer() {
        guard buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count else {
            canvasVisualColumn = 0
            return
        }
        canvasVisualColumn = buffer.lines[buffer.lineIndex].visualColumn(forCharacterOffset: buffer.columnIndex)
    }

    func syncCanvasCursorToBuffer() {
        ensureCanvasLineExists(buffer.lineIndex)
        let line = buffer.lines[buffer.lineIndex]
        buffer.columnIndex = line.characterOffset(forVisualColumn: canvasVisualColumn)
    }

    func moveCanvasCursor(deltaLine: Int, deltaColumn: Int, extendDownward: Bool = true) {
        let targetLine = buffer.lineIndex + deltaLine
        if extendDownward && deltaLine > 0 {
            ensureCanvasLineExists(targetLine)
        }
        buffer.lineIndex = max(0, min(targetLine, buffer.lines.count - 1))
        canvasVisualColumn = max(0, canvasVisualColumn + deltaColumn)
        syncCanvasCursorToBuffer()
    }

    func moveCanvasCursorToLineStart() {
        canvasVisualColumn = 0
        syncCanvasCursorToBuffer()
    }

    func moveCanvasCursorToLineEnd() {
        ensureCanvasLineExists(buffer.lineIndex)
        canvasVisualColumn = buffer.lines[buffer.lineIndex].displayWidth
        syncCanvasCursorToBuffer()
    }

    func insertCanvasCharacter(_ ch: Character) {
        ensureCanvasLineExists(buffer.lineIndex)
        let result = buffer.lines[buffer.lineIndex].writingAtVisualColumn(canvasVisualColumn, character: ch)
        buffer.lines[buffer.lineIndex] = result.text
        canvasVisualColumn = result.visualColumnAfterWrite
        buffer.columnIndex = result.characterOffsetAfterWrite
        buffer.isModified = true
    }

    func insertCanvasString(_ text: String) {
        clearActiveMark()
        let startColumn = canvasVisualColumn
        let lines = text.components(separatedBy: .newlines)
        guard !lines.isEmpty else { return }

        for (lineOffset, segment) in lines.enumerated() {
            if lineOffset > 0 {
                buffer.lineIndex += 1
                ensureCanvasLineExists(buffer.lineIndex)
                canvasVisualColumn = startColumn
            }

            for ch in segment {
                insertCanvasCharacter(ch)
            }
        }
    }

    func insertCanvasNewline() {
        clearActiveMark()
        let insertIndex = min(buffer.lineIndex + 1, buffer.lines.count)
        buffer.lines.insert("", at: insertIndex)
        buffer.lineIndex = insertIndex
        canvasVisualColumn = 0
        buffer.isModified = true
        syncCanvasCursorToBuffer()
    }

    func deleteCanvasCharacter() {
        clearActiveMark()
        ensureCanvasLineExists(buffer.lineIndex)
        let result = buffer.lines[buffer.lineIndex].clearingAtVisualColumn(canvasVisualColumn)
        buffer.lines[buffer.lineIndex] = result.text
        buffer.columnIndex = result.characterOffsetAfterWrite
        buffer.isModified = true
        syncCanvasCursorToBuffer()
    }

    func backspaceCanvasCharacter() {
        clearActiveMark()
        guard canvasVisualColumn > 0 else {
            buffer.deleteLine()
            canvasVisualColumn = 0
            syncCanvasCursorToBuffer()
            return
        }
        ensureCanvasLineExists(buffer.lineIndex)
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

    private func ensureCanvasLineExists(_ lineIndex: Int) {
        guard lineIndex >= 0 else { return }
        while buffer.lines.count <= lineIndex {
            buffer.lines.append("")
        }
    }

    func currentCanvasBlockRectangle() -> CanvasBlockRectangle? {
        guard let mark = canvasBlockMark else { return nil }
        let end = canvasBlockMarkEnd ?? mark
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
            setStatusMessage(L10n["status.no_block_marked"])
            return false
        }

        var rows: [String] = []
        for lineIndex in rect.topLine...rect.bottomLine {
            let line = lineIndex < buffer.lines.count ? buffer.lines[lineIndex] : ""
            rows.append(line.visualSlice(startVisualColumn: rect.leftColumn, width: rect.width).text)
        }

        canvasBlockClipboard = CanvasBlockClipboard(width: rect.width, rows: rows)
        setStatusMessage(L10n["status.copied_block"])
        return true
    }

    func cutCanvasBlock() {
        guard let rect = currentCanvasBlockRectangle(), rect.width > 0 else {
            setStatusMessage(L10n["status.no_block_marked"])
            return
        }

        var rows: [String] = []
        for lineIndex in rect.topLine...rect.bottomLine {
            ensureCanvasLineExists(lineIndex)
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
        setStatusMessage(L10n["status.cut_text"])
    }

    func pasteCanvasBlock() {
        guard let clipboard = canvasBlockClipboard, clipboard.width > 0, !clipboard.rows.isEmpty else {
            setStatusMessage(L10n["status.clipboard_empty"])
            return
        }

        saveUndoSnapshot()
        let startLine = buffer.lineIndex
        let startColumn = canvasVisualColumn
        for (rowOffset, rowText) in clipboard.rows.enumerated() {
            let targetLine = startLine + rowOffset
            ensureCanvasLineExists(targetLine)
            buffer.lines[targetLine] = buffer.lines[targetLine].insertingAtVisualColumn(startColumn, text: rowText)
        }

        buffer.lineIndex = startLine
        canvasVisualColumn = startColumn
        syncCanvasCursorToBuffer()
        clearActiveMark()
        buffer.isModified = true
        setStatusMessage(L10n["status.uncut_text"])
    }

    func fillCanvasBlock(with fillText: String) -> Bool {
        guard let rect = currentCanvasBlockRectangle(), rect.width > 0 else { return false }
        guard !fillText.isEmpty else {
            setStatusMessage(L10n["status.fill_text_required"])
            return true
        }

        saveUndoSnapshot()
        let replacement = repeatedCanvasFillText(fillText, width: rect.width)
        for lineIndex in rect.topLine...rect.bottomLine {
            ensureCanvasLineExists(lineIndex)
            var line = buffer.lines[lineIndex].removingVisualColumns(start: rect.leftColumn, width: rect.width)
            line = line.insertingAtVisualColumn(rect.leftColumn, text: replacement)
            buffer.lines[lineIndex] = line.trimmingTrailingSpaces()
        }
        clearActiveMark()
        buffer.isModified = true
        setStatusMessage(L10n["status.filled_block"])
        syncCanvasCursorToBuffer()
        return true
    }

    private func repeatedCanvasFillText(_ text: String, width: Int) -> String {
        let fillChars = Array(text)
        guard width > 0, !fillChars.isEmpty else { return "" }

        var result = ""
        var resultWidth = 0
        var idx = 0
        while resultWidth < width {
            let ch = fillChars[idx % fillChars.count]
            let chWidth = ch.displayWidth
            if resultWidth + chWidth <= width {
                result.append(ch)
                resultWidth += chWidth
            } else {
                result += String(repeating: " ", count: width - resultWidth)
                resultWidth = width
            }
            idx += 1
        }
        return result
    }

    private func drawCanvasStep(direction: CanvasDrawDirection, drawsArrow: Bool) {
        ensureCanvasLineExists(buffer.lineIndex)

        let delta = direction.delta
        let targetLine = buffer.lineIndex + delta.line
        let targetColumn = canvasVisualColumn + delta.column
        guard targetLine >= 0, targetColumn >= 0 else { return }

        let currentLine = buffer.lineIndex
        let currentColumn = canvasVisualColumn
        let style = defaultBorderStyle

        writeCanvasLineSegment(
            lineIndex: currentLine,
            visualColumn: currentColumn,
            direction: direction,
            style: style)

        if drawsArrow {
            ensureCanvasLineExists(targetLine)
            writeCanvasCharacterIfDrawable(
                arrowHead(for: direction, style: style),
                lineIndex: targetLine,
                visualColumn: targetColumn,
                style: style)
        }

        buffer.lineIndex = targetLine
        canvasVisualColumn = targetColumn
        syncCanvasCursorToBuffer()
        buffer.isModified = true
    }

    private func writeCanvasLineSegment(
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

    private func canvasCharacter(atLine lineIndex: Int, visualColumn: Int) -> Character? {
        guard lineIndex >= 0, lineIndex < buffer.lines.count else { return nil }
        let slice = buffer.lines[lineIndex].visualSlice(startVisualColumn: visualColumn, width: 1)
        return slice.text.first
    }

    private func writeCanvasCharacter(_ character: Character, lineIndex: Int, visualColumn: Int) {
        ensureCanvasLineExists(lineIndex)
        let result = buffer.lines[lineIndex].writingAtVisualColumn(visualColumn, character: character)
        buffer.lines[lineIndex] = result.text
    }

    private func writeCanvasCharacterIfDrawable(
        _ character: Character,
        lineIndex: Int,
        visualColumn: Int,
        style: BorderStyle
    ) {
        let existingCharacter = canvasCharacter(atLine: lineIndex, visualColumn: visualColumn)
        guard isCanvasDrawableCharacter(existingCharacter, style: style) else { return }
        writeCanvasCharacter(character, lineIndex: lineIndex, visualColumn: visualColumn)
    }

    private func isCanvasDrawableCharacter(_ character: Character?, style: BorderStyle) -> Bool {
        guard let character else { return true }
        return character == " " || character == "\t" || canvasMask(for: character, style: style) != 0
    }

    private func oppositeMask(for direction: CanvasDrawDirection) -> UInt8 {
        switch direction {
        case .up: return CanvasDrawDirection.down.mask
        case .down: return CanvasDrawDirection.up.mask
        case .left: return CanvasDrawDirection.right.mask
        case .right: return CanvasDrawDirection.left.mask
        }
    }

    private func canvasMask(for character: Character?, style _: BorderStyle) -> UInt8 {
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

    private func lineCharacter(forMask mask: UInt8, style: BorderStyle) -> Character {
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

    private func arrowHead(for direction: CanvasDrawDirection, style: BorderStyle) -> Character {
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
}
