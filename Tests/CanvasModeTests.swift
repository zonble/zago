import Foundation
import Testing
import TextMetrics

@testable import Editor

@Test func testCanvasModeShiftArrowDrawsBoxLines() throws {
    let editor = Editor()
    editor.switchToCanvasMode()

    editor.processKey(.shiftArrowRight)
    #expect(editor.buffer.lines[0] == "─")
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 1)

    editor.processKey(.shiftArrowDown)
    #expect(editor.buffer.lines[0] == "─┐")
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 1)
}

@Test func testCanvasModeLineFusionStepByStep() throws {
    // shift + right case: ─│ -> ─┤ -> ─┼
    do {
        let editor = Editor()
        editor.buffer.lines = ["─│"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0
        editor.switchToCanvasMode()
        editor.syncCanvasCursorFromBuffer()

        // 1st shift + right: moves from ─ to │. │ becomes ┤, cursor lands on ┤.
        editor.processKey(.shiftArrowRight)
        #expect(editor.buffer.lines[0] == "─┤")
        #expect(editor.canvasVisualColumn == 1)

        // 2nd shift + right: moves from ┤ to right. ┤ becomes ┼, cursor lands on col 2.
        editor.processKey(.shiftArrowRight)
        #expect(editor.buffer.lines[0] == "─┼")
        #expect(editor.canvasVisualColumn == 2)
    }

    // shift + down case: │ over ─ -> ┴ -> ┼
    do {
        let editor = Editor()
        editor.buffer.lines = ["│", "─"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0
        editor.switchToCanvasMode()
        editor.syncCanvasCursorFromBuffer()

        // 1st shift + down: moves from │ to ─. ─ becomes ┴, cursor lands on ┴.
        editor.processKey(.shiftArrowDown)
        #expect(editor.buffer.lines[0] == "│")
        #expect(editor.buffer.lines[1] == "┴")
        #expect(editor.buffer.lineIndex == 1)

        // 2nd shift + down: moves from ┴ down. ┴ becomes ┼, cursor lands on line 2.
        editor.processKey(.shiftArrowDown)
        #expect(editor.buffer.lines[1] == "┼")
        #expect(editor.buffer.lineIndex == 2)
    }

    // shift + left case: │─ -> ├─ -> ┼─
    do {
        let editor = Editor()
        editor.buffer.lines = [" │─"]
        editor.buffer.lineIndex = 0
        editor.canvasVisualColumn = 2
        editor.syncCanvasCursorToBuffer()
        editor.switchToCanvasMode()

        // 1st shift + left: moves from ─ to │. │ becomes ├, cursor lands on ├.
        editor.processKey(.shiftArrowLeft)
        #expect(editor.buffer.lines[0] == " ├─")
        #expect(editor.canvasVisualColumn == 1)

        // 2nd shift + left: moves from ├ left. ├ becomes ┼, cursor lands on col 0 (space).
        editor.processKey(.shiftArrowLeft)
        #expect(editor.buffer.lines[0] == " ┼─")
        #expect(editor.canvasVisualColumn == 0)
    }

    // shift + up case: ─ under │ -> ┬ -> ┼
    do {
        let editor = Editor()
        editor.buffer.lines = ["", "─", "│"]
        editor.buffer.lineIndex = 2
        editor.buffer.columnIndex = 0
        editor.switchToCanvasMode()
        editor.syncCanvasCursorFromBuffer()

        // 1st shift + up: moves from │ to ─. ─ becomes ┬, cursor lands on ┬.
        editor.processKey(.shiftArrowUp)
        #expect(editor.buffer.lines[1] == "┬")
        #expect(editor.buffer.lines[2] == "│")
        #expect(editor.buffer.lineIndex == 1)

        // 2nd shift + up: moves from ┬ up. ┬ becomes ┼, cursor lands on line 0.
        editor.processKey(.shiftArrowUp)
        #expect(editor.buffer.lines[1] == "┼")
        #expect(editor.buffer.lineIndex == 0)
    }

    // Double border style case: ═║ -> ═╣ -> ═╬
    do {
        let editor = Editor()
        editor.defaultBorderStyle = .double
        editor.buffer.lines = ["═║"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0
        editor.switchToCanvasMode()
        editor.syncCanvasCursorFromBuffer()

        // 1st shift + right: moves from ═ to ║. ║ becomes ╣, cursor lands on ╣.
        editor.processKey(.shiftArrowRight)
        #expect(editor.buffer.lines[0] == "═╣")
        #expect(editor.canvasVisualColumn == 1)

        // 2nd shift + right: moves from ╣ to right. ╣ becomes ╬, cursor lands on col 2.
        editor.processKey(.shiftArrowRight)
        #expect(editor.buffer.lines[0] == "═╬")
        #expect(editor.canvasVisualColumn == 2)
    }

    // ASCII border style case: -| -> -+ -> -+
    do {
        let editor = Editor()
        editor.defaultBorderStyle = .ascii
        editor.buffer.lines = ["-|"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0
        editor.switchToCanvasMode()
        editor.syncCanvasCursorFromBuffer()

        // 1st shift + right: moves from - to |. | becomes +, cursor lands on +.
        editor.processKey(.shiftArrowRight)
        #expect(editor.buffer.lines[0] == "-+")
        #expect(editor.canvasVisualColumn == 1)

        // 2nd shift + right: moves from + to right. + remains +, cursor lands on col 2.
        editor.processKey(.shiftArrowRight)
        #expect(editor.buffer.lines[0] == "-+")
        #expect(editor.canvasVisualColumn == 2)
    }
}

@Test func testCanvasModeCtrlShiftArrowDrawsArrows() throws {
    let editor = Editor()
    editor.defaultBorderStyle = .ascii
    editor.switchToCanvasMode()

    editor.processKey(.ctrlShiftArrowRight)
    #expect(editor.buffer.lines[0] == "->")
    #expect(editor.canvasVisualColumn == 1)

    editor.processKey(.ctrlShiftArrowRight)
    #expect(editor.buffer.lines[0] == "-->")
    #expect(editor.canvasVisualColumn == 2)
}

@Test func testCanvasModeDrawingUsesBorderStyleAndVisualColumn() throws {
    let editor = Editor()
    editor.buffer.lines = ["中"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 1
    editor.defaultBorderStyle = .double
    editor.switchToCanvasMode()

    editor.processKey(.shiftArrowRight)

    #expect(editor.buffer.lines[0] == "中═")
    #expect(editor.canvasVisualColumn == 3)
}

@Test func testCanvasModeDrawingDoesNotOverwriteTextOrTableCells() throws {
    let editor = Editor()
    editor.buffer.lines = ["A"]
    editor.switchToCanvasMode()

    editor.processKey(.shiftArrowRight)

    #expect(editor.buffer.lines[0] == "A")
    #expect(editor.canvasVisualColumn == 1)

    let tableEditor = Editor()
    tableEditor.buffer.lines = [
        "┌────────────────┐",
        "│                │",
        "└────────────────┘",
    ]
    tableEditor.buffer.lineIndex = 1
    tableEditor.buffer.columnIndex = 1
    tableEditor.switchToCanvasMode()
    tableEditor.tableModeController.toggleTableMode()

    tableEditor.processKey(.ctrlShiftArrowRight)

    #expect(tableEditor.buffer.lines[1] == "│                 │")
}

@Test func testCanvasModeDrawingUndoRestoresVisualCursor() throws {
    let editor = Editor()
    editor.switchToCanvasMode()

    editor.processKey(.shiftArrowRight)
    #expect(editor.buffer.lines[0] == "─")
    #expect(editor.canvasVisualColumn == 1)

    editor.performUndo()

    #expect(editor.buffer.lines[0] == "")
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 0)
    #expect(editor.canvasVisualColumn == 0)
}

@Test func testCanvasModeUndoRestoresSparseVisualCursor() throws {
    let editor = Editor()
    editor.switchToCanvasMode()
    editor.canvasVisualColumn = 8
    editor.syncCanvasCursorToBuffer()

    editor.processKey(.char("x"))
    #expect(editor.buffer.lines[0] == "        x")
    #expect(editor.canvasVisualColumn == 9)

    editor.performUndo()

    #expect(editor.buffer.lines[0] == "")
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 8)
    #expect(editor.buffer.columnIndex == 0)
}

@Test func testCanvasModeRedoRestoresVisualCursor() throws {
    let editor = Editor()
    editor.switchToCanvasMode()
    editor.canvasVisualColumn = 8
    editor.syncCanvasCursorToBuffer()

    editor.processKey(.char("x"))
    editor.processKey(.ctrl("z"))
    #expect(editor.canvasVisualColumn == 8)

    editor.processKey(.ctrlShift("z"))
    #expect(editor.buffer.lines[0] == "        x")
    #expect(editor.canvasVisualColumn == 9)
}

@Test func testCanvasModeFixedPositionTypingAndMovement() throws {
    let editor = Editor()
    editor.buffer.lines = ["AB", "中D"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 2

    editor.switchToCanvasMode()
    #expect(editor.canvasVisualColumn == 2)

    editor.processKey(.arrowRight)
    editor.processKey(.arrowRight)
    #expect(editor.canvasVisualColumn == 4)

    editor.processKey(.char("Z"))
    #expect(editor.buffer.lines[0] == "AB  Z")
    #expect(editor.canvasVisualColumn == 5)

    editor.processKey(.arrowUp)
    #expect(editor.buffer.lineIndex == 0)

    editor.processKey(.arrowDown)
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 5)

    editor.processKey(.char("Q"))
    #expect(editor.buffer.lines[1] == "中D  Q")
}

@Test func testCanvasModeTypingPreservesBlockMark() throws {
    let editor = Editor()
    editor.switchToCanvasMode()

    // Set canvas block mark at (0, 0)
    editor.processKey(.mark)
    #expect(editor.buffer.canvasBlockMark != nil)

    // Move to (2, 5) and set block mark end
    editor.buffer.lineIndex = 2
    editor.canvasVisualColumn = 5
    editor.processKey(.mark)
    #expect(editor.buffer.canvasBlockMark != nil)
    #expect(editor.buffer.canvasBlockMarkEnd != nil)

    // Typing a character should NOT clear the canvas block mark
    editor.processKey(.char("X"))
    #expect(editor.buffer.canvasBlockMark != nil)
    #expect(editor.buffer.canvasBlockMarkEnd != nil)

    // Backspace should NOT clear the canvas block mark
    editor.processKey(.backspace)
    #expect(editor.buffer.canvasBlockMark != nil)
    #expect(editor.buffer.canvasBlockMarkEnd != nil)

    // Delete should NOT clear the canvas block mark
    editor.processKey(.delete)
    #expect(editor.buffer.canvasBlockMark != nil)
    #expect(editor.buffer.canvasBlockMarkEnd != nil)
}

@Test func testCanvasModeReplaceAndClearPreserveDisplayWidth() throws {
    let editor = Editor()
    editor.buffer.lines = ["ABCD", "中D"]
    editor.switchToCanvasMode()

    editor.canvasVisualColumn = 1
    editor.syncCanvasCursorToBuffer()
    editor.processKey(.char("中"))
    #expect(editor.buffer.lines[0] == "A中D")
    #expect(editor.buffer.lines[0].displayWidth == 4)

    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 2
    editor.syncCanvasCursorToBuffer()
    editor.processKey(.delete)
    #expect(editor.buffer.lines[1] == "中 ")
    #expect(editor.buffer.lines[1].displayWidth == 3)

    editor.processKey(.backspace)
    #expect(editor.canvasVisualColumn == 0)
    #expect(editor.buffer.lines[1] == "   ")
}

@Test func testCanvasModeBackspaceAtLineStartDeletesCurrentLine() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two", "three"]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 0
    editor.switchToCanvasMode()

    editor.processKey(.backspace)

    #expect(editor.buffer.lines == ["one", "three"])
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 0)
}

@Test func testCanvasModeEnterInsertsBlankLine() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 3
    editor.switchToCanvasMode()

    editor.processKey(.enter)

    #expect(editor.buffer.lines == ["one", "", "two"])
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 0)
}

