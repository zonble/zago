import Foundation
import TextMetrics

/// Centralized Renderer class responsible for composing and formatting all
/// screen ANSI UI components (Title Bar, Menu Bar, WordStar Ruler, Main Text
/// Area, Line Numbers Gutter, Status/Prompt Line, Dynamic Help Bar, Cursor
/// Positioning).
public final class Renderer {
    public struct RenderedPrompt {
        public let text: String
        public let cursorCol: Int

        public init(text: String, cursorCol: Int) {
            self.text = text
            self.cursorCol = cursorCol
        }
    }

    public init() {}

    /// Renders the complete screen output ANSI string for given terminal rows and cols dimensions.
    public func render(editor: Editor, rows: Int, cols: Int) -> String {
        let showRuler = editor.displayConfig.showRuler && !editor.buffer.isDirectoryBuffer
        let mainAreaHeight = max(1, rows - (showRuler ? 5 : 4))  // Reserve 1 title bar, (optional 1 ruler), 1 status line, 2 help bar
        let showGutter = editor.displayConfig.showLineNumbers && !editor.buffer.isDirectoryBuffer
        let gutterWidth = showGutter ? 5 : 0
        let textWidth = max(10, cols - gutterWidth)

        // Compute Virtual Lines (wrapped visual sub-lines)
        let virtualLines =
            editor.isCanvasModeActive
            ? editor.layoutEngine.computeCanvasLines(from: editor.buffer.lines)
            : editor.layoutEngine.computeVirtualLines(from: editor.buffer.lines, viewWidth: textWidth)

        // Find current virtual line index for buffer cursor
        let (cursorVLineIdx, cursorVColIdx): (Int, Int)
        if editor.isCanvasModeActive {
            cursorVLineIdx = max(0, min(editor.buffer.lineIndex, max(0, virtualLines.count - 1)))
            cursorVColIdx = editor.buffer.columnIndex
            editor.ensureCanvasViewport(textWidth: textWidth)
        } else {
            (cursorVLineIdx, cursorVColIdx) = editor.layoutEngine.getVirtualCursor(
                lineIndex: editor.buffer.lineIndex,
                columnIndex: editor.buffer.columnIndex,
                virtualLines: virtualLines
            )
        }

        // Adjust topVLineIndex viewport scrolling offset
        if cursorVLineIdx < editor.topVLineIndex {
            editor.topVLineIndex = cursorVLineIdx
        } else if cursorVLineIdx >= editor.topVLineIndex + mainAreaHeight {
            editor.topVLineIndex = cursorVLineIdx - mainAreaHeight + 1
        }

        var output = ""
        output += "\u{1B}[?7l\u{1B}[H"  // Disable terminal auto-wrap (DECAWM Reset) & Reset cursor to (1, 1)

        // 1. Title Bar or Top Menu Bar Component
        output += renderTitleOrMenuBar(editor: editor, cols: cols)

        let (dropdownStartCol, dropdownBoxWidth, dropdownBoxLines) = generateDropdownOverlayLines(
            editor: editor, cols: cols)

        // 2. WordStar Ruler Bar Component (Optional)
        if showRuler {
            output += renderRulerBar(
                editor: editor,
                textWidth: textWidth,
                gutterWidth: gutterWidth,
                cols: cols,
                dropdownStartCol: dropdownStartCol,
                dropdownBoxWidth: dropdownBoxWidth,
                dropdownBoxLines: dropdownBoxLines
            )
        }

        // 3. Main Text Area Component (with Line Numbers Gutter)
        output += renderMainTextArea(
            editor: editor,
            mainAreaHeight: mainAreaHeight,
            gutterWidth: gutterWidth,
            virtualLines: virtualLines,
            cols: cols,
            dropdownStartCol: dropdownStartCol,
            dropdownBoxWidth: dropdownBoxWidth,
            dropdownBoxLines: dropdownBoxLines
        )

        // 4. Status & Prompt Line Component
        let renderedPrompt = renderStatusAndPromptLine(editor: editor, cols: cols, output: &output)

        // 5. Dynamic Contextual Help Bar Component
        output += renderHelpBar(cols: cols, promptMode: editor.currentPromptMode, editor: editor)

        // 6. Terminal Cursor Positioning Component
        output += positionCursor(
            editor: editor,
            rows: rows,
            cols: cols,
            cursorVLineIdx: cursorVLineIdx,
            cursorVColIdx: cursorVColIdx,
            gutterWidth: gutterWidth,
            virtualLines: virtualLines,
            renderedPrompt: renderedPrompt
        )

        return output
    }

    // MARK: - Component 1: Title Bar or Top Menu Bar

