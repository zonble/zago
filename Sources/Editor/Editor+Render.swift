import Foundation

extension Editor {
    /// Refreshes screen rendering (Title bar, WordStar ruler, Virtual lines, Prompt/Status line, Help bar, Cursor position).
    func refreshScreen() {
        let (rows, cols) = terminal.getWindowSize()
        let output = generateScreenOutput(rows: rows, cols: cols)
        print(output, terminator: "")
        fflush(nil)
    }

    /// Generates full screen ANSI output string for given terminal rows and cols dimensions.
    func generateScreenOutput(rows: Int, cols: Int) -> String {
        let mainAreaHeight = max(1, rows - (displayConfig.showRuler ? 5 : 4)) // Reserve 1 title bar, (optional 1 ruler), 1 status line, 2 help bar
        let textWidth = max(10, cols - 5) // 5 columns reserved for line number gutter ("1234 ")

        // Compute Virtual Lines (wrapped visual sub-lines)
        let virtualLines = layoutEngine.computeVirtualLines(from: buffer.lines, viewWidth: textWidth)

        // Find current virtual line index for buffer cursor
        let (cursorVLineIdx, cursorVColIdx) = layoutEngine.getVirtualCursor(
            lineIndex: buffer.lineIndex,
            columnIndex: buffer.columnIndex,
            virtualLines: virtualLines
        )

        // Adjust topVLineIndex viewport scrolling offset
        if cursorVLineIdx < topVLineIndex {
            topVLineIndex = cursorVLineIdx
        } else if cursorVLineIdx >= topVLineIndex + mainAreaHeight {
            topVLineIndex = cursorVLineIdx - mainAreaHeight + 1
        }

        var output = ""
        output += "\u{1B}[H" // Reset cursor to (1, 1)

        // 1. Title Bar (Inverted Colors, centered filename)
        let leftText = "  se"
        let centerText = buffer.filePath ?? L10n.newBuffer
        let rightText = buffer.isModified ? "\(L10n.modified)  " : "  "

        let leftW = leftText.displayWidth
        let centerW = centerText.displayWidth
        let rightW = rightText.displayWidth

        let targetCenterStart = max(leftW + 1, (cols - centerW) / 2)
        let leftPaddingCount = max(0, targetCenterStart - leftW)
        let leftSideWidth = leftW + leftPaddingCount

        let rightPaddingCount = max(0, cols - leftSideWidth - centerW - rightW)

        let titleStr = leftText
            + String(repeating: " ", count: leftPaddingCount)
            + centerText
            + String(repeating: " ", count: rightPaddingCount)
            + rightText

        let paddedTitle = titleStr.paddedToDisplayWidth(cols)
        output += "\u{1B}[7m\(paddedTitle)\u{1B}[m\r\n"

        // 1.5 Optional WordStar Ruler Bar
        let gutterWidth = 5
        if displayConfig.showRuler {
            let rulerStr = generateWordStarRuler(width: textWidth)
            output += "\u{1B}[K\u{1B}[90m     \(rulerStr)\u{1B}[0m\r\n"
        }

        // 2. Main Edit Area (Virtual Lines Rendering)
        for i in 0..<mainAreaHeight {
            let vIndex = topVLineIndex + i
            output += "\u{1B}[K" // Clear line

            if vIndex < virtualLines.count {
                let vLine = virtualLines[vIndex]
                let isFirstSubLine = (vLine.subLineIndex == 0)

                // Gutter (Line Number or Softwrap Indicator ↳)
                let lineNumStr: String
                if isFirstSubLine {
                    lineNumStr = String(format: "%4d ", vLine.bufferLineIndex + 1)
                } else {
                    lineNumStr = "   ↳ "
                }

                output += "\u{1B}[90m\(lineNumStr)\u{1B}[0m" // Dim gray gutter
                let currentLanguage = displayConfig.enableSyntaxHighlight ? syntaxHighlighter.detectLanguage(for: buffer.filePath) : nil
                if let lang = currentLanguage, selectionMark == nil {
                    output += syntaxHighlighter.highlight(line: vLine.text, syntax: lang)
                } else {
                    let chars = Array(vLine.text)
                    for (cIdxInVLine, ch) in chars.enumerated() {
                        let realCol = vLine.startCol + cIdxInVLine
                        if isCharacterSelected(line: vLine.bufferLineIndex, col: realCol) {
                            output += "\u{1B}[7m\(ch)\u{1B}[m" // Inverse video for selected characters
                        } else {
                            output += String(ch)
                        }
                    }
                }
            }
            output += "\r\n"
        }

        // 3. Status / Prompt Line
        output += "\u{1B}[K" // Clear line
        switch currentPromptMode {
        case .saveFilePath:
            let prompt = L10n["prompt.write_name"]
            output += "\u{1B}[1m\(prompt)\(promptInputText)_\u{1B}[0m"
        case .confirmExitSave:
            let prompt = L10n["prompt.confirm_exit_save"]
            output += "\u{1B}[1;33m\(prompt)\u{1B}[0m"
        case .confirmExternalReload:
            let prompt = L10n["prompt.confirm_reload"]
            output += "\u{1B}[1;33m\(prompt)\u{1B}[0m"
        case .search:
            let searchStr = L10n["prompt.search"]
            let defaultHint = lastSearchQuery.isEmpty ? "" : " [default: \(lastSearchQuery)]"
            output += "\u{1B}[1m\(searchStr)\(defaultHint): \(promptInputText)_\u{1B}[0m"
        case .insertFilePath:
            let prompt = L10n["prompt.insert_file"]
            output += "\u{1B}[1m\(prompt)\(promptInputText)_\u{1B}[0m"
        case .spellCheck(let word, _, _, _):
            let promptTemplate = L10n["prompt.edit_spelled_word"]
            let prompt = String(format: promptTemplate, word)
            output += "\u{1B}[1m\(prompt)\(promptInputText)_\u{1B}[0m"
        case .none:
            if let time = statusMessageTime, Date().timeIntervalSince(time) < 5.0 {
                let msgWidth = statusMessage.displayWidth
                let leftPaddingCount = max(0, (cols - msgWidth) / 2)
                let centeredMsg = String(repeating: " ", count: leftPaddingCount) + statusMessage
                output += centeredMsg.paddedToDisplayWidth(cols)
            }
        }
        output += "\r\n"

        // 4. Nano Key Help Bar (2 lines) - 2D column-aligned, dynamic gap spacing, no leading space
        output += formatHelpBar(cols: cols)

        // 5. Position Terminal Cursor (accounting for CJK/wide character display width)
        let vLineText = virtualLines[cursorVLineIdx].text
        let vLineChars = Array(vLineText)
        let clampedCol = max(0, min(cursorVColIdx, vLineChars.count))
        let cursorDisplayWidth = vLineChars[..<clampedCol].reduce(0) { $0 + $1.displayWidth }

        let screenRow = (cursorVLineIdx - topVLineIndex) + (displayConfig.showRuler ? 3 : 2) // +3 if ruler, +2 for title bar
        let screenCol = gutterWidth + cursorDisplayWidth + 1
        output += "\u{1B}[\(screenRow);\(screenCol)H"
        output += "\u{1B}[?25h" // Show cursor

        return output
    }

