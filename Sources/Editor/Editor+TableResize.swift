import Foundation
import LogoEngine
import TextMetrics

extension Editor {
    /// Resizes the column width of the active table cell (or standalone box) by delta (+1 or -1).
    func resizeCurrentTableCellWidth(delta: Int) {
        guard isTableModeActive, let cell = currentTableCell else { return }
        let detector = TableCellDetector()
        let tableLines = detectTableLineRange(for: cell)

        let colLeft = cell.minCol
        let colRight = cell.maxCol
        let currentWidth = colRight - colLeft - 1

        let nextCellToRight = findNextCellToRight(of: cell, on: cell.innerMinLine, detector: detector)
        let isSameGridTable = (nextCellToRight != nil && nextCellToRight!.minCol == colRight)

        if delta < 0 {
            for lineIdx in tableLines {
                let line = buffer.lines[lineIdx]
                let chars = Array(line)
                let (leftB, rightB) = findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
                if isTableBorderLine(chars, colLeft: leftB, colRight: rightB) {
                    continue
                }
                if leftB == colLeft && rightB == colRight {
                    if leftB + 1 < rightB {
                        let endIdx = min(rightB, chars.count)
                        let textInside = String(chars[(leftB + 1)..<endIdx]).trimmingTrailingWhitespace()
                        if textInside.displayWidth >= currentWidth {
                            setStatusMessage(l10n["status.cannot_shrink_width"])
                            return
                        }
                    }
                }
            }
            if currentWidth <= 1 {
                setStatusMessage(l10n["status.cannot_shrink_width"])
                return
            }
        } else if delta > 0 {
            for lineIdx in tableLines {
                let line = buffer.lines[lineIdx]
                let chars = Array(line)
                let (leftB, rightB) = findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
                if leftB == colLeft && rightB == colRight {
                    let nextIdx = rightB + 1
                    if nextIdx < chars.count && BorderCharacterSet.verticalBoundaryChars.contains(chars[nextIdx]) {
                        if !isSameGridTable {
                            setStatusMessage(l10n["status.cannot_expand_width_collision"])
                            return
                        }
                    }
                }
            }
        }

        for lineIdx in tableLines {
            var chars = Array(buffer.lines[lineIdx])
            if chars.count <= colLeft { continue }

            let (leftB, rightB) = findCellHorizontalBorders(
                in: buffer.lines[lineIdx], nearCol: cell.innerMinCol, cell: cell)
            if leftB != colLeft { continue }

            if delta > 0 {
                let isBorderLine = isTableBorderLine(chars, colLeft: leftB, colRight: rightB)
                let horiz = cell.style.tableCharacters.horizontal.first ?? "─"
                let insertChar: Character = isBorderLine ? horiz : " "
                let insertIndex = min(rightB, chars.count)
                chars.insert(insertChar, at: insertIndex)

                if !isSameGridTable {
                    let connectorIdx = insertIndex + 2
                    if connectorIdx < chars.count {
                        let c = chars[connectorIdx]
                        if BorderCharacterSet.isHorizontal(c) || c == " " {
                            chars.remove(at: connectorIdx)
                        }
                    }
                }
            } else if delta < 0 {
                let removeIndex = rightB - 1
                if removeIndex > colLeft && removeIndex < chars.count {
                    chars.remove(at: removeIndex)
                }
            }
            buffer.lines[lineIdx] = String(chars)
        }

        buffer.isModified = true

        if let newCell = detector.detectCell(in: buffer.lines, line: buffer.lineIndex, col: buffer.columnIndex) {
            currentTableCell = newCell
        }
        clampTableModeCursor()
    }

    /// Resizes the row height of the active table cell (or standalone box) by delta (+1 or -1).
    func resizeCurrentTableCellHeight(delta: Int) {
        guard isTableModeActive, let cell = currentTableCell else { return }
        let detector = TableCellDetector()

        let minLine = cell.minLine
        let maxLine = cell.maxLine
        let currentHeight = maxLine - minLine - 1

        if delta < 0 {
            if currentHeight <= 1 {
                setStatusMessage(l10n["status.cannot_shrink_height"])
                return
            }

            var lineToRemove: Int? = nil
            for lineIdx in stride(from: maxLine - 1, through: minLine + 1, by: -1) {
                if isLineEmptyAcrossRow(lineIdx) {
                    lineToRemove = lineIdx
                    break
                }
            }

            guard let removeLineIdx = lineToRemove else {
                setStatusMessage(l10n["status.cannot_shrink_height"])
                return
            }

            buffer.lines.remove(at: removeLineIdx)
            if buffer.lineIndex >= removeLineIdx && buffer.lineIndex > minLine + 1 {
                buffer.lineIndex -= 1
            }
        } else if delta > 0 {
            let templateLineIdx = minLine + 1
            let templateLine = (templateLineIdx < buffer.lines.count) ? buffer.lines[templateLineIdx] : ""
            var newLineChars = Array(templateLine)

            for c in 0..<newLineChars.count {
                if !BorderCharacterSet.verticalBoundaryChars.contains(newLineChars[c]) {
                    newLineChars[c] = " "
                }
            }
            let newLineStr = String(newLineChars)
            let insertLineIdx = maxLine
            buffer.lines.insert(newLineStr, at: insertLineIdx)
        }

        buffer.isModified = true

        if let newCell = detector.detectCell(in: buffer.lines, line: buffer.lineIndex, col: buffer.columnIndex) {
            currentTableCell = newCell
        }
        clampTableModeCursor()
    }

    private func isLineEmptyAcrossRow(_ lineIdx: Int) -> Bool {
        guard lineIdx >= 0 && lineIdx < buffer.lines.count else { return false }
        let line = buffer.lines[lineIdx]
        let chars = Array(line)

        for c in chars {
            if BorderCharacterSet.verticalBoundaryChars.contains(c) {
                continue
            }
            if !c.isWhitespace {
                return false
            }
        }
        return true
    }
}