    /// Renders the top Title Bar (or active Menu Bar categories).
    public func renderTitleOrMenuBar(editor: Editor, cols: Int) -> String {
        if editor.isMenuBarActive {
            editor.menuBar.updateCategories(for: editor)
            func menuSegment(title: String, isSelected: Bool) -> String {
                isSelected ? "[ \(title) ]" : "  \(title)  "
            }

            var rawMenuStr = " "
            for (idx, cat) in editor.menuBar.categories.enumerated() {
                let catTitle = L10n[cat.titleKey]
                rawMenuStr += menuSegment(title: catTitle, isSelected: idx == editor.menuBar.categoryIndex)
            }

            var formattedMenu = "\u{1B}[47;30m "
            for (idx, cat) in editor.menuBar.categories.enumerated() {
                let catTitle = L10n[cat.titleKey]
                if idx == editor.menuBar.categoryIndex {
                    formattedMenu += "\u{1B}[1;37;44m\(menuSegment(title: catTitle, isSelected: true))\u{1B}[0;47;30m"
                } else {
                    formattedMenu += menuSegment(title: catTitle, isSelected: false)
                }
            }
            let remainingSpaces = max(0, cols - rawMenuStr.displayWidth)
            return formattedMenu + String(repeating: " ", count: remainingSpaces) + "\u{1B}[0m\r\n"
        } else {
            let bufIndexStr =
                editor.buffers.count > 1 ? " [\(editor.currentBufferIndex + 1)/\(editor.buffers.count)]" : "zago"
            let leftText = "  \(bufIndexStr)"
            let centerText = editor.buffer.filePath ?? L10n.newBuffer
            let rightText = editor.buffer.isModified ? "\(L10n.modified)  " : "  "

            let leftW = leftText.displayWidth
            let centerW = centerText.displayWidth
            let rightW = rightText.displayWidth

            let targetCenterStart = max(leftW + 1, (cols - centerW) / 2)
            let leftPaddingCount = max(0, targetCenterStart - leftW)
            let leftSideWidth = leftW + leftPaddingCount

            let rightPaddingCount = max(0, cols - leftSideWidth - centerW - rightW)

            let titleStr =
                leftText
                + String(repeating: " ", count: leftPaddingCount)
                + centerText
                + String(repeating: " ", count: rightPaddingCount)
                + rightText

            let paddedTitle = titleStr.paddedToDisplayWidth(cols)
            return "\u{1B}[7m\(paddedTitle)\u{1B}[m\r\n"
        }
    }

    // MARK: - Component 2: WordStar Ruler Bar

    /// Renders the WordStar ruler line (----!----1----!----2...)
    public func renderRulerBar(
        editor: Editor,
        textWidth: Int,
        gutterWidth: Int,
        cols: Int,
        dropdownStartCol: Int,
        dropdownBoxWidth: Int,
        dropdownBoxLines: [String]
    ) -> String {
        let rulerStr = generateWordStarRuler(
            width: textWidth,
            startColumn: editor.isCanvasModeActive ? editor.canvasHorizontalOffset + 1 : 1,
            wrapColumn: editor.layoutEngine.wrapColumn)
        var lineStr = "\u{1B}[K"
        if editor.isMenuBarActive && dropdownBoxLines.count > 0 {
            let plainRulerLine = String(repeating: " ", count: gutterWidth) + rulerStr
            let sliced = sliceOverlayLine(
                baseFullLineStr: plainRulerLine,
                boxLine: dropdownBoxLines[0],
                dropdownStartCol: dropdownStartCol,
                dropdownBoxWidth: dropdownBoxWidth,
                cols: cols,
                isDim: true
            )
            lineStr += sliced + "\r\n"
        } else {
            lineStr += "\u{1B}[90m\(String(repeating: " ", count: gutterWidth))\(rulerStr)\u{1B}[0m\r\n"
        }
        return lineStr
    }

    // MARK: - Component 3: Main Text Area & Line Numbers Gutter

