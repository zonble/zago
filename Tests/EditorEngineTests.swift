import Foundation
import Testing
import TextMetrics

@testable import Editor

@Test func testShiftArrowKeyEnum() throws {
    let keyLeft: Key = .shiftArrowLeft
    let keyRight: Key = .shiftArrowRight
    let keyUp: Key = .shiftArrowUp
    let keyDown: Key = .shiftArrowDown
    let ctrlShiftKeyLeft: Key = .ctrlShiftArrowLeft
    let ctrlShiftKeyRight: Key = .ctrlShiftArrowRight
    let ctrlShiftKeyUp: Key = .ctrlShiftArrowUp
    let ctrlShiftKeyDown: Key = .ctrlShiftArrowDown
    #expect(keyLeft != keyRight)
    #expect(keyUp != keyDown)
    #expect(ctrlShiftKeyLeft != ctrlShiftKeyRight)
    #expect(ctrlShiftKeyUp != ctrlShiftKeyDown)
    #expect(ctrlShiftKeyLeft != keyLeft)
}

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
    tableEditor.toggleTableMode()

    tableEditor.processKey(.ctrlShiftArrowRight)

    #expect(tableEditor.buffer.lines[1] == "│                │")
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

@Test func testEditorUndoStack() throws {
    let editor = Editor()
    #expect(editor.buffer.lines[0] == "")

    editor.saveUndoSnapshot()
    editor.buffer.insertString("Hello World")
    #expect(editor.buffer.lines[0] == "Hello World")

    editor.saveUndoSnapshot()
    editor.buffer.insertString(" - Swift TUI")
    #expect(editor.buffer.lines[0] == "Hello World - Swift TUI")

    editor.performUndo()
    #expect(editor.buffer.lines[0] == "Hello World")

    editor.performUndo()
    #expect(editor.buffer.lines[0] == "")
}

@Test func testCommandRegistry() throws {
    let editor = Editor()
    #expect(editor.commandRegistry.commands.count > 20)

    var executed = false
    let testCmd = BlockCommand(id: .testCmd, name: "Test", description: "Test command", keys: [.ctrl("T")]) { _ in
        executed = true
    }
    let registry = CommandRegistry()
    registry.register(testCmd)

    let handled = registry.dispatch(key: .ctrl("T"), editor: editor)
    #expect(handled == true)
    #expect(executed == true)
}

@Test func testSaveKeySavesExistingFileWithoutPrompt() throws {
    let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent("zago_direct_save_test.txt").path
    defer {
        try? FileManager.default.removeItem(atPath: tmpPath)
    }

    let editor = Editor(filePath: tmpPath)
    editor.buffer.lines = ["saved without prompt"]
    editor.buffer.isModified = true

    let handled = editor.commandRegistry.dispatch(key: .ctrl("S"), editor: editor)

    #expect(handled == true)
    #expect(editor.buffer.isModified == false)
    #expect(try String(contentsOfFile: tmpPath, encoding: .utf8) == "saved without prompt")
    if case .none = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "^S should not prompt when the buffer already has a file path")
    }
}

@Test func testWriteOutStillPromptsForPath() throws {
    let editor = Editor()

    let handled = editor.commandRegistry.dispatch(key: .ctrl("O"), editor: editor)

    #expect(handled == true)
    if case .saveFilePath = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "^O should keep WriteOut behavior and ask for a path")
    }
}

@Test func testMultiBufferOperations() throws {
    let editor = Editor(filePaths: ["file1.txt", "file2.txt"])
    #expect(editor.buffers.count == 2)
    #expect(editor.currentBufferIndex == 0)
    #expect(editor.buffer.filePath?.contains("file1.txt") == true)

    // Test next buffer
    editor.nextBuffer()
    #expect(editor.currentBufferIndex == 1)
    #expect(editor.buffer.filePath?.contains("file2.txt") == true)

    // Test next buffer wrapping back to 0
    editor.nextBuffer()
    #expect(editor.currentBufferIndex == 0)

    // Test prev buffer wrapping to last
    editor.prevBuffer()
    #expect(editor.currentBufferIndex == 1)

    // Test opening a new buffer
    editor.openNewBuffer(filePath: "file3.txt")
    #expect(editor.buffers.count == 3)
    #expect(editor.currentBufferIndex == 2)
    #expect(editor.buffer.filePath?.contains("file3.txt") == true)

    // Test screen render Title Bar format includes [3/3]
    let output = editor.renderer.render(editor: editor, rows: 24, cols: 80)
    #expect(output.contains("[3/3]"))

    // Test close current buffer
    editor.closeCurrentBuffer()
    #expect(editor.buffers.count == 2)
    #expect(editor.currentBufferIndex == 1)
}