@Test func testCanvasModePageDownDoesNotCreateBlankLines() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two"]
    editor.buffer.lineIndex = 0
    editor.switchToCanvasMode()
    editor.canvasVisualColumn = 5
    editor.syncCanvasCursorToBuffer()

    editor.processKey(.pageDown)

    #expect(editor.buffer.lines == ["one", "two"])
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 5)

    editor.processKey(.pageUp)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 5)

    editor.processKey(.pageDown)

    #expect(editor.buffer.lines == ["one", "two"])
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 5)

    editor.processKey(.arrowDown)

    #expect(editor.buffer.lines == ["one", "two", ""])
    #expect(editor.buffer.lineIndex == 2)
    #expect(editor.canvasVisualColumn == 5)
}

@Test func testCanvasCtrlPageNavigationDoesNotExtendDocument() throws {
    let editor = Editor()
    editor.apply(.keymap(.classic))
    editor.buffer.lines = ["one", "two"]
    editor.switchToCanvasMode()
    editor.canvasVisualColumn = 5
    editor.syncCanvasCursorToBuffer()

    editor.processKey(.ctrl("v"))
    #expect(editor.buffer.lines == ["one", "two"])
    #expect(editor.buffer.lineIndex == 1)

    editor.processKey(.ctrl("y"))
    #expect(editor.buffer.lines == ["one", "two"])
    #expect(editor.buffer.lineIndex == 0)
}