    /// Renders the central text area containing virtual wrapped lines, line numbers gutter, and overlay elements.
    public func renderMainTextArea(
        editor: Editor,
        mainAreaHeight: Int,
        gutterWidth: Int,
        virtualLines: [VirtualLine],
        cols: Int,
        dropdownStartCol: Int,
        dropdownBoxWidth: Int,
        dropdownBoxLines: [String]
    ) -> String {
        var output = ""

        for i in 0..<mainAreaHeight {
            let vIndex = editor.topVLineIndex + i
            output += "\u{1B}[K"  // Clear line

            let boxIdx = editor.displayConfig.showRuler ? (i + 1) : i

            var lineOutput = ""
            if vIndex < virtualLines.count {
                let vLine = virtualLines[vIndex]
                let isFirstSubLine = (vLine.subLineIndex == 0)

                // Render Gutter (Line Number or Softwrap Indicator ↳)
                if editor.displayConfig.showLineNumbers && !editor.buffer.isDirectoryBuffer {
                    let lineNumStr = renderLineNumberGutter(
                        lineNumber: vLine.bufferLineIndex + 1,
                        isFirstSubLine: isFirstSubLine,
                        showLineNumbers: true,
                        isMenuOverlay: editor.isMenuBarActive && boxIdx < dropdownBoxLines.count
                    )
                    lineOutput += "\u{1B}[90m\(lineNumStr)\u{1B}[0m"  // Dim gray gutter
                }

                let renderedLineText: String
                let renderedStartCol: Int
                if editor.isCanvasModeActive {
                    let slice = vLine.text.visualSlice(
                        startVisualColumn: editor.canvasHorizontalOffset,
                        width: max(0, cols - gutterWidth))
                    renderedLineText = slice.text
                    renderedStartCol = slice.startCharacterOffset
                } else {
                    renderedLineText = vLine.text
                    renderedStartCol = vLine.startCol
                }

                let currentLanguage =
                    editor.displayConfig.enableSyntaxHighlight
                    ? editor.syntaxHighlighter.getSyntaxForLine(editor: editor, bufferLineIndex: vLine.bufferLineIndex)
                    : nil
                let tokenTypes =
                    (currentLanguage != nil)
                    ? editor.syntaxHighlighter.tokenTypes(for: renderedLineText, syntax: currentLanguage!)
                    : []

                var activeCellBounds: (left: Int, right: Int)? = nil
                if editor.isTableModeActive, let cell = editor.currentTableCell,
                    vLine.bufferLineIndex >= cell.innerMinLine && vLine.bufferLineIndex <= cell.innerMaxLine,
                    vLine.bufferLineIndex >= 0 && vLine.bufferLineIndex < editor.buffer.lines.count
                {
                    let fullLine = editor.buffer.lines[vLine.bufferLineIndex]
                    activeCellBounds = editor.findCellHorizontalBorders(
                        in: fullLine, nearCol: cell.innerMinCol, cell: cell)
                }

                let chars = Array(renderedLineText)
                var renderedDisplayWidth = 0
                for (cIdxInVLine, ch) in chars.enumerated() {
                    let realCol = renderedStartCol + cIdxInVLine
                    let charVisualColumn =
                        editor.isCanvasModeActive
                        ? editor.canvasHorizontalOffset + renderedDisplayWidth
                        : realCol
                    let isCellActive: Bool
                    if let (cellLeft, cellRight) = activeCellBounds {
                        isCellActive = realCol > cellLeft && realCol < cellRight
                    } else {
                        isCellActive = false
                    }

                    if editor.isCanvasModeActive
                        && editor.isCanvasCellSelected(line: vLine.bufferLineIndex, visualColumn: charVisualColumn)
                    {
                        lineOutput += "\u{1B}[7m\(ch)\u{1B}[m"
                    } else if !editor.isCanvasModeActive
                        && editor.isCharacterSelected(line: vLine.bufferLineIndex, col: realCol)
                    {
                        lineOutput += "\u{1B}[7m\(ch)\u{1B}[m"  // Inverse video for selection
                    } else if isCellActive {
                        lineOutput += "\u{1B}[42;97;1m\(ch)\u{1B}[0m"  // Green bg for active cell
                    } else if cIdxInVLine < tokenTypes.count && tokenTypes[cIdxInVLine] != .normal {
                        let tok = tokenTypes[cIdxInVLine]
                        lineOutput += tok.ansiColor + String(ch) + "\u{1B}[0m"
                    } else {
                        lineOutput += String(ch)
                    }
                    renderedDisplayWidth += ch.displayWidth
                }

                let visibleTextWidth = max(0, cols - gutterWidth)
                if editor.isCanvasModeActive {
                    let padStart = editor.canvasHorizontalOffset + renderedDisplayWidth
                    var selectedPad = ""
                    var normalPad = ""
                    for screenOffset in renderedDisplayWidth..<visibleTextWidth {
                        let visualCol = editor.canvasHorizontalOffset + screenOffset
                        if editor.isCanvasCellSelected(line: vLine.bufferLineIndex, visualColumn: visualCol) {
                            if !normalPad.isEmpty {
                                lineOutput += normalPad
                                normalPad = ""
                            }
                            selectedPad.append(" ")
                        } else {
                            if !selectedPad.isEmpty {
                                lineOutput += "\u{1B}[7m\(selectedPad)\u{1B}[m"
                                selectedPad = ""
                            }
                            normalPad.append(" ")
                        }
                    }
                    if !selectedPad.isEmpty {
                        lineOutput += "\u{1B}[7m\(selectedPad)\u{1B}[m"
                    }
                    if !normalPad.isEmpty
                        && editor.isCanvasCellSelected(line: vLine.bufferLineIndex, visualColumn: padStart)
                    {
                        lineOutput += normalPad
                    }
                } else if chars.isEmpty && editor.isLineSelected(line: vLine.bufferLineIndex) {
                    lineOutput += "\u{1B}[7m\(String(repeating: " ", count: visibleTextWidth))\u{1B}[m"
                }
            } else if editor.isCanvasModeActive && vIndex == virtualLines.count {
                let gutter = editor.displayConfig.showLineNumbers ? String(repeating: " ", count: gutterWidth) : ""
                lineOutput += "\u{1B}[90m\(gutter)~ \(L10n["chrome.end_of_file"])\u{1B}[0m"
            }

            if editor.isMenuBarActive && boxIdx < dropdownBoxLines.count {
                let sliced = sliceOverlayLine(
                    baseFullLineStr: lineOutput,
                    boxLine: dropdownBoxLines[boxIdx],
                    dropdownStartCol: dropdownStartCol,
                    dropdownBoxWidth: dropdownBoxWidth,
                    cols: cols,
                    showLineNumbers: editor.displayConfig.showLineNumbers,
                    gutterWidth: gutterWidth
                )
                output += sliced + "\r\n"
            } else {
                output += lineOutput + "\r\n"
            }
        }

        return output
    }