@Test func testEditorProcessKeyInput() throws {
    let editor = Editor()
    #expect(editor.buffer.lines.count == 1)
    #expect(editor.buffer.lines[0] == "")

    // Test typing characters
    editor.processKey(.char("H"))
    editor.processKey(.char("i"))
    #expect(editor.buffer.lines[0] == "Hi")

    // Test Enter
    editor.processKey(.enter)
    #expect(editor.buffer.lines.count == 2)

    // Test typing on second line
    editor.processKey(.char("W"))
    #expect(editor.buffer.lines[1] == "W")

    // Test Backspace
    editor.processKey(.backspace)
    #expect(editor.buffer.lines[1] == "")
}

@Test func testCursorPositionStatusIncludesVisualColumn() throws {
    L10n.currentLanguage = .en
    let editor = Editor()
    editor.buffer.lines = ["中AB"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 2

    editor.processKey(.ctrl("C"))

    #expect(editor.statusMessage == "line 1/1 (100%), col 3/4, visual col 4/5")
}

@Test func testTextModeEndStopsAtCurrentWrappedVisualLineEnd() throws {
    let editor = Editor(wrapColumn: 10)
    editor.buffer.lines = ["1234567890ABCDEFGHIJ12345"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 0

    editor.processKey(.end)
    #expect(editor.buffer.columnIndex == 9)

    editor.buffer.columnIndex = 10
    editor.processKey(.end)
    #expect(editor.buffer.columnIndex == 19)

    editor.buffer.columnIndex = 20
    editor.processKey(.end)
    #expect(editor.buffer.columnIndex == 25)
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

    editor.processKey(.pageDown)

    #expect(editor.buffer.lines == ["one", "two"])
    #expect(editor.buffer.lineIndex == 1)

    editor.processKey(.arrowDown)

    #expect(editor.buffer.lines == ["one", "two", ""])
    #expect(editor.buffer.lineIndex == 2)
}

@Test func testCanvasModeHorizontalRenderingOffset() throws {
    let editor = Editor()
    editor.buffer.lines = ["ABCDEFGHIJKLMNOPQRSTUVWXYZ"]
    editor.switchToCanvasMode()
    editor.canvasVisualColumn = 12
    editor.syncCanvasCursorToBuffer()

    let output = editor.renderer.render(editor: editor, rows: 8, cols: 15)

    #expect(editor.canvasHorizontalOffset == 10)
    #expect(output.contains("KLMNOPQRST"))
}

@Test func testCanvasModeLogoShapesStartAtVisualCursorColumn() throws {
    let lineEditor = Editor()
    lineEditor.buffer.lines = ["中ABCDEFG"]
    lineEditor.buffer.lineIndex = 0
    lineEditor.buffer.columnIndex = 1
    lineEditor.switchToCanvasMode()
    lineEditor.canvasVisualColumn = 4
    lineEditor.syncCanvasCursorToBuffer()

    lineEditor.runLogoScript("LINE 3")

    #expect(lineEditor.buffer.lines[0] == "中AB───FG")
    #expect(lineEditor.canvasVisualColumn == 7)

    let boxEditor = Editor()
    boxEditor.buffer.lines = ["中ABCDEFG", "中ABCDEFG", "中ABCDEFG"]
    boxEditor.buffer.lineIndex = 0
    boxEditor.buffer.columnIndex = 1
    boxEditor.switchToCanvasMode()
    boxEditor.canvasVisualColumn = 4
    boxEditor.syncCanvasCursorToBuffer()

    boxEditor.runLogoScript("DRAWBOX 4 3 ASCII")

    #expect(boxEditor.buffer.lines[0] == "中AB+--+G")
    #expect(boxEditor.buffer.lines[1] == "中AB|  |G")
    #expect(boxEditor.buffer.lines[2] == "中AB+--+G")
    #expect(boxEditor.canvasVisualColumn == 8)
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

@Test func testEscAndAltColonTriggersLogoPrompt() throws {
    let editor = Editor()

    // Test Esc
    editor.processKey(.esc)
    if case .logoMacro = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Esc should trigger command prompt mode")
    }

    editor.currentPromptMode = .none

    // Test Alt+: (.alt(":"))
    editor.processKey(.alt(":"))
    if case .logoMacro = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Alt+: should trigger command prompt mode")
    }
}

@Test func testCtrlGClearsSelectionAndEscOpensLogoPrompt() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 3
    editor.selectionMark = (line: 0, column: 1)

    editor.processKey(.ctrl("G"))

    #expect(editor.selectionMark == nil)
    if case .none = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "^G with selection should stay in editing mode")
    }
    #expect(editor.statusMessage == L10n["status.mark_unset"])

    editor.processKey(.esc)
    if case .logoMacro = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Esc should still trigger command prompt mode")
    }
}