@Test func testCanvasModeHorizontalRenderingOffset() throws {
    let editor = Editor()
    editor.buffer.lines = ["ABCDEFGHIJKLMNOPQRSTUVWXYZ"]
    editor.switchToCanvasMode()
    editor.canvasVisualColumn = 12
    editor.syncCanvasCursorToBuffer()

    let mainAreaHeight = max(1, 8 - 4)
    let textWidth = max(10, 15 - 5)
    editor.adjustViewport(mainAreaHeight: mainAreaHeight, textWidth: textWidth)

    let output = editor.renderer.render(editor: editor, rows: 8, cols: 15)

    #expect(editor.canvasHorizontalOffset == 10)
    #expect(output.contains("KLMNOPQRST"))
}

@Test func testCanvasModeGotoAutoExtendsRowsWithinLimit() throws {
    let editor = Editor()
    editor.buffer.lines = ["one"]
    editor.switchToCanvasMode()

    editor.goToLocation(line: 5, column: 10)

    #expect(editor.buffer.lines.count == 5)
    #expect(editor.buffer.lineIndex == 4)
    #expect(editor.canvasVisualColumn == 9)
    #expect(editor.buffer.columnIndex == 0)
    #expect(editor.buffer.isModified == true)
}

@Test func testCanvasModeGotoRejectsRowsAndColumnsBeyondLimit() throws {
    let editor = Editor()
    editor.buffer.lines = ["one"]
    editor.switchToCanvasMode()

    editor.goToLocation(line: EditorLimits.maxCanvasAutoExtendRows + 1, column: 1)

    #expect(editor.buffer.lines.count == 1)
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 0)
    #expect(editor.statusMessage == editor.l10n["status.canvas_row_limit_exceeded"])

    editor.goToLocation(line: 1, column: EditorLimits.maxCanvasAutoExtendColumns + 1)

    #expect(editor.buffer.lines.count == 1)
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 0)
    #expect(editor.statusMessage == editor.l10n["status.canvas_column_limit_exceeded"])
}