    /// Formats Nano help bar lines with 2D column alignment and dynamic gap spacing (Bold Cyan keys, no leading space).
    func formatHelpBar(cols: Int) -> String {
        let helpWidth = min(cols, 80)
        let helpItems1: [(key: String, label: String)] = [
            ("^G", L10n.helpGetHelp), ("^O", L10n.helpWriteOut), ("^R", L10n.helpReadFile),
            ("^Y", L10n.helpPrevPg),  ("^K", L10n.helpCutText), ("^C", L10n.helpCurPos)
        ]
        let helpItems2: [(key: String, label: String)] = [
            ("^X", L10n.helpExit),     ("^J", L10n.helpJustify),  ("^W", L10n.helpWhereIs),
            ("^V", L10n.helpNextPg),  ("^U", L10n.helpUnCutText), ("^T", L10n.helpToSpell)
        ]

        let numCols = min(helpItems1.count, helpItems2.count)
        var maxColWidths: [Int] = []
        for i in 0..<numCols {
            let w1 = helpItems1[i].key.count + 1 + helpItems1[i].label.displayWidth
            let w2 = helpItems2[i].key.count + 1 + helpItems2[i].label.displayWidth
            maxColWidths.append(max(w1, w2))
        }

        let totalItemsWidth = maxColWidths.reduce(0, +)
        let gapCount = max(1, numCols - 1)
        let availableGapSpace = helpWidth - totalItemsWidth

        let gapSize = max(1, min(2, availableGapSpace / gapCount))
        let gapStr = String(repeating: " ", count: gapSize)

        func renderLine(_ items: [(key: String, label: String)]) -> String {
            var result = ""
            var currentDisplayWidth = 0

            for i in 0..<items.count {
                let rawWidth = items[i].key.count + 1 + items[i].label.displayWidth
                let targetColWidth = (i < maxColWidths.count) ? maxColWidths[i] : rawWidth
                let itemStr = "\u{1B}[1;36m\(items[i].key)\u{1B}[0m \(items[i].label)"
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

            if currentDisplayWidth < cols {
                result += String(repeating: " ", count: cols - currentDisplayWidth)
            }
            return result
        }

        let line1 = "\u{1B}[K" + renderLine(helpItems1)
        let line2 = "\u{1B}[K" + renderLine(helpItems2)
        return line1 + "\r\n" + line2
    }

    /// Generates WordStar-style ruler bar (----!----1----!----2----!----3...)
    func generateWordStarRuler(width: Int) -> String {
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

    /// Returns the VirtualLine structure containing current cursor.
    func getVirtualLineForCursor() -> VirtualLine {
        let (_, cols) = terminal.getWindowSize()
        let textWidth = max(10, cols - 5)
        let virtualLines = layoutEngine.computeVirtualLines(from: buffer.lines, viewWidth: textWidth)

        let (cursorVLineIdx, _) = layoutEngine.getVirtualCursor(
            lineIndex: buffer.lineIndex,
            columnIndex: buffer.columnIndex,
            virtualLines: virtualLines
        )

        if cursorVLineIdx >= 0 && cursorVLineIdx < virtualLines.count {
            return virtualLines[cursorVLineIdx]
        }

        return VirtualLine(
            bufferLineIndex: buffer.lineIndex,
            subLineIndex: 0,
            text: buffer.lines[buffer.lineIndex],
            startCol: 0,
            endCol: buffer.lines[buffer.lineIndex].count
        )
    }

    /// Maps virtual line index and target visual display column width to real buffer cursor.
    func getBufferCursorForVisualColumn(
        vLineIndex: Int,
        visualCol: Int
    ) -> (lineIndex: Int, columnIndex: Int) {
        let (_, cols) = terminal.getWindowSize()
        let textWidth = max(10, cols - 5)
        let virtualLines = layoutEngine.computeVirtualLines(from: buffer.lines, viewWidth: textWidth)

        guard vLineIndex >= 0 && vLineIndex < virtualLines.count else {
            return (buffer.lineIndex, buffer.columnIndex)
        }

        let targetVLine = virtualLines[vLineIndex]
        let chars = Array(targetVLine.text)

        var curW = 0
        var charIdx = 0

        for (idx, ch) in chars.enumerated() {
            let w = ch.displayWidth
            if curW + w > visualCol {
                break
            }
            curW += w
            charIdx = idx + 1
        }

        let realCol = min(targetVLine.startCol + charIdx, targetVLine.endCol)
        return (targetVLine.bufferLineIndex, realCol)
    }

    /// Moves cursor by virtual line rows (sub-lines), supporting Home/End/Arrow key navigation.
    func moveCursorVirtual(deltaRow: Int) {
        let (_, cols) = terminal.getWindowSize()
        let textWidth = max(10, cols - 5)
        let virtualLines = layoutEngine.computeVirtualLines(from: buffer.lines, viewWidth: textWidth)

        let (cursorVLineIdx, _) = layoutEngine.getVirtualCursor(
            lineIndex: buffer.lineIndex,
            columnIndex: buffer.columnIndex,
            virtualLines: virtualLines
        )

        let targetVLineIdx = max(0, min(cursorVLineIdx + deltaRow, virtualLines.count - 1))
        let currentVLine = virtualLines[cursorVLineIdx]
        let vLineChars = Array(currentVLine.text)
        let clampedCol = max(0, min(buffer.columnIndex - currentVLine.startCol, vLineChars.count))
        let visualCol = vLineChars[..<clampedCol].reduce(0) { $0 + $1.displayWidth }

        let (newLineIdx, newColIdx) = getBufferCursorForVisualColumn(
            vLineIndex: targetVLineIdx,
            visualCol: visualCol
        )

        buffer.lineIndex = newLineIdx
        buffer.columnIndex = newColIdx
    }
}