    /// Formats line number string for gutter column.
    public func renderLineNumberGutter(
        lineNumber: Int,
        isFirstSubLine: Bool,
        showLineNumbers: Bool,
        isMenuOverlay: Bool = false
    ) -> String {
        guard showLineNumbers else { return "" }
        if isMenuOverlay {
            guard lineNumber > 0 else { return "     " }
            return isFirstSubLine ? String(format: "%4d ", lineNumber) : "   ↳ "
        } else {
            return isFirstSubLine ? String(format: "%4d ", lineNumber) : "   ↳ "
        }
    }

    // MARK: - Component 4: Status & Prompt Line

    /// Renders status message line or interactive prompt line.
    public func renderStatusAndPromptLine(editor: Editor, cols: Int, output: inout String) -> RenderedPrompt {
        output += "\u{1B}[K"  // Clear line
        let renderedPrompt = formatPromptLine(editor: editor, cols: cols)
        if case .none = editor.currentPromptMode {
            output += renderIdleStatusLine(editor: editor, cols: cols)
        } else {
            output += renderedPrompt.text
        }
        output += "\r\n"
        return renderedPrompt
    }

    public func renderIdleStatusLine(editor: Editor, cols: Int) -> String {
        let modeText = editor.modeIndicatorText()
        let activeStatus: String
        if let markStatus = canvasMarkStatusText(editor: editor) {
            activeStatus = markStatus
        } else if let time = editor.statusMessageTime, Date().timeIntervalSince(time) < 5.0 {
            activeStatus = editor.statusMessage
        } else if editor.baseMode == .canvas {
            activeStatus = "(M+V to exit)"
        } else {
            activeStatus = ""
        }

        let combined: String
        if modeText.isEmpty {
            combined = activeStatus
        } else if activeStatus.isEmpty {
            combined = modeText
        } else {
            combined = "\(modeText)  \(activeStatus)"
        }

        guard !combined.isEmpty else {
            return String(repeating: " ", count: max(0, cols))
        }

        let leftPaddingCount = max(0, (cols - combined.displayWidth) / 2)
        let centered = String(repeating: " ", count: leftPaddingCount) + combined
        return centered.paddedToDisplayWidth(cols)
    }

    private func canvasMarkStatusText(editor: Editor) -> String? {
        guard editor.isCanvasModeActive, let mark = editor.canvasBlockMark else { return nil }
        let end = editor.canvasBlockMarkEnd ?? mark
        let startRow = mark.line + 1
        let startCol = mark.visualColumn + 1
        let endRow = end.line + 1
        let endCol = end.visualColumn + 1
        return "\(L10n["status.mark_set"]) (start \(startRow),\(startCol) end \(endRow),\(endCol))"
    }

    // MARK: - Component 5: Dynamic Contextual Help Bar