@Test func testCtrlMarkInTextModeReportsCanvasOnlyMessage() throws {
    let editor = Editor()

    editor.processKey(.mark)

    #expect(editor.selectionMark == nil)
    #expect(editor.canvasBlockMark == nil)
    #expect(editor.statusMessage == L10n["status.block_mark_canvas_only"])
}

@Test func testModeSwitchClearsMarksButKeepsSeparateClipboards() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef"]
    editor.clipboardText = "text"
    editor.selectionMark = (line: 0, column: 1)
    editor.canvasBlockClipboard = Editor.CanvasBlockClipboard(width: 2, rows: ["xy"])

    editor.switchToCanvasMode()
    #expect(editor.selectionMark == nil)
    #expect(editor.clipboardText == "text")
    #expect(editor.canvasBlockClipboard == Editor.CanvasBlockClipboard(width: 2, rows: ["xy"]))

    editor.canvasBlockMark = (line: 0, visualColumn: 1)
    editor.switchToTextMode()
    #expect(editor.canvasBlockMark == nil)
    #expect(editor.clipboardText == "text")
    #expect(editor.canvasBlockClipboard == Editor.CanvasBlockClipboard(width: 2, rows: ["xy"]))
}

@Test func testTextCopySelectionKeepsSelectionCursorAndBuffer() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 4
    editor.selectionMark = (line: 0, column: 1)

    editor.processKey(.alt("w"))

    #expect(editor.clipboardText == "bcd")
    #expect(editor.buffer.lines == ["abcdef"])
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 4)
    #expect(editor.selectionMark?.line == 0)
    #expect(editor.selectionMark?.column == 1)
    #expect(editor.buffer.isModified == false)
    #expect(editor.statusMessage == L10n["status.copied_text"])
}

@Test func testCopyWithoutSelectionReportsNoSelection() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef"]

    editor.processKey(.alt("w"))

    #expect(editor.clipboardText == nil)
    #expect(editor.buffer.lines == ["abcdef"])
    #expect(editor.statusMessage == L10n["status.no_selection"])
}

@Test func testTextSelectionReplacementAndEmptyLineHighlight() throws {
    let editor = Editor()
    editor.buffer.lines = ["abc", "", "def"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 1

    editor.processKey(.shiftArrowDown)
    editor.processKey(.shiftArrowDown)
    #expect(editor.selectionMark?.line == 0)
    #expect(editor.selectionMark?.column == 1)
    #expect(editor.buffer.lineIndex == 2)
    #expect(editor.buffer.columnIndex == 0)

    let rendered = editor.renderer.render(editor: editor, rows: 10, cols: 24)
    #expect(rendered.contains("\u{1B}[7m                   \u{1B}[m"))

    editor.processKey(.char("X"))
    #expect(editor.selectionMark == nil)
    #expect(editor.buffer.lines == ["aXdef"])
}

@Test func testCanvasCopyBlockKeepsMarkCursorAndBuffer() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef", "123456"]
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 1
    editor.processKey(.mark)
    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 3
    editor.processKey(.mark)

    editor.processKey(.alt("W"))

    #expect(editor.canvasBlockClipboard == Editor.CanvasBlockClipboard(width: 3, rows: ["bcd", "234"]))
    #expect(editor.buffer.lines == ["abcdef", "123456"])
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 3)
    #expect(editor.canvasBlockMark?.line == 0)
    #expect(editor.canvasBlockMark?.visualColumn == 1)
    #expect(editor.canvasBlockMarkEnd?.line == 1)
    #expect(editor.canvasBlockMarkEnd?.visualColumn == 3)
    #expect(editor.buffer.isModified == false)
    #expect(editor.statusMessage == L10n["status.copied_block"])
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
    #expect(editor.canvasBlockMark == nil)
    #expect(editor.canvasBlockMarkEnd == nil)

    editor.buffer.lines = ["xxYY", "zzWW"]
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 2
    editor.processKey(.ctrl("U"))

    #expect(editor.buffer.lines == ["xxbcdYY", "zz234WW"])
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 2)

    editor.processKey(.mark)
    #expect(editor.canvasBlockMark != nil)
    #expect(editor.canvasBlockMarkEnd != nil)
    editor.processKey(.ctrl("G"))
    #expect(editor.canvasBlockMark == nil)
    #expect(editor.canvasBlockMarkEnd == nil)
}

