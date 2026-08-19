import ANSIStyle
import Config
import Foundation
import Syntax
import TextEncoding
import TextMetrics

extension Renderer {
    /// Renders the top Title Bar or Menu Bar based on active state.
    func renderTitleOrMenuBar(editor: Editor, cols: Int) -> String {
        editor.isMenuBarActive
            ? renderMenuBar(editor: editor, cols: cols)
            : renderTitleBar(editor: editor, cols: cols)
    }

    /// Renders active top Menu Bar categories line.
    func renderMenuBar(editor: Editor, cols: Int) -> String {
        editor.menuBar.updateCategories(for: editor)
        func menuSegment(title: String, isSelected: Bool) -> String {
            isSelected ? "[\(title)]" : " \(title) "
        }

        var rawMenuStr = " "
        for (idx, cat) in editor.menuBar.categories.enumerated() {
            let catTitle = editor.l10n[cat.titleKey]
            rawMenuStr += menuSegment(title: catTitle, isSelected: idx == editor.menuBar.categoryIndex)
        }

        var formattedMenu = "\(ANSIStyle.menuDefault) "
        for (idx, cat) in editor.menuBar.categories.enumerated() {
            let catTitle = editor.l10n[cat.titleKey]
            let styledTitle = menuTitleWithUnderlinedHotkey(
                catTitle,
                hotkeyChar: cat.hotkeyChar,
                appendMissingHotkey: false
            )
            if idx == editor.menuBar.categoryIndex {
                formattedMenu +=
                    "\(ANSIStyle.menuSelected)\(menuSegment(title: styledTitle, isSelected: true))\(ANSIStyle.menuReset)"
            } else {
                formattedMenu += menuSegment(title: styledTitle, isSelected: false)
            }
        }
        let remainingSpaces = max(0, cols - rawMenuStr.displayWidth)
        return formattedMenu + String(repeating: " ", count: remainingSpaces) + "\(ANSIStyle.reset)\r\n"
    }

    func menuTitleWithUnderlinedHotkey(
        _ title: String,
        hotkeyChar: Character,
        appendMissingHotkey: Bool
    ) -> String {
        let hotkey = String(hotkeyChar).lowercased()
        var output = ""
        var didUnderline = false
        for character in title {
            if !didUnderline, String(character).lowercased() == hotkey {
                output += "\(ANSIStyle.underline)\(character)\(ANSIStyle.underlineOff)"
                didUnderline = true
            } else {
                output.append(character)
            }
        }
        if !didUnderline, appendMissingHotkey {
            let displayHotkey = displayMenuHotkey(hotkeyChar)
            output += " (\(ANSIStyle.underline)\(displayHotkey)\(ANSIStyle.underlineOff))"
        }
        return output
    }

    func displayMenuHotkey(_ hotkeyChar: Character) -> String {
        let hotkey = String(hotkeyChar)
        return hotkey.rangeOfCharacter(from: .letters) == nil ? hotkey : hotkey.uppercased()
    }