    /// Renders dynamic Help Bar customized for current PromptMode (2 lines, 2D aligned).
    public func renderHelpBar(cols: Int, promptMode: Editor.PromptMode, editor: Editor? = nil) -> String {
        let helpWidth = min(cols, 80)

        let helpItems1: [(key: String, label: String)]
        let helpItems2: [(key: String, label: String)]

        switch promptMode {
        case .logoMacro:
            if let completionText = editor?.promptCompletionText, !completionText.isEmpty {
                helpItems1 = [("SET", completionText)]
                helpItems2 = [("Tab", L10n["help.complete"]), ("Enter", L10n["help.confirm"]), ("^C", L10n.helpCancel)]
            } else {
                // Custom LOGO macro primitives help bar
                helpItems1 = [
                    ("BOX", "[TEXT][W H][BORDER]"), ("TABLE", "[ROWS][COLS][W]"), ("LINE", "[LEN][ARROW]"),
                ]
                helpItems2 = [
                    ("DRAWBOX", "[TEXT][W H][BORDER]"), ("FILL", "TEXT"), ("Tab", L10n["help.complete"]),
                ]
            }

        case .confirmExitSave, .confirmExternalReload, .confirmCreateTable:
            // Y/N Exit & Confirmation prompt help bar
            helpItems1 = [
                ("Y", L10n["help.yes"]), ("^C", L10n.helpCancel),
            ]
            helpItems2 = [
                ("N", L10n["help.no"])
            ]

        case .saveFilePath, .insertFilePath, .search, .fillText, .tableDimensions, .gotoLine, .spellCheck:
            // Text & File Path Input prompt help bar
            helpItems1 = [
                ("Enter", L10n["help.confirm"]), ("^C", L10n.helpCancel), ("^U", L10n["help.clear"]),
            ]
            helpItems2 = [
                ("←/→", L10n["help.move"]), ("Home/End", L10n["help.jump"]),
            ]

        case .none:
            if editor?.isTableModeActive == true {
                helpItems1 = [
                    ("F1", L10n.helpMenu), ("^O", L10n.helpWriteOut), ("M+T", L10n["help.table_exit"]),
                    ("C+⇧+←/→", L10n["help.cell_width"]), ("^J", L10n["help.center_text"]),
                    ("^K", L10n["help.clear_cell"]),
                ]
                helpItems2 = [
                    ("^X", L10n.helpExit), ("Tab", L10n["help.next_cell"]), ("⇧+Tab", L10n["help.prev_cell"]),
                    ("C+⇧+↑/↓", L10n["help.cell_height"]), ("⇧+Arrow", L10n["help.select_text"]), ("Esc", L10n["help.command"]),
                ]
            } else if editor?.isCanvasModeActive == true {
                helpItems1 = [
                    ("F1", L10n.helpMenu), ("^O", L10n.helpWriteOut), ("^^", L10n["help.mark_block"]),
                    ("^K", L10n["help.cut_block"]), ("⇧+Arrow", L10n["help.line"]),
                ]
                helpItems2 = [
                    ("^X", L10n.helpExit), ("^W", L10n.helpWhereIs), ("M+W", L10n["help.copy_block"]),
                    ("^U", L10n["help.uncut_block"]), ("^⇧+Arrow", L10n["help.arrow"]),
                ]
            } else {
                // Default Nano text editing help bar
                helpItems1 = [
                    ("F1", L10n.helpMenu), ("^O", L10n.helpWriteOut), ("^R", L10n.helpReadFile),
                    ("^Y", L10n.helpPrevPg), ("^K", L10n.helpCutText), ("^C", L10n.helpCurPos),
                ]
                helpItems2 = [
                    ("^X", L10n.helpExit), ("^J", L10n.helpJustify), ("^W", L10n.helpWhereIs),
                    ("^V", L10n.helpNextPg), ("^U", L10n.helpUnCutText), ("^T", L10n.helpToSpell),
                ]
            }
        }

        return renderHelpItemsGrid(cols: cols, helpWidth: helpWidth, items1: helpItems1, items2: helpItems2)
    }

    /// Internal 2D column-alignment layout algorithm for Help Bar items.
    private func renderHelpItemsGrid(
        cols: Int,
        helpWidth: Int,
        items1: [(key: String, label: String)],
        items2: [(key: String, label: String)]
    ) -> String {
        let numCols = max(items1.count, items2.count)
        var maxColWidths: [Int] = []

        for i in 0..<numCols {
            let item1Width: Int
            if i < items1.count {
                item1Width = items1[i].key.count + (items1[i].label.isEmpty ? 0 : 1) + items1[i].label.displayWidth
            } else {
                item1Width = 0
            }

            let item2Width: Int
            if i < items2.count {
                item2Width = items2[i].key.count + (items2[i].label.isEmpty ? 0 : 1) + items2[i].label.displayWidth
            } else {
                item2Width = 0
            }

            maxColWidths.append(max(item1Width, item2Width))
        }

        let totalItemsWidth = maxColWidths.reduce(0, +)
        let gapCount = max(1, numCols - 1)
        let availableGapSpace = helpWidth - totalItemsWidth

        let gapSize = max(1, min(4, availableGapSpace / gapCount))
        let gapStr = String(repeating: " ", count: gapSize)

        func renderLine(_ items: [(key: String, label: String)]) -> String {
            var result = ""
            var currentDisplayWidth = 0

            for i in 0..<items.count {
                let rawWidth = items[i].key.count + (items[i].label.isEmpty ? 0 : 1) + items[i].label.displayWidth
                let targetColWidth = (i < maxColWidths.count) ? maxColWidths[i] : rawWidth

                let itemStr: String
                if items[i].label.isEmpty {
                    itemStr = "\u{1B}[1;36m\(items[i].key)\u{1B}[0m"
                } else {
                    itemStr = "\u{1B}[1;36m\(items[i].key)\u{1B}[0m \(items[i].label)"
                }

                let padCount = max(0, targetColWidth - rawWidth)
                let paddedItem = itemStr + String(repeating: " ", count: padCount)

                if i > 0 {
                    if currentDisplayWidth + gapSize + targetColWidth > helpWidth {
                        break
                    }
                    result += gapStr
                    currentDisplayWidth += gapSize
                }

                if currentDisplayWidth + targetColWidth > helpWidth {
                    break
                }

                result += paddedItem
                currentDisplayWidth += targetColWidth
            }

            let targetCols = max(1, cols - 1)
            if currentDisplayWidth < targetCols {
                result += String(repeating: " ", count: targetCols - currentDisplayWidth)
            }
            return result
        }

        let line1 = "\u{1B}[K" + renderLine(items1)
        let line2 = "\u{1B}[K" + renderLine(items2)
        return line1 + "\r\n" + line2
    }

