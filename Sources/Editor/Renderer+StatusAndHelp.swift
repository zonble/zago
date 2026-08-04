import Config
import Foundation
import TextEncoding
import Syntax
import TextMetrics

extension Renderer {
    // MARK: - Title Bar or Top Menu Bar

    /// Renders the top Title Bar (or active Menu Bar categories).
    func renderTitleOrMenuBar(editor: Editor, cols: Int) -> String {
        if editor.isMenuBarActive {
            editor.menuBar.updateCategories(for: editor)
            func menuSegment(title: String, isSelected: Bool) -> String {
                isSelected ? "[\(title)]" : " \(title) "
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
            let bufCountStr =
                editor.buffers.count > 1 ? " [\(editor.currentBufferIndex + 1)/\(editor.buffers.count)]" : ""
            let leftText = "  zago \(ZagoVersion.current)\(bufCountStr)"
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

    // MARK: - WordStar Ruler Bar

    /// Renders the WordStar ruler line (----!----1----!----2...)
    func renderRulerBar(
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
            let styledRulerStr = highlightWrapColumnMarker(in: rulerStr)
            lineStr += "\u{1B}[90m\(String(repeating: " ", count: gutterWidth))\(styledRulerStr)\u{1B}[0m\r\n"
        }
        return lineStr
    }

    // MARK: - Status & Prompt Line

    /// Renders status message line or interactive prompt line.
    func renderStatusAndPromptLine(editor: Editor, cols: Int, output: inout String) -> RenderedPrompt {
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

    func renderIdleStatusLine(editor: Editor, cols: Int) -> String {
        let modeText = editor.modeIndicatorText()
        let activeStatus: String
        if let markStatus = canvasMarkStatusText(editor: editor) {
            activeStatus = markStatus
        } else if let time = editor.statusMessageTime, Date().timeIntervalSince(time) < 5.0 {
            activeStatus = editor.statusMessage
        } else if editor.baseMode == .canvas {
            activeStatus = L10n["status.canvas_mode_hint"]
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

    func canvasMarkStatusText(editor: Editor) -> String? {
        guard editor.isCanvasModeActive, let mark = editor.canvasBlockMark else { return nil }
        let end = editor.canvasBlockMarkEnd ?? mark
        let startRow = mark.line + 1
        let startCol = mark.visualColumn + 1
        let endRow = end.line + 1
        let endCol = end.visualColumn + 1
        return "\(L10n["status.mark_set"]) (start \(startRow),\(startCol) end \(endRow),\(endCol))"
    }

    // MARK: - Dynamic Contextual Help Bar

    /// Renders dynamic Help Bar customized for current PromptMode (2 lines, 2D aligned).
    func renderHelpBar(cols: Int, promptMode: Editor.PromptMode, editor: Editor? = nil) -> String {
        let helpWidth = min(cols, 80)
        let language = editor?.usesExplicitLanguage == true ? editor?.language ?? L10n.currentLanguage : L10n.currentLanguage
        func tr(_ key: String) -> String {
            L10n.string(key, language: language)
        }

        let helpItems1: [(key: String, label: String)]
        let helpItems2: [(key: String, label: String)]

        switch promptMode {
        case .logoMacro:
            if let completionText = editor?.promptCompletionText, !completionText.isEmpty {
                let line1 = formatCompletionLineText(completionText, width: helpWidth)
                let grid = renderHelpItemsGrid(
                    cols: cols,
                    helpWidth: helpWidth,
                    items1: [],
                    items2: [("Tab", tr("help.complete")), ("Enter", tr("help.confirm")), ("^C", tr("help.cancel"))]
                )
                let line2 = grid.components(separatedBy: "\r\n").last ?? grid
                return line1 + "\r\n" + line2
            } else {
                helpItems1 = [
                    ("BOX", "[TEXT][W H][BORDER]"), ("TABLE", "[ROWS][COLS][W]"), ("LINE", "[LEN][ARROW]"),
                ]
                helpItems2 = [
                    ("DRAWBOX", "[TEXT][W H][BORDER]"), ("FILL", "TEXT"), ("Tab", tr("help.complete")),
                ]
            }


        case .confirmExitSave, .confirmExternalReload, .confirmEncodingFallback:
            helpItems1 = [
                ("Y", tr("help.yes")), ("^C", tr("help.cancel")),
            ]
            helpItems2 = [
                ("N", tr("help.no"))
            ]

        case .saveFilePath, .insertFilePath, .search, .fillText, .tableDimensions, .gotoLine, .spellCheck:
            helpItems1 = [
                ("Enter", tr("help.confirm")), ("^C", tr("help.cancel")), ("^U", tr("help.clear")),
            ]
            helpItems2 = [
                ("←/→", tr("help.move")), ("Home/End", tr("help.jump")),
            ]

        case .none:
            if editor?.isTableModeActive == true {
                helpItems1 = [
                    ("F1", tr("help.menu")), ("^O", tr("help.write_out")), ("M+T", tr("help.table_exit")),
                    ("C+⇧+←/→", tr("help.cell_width")), ("^J", tr("help.center_text")),
                    ("^K", tr("help.clear_cell")),
                ]
                helpItems2 = [
                    ("^X", tr("help.exit")), ("Tab", tr("help.next_cell")), ("⇧+Tab", tr("help.prev_cell")),
                    ("C+⇧+↑/↓", tr("help.cell_height")), ("⇧+Arrow", tr("help.select_text")),
                    ("Esc", tr("help.command")),
                ]
            } else if editor?.isCanvasModeActive == true {
                helpItems1 = [
                    ("F1", tr("help.menu")), ("^O", tr("help.write_out")), ("M+B", tr("help.mark_block")),
                    ("^K", tr("help.cut_block")), ("⇧+Arrow", tr("help.line")),
                ]
                helpItems2 = [
                    ("^X", tr("help.exit")), ("^W", tr("help.where_is")), ("M+W", tr("help.copy_block")),
                    ("^U", tr("help.uncut_block")), ("^⇧+Arrow", tr("help.arrow")),
                ]
            } else {
                helpItems1 = [
                    ("F1", tr("help.menu")), ("^O", tr("help.write_out")), ("^R", tr("help.read_file")),
                    ("^Y", tr("help.prev_pg")), ("^K", tr("help.cut_text")), ("^C", tr("help.cur_pos")),
                ]
                helpItems2 = [
                    ("^X", tr("help.exit")), ("^J", tr("help.justify")), ("^W", tr("help.where_is")),
                    ("^V", tr("help.next_pg")), ("^U", tr("help.uncut_text")), ("^T", tr("help.to_spell")),
                ]
            }
        }

        return renderHelpItemsGrid(cols: cols, helpWidth: helpWidth, items1: helpItems1, items2: helpItems2)
    }

    /// Formats single-line completion candidates text for Help Bar line 1.
    func formatCompletionLineText(_ text: String, width: Int) -> String {
        let displayWidth = text.displayWidth
        let visibleText: String
        if displayWidth > width {
            visibleText = text.visualSlice(startVisualColumn: 0, width: width).text
        } else {
            visibleText = text
        }
        let styled = "\u{1B}[1;33m\(visibleText)\u{1B}[0m"
        let padCount = max(0, width - visibleText.displayWidth)
        return styled + String(repeating: " ", count: padCount)
    }

    /// Internal 2D column-alignment layout algorithm for Help Bar items.

    func renderHelpItemsGrid(
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

    // MARK: - Prompt & Ruler Helpers

    /// Computes horizontally scrolled prompt text and terminal cursor column for any prompt mode.
    func formatPromptLine(editor: Editor, cols: Int) -> RenderedPrompt {
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
        case .confirmEncodingFallback(let originalEncoding, _):
            let name = TextEncodingDetector.displayName(for: originalEncoding)
            promptPrefix = String(format: L10n["prompt.encoding_fallback"], name)
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
    func generateWordStarRuler(width: Int) -> String {
        generateWordStarRuler(width: width, startColumn: 1, wrapColumn: nil)
    }

    func generateWordStarRuler(width: Int, startColumn: Int, wrapColumn: Int? = nil) -> String {
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

    func highlightWrapColumnMarker(in rulerStr: String) -> String {
        rulerStr.replacingOccurrences(of: "<", with: "\u{1B}[1;33m<\u{1B}[90m")
    }
}
