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
        let mainAreaHeight = max(1, rows - (editor.displayConfig.showRuler ? 5 : 4))  // Reserve 1 title bar, (optional 1 ruler), 1 status line, 2 help bar
        let gutterWidth = editor.displayConfig.showLineNumbers ? 5 : 0
        let textWidth = max(10, cols - gutterWidth)

        // Compute Virtual Lines (wrapped visual sub-lines)
        let virtualLines = editor.layoutEngine.computeVirtualLines(from: editor.buffer.lines, viewWidth: textWidth)

        // Find current virtual line index for buffer cursor
        let (cursorVLineIdx, cursorVColIdx) = editor.layoutEngine.getVirtualCursor(
            lineIndex: editor.buffer.lineIndex,
            columnIndex: editor.buffer.columnIndex,
            virtualLines: virtualLines
        )

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
        if editor.displayConfig.showRuler {
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
        output += renderHelpBar(cols: cols, promptMode: editor.currentPromptMode)

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
            var rawMenuStr = " "
            for (idx, cat) in editor.menuBar.categories.enumerated() {
                let catTitle = L10n[cat.titleKey]
                if idx == editor.menuBar.categoryIndex {
                    rawMenuStr += " [ \(catTitle) ] "
                } else {
                    rawMenuStr += "  \(catTitle)  "
                }
            }

            var formattedMenu = "\u{1B}[47;30m "
            for (idx, cat) in editor.menuBar.categories.enumerated() {
                let catTitle = L10n[cat.titleKey]
                if idx == editor.menuBar.categoryIndex {
                    formattedMenu += "\u{1B}[1;37;44m [ \(catTitle) ] \u{1B}[0;47;30m "
                } else {
                    formattedMenu += "  \(catTitle)  "
                }
            }
            let remainingSpaces = max(0, cols - rawMenuStr.displayWidth)
            return formattedMenu + String(repeating: " ", count: remainingSpaces) + "\u{1B}[0m\r\n"
        } else {
            let bufIndexStr = editor.buffers.count > 1 ? " [\(editor.currentBufferIndex + 1)/\(editor.buffers.count)]" : "zago"
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
        let rulerStr = generateWordStarRuler(width: textWidth)
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

            if editor.isMenuBarActive && boxIdx < dropdownBoxLines.count {
                let vLineText = (vIndex < virtualLines.count) ? virtualLines[vIndex].text : ""
                let isFirstSubLine = (vIndex < virtualLines.count) ? (virtualLines[vIndex].subLineIndex == 0) : true
                let lineNumVal = (vIndex < virtualLines.count) ? virtualLines[vIndex].bufferLineIndex + 1 : 0

                let rawLineNumStr = renderLineNumberGutter(
                    lineNumber: lineNumVal,
                    isFirstSubLine: isFirstSubLine,
                    showLineNumbers: editor.displayConfig.showLineNumbers,
                    isMenuOverlay: true
                )

                let plainFullLineStr = rawLineNumStr + vLineText
                let sliced = sliceOverlayLine(
                    baseFullLineStr: plainFullLineStr,
                    boxLine: dropdownBoxLines[boxIdx],
                    dropdownStartCol: dropdownStartCol,
                    dropdownBoxWidth: dropdownBoxWidth,
                    cols: cols,
                    showLineNumbers: editor.displayConfig.showLineNumbers,
                    gutterWidth: gutterWidth
                )
                output += sliced + "\r\n"
            } else {
                var lineOutput = ""
                if vIndex < virtualLines.count {
                    let vLine = virtualLines[vIndex]
                    let isFirstSubLine = (vLine.subLineIndex == 0)

                    // Render Gutter (Line Number or Softwrap Indicator ↳)
                    if editor.displayConfig.showLineNumbers {
                        let lineNumStr = renderLineNumberGutter(
                            lineNumber: vLine.bufferLineIndex + 1,
                            isFirstSubLine: isFirstSubLine,
                            showLineNumbers: true,
                            isMenuOverlay: false
                        )
                        lineOutput += "\u{1B}[90m\(lineNumStr)\u{1B}[0m"  // Dim gray gutter
                    }

                    let currentLanguage =
                        editor.displayConfig.enableSyntaxHighlight
                        ? editor.syntaxHighlighter.getSyntaxForLine(editor: editor, bufferLineIndex: vLine.bufferLineIndex) : nil
                    let tokenTypes = (currentLanguage != nil && editor.selectionMark == nil)
                        ? editor.syntaxHighlighter.tokenTypes(for: vLine.text, syntax: currentLanguage!)
                        : []

                    var activeCellBounds: (left: Int, right: Int)? = nil
                    if editor.isTableModeActive, let cell = editor.currentTableCell,
                       vLine.bufferLineIndex >= cell.innerMinLine && vLine.bufferLineIndex <= cell.innerMaxLine,
                       vLine.bufferLineIndex >= 0 && vLine.bufferLineIndex < editor.buffer.lines.count {
                        let fullLine = editor.buffer.lines[vLine.bufferLineIndex]
                        activeCellBounds = editor.findCellHorizontalBorders(in: fullLine, nearCol: cell.innerMinCol, cell: cell)
                    }

                    let chars = Array(vLine.text)
                    for (cIdxInVLine, ch) in chars.enumerated() {
                        let realCol = vLine.startCol + cIdxInVLine
                        let isCellActive: Bool
                        if let (cellLeft, cellRight) = activeCellBounds {
                            isCellActive = realCol > cellLeft && realCol < cellRight
                        } else {
                            isCellActive = false
                        }

                        if editor.isCharacterSelected(line: vLine.bufferLineIndex, col: realCol) {
                            lineOutput += "\u{1B}[7m\(ch)\u{1B}[m"  // Inverse video for selection
                        } else if isCellActive {
                            lineOutput += "\u{1B}[42;97;1m\(ch)\u{1B}[0m"  // Green bg for active cell
                        } else if cIdxInVLine < tokenTypes.count && tokenTypes[cIdxInVLine] != .normal {
                            let tok = tokenTypes[cIdxInVLine]
                            lineOutput += tok.ansiColor + String(ch) + "\u{1B}[0m"
                        } else {
                            lineOutput += String(ch)
                        }
                    }
                }
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
            if let time = editor.statusMessageTime, Date().timeIntervalSince(time) < 5.0 {
                let msgWidth = editor.statusMessage.displayWidth
                let leftPaddingCount = max(0, (cols - msgWidth) / 2)
                let centeredMsg = String(repeating: " ", count: leftPaddingCount) + editor.statusMessage
                output += centeredMsg.paddedToDisplayWidth(cols)
            }
        } else {
            output += renderedPrompt.text
        }
        output += "\r\n"
        return renderedPrompt
    }

    // MARK: - Component 5: Dynamic Contextual Help Bar

    /// Renders dynamic Help Bar customized for current PromptMode (2 lines, 2D aligned).
    public func renderHelpBar(cols: Int, promptMode: Editor.PromptMode) -> String {
        let helpWidth = min(cols, 80)

        let helpItems1: [(key: String, label: String)]
        let helpItems2: [(key: String, label: String)]

        switch promptMode {
        case .logoMacro:
            // Custom LOGO macro primitives help bar
            helpItems1 = [
                ("BOX", "[TEXT][W H][BORDER]"), ("TABLE", "[ROWS][COLS]"), ("LINE", "[LEN][ARROW]"), ("SHOW", "VALUE")
            ]
            helpItems2 = [
                ("DRAWBOX", "[TEXT][W H][BORDER]"), ("FILL", "TEXT"), ("VLINE", "[LEN][ARROW]"), ("TYPE", "VALUE")
            ]

        case .confirmExitSave, .confirmExternalReload, .confirmCreateTable:
            // Y/N Exit & Confirmation prompt help bar
            helpItems1 = [
                ("Y", "Yes"), ("^C", "Cancel")
            ]
            helpItems2 = [
                ("N", "No")
            ]

        case .saveFilePath, .insertFilePath, .search, .gotoLine, .spellCheck:
            // Text & File Path Input prompt help bar
            helpItems1 = [
                ("^G", "Help"), ("^C", "Cancel")
            ]
            helpItems2 = [
                ("Enter", "Confirm"), ("^U", "Clear")
            ]

        case .none:
            // Default Nano text editing help bar
            helpItems1 = [
                ("^G", L10n.helpGetHelp), ("^O", L10n.helpWriteOut), ("^R", L10n.helpReadFile),
                ("^Y", L10n.helpPrevPg), ("^K", L10n.helpCutText), ("^C", L10n.helpCurPos),
            ]
            helpItems2 = [
                ("^X", L10n.helpExit), ("^J", L10n.helpJustify), ("^W", L10n.helpWhereIs),
                ("^V", L10n.helpNextPg), ("^U", L10n.helpUnCutText), ("^T", L10n.helpToSpell),
            ]
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
            let vLineText = (cursorVLineIdx >= 0 && cursorVLineIdx < virtualLines.count) ? virtualLines[cursorVLineIdx].text : ""
            let vLineChars = Array(vLineText)
            let clampedCol = max(0, min(cursorVColIdx, vLineChars.count))
            let cursorDisplayWidth = vLineChars[..<clampedCol].reduce(0) { $0 + $1.displayWidth }

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
        guard width > 0 else { return "" }
        var result = ""
        for col in 1...width {
            if col % 10 == 0 {
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

    /// Slices plain line text cleanly to insert a 2D dropdown box segment.
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
        let chars = Array(baseFullLineStr)

        var leftChars: [Character] = []
        var w = 0
        var cIdx = 0
        while cIdx < chars.count && w < dropdownStartCol {
            let chW = chars[cIdx].displayWidth
            if w + chW > dropdownStartCol { break }
            leftChars.append(chars[cIdx])
            w += chW
            cIdx += 1
        }
        var leftStr = String(leftChars)
        if w < dropdownStartCol {
            leftStr += String(repeating: " ", count: dropdownStartCol - w)
        }

        if showLineNumbers && gutterWidth > 0 && leftStr.count >= gutterWidth {
            let gutterPart = String(leftStr.prefix(gutterWidth))
            let textPart = String(leftStr.dropFirst(gutterWidth))
            leftStr = "\u{1B}[90m\(gutterPart)\u{1B}[0m\(textPart)"
        } else if isDim {
            leftStr = "\u{1B}[90m\(leftStr)\u{1B}[0m"
        }

        let rightStartCol = dropdownStartCol + dropdownBoxWidth
        var rightStr = ""
        var w2 = 0
        var cIdx2 = 0
        while cIdx2 < chars.count {
            let chW = chars[cIdx2].displayWidth
            if w2 >= rightStartCol {
                rightStr.append(chars[cIdx2])
            }
            w2 += chW
            cIdx2 += 1
        }
        let remainingRight = max(0, cols - rightStartCol - rightStr.displayWidth)
        if remainingRight > 0 {
            rightStr += String(repeating: " ", count: remainingRight)
        }

        if isDim {
            rightStr = "\u{1B}[90m\(rightStr)\u{1B}[0m"
        }
        return leftStr + boxLine + rightStr
    }

    /// Generates 2D dropdown box overlay lines for active menu category.
    public func generateDropdownOverlayLines(editor: Editor, cols: Int) -> (startCol: Int, boxWidth: Int, boxLines: [String]) {
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
            let label = parts[0]
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
            let label = parts[0]
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