    // MARK: - Component 6: Cursor Position

    /// Formats terminal ANSI cursor movement sequence.
    public func positionCursor(
        editor: Editor,
        rows: Int,
        cols: Int,
        cursorVLineIdx: Int,
        cursorVColIdx: Int,
        gutterWidth: Int,
        virtualLines: [VirtualLine],
        renderedPrompt: RenderedPrompt
    ) -> String {
        var output = ""
        if editor.isMenuBarActive {
            output += "\u{1B}[\(rows);\(cols)H"
        } else if case .none = editor.currentPromptMode {
            let cursorDisplayWidth: Int
            if editor.isCanvasModeActive {
                cursorDisplayWidth = max(0, editor.canvasVisualColumn - editor.canvasHorizontalOffset)
            } else {
                let vLineText =
                    (cursorVLineIdx >= 0 && cursorVLineIdx < virtualLines.count)
                    ? virtualLines[cursorVLineIdx].text : ""
                let vLineChars = Array(vLineText)
                let clampedCol = max(0, min(cursorVColIdx, vLineChars.count))
                cursorDisplayWidth = vLineChars[..<clampedCol].reduce(0) { $0 + $1.displayWidth }
            }

            let screenRow = (cursorVLineIdx - editor.topVLineIndex) + (editor.displayConfig.showRuler ? 3 : 2)  // +3 if ruler, +2 for title bar
            let screenCol = gutterWidth + cursorDisplayWidth + 1
            output += "\u{1B}[\(screenRow);\(screenCol)H"
        } else {
            let promptRow = rows - 2
            let promptCol = max(1, min(cols, renderedPrompt.cursorCol))
            output += "\u{1B}[\(promptRow);\(promptCol)H"
        }
        output += "\u{1B}[?25h"  // Show cursor
        return output
    }

    // MARK: - Helpers

