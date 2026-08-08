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

    private var lastRenderedLines: [String] = []
    private var lastRows: Int = 0
    private var lastCols: Int = 0

    /// Returns whether the screen line buffer cache is currently valid/populated.
    public var isScreenCacheValid: Bool {
        !lastRenderedLines.isEmpty
    }

    /// Invalidates the screen line buffer cache, forcing a full redraw on the next render pass.
    public func invalidateScreenCache() {
        lastRenderedLines.removeAll()
    }

    /// Renders complete static screen ANSI output for given ScreenGeometry.
    public func render(editor: Editor, geometry: ScreenGeometry) -> String {
        let (screenLines, cursorPosStr) = renderScreenLines(editor: editor, geometry: geometry)
        return ANSIStyle.disableLineWrap + ANSIStyle.cursorHome + screenLines.joined(separator: "\r\n") + cursorPosStr
    }

    /// Renders screen using Double Buffering / Screen Line Diffing for given ScreenGeometry.
    public func renderDiff(editor: Editor, geometry: ScreenGeometry) -> String {
        let (screenLines, cursorPosStr) = renderScreenLines(editor: editor, geometry: geometry)
        let isDiffable =
            (geometry.rows == lastRows && geometry.cols == lastCols && lastRenderedLines.count == screenLines.count)

        var output = ""
        if !isDiffable {
            output += ANSIStyle.disableLineWrap + ANSIStyle.cursorHome
            for i in 0..<screenLines.count {
                output += screenLines[i] + ANSIStyle.clearLine
                if i < screenLines.count - 1 {
                    output += "\r\n"
                }
            }
            output += cursorPosStr
        } else {
            for i in 0..<screenLines.count {
                if screenLines[i] != lastRenderedLines[i] {
                    output += "\(ANSIStyle.disableLineWrap)\u{1B}[\(i + 1);1H" + screenLines[i] + ANSIStyle.clearLine
                }
            }
            output += cursorPosStr
        }

        lastRenderedLines = screenLines
        lastRows = geometry.rows
        lastCols = geometry.cols
        return output
    }

    /// Renders complete static screen output ANSI string for given terminal rows and cols.
    public func render(editor: Editor, rows: Int, cols: Int) -> String {
        render(editor: editor, geometry: ScreenGeometry(rows: rows, cols: cols, editor: editor))
    }

    /// Renders screen using Double Buffering for given terminal rows and cols.
    public func renderDiff(editor: Editor, rows: Int, cols: Int) -> String {
        renderDiff(editor: editor, geometry: ScreenGeometry(rows: rows, cols: cols, editor: editor))
    }

    private func renderScreenLines(editor: Editor, geometry: ScreenGeometry) -> (
        screenLines: [String], cursorPosStr: String
    ) {
        let rows = geometry.rows
        let cols = geometry.cols
        let mainAreaHeight = geometry.mainAreaHeight
        let gutterWidth = geometry.gutterWidth
        let textWidth = geometry.textWidth
        let showSubLineInfo = shouldRenderSubLineInfo(editor: editor, textWidth: textWidth)

        let virtualLines: [VirtualLine]
        let virtualLineStartIndex: Int
        let totalVirtualLineCount: Int
        let (cursorVLineIdx, cursorVColIdx): (Int, Int)
        if editor.isCanvasModeActive {
            virtualLines = editor.layoutEngine.computeCanvasLines(from: editor.buffer.lines)
            virtualLineStartIndex = 0
            totalVirtualLineCount = virtualLines.count
            cursorVLineIdx = max(0, min(editor.buffer.lineIndex, max(0, virtualLines.count - 1)))
            cursorVColIdx = editor.buffer.columnIndex
        } else {
            if showSubLineInfo {
                virtualLines = editor.layoutEngine.computeVirtualLines(from: editor.buffer.lines, viewWidth: textWidth)
                virtualLineStartIndex = 0
                totalVirtualLineCount = virtualLines.count
                (cursorVLineIdx, cursorVColIdx) = editor.layoutEngine.getVirtualCursor(
                    lineIndex: editor.buffer.lineIndex,
                    columnIndex: editor.buffer.columnIndex,
                    virtualLines: virtualLines
                )
            } else {
                let viewport = editor.layoutEngine.computeVirtualViewport(
                    from: editor.buffer.lines,
                    viewWidth: textWidth,
                    topVirtualLineIndex: editor.topVLineIndex,
                    height: mainAreaHeight,
                    cursorLineIndex: editor.buffer.lineIndex,
                    cursorColumnIndex: editor.buffer.columnIndex,
                    computeTotalLineCount: false
                )
                virtualLines = viewport.lines
                virtualLineStartIndex = viewport.startVirtualIndex
                totalVirtualLineCount = viewport.totalVirtualLineCount
                cursorVLineIdx = viewport.cursorVirtualLineIndex
                cursorVColIdx = viewport.cursorVirtualColumnIndex
            }
        }

        var screenLines: [String] = []

        // 1. Title Bar or Top Menu Bar Component
        let titleLineStr = renderTitleOrMenuBar(editor: editor, cols: cols)
        let titleLines = titleLineStr.components(separatedBy: "\r\n").filter { !$0.isEmpty }
        screenLines.append(contentsOf: titleLines)

        let (dropdownStartCol, dropdownBoxWidth, dropdownBoxLines) = generateDropdownOverlayLines(
            editor: editor, cols: cols)

        // 2. WordStar Ruler Bar Component (Optional)
        if geometry.showRuler {
            let rulerLineStr = renderRulerBar(
                editor: editor,
                textWidth: textWidth,
                gutterWidth: gutterWidth,
                cols: cols,
                dropdownStartCol: dropdownStartCol,
                dropdownBoxWidth: dropdownBoxWidth,
                dropdownBoxLines: dropdownBoxLines
            )
            let rulerLines = rulerLineStr.components(separatedBy: "\r\n").filter { !$0.isEmpty }
            screenLines.append(contentsOf: rulerLines)
        }

        // 3. Main Text Area Component (with Line Numbers Gutter)
        let mainTextStr = renderMainTextArea(
            editor: editor,
            mainAreaHeight: mainAreaHeight,
            gutterWidth: gutterWidth,
            showSubLineInfo: showSubLineInfo,
            virtualLines: virtualLines,
            virtualLineStartIndex: virtualLineStartIndex,
            totalVirtualLineCount: totalVirtualLineCount,
            cols: cols,
            dropdownStartCol: dropdownStartCol,
            dropdownBoxWidth: dropdownBoxWidth,
            dropdownBoxLines: dropdownBoxLines
        )
        let mainLines = mainTextStr.components(separatedBy: "\r\n").filter { !$0.isEmpty }
        screenLines.append(contentsOf: mainLines)

        // 4. Status & Prompt Line Component
        var statusStr = ""
        let renderedPrompt = renderStatusAndPromptLine(editor: editor, cols: cols, output: &statusStr)
        let statusLines = statusStr.components(separatedBy: "\r\n").filter { !$0.isEmpty }
        screenLines.append(contentsOf: statusLines)

        // 5. Dynamic Contextual Help Bar Component
        let helpStr = renderHelpBar(cols: cols, promptMode: editor.currentPromptMode, editor: editor)
        let helpLines = helpStr.components(separatedBy: "\r\n").filter { !$0.isEmpty }
        screenLines.append(contentsOf: helpLines)

        // 6. Terminal Cursor Positioning Component
        let cursorPosStr = positionCursor(
            editor: editor,
            rows: rows,
            cols: cols,
            cursorVLineIdx: cursorVLineIdx,
            cursorVColIdx: cursorVColIdx,
            gutterWidth: gutterWidth,
            virtualLines: virtualLines,
            virtualLineStartIndex: virtualLineStartIndex,
            renderedPrompt: renderedPrompt
        )

        return (screenLines, cursorPosStr)
    }

    // MARK: - Main Text Area & Line Numbers Gutter

    /// Renders the central text area containing virtual wrapped lines, line numbers gutter, and overlay elements.
    func renderMainTextArea(
        editor: Editor,
        mainAreaHeight: Int,
        gutterWidth: Int,
        showSubLineInfo: Bool? = nil,
        virtualLines: [VirtualLine],
        virtualLineStartIndex: Int = 0,
        totalVirtualLineCount: Int? = nil,
        cols: Int,
        dropdownStartCol: Int,
        dropdownBoxWidth: Int,
        dropdownBoxLines: [String]
    ) -> String {
        var output = ""
        let resolvedShowSubLineInfo =
            showSubLineInfo ?? shouldRenderSubLineInfo(editor: editor, textWidth: max(0, cols - gutterWidth))
        let subLineCounts = makeSubLineCounts(from: virtualLines)
        var tokenTypesCache: [Int: [SyntaxTokenType]] = [:]

        for i in 0..<mainAreaHeight {
            let vIndex = editor.topVLineIndex + i
            let localVIndex = vIndex - virtualLineStartIndex
            output += "\u{1B}[K"  // Clear line

            let boxIdx = editor.displayConfig.showRuler ? (i + 1) : i

            var lineOutput = ""
            if localVIndex >= 0 && localVIndex < virtualLines.count {
                let vLine = virtualLines[localVIndex]
                let isFirstSubLine = (vLine.subLineIndex == 0)

                // Render Gutter (Line Number or Softwrap Indicator ↳)
                if editor.displayConfig.showLineNumbers && !editor.buffer.isDirectoryBuffer {
                    let lineNumStr = renderLineNumberGutter(
                        editor: editor,
                        lineNumber: vLine.bufferLineIndex + 1,
                        isFirstSubLine: isFirstSubLine,
                        showLineNumbers: true,
                        isMenuOverlay: editor.isMenuBarActive && boxIdx < dropdownBoxLines.count
                    )
                    lineOutput += lineNumStr
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

                let fullLineText =
                    (vLine.bufferLineIndex >= 0 && vLine.bufferLineIndex < editor.buffer.lines.count)
                    ? editor.buffer.lines[vLine.bufferLineIndex]
                    : renderedLineText

                let currentLanguage =
                    editor.displayConfig.enableSyntaxHighlight
                    ? editor.syntaxForLine(at: vLine.bufferLineIndex)
                    : nil
                let tokenTypes =
                    (currentLanguage != nil)
                    ? (tokenTypesCache[vLine.bufferLineIndex]
                        ?? {
                            let computed = editor.syntaxHighlighter.tokenTypes(
                                for: fullLineText, syntax: currentLanguage!)
                            tokenTypesCache[vLine.bufferLineIndex] = computed
                            return computed
                        }())
                    : []

                var activeCellBounds: (left: Int, right: Int)? = nil
                if editor.isTableModeActive, let cell = editor.currentTableCell,
                    vLine.bufferLineIndex >= cell.innerMinLine && vLine.bufferLineIndex <= cell.innerMaxLine,
                    vLine.bufferLineIndex >= 0 && vLine.bufferLineIndex < editor.buffer.lines.count
                {
                    let fullLine = editor.buffer.lines[vLine.bufferLineIndex]
                    activeCellBounds = TableModeController.findCellHorizontalBorders(
                        in: fullLine, nearCol: cell.innerMinCol, cell: cell)
                }

                var renderedDisplayWidth = 0
                let visibleTextWidth = max(0, cols - gutterWidth)

                let hangingIndent = (vLine.subLineIndex > 0 && editor.displayConfig.listWrapIndent) ? LayoutEngine.calculateListHangingIndent(in: fullLineText) : 0
                if hangingIndent > 0 {
                    lineOutput += String(repeating: " ", count: hangingIndent)
                    renderedDisplayWidth += hangingIndent
                }

                let chars = Array(renderedLineText)
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
                        lineOutput += ch.ansiStyled(style: ANSIStyle.inverse, endStyle: ANSIStyle.resetShort)
                    } else if !editor.isCanvasModeActive
                        && editor.buffer.isCharacterSelected(line: vLine.bufferLineIndex, col: realCol)
                    {
                        lineOutput += ch.ansiStyled(style: ANSIStyle.inverse, endStyle: ANSIStyle.resetShort)  // Inverse video for selection
                    } else if !editor.isCanvasModeActive
                        && editor.searchController.isSearchMatchCharacter(line: vLine.bufferLineIndex, col: realCol)
                    {
                        lineOutput += ch.ansiStyled(style: ANSIStyle.canvasCursor)
                    } else if isCellActive {
                        lineOutput += ch.ansiStyled(style: ANSIStyle.canvasActiveCell)  // Green bg for active cell
                    } else if realCol < tokenTypes.count && tokenTypes[realCol] != .normal {
                        let tok = tokenTypes[realCol]
                        lineOutput += ch.ansiStyled(style: tok.ansiColor)
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
                                lineOutput += selectedPad.ansiStyled(
                                    style: ANSIStyle.inverse, endStyle: ANSIStyle.resetShort)
                                selectedPad = ""
                            }
                            normalPad.append(" ")
                        }
                    }
                    if !selectedPad.isEmpty {
                        lineOutput += selectedPad.ansiStyled(style: ANSIStyle.inverse, endStyle: ANSIStyle.resetShort)
                    }
                    if !normalPad.isEmpty
                        && editor.isCanvasCellSelected(line: vLine.bufferLineIndex, visualColumn: padStart)
                    {
                        lineOutput += normalPad
                    }
                } else if chars.isEmpty && editor.buffer.isLineSelected(line: vLine.bufferLineIndex) {
                    lineOutput += String(repeating: " ", count: visibleTextWidth).ansiStyled(
                        style: ANSIStyle.inverse, endStyle: ANSIStyle.resetShort)
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
            } else if editor.isCanvasModeActive && vIndex == (totalVirtualLineCount ?? virtualLines.count) {
                let gutter = editor.displayConfig.showLineNumbers ? String(repeating: " ", count: gutterWidth) : ""
                lineOutput += "\(gutter)~ \(editor.l10n["chrome.end_of_file"])".ansiStyled(style: ANSIStyle.dimGray)
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
            label = "[\(String(format: editor.l10n["subline.char_count"], charCount))]"
        } else {
            label = "\(virtualLine.subLineIndex + 1)"
        }

        return " " + label.ansiStyled(style: ANSIStyle.dimGray)
    }

    /// Formats line number string for gutter column.
    func renderLineNumberGutter(
        editor: Editor,
        lineNumber: Int,
        isFirstSubLine: Bool,
        showLineNumbers: Bool,
        isMenuOverlay: Bool = false
    ) -> String {
        guard showLineNumbers else { return "" }
        let lineIdx = lineNumber - 1

        if isMenuOverlay {
            guard lineNumber > 0 else { return "     " }
            let fmt = String(format: "%4d ", lineNumber)
            let sub = "   ↳ "
            return isFirstSubLine ? fmt.ansiStyled(style: ANSIStyle.dimGray) : sub.ansiStyled(style: ANSIStyle.dimGray)
        }

        guard isFirstSubLine else {
            return "   ↳ ".ansiStyled(style: ANSIStyle.dimGray)
        }

        let numStr = String(format: "%4d ", lineNumber)
        let hasGitDiff = editor.displayConfig.showGitDiff && editor.gitDiffInfo.hasDiffMarkers && !editor.buffer.isScratchBuffer

        if hasGitDiff {
            let status = editor.gitDiffInfo.lineStatuses[lineIdx] ?? .unmodified
            let isDeleted = editor.gitDiffInfo.deletedLineIndices.contains(lineIdx)

            switch status {
            case .added:
                return numStr.ansiStyled(color: .brightGreen)
            case .modified:
                return numStr.ansiStyled(color: .brightYellow)
            case .unmodified:
                if isDeleted {
                    return numStr.ansiStyled(color: .brightRed)
                } else {
                    return numStr.ansiStyled(color: .brightBlack)
                }
            case .deletedBefore:
                return numStr.ansiStyled(color: .brightRed)
            }
        } else {
            return numStr.ansiStyled(color: .brightBlack)
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
        virtualLineStartIndex: Int = 0,
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
                let localCursorVLineIdx = cursorVLineIdx - virtualLineStartIndex
                let vLineText =
                    (localCursorVLineIdx >= 0 && localCursorVLineIdx < virtualLines.count)
                    ? virtualLines[localCursorVLineIdx].text : ""
                let vLineChars = Array(vLineText)
                let effectiveCol: Int
                if editor.isTableModeActive, let cell = editor.currentTableCell,
                    editor.buffer.lineIndex >= cell.innerMinLine && editor.buffer.lineIndex <= cell.innerMaxLine
                {
                    let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(
                        in: vLineText, nearCol: cursorVColIdx, cell: cell)
                    if cursorVColIdx >= rightBorder {
                        effectiveCol = max(leftBorder + 1, rightBorder - 1)
                    } else {
                        effectiveCol = cursorVColIdx
                    }
                } else {
                    effectiveCol = cursorVColIdx
                }
                let clampedCol = max(0, min(effectiveCol, vLineChars.count))
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
