import Config
import Foundation
import TextMetrics

extension Editor {
    /// Central mouse event processing entrypoint for the Editor event loop.
    public func handleMouseEvent(_ mouseEvent: MouseEvent) {
        guard displayConfig.enableMouse else { return }

        let (rows, cols) = terminal.getWindowSize()
        let geometry = ScreenGeometry(rows: rows, cols: cols, editor: self)

        // 1. Drag Selection Auto-Scroll (takes priority when dragging across or beyond bars)
        if case .drag(.left) = mouseEvent.action {
            if buffer.isReadOnly || promptController.isActive { return }

            let topMargin = 1 + (geometry.showRuler ? 1 : 0)
            let totalLineCount: Int
            if isCanvasModeActive {
                totalLineCount = max(1, buffer.lines.count)
            } else {
                let virtualLines = prepareVirtualLines(textWidth: geometry.textWidth)
                totalLineCount = max(1, virtualLines.count)
            }

            // Determine if at or beyond boundary and compute two-tier interval
            let isOutsideWindow = mouseEvent.row <= 0 || mouseEvent.row > geometry.rows
                || mouseEvent.col <= 0 || mouseEvent.col > geometry.cols
            let isAtBoundaryRow = mouseEvent.row <= topMargin || mouseEvent.row > topMargin + geometry.mainAreaHeight
            let isAtBoundaryCol = isCanvasModeActive && (mouseEvent.col <= 1 + geometry.gutterWidth || mouseEvent.col > geometry.cols)

            if isOutsideWindow {
                activeBoundaryDragState = BoundaryDragScrollState(lastEvent: mouseEvent, intervalMs: 30)
            } else if isAtBoundaryRow || isAtBoundaryCol {
                activeBoundaryDragState = BoundaryDragScrollState(lastEvent: mouseEvent, intervalMs: 60)
            } else {
                activeBoundaryDragState = nil
            }

            // Vertical Auto-Scroll & Coordinate Clamping
            let vLineIndex: Int
            if mouseEvent.row <= topMargin {
                if topVLineIndex > 0 {
                    topVLineIndex -= 1
                }
                vLineIndex = topVLineIndex
            } else if mouseEvent.row > topMargin + geometry.mainAreaHeight {
                let maxTop = max(0, totalLineCount - 1)
                if topVLineIndex < maxTop {
                    topVLineIndex += 1
                }
                let screenOffset = max(0, min(geometry.mainAreaHeight - 1, (totalLineCount - 1) - topVLineIndex))
                vLineIndex = topVLineIndex + screenOffset
            } else {
                let screenOffset = mouseEvent.row - topMargin - 1
                vLineIndex = topVLineIndex + screenOffset
            }

            // Horizontal Auto-Scroll & Coordinate Clamping for Canvas Mode
            if isCanvasModeActive {
                if mouseEvent.col <= 1 + geometry.gutterWidth {
                    canvasHorizontalOffset = max(0, canvasHorizontalOffset - 2)
                } else if mouseEvent.col > cols {
                    canvasHorizontalOffset += 2
                }
            }

            let rawVisualCol = mouseEvent.col - 1 - geometry.gutterWidth
            let visualCol = max(0, min(rawVisualCol, geometry.textWidth - 1))

            if isCanvasModeActive {
                let canvasY = vLineIndex
                let canvasX = visualCol + canvasHorizontalOffset
                guard isCanvasLineAllowed(canvasY) else { return }

                if buffer.canvasBlockMark == nil {
                    buffer.canvasBlockMark = (line: buffer.lineIndex, visualColumn: canvasVisualColumn)
                }

                if let prevEnd = buffer.canvasBlockMarkEnd,
                    prevEnd.line == canvasY && prevEnd.visualColumn == canvasX,
                    buffer.lineIndex == canvasY, canvasVisualColumn == canvasX
                {
                    return
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
            return
        }

        activeBoundaryDragState = nil

        // 2. Help Bar Hit-Testing (Lines geometry.rows - 1 and geometry.rows)
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

        // 3. Menu Bar & Dropdown Overlay
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
            if promptController.isActive { return }
            if case .press(.left) = mouseEvent.action {
                menuBarController.toggle()
            }
            return
        }

        // Status Line / Prompt Area (geometry.rows - 2)
        if mouseEvent.row == geometry.rows - 2 {
            return
        }

        // Main Viewport Area for clicks and other non-drag events
        let topMargin = 1 + (geometry.showRuler ? 1 : 0)
        guard mouseEvent.row > topMargin && mouseEvent.row <= topMargin + geometry.mainAreaHeight else {
            return
        }

        let screenVLineOffset = mouseEvent.row - topMargin - 1
        let vLineIndex = topVLineIndex + screenVLineOffset
        let visualCol = max(0, mouseEvent.col - 1 - geometry.gutterWidth)

        switch mouseEvent.action {
        case .scrollUp:
            topVLineIndex = max(0, topVLineIndex - 3)

        case .scrollDown:
            let virtualLines = prepareVirtualLines(textWidth: geometry.textWidth)
            let maxTop = max(0, virtualLines.count - 1)
            topVLineIndex = min(maxTop, topVLineIndex + 3)

        case .press(.right):
            if promptController.isActive { return }
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
            if promptController.isActive {
                return
            }
            if buffer.isReadOnly && buffer.isDirectoryBuffer {
                let minSelectableLine = min(3, max(0, buffer.lines.count - 1))
                if vLineIndex >= minSelectableLine && vLineIndex < buffer.lines.count {
                    let clicks = mouseClickTracker.registerClick(
                        row: mouseEvent.row,
                        col: mouseEvent.col,
                        vLineIndex: vLineIndex
                    )
                    buffer.lineIndex = vLineIndex
                    buffer.columnIndex = 0
                    if clicks >= 2 {
                        mouseClickTracker.reset()
                        if let dirBuffer = buffer as? DirectoryBuffer {
                            dirBuffer.activateEntry(editor: self)
                        }
                    }
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

        case .release(.left):
            if promptController.isActive {
                return
            }
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