    /// Computes horizontally scrolled prompt text and terminal cursor column for any prompt mode.
    public func formatPromptLine(editor: Editor, cols: Int) -> RenderedPrompt {
        let promptPrefix: String
        let isConfirmation: Bool

        switch editor.currentPromptMode {
        case .saveFilePath:
            promptPrefix = L10n["prompt.write_name"]
            isConfirmation = false
        case .confirmExitSave:
            promptPrefix = L10n["prompt.confirm_exit_save"]
            isConfirmation = true
        case .confirmExternalReload:
            promptPrefix = L10n["prompt.confirm_reload"]
            isConfirmation = true
        case .confirmCreateTable:
            promptPrefix = "Create 3x3 table at cursor? (y/n): "
            isConfirmation = true
        case .search:
            let defaultHint = editor.lastSearchQuery.isEmpty ? "" : " [default: \(editor.lastSearchQuery)]"
            promptPrefix = "\(L10n["prompt.search"])\(defaultHint): "
            isConfirmation = false
        case .insertFilePath:
            promptPrefix = L10n["prompt.insert_file"]
            isConfirmation = false
        case .spellCheck(let word, _, _, _):
            promptPrefix = String(format: L10n["prompt.edit_spelled_word"], word)
            isConfirmation = false
        case .logoMacro:
            promptPrefix = L10n["prompt.logo"]
            isConfirmation = false
        case .fillText:
            promptPrefix = L10n["prompt.fill_text"]
            isConfirmation = false
        case .tableDimensions:
            promptPrefix = L10n["prompt.table_dimensions"]
            isConfirmation = false
        case .gotoLine:
            promptPrefix = L10n["prompt.goto_line"]
            isConfirmation = false
        case .none:
            return RenderedPrompt(text: "", cursorCol: 1)
        }

        if isConfirmation {
            let boldText = "\u{1B}[1;33m\(promptPrefix)\u{1B}[0m"
            return RenderedPrompt(text: boldText, cursorCol: promptPrefix.displayWidth + 1)
        }

        let prefixWidth = promptPrefix.displayWidth
        let maxInputWidth = max(1, cols - prefixWidth)

        let clampedCursorIdx = max(0, min(editor.promptCursorIndex, editor.promptInputText.count))

        let inputChars = Array(editor.promptInputText)
        let cursorDisplayWidth = inputChars[..<clampedCursorIdx].reduce(0) { $0 + $1.displayWidth }
        let totalInputDisplayWidth = inputChars.reduce(0) { $0 + $1.displayWidth }

        if totalInputDisplayWidth < maxInputWidth {
            let styledText = "\u{1B}[1m\(promptPrefix)\(editor.promptInputText)\u{1B}[0m"
            let cursorCol = prefixWidth + cursorDisplayWidth + 1
            return RenderedPrompt(text: styledText, cursorCol: min(cols, cursorCol))
        }

        var windowStartCol = 0
        if cursorDisplayWidth >= maxInputWidth {
            windowStartCol = cursorDisplayWidth - maxInputWidth + 1
        }

        var visibleChars: [Character] = []
        var currentWidth = 0
        var cursorColInWindow = 0

        for (idx, ch) in inputChars.enumerated() {
            let chWidth = ch.displayWidth
            let charStart = inputChars[..<idx].reduce(0) { $0 + $1.displayWidth }

            if charStart + chWidth <= windowStartCol {
                continue
            }

            if idx == clampedCursorIdx {
                cursorColInWindow = visibleChars.reduce(0) { $0 + $1.displayWidth }
            }

            if currentWidth + chWidth > maxInputWidth {
                break
            }

            visibleChars.append(ch)
            currentWidth += chWidth
        }

        if clampedCursorIdx == inputChars.count {
            cursorColInWindow = visibleChars.reduce(0) { $0 + $1.displayWidth }
        }

        if windowStartCol > 0 && !visibleChars.isEmpty {
            visibleChars[0] = "$"
        }

        let visibleWidth = visibleChars.reduce(0) { $0 + $1.displayWidth }
        if windowStartCol + visibleWidth < totalInputDisplayWidth && visibleChars.count > 1 {
            visibleChars[visibleChars.count - 1] = "$"
        }

        let visibleString = String(visibleChars)
        let styledText = "\u{1B}[1m\(promptPrefix)\(visibleString)\u{1B}[0m"
        let cursorCol = prefixWidth + cursorColInWindow + 1

        return RenderedPrompt(text: styledText, cursorCol: min(cols, cursorCol))
    }

    /// Generates WordStar-style ruler bar string.
    public func generateWordStarRuler(width: Int) -> String {
        generateWordStarRuler(width: width, startColumn: 1, wrapColumn: nil)
    }

    public func generateWordStarRuler(width: Int, startColumn: Int, wrapColumn: Int? = nil) -> String {
        guard width > 0 else { return "" }
        var result = ""
        let firstColumn = max(1, startColumn)
        for col in firstColumn..<(firstColumn + width) {
            if col == wrapColumn {
                result += "<"
            } else if col % 10 == 0 {
                let digit = (col / 10) % 10
                result += "\(digit)"
            } else if col % 5 == 0 {
                result += "!"
            } else {
                result += "-"
            }
        }
        return result
    }