@Test func testCanvasModeDrawingStopsAtColumnLimit() throws {
    let editor = Editor()
    editor.switchToCanvasMode()
    editor.goToLocation(line: 1, column: EditorLimits.maxCanvasAutoExtendColumns)

    editor.processKey(.shiftArrowRight)

    #expect(editor.canvasVisualColumn == EditorLimits.maxCanvasAutoExtendColumns - 1)
    #expect(editor.buffer.lines[0] == "")
    #expect(editor.statusMessage == editor.l10n["status.canvas_column_limit_exceeded"])
}

@Test func testCanvasModeRejectsJustification() throws {
    let editor = Editor()
    editor.buffer.lines = ["one two three four"]
    editor.switchToCanvasMode()

    let handled = editor.commandRegistry.dispatch(key: .ctrl("J"), editor: editor)

    #expect(handled == true)
    #expect(editor.buffer.lines == ["one two three four"])
    #expect(editor.statusMessage == "[ Justify disabled in Canvas Mode ]")
}

@Test func testCanvasBlockCutPasteAndCancel() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef", "123456"]
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 1
    editor.processKey(.mark)
    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 3
    editor.processKey(.mark)

    editor.processKey(.ctrl("K"))

    #expect(editor.buffer.lines == ["aef", "156"])
    #expect(editor.canvasBlockClipboard == Editor.CanvasBlockClipboard(width: 3, rows: ["bcd", "234"]))
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 1)
    #expect(editor.buffer.canvasBlockMark == nil)
    #expect(editor.buffer.canvasBlockMarkEnd == nil)

    editor.buffer.lines = ["xxYY", "zzWW"]
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 2
    editor.processKey(.ctrl("U"))

    #expect(editor.buffer.lines == ["xxbcdYY", "zz234WW"])
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 2)

    editor.processKey(.mark)
    #expect(editor.buffer.canvasBlockMark != nil)
    #expect(editor.buffer.canvasBlockMarkEnd != nil)
    editor.processKey(.ctrl("G"))
    #expect(editor.buffer.canvasBlockMark == nil)
    #expect(editor.buffer.canvasBlockMarkEnd == nil)
}

