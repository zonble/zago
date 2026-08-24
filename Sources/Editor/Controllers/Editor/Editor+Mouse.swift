import Config
import Foundation
import TextMetrics

extension Editor {
    /// Central mouse event processing entrypoint for the Editor event loop.
    public func handleMouseEvent(_ mouseEvent: MouseEvent) {
        guard displayConfig.enableMouse else { return }

        let (rows, cols) = terminal.getWindowSize()
        let geometry = ScreenGeometry(rows: rows, cols: cols, editor: self)

        // 1. Help Bar Hit-Testing (Lines geometry.rows - 1 and geometry.rows)
        if mouseEvent.row >= geometry.rows - 1 {
            if case .press(.left) = mouseEvent.action {
                if let keyStr = renderer.hitTestHelpBar(
                    col: mouseEvent.col,
                    row: mouseEvent.row,
                    geometry: geometry,
                    promptMode: promptController.mode,
                    editor: self
                ) {
                    if let key = KeyParser.parse(keyStr) {
                        processKey(key)
                        return
                    }
                }
            }
            return
        }

        // 2. Menu Bar & Dropdown Overlay
        if menuBarController.isActive {
            if mouseEvent.row == 1 {
                if case .press(.left) = mouseEvent.action {
                    menuBar.updateCategories(for: self)
                    var colOffset = 1
                    for (idx, cat) in menuBar.categories.enumerated() {
                        let title = l10n[cat.titleKey]
                        let catWidth = title.displayWidth + 2
                        if mouseEvent.col >= colOffset && mouseEvent.col < colOffset + catWidth {
                            menuBar.categoryIndex = idx
                            menuBar.itemIndex = 0
                            return
                        }
                        colOffset += catWidth
                    }
                }
                return
            }

            let (startCol, boxWidth, boxLines) = renderer.generateDropdownOverlayLines(editor: self, cols: cols)
            let boxEndRow = 2 + boxLines.count - 1
            if mouseEvent.row >= 2 && mouseEvent.row <= boxEndRow &&
               mouseEvent.col >= startCol + 1 && mouseEvent.col <= startCol + boxWidth {
                let items = menuBar.currentCategory.items
                let itemRowStart = 3
                let itemRowEnd = 2 + items.count
                if mouseEvent.row >= itemRowStart && mouseEvent.row <= itemRowEnd {
                    if case .press(.left) = mouseEvent.action {
                        let clickedItemIdx = mouseEvent.row - itemRowStart
                        if clickedItemIdx >= 0 && clickedItemIdx < items.count {
                            menuBar.itemIndex = clickedItemIdx
                            menuBarController.executeCurrentMenuItem()
                            return
                        }
                    }
                }
                return
            }

            // Clicked outside dropdown menu
            if case .press = mouseEvent.action {
                menuBarController.isActive = false
            }
            return
        }

        // Top Row (Title Bar / Menu Header when inactive)
        if mouseEvent.row == 1 {
            if case .press(.left) = mouseEvent.action {
                menuBarController.toggle()
            }
            return
        }

        // Status Line / Prompt Area (geometry.rows - 2)
        if mouseEvent.row == geometry.rows - 2 {
            return
        }

        // Main Viewport Area
        let topMargin = 1 + (geometry.showRuler ? 1 : 0)
        guard mouseEvent.row > topMargin && mouseEvent.row <= topMargin + geometry.mainAreaHeight else {
            return
        }

        let screenVLineOffset = mouseEvent.row - topMargin - 1
        let vLineIndex = topVLineIndex + screenVLineOffset
        let visualCol = max(0, mouseEvent.col - 1 - geometry.gutterWidth)

        switch mouseEvent.action {
        case .scrollUp:
            if isCanvasModeActive {
                topVLineIndex = max(0, topVLineIndex - 3)
            } else {
                for _ in 0..<3 {
                    if topVLineIndex > 0 {
                        topVLineIndex -= 1
                    }
                }
            }

        case .scrollDown:
            if isCanvasModeActive {
                topVLineIndex += 3
            } else {
                for _ in 0..<3 {
                    topVLineIndex += 1
                }
            }

        case .press(.right):
            if isCanvasModeActive {
                if buffer.canvasBlockMark != nil {
                    buffer.canvasBlockMark = nil
                    buffer.canvasBlockMarkEnd = nil
                } else {
                    menuBarController.toggle()
                }
            } else if !buffer.isReadOnly {
                menuBarController.toggle()
            }

        case .press(.left):
            if buffer.isReadOnly && buffer.isDirectoryBuffer {
                if vLineIndex < buffer.lines.count {
                    buffer.lineIndex = vLineIndex
                    buffer.columnIndex = 0
                }
                return
            }
            if buffer.isReadOnly {
                return
            }

            if isCanvasModeActive {
                let canvasY = vLineIndex
                let canvasX = visualCol + canvasHorizontalOffset
                buffer.canvasBlockMark = nil
                buffer.canvasBlockMarkEnd = nil

                guard ensureCanvasLineExists(canvasY) else { return }
                buffer.lineIndex = canvasY
                canvasVisualColumn = canvasX
                syncCanvasCursorToBuffer()
            } else if isTableModeActive {
                let (targetLine, targetCol) = getBufferCursorForVisualColumn(vLineIndex: vLineIndex, visualCol: visualCol)
                buffer.lineIndex = targetLine
                buffer.columnIndex = targetCol
                tableModeController.clampTableModeCursor()
            } else {
                let (targetLine, targetCol) = getBufferCursorForVisualColumn(vLineIndex: vLineIndex, visualCol: visualCol)
                buffer.selectionMark = nil
                buffer.lineIndex = targetLine
                buffer.columnIndex = targetCol
            }

        case .drag(.left):
            if buffer.isReadOnly { return }
            if isCanvasModeActive {
                let canvasY = vLineIndex
                let canvasX = visualCol + canvasHorizontalOffset
                guard isCanvasLineAllowed(canvasY) else { return }

                if buffer.canvasBlockMark == nil {
                    buffer.canvasBlockMark = (line: buffer.lineIndex, visualColumn: canvasVisualColumn)
                }
                buffer.canvasBlockMarkEnd = (line: canvasY, visualColumn: canvasX)
                if canvasY < buffer.lines.count {
                    buffer.lineIndex = canvasY
                } else {
                    guard ensureCanvasLineExists(canvasY) else { return }
                    buffer.lineIndex = canvasY
                }
                canvasVisualColumn = canvasX
                syncCanvasCursorToBuffer()
            } else if isTableModeActive {
                let (targetLine, targetCol) = getBufferCursorForVisualColumn(vLineIndex: vLineIndex, visualCol: visualCol)
                if buffer.selectionMark == nil {
                    buffer.selectionMark = (line: buffer.lineIndex, column: buffer.columnIndex)
                }
                buffer.lineIndex = targetLine
                buffer.columnIndex = targetCol
                tableModeController.clampTableModeCursor()
            } else {
                let (targetLine, targetCol) = getBufferCursorForVisualColumn(vLineIndex: vLineIndex, visualCol: visualCol)
                if buffer.selectionMark == nil {
                    buffer.selectionMark = (line: buffer.lineIndex, column: buffer.columnIndex)
                }
                buffer.lineIndex = targetLine
                buffer.columnIndex = targetCol
            }

        case .release(.left):
            if !isCanvasModeActive && !isTableModeActive {
                if let mark = buffer.selectionMark, mark.line == buffer.lineIndex && mark.column == buffer.columnIndex {
                    buffer.selectionMark = nil
                }
            }

        default:
            break
        }
    }
}