    /// Renders standard top Title Bar line containing app version, filename, modified badge, and git branch.
    func renderTitleBar(editor: Editor, cols: Int) -> String {
        let bufCountStr =
            editor.buffers.count > 1 ? " [\(editor.currentBufferIndex + 1)/\(editor.buffers.count)]" : ""
        let leftText = "  zago \(ZagoVersion.current)\(bufCountStr)"
        let formatTagStr = editor.buffer.lineEnding.statusTag.map { " \($0)" } ?? ""
        let centerText = (editor.buffer.filePath ?? editor.l10n.newBuffer) + formatTagStr
        let branchTextStr: String
        if editor.displayConfig.showGitDiff, let branch = editor.gitDiffInfo.branchName, !branch.isEmpty {
            branchTextStr = " [\(branch)]"
        } else {
            branchTextStr = ""
        }

        let modifiedBadgeStr = editor.buffer.isModified ? "\(editor.l10n.modified)" : ""
        let rightText: String
        if !modifiedBadgeStr.isEmpty && !branchTextStr.isEmpty {
            rightText = "\(modifiedBadgeStr)\(branchTextStr)  "
        } else if !modifiedBadgeStr.isEmpty {
            rightText = "\(modifiedBadgeStr)  "
        } else if !branchTextStr.isEmpty {
            rightText = "\(branchTextStr)  "
        } else {
            rightText = "  "
        }

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
        return paddedTitle.ansiStyled(style: ANSIStyle.inverse, endStyle: ANSIStyle.resetShort) + "\r\n"
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
        var lineStr = ANSIStyle.clearLine
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
            lineStr +=
                "\(ANSIStyle.dimGray)\(String(repeating: " ", count: gutterWidth))\(styledRulerStr)\(ANSIStyle.reset)\r\n"
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
            activeStatus = editor.l10n["status.canvas_mode_hint"]
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
        guard editor.isCanvasModeActive, let mark = editor.buffer.canvasBlockMark else { return nil }
        let end = editor.buffer.canvasBlockMarkEnd ?? mark
        let startRow = mark.line + 1
        let startCol = mark.visualColumn + 1
        let endRow = end.line + 1
        let endCol = end.visualColumn + 1
        return "\(editor.l10n["status.mark_set"]) (start \(startRow),\(startCol) end \(endRow),\(endCol))"
    }

    // MARK: - Dynamic Contextual Help Bar