@Test func testCanvasBlockCutWithoutMarkAndCJKBoundarySnap() throws {
    let noMarkEditor = Editor()
    noMarkEditor.buffer.lines = ["abcdef"]
    noMarkEditor.switchToCanvasMode()
    noMarkEditor.processKey(.ctrl("K"))
    #expect(noMarkEditor.buffer.lines == ["abcdef"])
    #expect(noMarkEditor.canvasBlockClipboard == nil)
    #expect(noMarkEditor.statusMessage == noMarkEditor.l10n["status.no_block_marked"])

    let cjkEditor = Editor()
    cjkEditor.buffer.lines = ["A中BC"]
    cjkEditor.switchToCanvasMode()
    cjkEditor.buffer.lineIndex = 0
    cjkEditor.canvasVisualColumn = 2
    cjkEditor.processKey(.mark)
    cjkEditor.canvasVisualColumn = 2
    cjkEditor.processKey(.mark)
    cjkEditor.processKey(.ctrl("K"))

    #expect(cjkEditor.buffer.lines == ["ABC"])
    #expect(cjkEditor.canvasBlockClipboard == Editor.CanvasBlockClipboard(width: 2, rows: ["中"]))
}

@Test func testCanvasBlockMarkStatusShowsStartAndEndCoordinates() throws {
    let editor = Editor()
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 1
    editor.processKey(.mark)
    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 3
    editor.processKey(.mark)

    let status = editor.renderer.renderIdleStatusLine(editor: editor, cols: 80)
    #expect(status.contains("Mark Set (start 1,2 end 2,4)"))
}

