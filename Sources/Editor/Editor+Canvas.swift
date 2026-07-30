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
        drawCanvasStep(direction: direction, drawsArrow: drawsArrow)
        return true
    }

    public func syncCanvasCursorFromBuffer() {
        guard buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count else {
            canvasVisualColumn = 0
            return
        }
        canvasVisualColumn = buffer.lines[buffer.lineIndex].visualColumn(forCharacterOffset: buffer.columnIndex)
    }

    public func syncCanvasCursorToBuffer() {
        ensureCanvasLineExists(buffer.lineIndex)
        let line = buffer.lines[buffer.lineIndex]
        buffer.columnIndex = line.characterOffset(forVisualColumn: canvasVisualColumn)
    }

    public func moveCanvasCursor(deltaLine: Int, deltaColumn: Int, extendDownward: Bool = true) {
        let targetLine = buffer.lineIndex + deltaLine
        if extendDownward && deltaLine > 0 {
            ensureCanvasLineExists(targetLine)
        }
        buffer.lineIndex = max(0, min(targetLine, buffer.lines.count - 1))
        canvasVisualColumn = max(0, canvasVisualColumn + deltaColumn)
        syncCanvasCursorToBuffer()
    }

    public func moveCanvasCursorToLineStart() {
        canvasVisualColumn = 0
        syncCanvasCursorToBuffer()
    }

    public func moveCanvasCursorToLineEnd() {
        ensureCanvasLineExists(buffer.lineIndex)
        canvasVisualColumn = buffer.lines[buffer.lineIndex].displayWidth
        syncCanvasCursorToBuffer()
    }

    public func insertCanvasCharacter(_ ch: Character) {
        ensureCanvasLineExists(buffer.lineIndex)
        let result = buffer.lines[buffer.lineIndex].writingAtVisualColumn(canvasVisualColumn, character: ch)
        buffer.lines[buffer.lineIndex] = result.text
        canvasVisualColumn = result.visualColumnAfterWrite
        buffer.columnIndex = result.characterOffsetAfterWrite
        buffer.isModified = true
    }

    public func insertCanvasString(_ text: String) {
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

    public func insertCanvasNewline() {
        let insertIndex = min(buffer.lineIndex + 1, buffer.lines.count)
        buffer.lines.insert("", at: insertIndex)
        buffer.lineIndex = insertIndex
        canvasVisualColumn = 0
        buffer.isModified = true
        syncCanvasCursorToBuffer()
    }

    public func deleteCanvasCharacter() {
        ensureCanvasLineExists(buffer.lineIndex)
        let result = buffer.lines[buffer.lineIndex].clearingAtVisualColumn(canvasVisualColumn)
        buffer.lines[buffer.lineIndex] = result.text
        buffer.columnIndex = result.characterOffsetAfterWrite
        buffer.isModified = true
        syncCanvasCursorToBuffer()
    }

    public func backspaceCanvasCharacter() {
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

    public func ensureCanvasViewport(textWidth: Int) {
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
        if adjacentCanvasLineContinues(lineIndex: lineIndex, visualColumn: visualColumn, direction: .down, style: style) {
            mask |= CanvasDrawDirection.down.mask
        }
        if adjacentCanvasLineContinues(lineIndex: lineIndex, visualColumn: visualColumn, direction: .left, style: style) {
            mask |= CanvasDrawDirection.left.mask
        }
        if adjacentCanvasLineContinues(lineIndex: lineIndex, visualColumn: visualColumn, direction: .right, style: style) {
            mask |= CanvasDrawDirection.right.mask
        }

        writeCanvasCharacter(lineCharacter(forMask: mask, style: style), lineIndex: lineIndex, visualColumn: visualColumn)
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
        case "├", "╠": return CanvasDrawDirection.up.mask | CanvasDrawDirection.right.mask | CanvasDrawDirection.down.mask
        case "┤", "╣": return CanvasDrawDirection.up.mask | CanvasDrawDirection.down.mask | CanvasDrawDirection.left.mask
        case "┬", "╦": return CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask | CanvasDrawDirection.down.mask
        case "┴", "╩": return CanvasDrawDirection.up.mask | CanvasDrawDirection.left.mask | CanvasDrawDirection.right.mask
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
