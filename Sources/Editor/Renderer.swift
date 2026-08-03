import Foundation
import Syntax
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
        let showSubLineInfo = shouldRenderSubLineInfo(editor: editor, textWidth: textWidth)

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
        } else if editor.isCanvasModeActive && cursorVLineIdx >= editor.topVLineIndex + max(1, mainAreaHeight - 1) {
            editor.topVLineIndex = cursorVLineIdx - max(0, mainAreaHeight - 2)
        } else if !editor.isCanvasModeActive && cursorVLineIdx >= editor.topVLineIndex + mainAreaHeight {
            editor.topVLineIndex = cursorVLineIdx - mainAreaHeight + 1
        }
        if editor.isCanvasModeActive {
            let maxCanvasTop = max(0, virtualLines.count - max(1, mainAreaHeight - 1))
            editor.topVLineIndex = max(0, min(editor.topVLineIndex, maxCanvasTop))
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
            showSubLineInfo: showSubLineInfo,
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

    // MARK: - Main Text Area & Line Numbers Gutter

    /// Renders the central text area containing virtual wrapped lines, line numbers gutter, and overlay elements.
    func renderMainTextArea(
        editor: Editor,
        mainAreaHeight: Int,
        gutterWidth: Int,
        showSubLineInfo: Bool? = nil,
        virtualLines: [VirtualLine],
        cols: Int,
        dropdownStartCol: Int,
        dropdownBoxWidth: Int,
        dropdownBoxLines: [String]
    ) -> String {
        var output = ""
        let resolvedShowSubLineInfo =
            showSubLineInfo ?? shouldRenderSubLineInfo(editor: editor, textWidth: max(0, cols - gutterWidth))
        let subLineCounts = makeSubLineCounts(from: virtualLines)

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
                let visibleTextWidth = max(0, cols - gutterWidth)
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
                    } else if !editor.isCanvasModeActive
                        && editor.isSearchMatchCharacter(line: vLine.bufferLineIndex, col: realCol)
                    {
                        lineOutput += "\u{1B}[43;30m\(ch)\u{1B}[0m"
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

                if let subLineInfo = renderSubLineInfo(
                    editor: editor,
                    virtualLine: vLine,
                    subLineCount: subLineCounts[vLine.bufferLineIndex] ?? 1,
                    isEnabled: resolvedShowSubLineInfo
                ) {
                    let targetWidth = editor.layoutEngine.wrapColumn ?? renderedDisplayWidth
                    lineOutput += String(repeating: " ", count: max(0, targetWidth - renderedDisplayWidth))
                    lineOutput += subLineInfo
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

    func shouldRenderSubLineInfo(editor: Editor, textWidth: Int) -> Bool {
        guard editor.displayConfig.showSubLineNumbers,
            let wrapColumn = editor.layoutEngine.wrapColumn,
            textWidth >= wrapColumn,
            !editor.isCanvasModeActive,
            !editor.isTableModeActive,
            !editor.buffer.isDirectoryBuffer
        else {
            return false
        }
        return true
    }

    func makeSubLineCounts(from virtualLines: [VirtualLine]) -> [Int: Int] {
        var counts: [Int: Int] = [:]
        for vLine in virtualLines {
            counts[vLine.bufferLineIndex] = max(counts[vLine.bufferLineIndex] ?? 0, vLine.subLineIndex + 1)
        }
        return counts
    }

    func renderSubLineInfo(
        editor: Editor,
        virtualLine: VirtualLine,
        subLineCount: Int,
        isEnabled: Bool
    ) -> String? {
        guard isEnabled, subLineCount > 1 else { return nil }

        let label: String
        if virtualLine.subLineIndex == 0 {
            let charCount =
                editor.buffer.lines.indices.contains(virtualLine.bufferLineIndex)
                ? editor.buffer.lines[virtualLine.bufferLineIndex].count
                : 0
            label = "[\(String(format: L10n["subline.char_count"], charCount))]"
        } else {
            label = "\(virtualLine.subLineIndex + 1)"
        }

        return " \u{1B}[90m\(label)\u{1B}[0m"
    }

    /// Formats line number string for gutter column.
    func renderLineNumberGutter(
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

    // MARK: - Cursor Positioning

    /// Formats terminal ANSI cursor movement sequence.
    func positionCursor(
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
}