@Test func testCanvasArrowMovementKeepsBlockMarkWithoutChangingBlock() throws {
    let editor = Editor()
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 1
    editor.processKey(.mark)
    #expect(editor.buffer.canvasBlockMarkEnd?.line == 0)
    #expect(editor.buffer.canvasBlockMarkEnd?.visualColumn == 1)

    editor.processKey(.arrowRight)
    editor.processKey(.arrowDown)

    #expect(editor.buffer.canvasBlockMark?.line == 0)
    #expect(editor.buffer.canvasBlockMark?.visualColumn == 1)
    #expect(editor.buffer.canvasBlockMarkEnd?.line == 0)
    #expect(editor.buffer.canvasBlockMarkEnd?.visualColumn == 1)
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 2)

    let status = editor.renderer.renderIdleStatusLine(editor: editor, cols: 80)
    #expect(status.contains("Mark Set (start 1,2 end 1,2)"))

    editor.processKey(.mark)
    #expect(editor.buffer.canvasBlockMark?.line == 0)
    #expect(editor.buffer.canvasBlockMark?.visualColumn == 1)
    #expect(editor.buffer.canvasBlockMarkEnd?.line == 1)
    #expect(editor.buffer.canvasBlockMarkEnd?.visualColumn == 2)
}

@Test func testCanvasEmptyLineHighlightsOnlyMarkedBlockWidth() throws {
    let editor = Editor()
    editor.buffer.lines = ["abc", "", "def"]
    editor.displayConfig.showLineNumbers = false
    editor.displayConfig.showRuler = false
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 2
    editor.processKey(.mark)
    editor.canvasVisualColumn = 4
    editor.processKey(.mark)

    let virtualLines = editor.layoutEngine.computeVirtualLines(from: editor.buffer.lines, viewWidth: 10)
    let rendered = editor.renderer.renderMainTextArea(
        editor: editor,
        mainAreaHeight: 3,
        gutterWidth: 0,
        virtualLines: virtualLines,
        cols: 10,
        dropdownStartCol: 0,
        dropdownBoxWidth: 0,
        dropdownBoxLines: []
    )

    let highlightedCells = rendered.components(separatedBy: "\u{1B}[7m \u{1B}[m").count - 1
    #expect(highlightedCells == 3)
    #expect(!rendered.contains("\u{1B}[7m          \u{1B}[m"))
}

@Test func testCanvasFillUsesActiveBlockMark() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef", "123456", "uvwxyz"]
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 1
    editor.processKey(.mark)
    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 3
    editor.processKey(.mark)

    editor.runLogoScript("FILL \"x")

    #expect(editor.buffer.lines == ["axxxef", "1xxx56", "uvwxyz"])
    #expect(editor.buffer.canvasBlockMark == nil)
    #expect(editor.buffer.canvasBlockMarkEnd == nil)
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 3)
}

@Test func testCanvasModeCtrlArrowDrawsArrowLines() throws {
    let editor = Editor()
    editor.buffer.baseMode = .canvas
    editor.buffer.lines = ["", "", "", ""]

    let controller = CanvasModeController(editor: editor)

    // Ctrl+Right and Ctrl+Shift+Right draw arrow lines to the right
    #expect(controller.handleKey(.ctrlArrowRight) == true)
    #expect(editor.buffer.lines[0].contains("▶") || editor.buffer.lines[0].contains(">"))

    #expect(controller.handleKey(.ctrlShiftArrowRight) == true)
    #expect(editor.buffer.lines[0].contains("▶") || editor.buffer.lines[0].contains(">"))

    // Ctrl+Down and Ctrl+Shift+Down draw arrow lines downward
    #expect(controller.handleKey(.ctrlArrowDown) == true)
    #expect(editor.buffer.lines[1].contains("▼") || editor.buffer.lines[1].contains("v"))

    #expect(controller.handleKey(.ctrlShiftArrowDown) == true)
    #expect(editor.buffer.lines[2].contains("▼") || editor.buffer.lines[2].contains("v"))

    // Ctrl+Left and Ctrl+Shift+Left draw arrow lines to the left
    #expect(controller.handleKey(.ctrlArrowLeft) == true)
    #expect(editor.buffer.lines[2].contains("◀") || editor.buffer.lines[2].contains("<"))

    #expect(controller.handleKey(.ctrlShiftArrowLeft) == true)

    // Ctrl+Up and Ctrl+Shift+Up draw arrow lines upward
    #expect(controller.handleKey(.ctrlArrowUp) == true)
    #expect(controller.handleKey(.ctrlShiftArrowUp) == true)
}