@Test func testCanvasBlockCutWithoutMarkAndCJKBoundarySnap() throws {
    let noMarkEditor = Editor()
    noMarkEditor.buffer.lines = ["abcdef"]
    noMarkEditor.switchToCanvasMode()
    noMarkEditor.processKey(.ctrl("K"))
    #expect(noMarkEditor.buffer.lines == ["abcdef"])
    #expect(noMarkEditor.canvasBlockClipboard == nil)
    #expect(noMarkEditor.statusMessage == L10n["status.no_block_marked"])

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
    #expect(editor.canvasBlockMarkEnd?.line == 0)
    #expect(editor.canvasBlockMarkEnd?.visualColumn == 1)

    editor.processKey(.arrowRight)
    editor.processKey(.arrowDown)

    #expect(editor.canvasBlockMark?.line == 0)
    #expect(editor.canvasBlockMark?.visualColumn == 1)
    #expect(editor.canvasBlockMarkEnd?.line == 0)
    #expect(editor.canvasBlockMarkEnd?.visualColumn == 1)
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 2)

    let status = editor.renderer.renderIdleStatusLine(editor: editor, cols: 80)
    #expect(status.contains("Mark Set (start 1,2 end 1,2)"))

    editor.processKey(.mark)
    #expect(editor.canvasBlockMark?.line == 0)
    #expect(editor.canvasBlockMark?.visualColumn == 1)
    #expect(editor.canvasBlockMarkEnd?.line == 1)
    #expect(editor.canvasBlockMarkEnd?.visualColumn == 2)
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
    #expect(editor.canvasBlockMark == nil)
    #expect(editor.canvasBlockMarkEnd == nil)
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 3)
}

@Test func testCtrlBackspaceDeleteLineCommand() throws {
    let editor = Editor()
    editor.buffer.lines = ["First Line", "Second Line", "Third Line"]
    editor.buffer.lineIndex = 1

    editor.processKey(.ctrlBackspace)
    #expect(editor.buffer.lines == ["First Line", "Third Line"])

    editor.performUndo()
    #expect(editor.buffer.lines == ["First Line", "Second Line", "Third Line"])
}

@Test func testF4SaveAndExitCommand() throws {
    let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent("test_f4_save_exit.txt").path
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    let editor = Editor(filePath: tmpPath)
    editor.buffer.lines = ["Line 1 for F4 test"]
    editor.buffer.isModified = true

    // Trigger F4 (file.save_exit)
    let handled = editor.commandRegistry.dispatch(key: .f4, editor: editor)
    #expect(handled == true)

    // File should be saved to disk
    let savedContent = try String(contentsOfFile: tmpPath, encoding: .utf8)
    #expect(savedContent == "Line 1 for F4 test")
}

@Test func testCtrlITabInsertion() throws {
    let editor = Editor()
    editor.processKey(.ctrl("I"))
    #expect(editor.buffer.lines[0] == "    ")
}