    /// Slices line text (including ANSI syntax highlight sequences) cleanly to insert a 2D dropdown box segment.
    public func sliceOverlayLine(
        baseFullLineStr: String,
        boxLine: String,
        dropdownStartCol: Int,
        dropdownBoxWidth: Int,
        cols: Int,
        isDim: Bool = false,
        showLineNumbers: Bool = false,
        gutterWidth: Int = 0
    ) -> String {
        var leftStr = ""
        var rightStr = ""
        var currentVisCol = 0
        var activeAnsiStyle = ""
        var inAnsi = false
        var currentAnsiSeq = ""

        let rightStartCol = dropdownStartCol + dropdownBoxWidth
        let chars = Array(baseFullLineStr)
        var i = 0

        while i < chars.count {
            let ch = chars[i]

            if ch == "\u{1B}" {
                inAnsi = true
                currentAnsiSeq = "\u{1B}"
                i += 1
                continue
            }

            if inAnsi {
                currentAnsiSeq.append(ch)
                if ch == "m" || ch == "H" || ch == "J" || ch == "K" {
                    inAnsi = false
                    if currentAnsiSeq != "\u{1B}[0m" && currentAnsiSeq != "\u{1B}[m" {
                        activeAnsiStyle = currentAnsiSeq
                    } else {
                        activeAnsiStyle = ""
                    }
                    if currentVisCol < dropdownStartCol {
                        leftStr += currentAnsiSeq
                    } else if currentVisCol >= rightStartCol {
                        rightStr += currentAnsiSeq
                    }
                    currentAnsiSeq = ""
                }
                i += 1
                continue
            }

            let chW = ch.displayWidth
            let nextVisCol = currentVisCol + chW

            if currentVisCol < dropdownStartCol && nextVisCol > dropdownStartCol {
                leftStr += String(repeating: " ", count: dropdownStartCol - currentVisCol)
            } else if currentVisCol < dropdownStartCol {
                leftStr.append(ch)
            } else if currentVisCol < rightStartCol && nextVisCol > rightStartCol {
                rightStr += String(repeating: " ", count: nextVisCol - rightStartCol)
            } else if currentVisCol >= rightStartCol {
                rightStr.append(ch)
            }

            currentVisCol = nextVisCol
            i += 1
        }

        if currentVisCol < dropdownStartCol {
            leftStr += String(repeating: " ", count: dropdownStartCol - currentVisCol)
        }

        if isDim {
            leftStr = "\u{1B}[90m\(leftStr)\u{1B}[0m"
        }

        let remainingRight = max(0, cols - rightStartCol - rightStr.displayWidth)
        if remainingRight > 0 {
            rightStr += String(repeating: " ", count: remainingRight)
        }

        if isDim {
            rightStr = "\u{1B}[90m\(rightStr)\u{1B}[0m"
        } else if !activeAnsiStyle.isEmpty {
            rightStr = "\(activeAnsiStyle)\(rightStr)\u{1B}[0m"
        }

        return leftStr + "\u{1B}[0m" + boxLine + "\u{1B}[0m" + rightStr
    }

    /// Generates 2D dropdown box overlay lines for active menu category.
    public func generateDropdownOverlayLines(editor: Editor, cols: Int) -> (
        startCol: Int, boxWidth: Int, boxLines: [String]
    ) {
        guard editor.isMenuBarActive else { return (0, 0, []) }

        var colOffset = 1
        for idx in 0..<editor.menuBar.categoryIndex {
            let title = L10n[editor.menuBar.categories[idx].titleKey]
            colOffset += title.displayWidth + 4
        }

        let cat = editor.menuBar.currentCategory
        let items = cat.items
        guard !items.isEmpty else { return (colOffset, 0, []) }

        var formattedItems: [String] = []
        for item in items {
            let rawStr = L10n[item.titleKey]
            let parts = rawStr.components(separatedBy: "\t")
            let labelPrefix = (item.isChecked?(editor) ?? false) ? "✓ " : "  "
            let label = labelPrefix + parts[0]
            let shortcut = parts.count > 1 ? parts[1] : ""
            formattedItems.append("\(label)\t\(shortcut)")
        }

        let maxLabelW = formattedItems.map { $0.components(separatedBy: "\t")[0].displayWidth }.max() ?? 10
        let maxShortW = formattedItems.map { $0.components(separatedBy: "\t")[1].displayWidth }.max() ?? 0
        let innerWidth = max(20, maxLabelW + maxShortW + 4)
        let boxWidth = innerWidth + 2

        let topBorder = "\u{1B}[47;30m┌" + String(repeating: "─", count: innerWidth) + "┐\u{1B}[0m"
        let bottomBorder = "\u{1B}[47;30m└" + String(repeating: "─", count: innerWidth) + "┘\u{1B}[0m"

        var boxLines: [String] = [topBorder]
        for (iIdx, item) in items.enumerated() {
            let rawStr = L10n[item.titleKey]
            let parts = rawStr.components(separatedBy: "\t")
            let labelPrefix = (item.isChecked?(editor) ?? false) ? "✓ " : "  "
            let label = labelPrefix + parts[0]
            let shortcut = parts.count > 1 ? parts[1] : ""

            let spaceCount = max(1, innerWidth - label.displayWidth - shortcut.displayWidth - 2)
            let itemLine = " " + label + String(repeating: " ", count: spaceCount) + shortcut + " "

            if iIdx == editor.menuBar.itemIndex {
                boxLines.append("\u{1B}[47;30m│\u{1B}[1;37;44m\(itemLine)\u{1B}[0;47;30m│\u{1B}[0m")
            } else {
                boxLines.append("\u{1B}[47;30m│\(itemLine)│\u{1B}[0m")
            }
        }
        boxLines.append(bottomBorder)

        let clampedStartCol = max(0, min(colOffset, cols - boxWidth))
        return (clampedStartCol, boxWidth, boxLines)
    }
}