@Test func testCanvasBlockModernKeymapCopyCutPaste() throws {
    let editor = Editor()
    editor.apply(.keymap(.modern))
    editor.buffer.lines = ["abcdef", "123456"]
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 1
    editor.processKey(.mark)
    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 3
    editor.processKey(.mark)

    // Test ^C (Copy)
    editor.processKey(.ctrl("c"))
    #expect(editor.canvasBlockClipboard == Editor.CanvasBlockClipboard(width: 3, rows: ["bcd", "234"]))
    #expect(editor.buffer.lines == ["abcdef", "123456"])

    // Test ^X (Cut)
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 1
    editor.processKey(.mark)
    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 3
    editor.processKey(.mark)
    editor.processKey(.ctrl("x"))
    #expect(editor.buffer.lines == ["aef", "156"])

    // Test ^U (Paste; ^V pages in Canvas Mode)
    editor.buffer.lines = ["xxYY", "zzWW"]
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 2
    editor.processKey(.ctrl("u"))
    #expect(editor.buffer.lines == ["xxbcdYY", "zz234WW"])
}

@Test func testCanvasClassicKeymapPreservesCtrlCAndCtrlX() throws {
    let editor = Editor()
    #expect(editor.keymapManager.activePreset == .classic)
    editor.buffer.lines = ["abcdef", "123456"]
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 1
    editor.processKey(.mark)
    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 3
    editor.processKey(.mark)

    // Test ^C in Classic (shows Cursor Pos status, does not copy block)
    editor.processKey(.ctrl("c"))
    #expect(editor.canvasBlockClipboard == nil)
    #expect(editor.statusMessage.contains("col") || editor.statusMessage.contains("line"))

    // Test ^K in Classic (Cuts block)
    editor.processKey(.ctrl("k"))
    #expect(editor.buffer.lines == ["aef", "156"])
    #expect(editor.canvasBlockClipboard == Editor.CanvasBlockClipboard(width: 3, rows: ["bcd", "234"]))
}

@Test func testCanvasClassicKeymapPageUpDown() throws {
    let editor = Editor()
    #expect(editor.keymapManager.activePreset == .classic)
    editor.buffer.lines = Array(repeating: "Canvas Row Text", count: 40)
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 5

    // ^V Page Down in Canvas
    editor.processKey(.ctrl("v"))
    #expect(editor.buffer.lineIndex > 0)
    let movedLine = editor.buffer.lineIndex

    // ^Y Page Up in Canvas
    editor.processKey(.ctrl("y"))
    #expect(editor.buffer.lineIndex < movedLine)
}

@Test func testCanvasModernSelectAll() throws {
    let editor = Editor()
    editor.apply(.keymap(.modern))
    editor.buffer.lines = ["12345", "ABCDE", "xyz"]
    editor.switchToCanvasMode()

    // ^A in Modern Canvas Mode sets 2D block mark covering all rows
    editor.processKey(.ctrl("a"))
    #expect(editor.buffer.canvasBlockMark != nil)
    #expect(editor.buffer.canvasBlockMark?.line == 0)
    #expect(editor.buffer.canvasBlockMark?.visualColumn == 0)
    #expect(editor.buffer.canvasBlockMarkEnd?.line == 2)
    #expect(editor.buffer.canvasBlockMarkEnd?.visualColumn == 4)
}