@Test func testMenuBarActivationAndNavigation() throws {
    let editor = Editor()
    #expect(editor.isMenuBarActive == false)

    // Press ESC in normal mode to open command prompt, not Menu Bar.
    editor.processKey(.esc)
    #expect(editor.isMenuBarActive == false)
    if case .logoMacro = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Esc should trigger command prompt mode")
    }
    editor.currentPromptMode = .none

    // 1. Press F1 to activate Menu Bar
    editor.processKey(.f1)
    #expect(editor.isMenuBarActive == true)
    #expect(editor.menuBar.categoryIndex == 0)

    // 2. Press Right Arrow to switch to Edit category (index 1)
    editor.processKey(.arrowRight)
    #expect(editor.menuBar.categoryIndex == 1)

    // 3. Press Down Arrow to navigate items in Edit menu
    editor.processKey(.arrowDown)
    #expect(editor.menuBar.itemIndex == 1)

    // 4. Press letter 's' to jump to Shapes menu
    editor.processKey(.char("s"))
    #expect(editor.menuBar.currentCategory.titleKey == "menu.shapes")

    // 4b. Home/End jump within menu items; PageUp/PageDown jump across menu categories
    editor.processKey(.end)
    #expect(editor.menuBar.itemIndex == editor.menuBar.currentCategory.items.count - 1)
    editor.processKey(.home)
    #expect(editor.menuBar.itemIndex == 0)
    editor.processKey(.pageDown)
    #expect(editor.menuBar.categoryIndex == editor.menuBar.categories.count - 1)
    editor.processKey(.pageUp)
    #expect(editor.menuBar.categoryIndex == 0)

    // 5. Press ESC to close Menu Bar
    editor.processKey(.esc)
    #expect(editor.isMenuBarActive == false)

    // 6. Press Ctrl+M to activate Menu Bar
    editor.processKey(.ctrl("M"))
    #expect(editor.isMenuBarActive == true)
    editor.processKey(.esc)
    #expect(editor.isMenuBarActive == false)

    // 7. Test executing menu item via Enter
    editor.processKey(.f1)  // Activate menu
    editor.menuBar.categoryIndex = editor.menuBar.categories.firstIndex(where: { $0.titleKey == "menu.tools" })!
    editor.menuBar.itemIndex = 0  // Command Prompt
    editor.processKey(.enter)  // Execute
    #expect(editor.isMenuBarActive == false)
    if case .logoMacro = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Enter on LOGO item should trigger LOGO prompt mode")
    }

    // 8. Test Goto Line from Edit menu
    editor.currentPromptMode = .none
    editor.processKey(.f1)
    editor.menuBar.categoryIndex = editor.menuBar.categories.firstIndex(where: { $0.titleKey == "menu.edit" })!
    editor.menuBar.itemIndex = editor.menuBar.currentCategory.items.firstIndex(where: { $0.titleKey == "menu.edit.goto_line" })!
    editor.processKey(.enter)
    #expect(editor.isMenuBarActive == false)
    if case .gotoLine = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Enter on Goto Line item should trigger gotoLine prompt mode")
    }
}

@Test func testSearchPromptMiddleSpaceInsertion() throws {
    let editor = Editor()
    editor.promptSearch()

    // Type "hello"
    for ch in "hello" {
        editor.processPromptKey(.char(ch))
    }
    #expect(editor.promptInputText == "hello")
    #expect(editor.promptCursorIndex == 5)

    // Move cursor left 3 times (between 'e' and 'l')
    editor.processPromptKey(.arrowLeft)
    editor.processPromptKey(.arrowLeft)
    editor.processPromptKey(.arrowLeft)
    #expect(editor.promptCursorIndex == 2)

    // Type space ' '
    editor.processPromptKey(.char(" "))

    // Expect "he llo", NOT "hello "!
    #expect(editor.promptInputText == "he llo")
    #expect(editor.promptCursorIndex == 3)
}

private func submitCommandBar(_ text: String, editor: Editor) {
    editor.promptLogoMacro()
    for ch in text {
        editor.processPromptKey(.char(ch))
    }
    editor.processPromptKey(.enter)
}

@Test func testCommandBarNumericGotoShorthand() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two", "three"]

    submitCommandBar("2", editor: editor)

    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 0)
    #expect(editor.logoEngine.lastResult == nil)
}

@Test func testCommandBarNumericGotoWithColumnShorthand() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two", "three"]

    submitCommandBar("3:2", editor: editor)

    #expect(editor.buffer.lineIndex == 2)
    #expect(editor.buffer.columnIndex == 1)

    submitCommandBar("1,3", editor: editor)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 2)
}

@Test func testCommandBarLogoExpressionFallback() throws {
    let editor = Editor()

    submitCommandBar("1 + 1", editor: editor)

    #expect(editor.logoEngine.lastResult == "2")
    #expect(editor.statusMessage == "2")
}

@Test func testCommandBarInvalidNumericGotoDoesNotFallThroughToLogo() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two"]

    submitCommandBar("-1", editor: editor)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.logoEngine.lastResult == nil)
    #expect(editor.statusMessage == L10n["status.invalid_line"])

    submitCommandBar("0", editor: editor)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.logoEngine.lastResult == nil)
    #expect(editor.statusMessage == L10n["status.invalid_line"])
}