    /// Renders dynamic Help Bar customized for current PromptMode (2 lines, 2D aligned).
    func renderHelpBar(cols: Int, promptMode: Editor.PromptMode, editor: Editor? = nil) -> String {
        let helpWidth = max(1, cols - 1)
        let language = editor?.language ?? .detectSystemLanguage()
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
                    ("Esc", tr("help.go_back")),
                    ("BOX", "[TEXT][W H][BORDER]"),
                    ("LINE", "[LEN][ARROW]"),
                    ("FILL", "TEXT"),
                    ("TABLE", "[ROWS][COLS][W]"),
                ]
                helpItems2 = [
                    ("Tab", tr("help.complete")),
                    ("DRAWBOX", "[TEXT][W H][BORDER]"),
                    ("VLINE", "[LEN][ARROW]"),
                    ("INSET", "TEXT"),
                    ("REPEAT", "TIMES ACTION"),
                ]
            }

        case .confirmExitSave, .confirmExternalReload, .confirmEncodingFallback:
            helpItems1 = [
                ("Y", tr("help.yes")), ("^C", tr("help.cancel")),
            ]
            helpItems2 = [
                ("N", tr("help.no"))
            ]

        case .confirmReplace:
            helpItems1 = [
                ("Y", tr("help.yes")), ("A", tr("help.all")),
            ]
            helpItems2 = [
                ("N", tr("help.no")), ("^C", tr("help.cancel")),
            ]

        case .saveFilePath, .insertFilePath, .search, .replaceSearch, .replaceWith, .fillText, .tableDimensions,
            .gotoLine, .spellCheck,
            .logoReadWord, .logoReadChar:
            if editor?.keymapManager.activePreset == .modern {
                helpItems1 = [
                    ("Enter", tr("help.confirm")), ("^G", tr("help.cancel")), ("^X", tr("help.cut_text")),
                ]
                helpItems2 = [
                    ("^C", tr("help.copy_text")), ("^V", tr("help.uncut_text")), ("←/→", tr("help.move")),
                    ("Home/End", tr("help.jump")),
                ]
            } else {
                helpItems1 = [
                    ("Enter", tr("help.confirm")), ("^C", tr("help.cancel")), ("^K", tr("help.cut_text")),
                ]
                helpItems2 = [
                    ("^U", tr("help.uncut_text")), ("M+W", tr("help.copy_text")), ("←/→", tr("help.move")),
                    ("Home/End", tr("help.jump")),
                ]
            }

        case .describeKey:
            helpItems1 = []
            helpItems2 = []

        case .none:
            func keyLabel(for cmd: CommandID, fallback: String) -> String {
                guard let editor else { return fallback }
                return editor.keymapManager.primaryKeyLabel(for: cmd, in: editor.currentMode) ?? fallback
            }

            if editor?.isTableModeActive == true {
                helpItems1 = [
                    (keyLabel(for: .menuShow, fallback: "F1"), tr("help.menu")),
                    ("Esc", tr("help.commands")),
                    (keyLabel(for: .tableNextCell, fallback: "Tab"), tr("help.next_cell")),
                    ("C+⇧+←/→", tr("help.cell_width")),
                    ("Arrow", tr("help.move")),
                    (keyLabel(for: .tableCenterText, fallback: "^J"), tr("help.center_text")),
                ]
                helpItems2 = [
                    (keyLabel(for: .fileExit, fallback: "^X"), tr("help.exit")),
                    (keyLabel(for: .tableToggle, fallback: "F7"), tr("help.table_exit")),
                    (keyLabel(for: .tablePrevCell, fallback: "⇧+Tab"), tr("help.prev_cell")),
                    ("C+⇧+↑/↓", tr("help.cell_height")),
                    ("⇧+Arrow", tr("help.select_text")),
                    (keyLabel(for: .tableClearCell, fallback: "^K"), tr("help.clear_cell")),
                ]
            } else if editor?.isCanvasModeActive == true {
                helpItems1 = [
                    (keyLabel(for: .menuShow, fallback: "F1"), tr("help.menu")),
                    (keyLabel(for: .canvasToggle, fallback: "F8"), tr("help.text_mode")),
                    ("ESC", tr("help.commands")),
                    ("⇧+Arrow", tr("help.line")),
                    (keyLabel(for: .fileWriteOut, fallback: "^O"), tr("help.write_out")),
                    ("^^/M+B", tr("help.mark_block")),
                    (keyLabel(for: .editCut, fallback: "^K"), tr("help.cut_block")),
                    (keyLabel(for: .editCopy, fallback: "M+W"), tr("help.copy_block")),
                ]
                helpItems2 = [
                    (keyLabel(for: .fileExit, fallback: "^X"), tr("help.exit")),
                    (keyLabel(for: .tableToggle, fallback: "F7"), tr("help.table_mode")),
                    (keyLabel(for: .editUndo, fallback: "^Z"), tr("help.undo")),
                    ("^⇧+Arrow", tr("help.arrow")),
                    (keyLabel(for: .searchWhereIs, fallback: "^W"), tr("help.where_is")),
                    ("^G", tr("help.clear_mark")),
                    (keyLabel(for: .editUncut, fallback: "^U"), tr("help.uncut_block")),
                    ("M+S", tr("help.border_style")),
                ]
            } else {
                if editor?.proposalQueue.isEmpty == false {
                    helpItems1 = [
                        (keyLabel(for: .proposalAccept, fallback: "M+A"), tr("help.ai_accept")),
                        (keyLabel(for: .proposalNext, fallback: "M+P"), tr("help.ai_next_proposal")),
                        (keyLabel(for: .menuShow, fallback: "F1"), tr("help.menu")),
                        (keyLabel(for: .fileWriteOut, fallback: "^O"), tr("help.write_out")),
                        (keyLabel(for: .editCut, fallback: "^K"), tr("help.cut_text")),
                        (keyLabel(for: .movePgup, fallback: "PgUp"), tr("help.prev_pg")),
                    ]
                    helpItems2 = [
                        (keyLabel(for: .proposalReject, fallback: "M+R"), tr("help.ai_reject")),
                        (keyLabel(for: .proposalPrev, fallback: "M+P"), tr("help.ai_previous_proposal")),
                        (keyLabel(for: .fileExit, fallback: "^X"), tr("help.exit")),
                        (keyLabel(for: .searchWhereIs, fallback: "^W"), tr("help.where_is")),
                        (keyLabel(for: .editUncut, fallback: "^U"), tr("help.uncut_text")),
                        (keyLabel(for: .movePgdn, fallback: "PgDn"), tr("help.next_pg")),
                    ]
                } else if editor?.keymapManager.activePreset == .modern {
                    helpItems1 = [
                        (keyLabel(for: .menuShow, fallback: "F1"), tr("help.menu")),
                        (keyLabel(for: .canvasToggle, fallback: "F8"), tr("help.canvas_mode")),
                        (keyLabel(for: .fileSave, fallback: "^S"), tr("help.save")),
                        (keyLabel(for: .editCut, fallback: "^X"), tr("help.cut_text")),
                        (keyLabel(for: .editCopy, fallback: "^C"), tr("help.copy_text")),
                        (keyLabel(for: .editUncut, fallback: "^V"), tr("help.uncut_text")),
                        (keyLabel(for: .editUndo, fallback: "^Z"), tr("help.undo")),
                        (keyLabel(for: .movePgup, fallback: "PgUp"), tr("help.prev_pg")),
                        (keyLabel(for: .editEvalLogo, fallback: "^E"), tr("help.run_logo")),
                    ]
                    helpItems2 = [
                        (keyLabel(for: .fileExit, fallback: "^Q"), tr("help.exit")),
                        (keyLabel(for: .tableToggle, fallback: "F7"), tr("help.table_mode")),
                        (keyLabel(for: .editJustify, fallback: "^J"), tr("help.justify")),
                        (keyLabel(for: .searchWhereIs, fallback: "^F"), tr("help.where_is")),
                        (keyLabel(for: .searchReplace, fallback: "^H"), tr("help.replace")),
                        (keyLabel(for: .selectAll, fallback: "^A"), tr("help.select_all")),
                        (keyLabel(for: .editRedo, fallback: "^Y"), tr("help.redo")),
                        (keyLabel(for: .movePgdn, fallback: "PgDn"), tr("help.next_pg")),
                        (keyLabel(for: .fileWriteOut, fallback: "^O"), tr("help.write_out")),
                    ]
                } else {
                    helpItems1 = [
                        (keyLabel(for: .menuShow, fallback: "F1"), tr("help.menu")),
                        (keyLabel(for: .canvasToggle, fallback: "F8"), tr("help.canvas_mode")),
                        ("ESC", tr("help.commands")),
                        (keyLabel(for: .fileWriteOut, fallback: "^O"), tr("help.write_out")),
                        (keyLabel(for: .searchWhereIs, fallback: "^W"), tr("help.where_is")),
                        (keyLabel(for: .editCut, fallback: "^K"), tr("help.cut_text")),
                        (keyLabel(for: .editCopy, fallback: "M+W"), tr("help.copy_text")),
                        (keyLabel(for: .movePgup, fallback: "^Y"), tr("help.prev_pg")),
                        (keyLabel(for: .editEvalLogo, fallback: "^Q"), tr("help.run_logo")),
                    ]
                    helpItems2 = [
                        (keyLabel(for: .fileExit, fallback: "^X"), tr("help.exit")),
                        (keyLabel(for: .tableToggle, fallback: "F7"), tr("help.table_mode")),
                        (keyLabel(for: .editJustify, fallback: "^J"), tr("help.justify")),
                        (keyLabel(for: .fileInsert, fallback: "^R"), tr("help.read_file")),
                        (keyLabel(for: .searchReplace, fallback: "^\\"), tr("help.replace")),
                        (keyLabel(for: .editUncut, fallback: "^U"), tr("help.uncut_text")),
                        (keyLabel(for: .editUndo, fallback: "^Z"), tr("help.undo")),
                        (keyLabel(for: .movePgdn, fallback: "^V"), tr("help.next_pg")),
                        (keyLabel(for: .editSpell, fallback: "^T"), tr("help.to_spell")),
                    ]
                }
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
        let styled = visibleText.ansiStyled(style: ANSIStyle.boldYellow)
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
                    itemStr = items[i].key.ansiStyled(style: ANSIStyle.boldCyan)
                } else {
                    itemStr = items[i].key.ansiStyled(style: ANSIStyle.boldCyan) + " \(items[i].label)"
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

        let line1 = ANSIStyle.clearLine + renderLine(items1)
        let line2 = ANSIStyle.clearLine + renderLine(items2)
        return line1 + "\r\n" + line2
    }

    // MARK: - Prompt & Ruler Helpers

    /// Computes horizontally scrolled prompt text and terminal cursor column for any prompt mode.
    func formatPromptLine(editor: Editor, cols: Int) -> RenderedPrompt {
        let promptPrefix: String
        let isConfirmation: Bool

        switch editor.currentPromptMode {
        case .saveFilePath:
            promptPrefix = editor.l10n["prompt.write_name"]
            isConfirmation = false
        case .confirmExitSave:
            promptPrefix = editor.l10n["prompt.confirm_exit_save"]
            isConfirmation = true
        case .confirmExternalReload:
            promptPrefix = editor.l10n["prompt.confirm_reload"]
            isConfirmation = true
        case .confirmEncodingFallback(let originalEncoding, _):
            let name = TextEncodingDetector.displayName(for: originalEncoding)
            promptPrefix = String(format: editor.l10n["prompt.encoding_fallback"], name)
            isConfirmation = true
        case .search:
            let defaultHint = editor.lastSearchQuery.isEmpty ? "" : " [default: \(editor.lastSearchQuery)]"
            promptPrefix = "\(editor.l10n["prompt.search"])\(defaultHint): "
            isConfirmation = false
        case .replaceSearch:
            let defaultHint = editor.lastSearchQuery.isEmpty ? "" : " [default: \(editor.lastSearchQuery)]"
            promptPrefix = "\(editor.l10n["prompt.replace_search"])\(defaultHint): "
            isConfirmation = false
        case .replaceWith:
            promptPrefix = editor.l10n["prompt.replace_with"]
            isConfirmation = false
        case .confirmReplace:
            promptPrefix = editor.l10n["prompt.confirm_replace"]
            isConfirmation = true
        case .insertFilePath:
            promptPrefix = editor.l10n["prompt.insert_file"]
            isConfirmation = false
        case .spellCheck(let word, _, _, _):
            promptPrefix = String(format: editor.l10n["prompt.edit_spelled_word"], word)
            isConfirmation = false
        case .logoMacro:
            promptPrefix = editor.l10n["prompt.logo"]
            isConfirmation = false
        case .fillText:
            promptPrefix = editor.l10n["prompt.fill_text"]
            isConfirmation = false
        case .tableDimensions:
            promptPrefix = editor.l10n["prompt.table_dimensions"]
            isConfirmation = false
        case .gotoLine:
            promptPrefix = editor.l10n["prompt.goto_line"]
            isConfirmation = false
        case .describeKey:
            promptPrefix = editor.l10n["prompt.describe_key"]
            isConfirmation = false
        case .logoReadWord(let prompt):
            let p = prompt.isEmpty ? editor.l10n["prompt.logo_input"] : (prompt.hasSuffix(" ") ? prompt : prompt + " ")
            promptPrefix = p
            isConfirmation = false
        case .logoReadChar(let prompt):
            let p =
                prompt.isEmpty ? editor.l10n["prompt.logo_read_key"] : (prompt.hasSuffix(" ") ? prompt : prompt + " ")
            promptPrefix = p
            isConfirmation = false
        case .none:
            return RenderedPrompt(text: "", cursorCol: 1)
        }

        if isConfirmation {
            let boldText = promptPrefix.ansiStyled(style: ANSIStyle.boldYellow)
            return RenderedPrompt(text: boldText, cursorCol: promptPrefix.displayWidth + 1)
        }

        let prefixWidth = promptPrefix.displayWidth
        let maxInputWidth = max(1, cols - prefixWidth)

        let clampedCursorIdx = max(0, min(editor.promptCursorIndex, editor.promptInputText.count))

        let inputChars = Array(editor.promptInputText)
        let cursorDisplayWidth = inputChars[..<clampedCursorIdx].reduce(0) { $0 + $1.displayWidth }
        let totalInputDisplayWidth = inputChars.reduce(0) { $0 + $1.displayWidth }
        let selectionRange = editor.promptController.selectionRange()

        if totalInputDisplayWidth < maxInputWidth {
            let styledInput = styledPromptInput(
                inputChars.enumerated().map { (index: $0.offset, character: $0.element) },
                selectionRange: selectionRange
            )
            let styledText = "\(ANSIStyle.bold)\(promptPrefix)\(styledInput)\(ANSIStyle.reset)"
            let cursorCol = prefixWidth + cursorDisplayWidth + 1
            return RenderedPrompt(text: styledText, cursorCol: min(cols, cursorCol))
        }

        var windowStartCol = 0
        if cursorDisplayWidth >= maxInputWidth {
            windowStartCol = cursorDisplayWidth - maxInputWidth + 1
        }

        var visibleChars: [(index: Int?, character: Character)] = []
        var currentWidth = 0
        var cursorColInWindow = 0

        for (idx, ch) in inputChars.enumerated() {
            let chWidth = ch.displayWidth
            let charStart = inputChars[..<idx].reduce(0) { $0 + $1.displayWidth }

            if charStart + chWidth <= windowStartCol {
                continue
            }

            if idx == clampedCursorIdx {
                cursorColInWindow = visibleChars.reduce(0) { $0 + $1.character.displayWidth }
            }

            if currentWidth + chWidth > maxInputWidth {
                break
            }

            visibleChars.append((index: idx, character: ch))
            currentWidth += chWidth
        }

        if clampedCursorIdx == inputChars.count {
            cursorColInWindow = visibleChars.reduce(0) { $0 + $1.character.displayWidth }
        }

        if windowStartCol > 0 && !visibleChars.isEmpty {
            visibleChars[0] = (index: nil, character: "$")
        }

        let visibleWidth = visibleChars.reduce(0) { $0 + $1.character.displayWidth }
        if windowStartCol + visibleWidth < totalInputDisplayWidth && visibleChars.count > 1 {
            visibleChars[visibleChars.count - 1] = (index: nil, character: "$")
        }

        let styledInput = styledPromptInput(visibleChars, selectionRange: selectionRange)
        let styledText = "\(ANSIStyle.bold)\(promptPrefix)\(styledInput)\(ANSIStyle.reset)"
        let cursorCol = prefixWidth + cursorColInWindow + 1

        return RenderedPrompt(text: styledText, cursorCol: min(cols, cursorCol))
    }

    private func styledPromptInput(
        _ chars: [(index: Int?, character: Character)],
        selectionRange: Range<Int>?
    ) -> String {
        var output = ""
        var isSelected = false
        for entry in chars {
            let selected = entry.index.map { selectionRange?.contains($0) == true } ?? false
            if selected != isSelected {
                output += selected ? ANSIStyle.boldInverse : ANSIStyle.inverseOff
                isSelected = selected
            }
            output.append(entry.character)
        }
        if isSelected {
            output += ANSIStyle.inverseOff
        }
        return output
    }

    /// Generates WordStar-style ruler bar string.
    func generateWordStarRuler(width: Int, startColumn: Int = 1, wrapColumn: Int? = nil) -> String {
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
        rulerStr.replacingOccurrences(of: "<", with: "\(ANSIStyle.boldYellow)<\(ANSIStyle.dimGray)")
    }
}