@Test func testCommandBarOpenNewAndBufferShorthand() throws {
    let editor = Editor()
    editor.buffer.filePath = "first.txt"

    submitCommandBar("open second.txt", editor: editor)

    #expect(editor.buffers.count == 2)
    #expect(editor.currentBufferIndex == 1)
    #expect(editor.buffer.filePath == "second.txt")

    submitCommandBar("new", editor: editor)

    #expect(editor.buffers.count == 3)
    #expect(editor.currentBufferIndex == 2)
    #expect(editor.buffer.filePath == nil)

    submitCommandBar("buffer prev", editor: editor)
    #expect(editor.currentBufferIndex == 1)

    submitCommandBar("buffer 1", editor: editor)
    #expect(editor.currentBufferIndex == 0)

    submitCommandBar("buffer 99", editor: editor)
    #expect(editor.currentBufferIndex == 0)
    #expect(editor.statusMessage == L10n["status.no_such_buffer"])
}

@Test func testCommandBarUppercaseBufferUsesCommandBarCommand() throws {
    let editor = Editor()
    editor.buffer.filePath = "first.txt"
    editor.openNewBuffer(filePath: "second.txt")
    editor.currentBufferIndex = 0

    submitCommandBar("BUFFER 2", editor: editor)

    #expect(editor.currentBufferIndex == 1)
}

@Test func testCommandBarWriteShorthandUsesEditorSavePath() throws {
    let path = FileManager.default.temporaryDirectory.appendingPathComponent("zago_command_bar_write.txt").path
    defer { try? FileManager.default.removeItem(atPath: path) }
    let editor = Editor()
    editor.buffer.lines = ["command bar write"]
    editor.buffer.isModified = true

    submitCommandBar("write \(path)", editor: editor)

    #expect(try String(contentsOfFile: path, encoding: .utf8) == "command bar write")
    #expect(editor.buffer.filePath == path)
    #expect(editor.buffer.isModified == false)
}

@Test func testCommandBarUppercaseSaveUsesEditorCommand() throws {
    let path = FileManager.default.temporaryDirectory.appendingPathComponent("zago_command_bar_save.txt").path
    defer { try? FileManager.default.removeItem(atPath: path) }
    let editor = Editor(filePath: path)
    editor.buffer.lines = ["command bar save"]
    editor.buffer.isModified = true

    submitCommandBar("SAVE", editor: editor)

    #expect(try String(contentsOfFile: path, encoding: .utf8) == "command bar save")
    #expect(editor.buffer.isModified == false)
}

@Test func testCommandBarSettingCommandsAreEditorCommands() throws {
    let editor = Editor()
    editor.displayConfig.showRuler = false
    editor.displayConfig.showLineNumbers = true
    editor.displayConfig.enableSyntaxHighlight = true

    submitCommandBar("SET RULER ON", editor: editor)
    #expect(editor.displayConfig.showRuler == true)

    submitCommandBar("set linenumbers off", editor: editor)
    #expect(editor.displayConfig.showLineNumbers == false)

    submitCommandBar("set syntax off", editor: editor)
    #expect(editor.displayConfig.enableSyntaxHighlight == false)

    submitCommandBar("set wrap 4", editor: editor)
    #expect(editor.layoutEngine.wrapColumn == 10)

    submitCommandBar("unset wrap", editor: editor)
    #expect(editor.layoutEngine.wrapColumn == nil)
}

@Test func testCommandBarSetTabShowsSettingCompletions() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "SET " {
        editor.processPromptKey(.char(ch))
    }

    editor.processPromptKey(.tab)

    #expect(editor.promptInputText == "SET ")
    #expect(editor.promptCompletionText?.contains("wrap") == true)
    #expect(editor.promptCompletionText?.contains("linenumbers") == true)
    #expect(editor.promptCompletionText?.contains("syntax") == true)

    let rendered = editor.renderer.render(editor: editor, rows: 24, cols: 80)
    #expect(rendered.contains("wrap"))
    #expect(rendered.contains("linenumbers"))
}

@Test func testCommandBarSetTabCompletesUniqueSettingPrefix() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "set li" {
        editor.processPromptKey(.char(ch))
    }

    editor.processPromptKey(.tab)

    #expect(editor.promptInputText == "set linenumbers ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarSetValueTabShowsValueCompletions() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "set syntax " {
        editor.processPromptKey(.char(ch))
    }

    editor.processPromptKey(.tab)

    #expect(editor.promptInputText == "set syntax ")
    #expect(editor.promptCompletionText?.contains("on") == true)
    #expect(editor.promptCompletionText?.contains("off") == true)
}

@Test func testCommandBarTabCompletesLogoKeyword() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "drawb" {
        editor.processPromptKey(.char(ch))
    }

    editor.processPromptKey(.tab)

    #expect(editor.promptInputText == "drawbox ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarTabCompletesCommandBarCommand() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "QUI" {
        editor.processPromptKey(.char(ch))
    }

    editor.processPromptKey(.tab)

    #expect(editor.promptInputText == "QUIT ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarTabCompletesHyphenatedCommandBarCommand() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "save-" {
        editor.processPromptKey(.char(ch))
    }

    editor.processPromptKey(.tab)

    #expect(editor.promptInputText == "save-exit ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarTabShowsMixedCommandAndLogoCompletions() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "sa" {
        editor.processPromptKey(.char(ch))
    }

    editor.processPromptKey(.tab)

    #expect(editor.promptInputText == "sa")
    #expect(editor.promptCompletionText?.contains("save") == true)
    #expect(editor.promptCompletionText?.contains("save-exit") == true)
}

@Test func testCommandBarCompletionClearsOnEsc() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "sa" {
        editor.processPromptKey(.char(ch))
    }

    editor.processPromptKey(.tab)
    #expect(editor.promptCompletionText != nil)

    editor.processPromptKey(.esc)
    #expect(editor.promptCompletionText == nil)
    #expect(editor.statusMessage.contains("save") == false)
}

@Test func testCommandBarTabCompletesTokenWithLeadingContext() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "box 10 drawb" {
        editor.processPromptKey(.char(ch))
    }

    editor.processPromptKey(.tab)

    #expect(editor.promptInputText == "box 10 drawbox ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarTabCompletesTokenAfterBracket() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "REPEAT 5 [drawb" {
        editor.processPromptKey(.char(ch))
    }

    editor.processPromptKey(.tab)

    #expect(editor.promptInputText == "REPEAT 5 [drawbox ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarExitAndSaveExitCommands() throws {
    let savePath = FileManager.default.temporaryDirectory.appendingPathComponent("zago_command_bar_save_exit.txt").path
    defer { try? FileManager.default.removeItem(atPath: savePath) }

    let editor = Editor()
    editor.buffer.filePath = "first.txt"
    editor.openNewBuffer(filePath: savePath)
    editor.buffer.lines = ["save and exit"]
    editor.buffer.isModified = true

    submitCommandBar("save-exit", editor: editor)

    #expect(try String(contentsOfFile: savePath, encoding: .utf8) == "save and exit")
    #expect(editor.buffers.count == 1)
    #expect(editor.currentBufferIndex == 0)

    editor.openNewBuffer(filePath: "third.txt")
    submitCommandBar("quit", editor: editor)

    #expect(editor.buffers.count == 1)
    #expect(editor.currentBufferIndex == 0)
}

@Test func testLastLineDownKeyMovesToEOL() throws {
    let editor = Editor()
    editor.buffer.lines = ["First Line", "Last Line"]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 0  // At start of "Last Line"

    editor.processKey(.arrowDown)
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 9)  // EOL of "Last Line"
}

@Test func testCtrlQEvalLogoCode() throws {
    let editor = Editor()

    // Test 1: Single Line Expression Eval
    editor.buffer.lines = ["SUM 1 6"]
    editor.buffer.lineIndex = 0
    editor.processKey(.ctrl("Q"))
    #expect(editor.statusMessage == "[Eval] 7")

    // Test 2: Drawing Line Eval
    editor.buffer.lines = ["BOX \"Test\""]
    editor.buffer.lineIndex = 0
    editor.processKey(.ctrl("Q"))
    #expect(editor.buffer.lines[1] == "│ Test │")

    // Test 3: Markdown Code Fence Eval
    editor.buffer.lines = ["# Title", "```logo", "MAKE \"x\" 10", ":x * 5", "```"]
    editor.buffer.lineIndex = 3
    editor.processKey(.ctrl("Q"))
    #expect(editor.statusMessage == "[Eval] 50")
}
