import Foundation
import Testing

@testable import Editor

// MARK: - TextBuffer.getOrderedRange

@Test func testGetOrderedRangeSameLine() {
    let (start, end) = TextBuffer.getOrderedRange(
        mark1: (line: 0, column: 3),
        mark2: (line: 0, column: 7))
    #expect(start.line == 0 && start.column == 3)
    #expect(end.line == 0 && end.column == 7)
}

@Test func testGetOrderedRangeSameLineReversed() {
    let (start, end) = TextBuffer.getOrderedRange(
        mark1: (line: 0, column: 7),
        mark2: (line: 0, column: 3))
    #expect(start.column == 3)
    #expect(end.column == 7)
}

@Test func testGetOrderedRangeMultiLine() {
    let (start, end) = TextBuffer.getOrderedRange(
        mark1: (line: 2, column: 0),
        mark2: (line: 0, column: 5))
    #expect(start.line == 0)
    #expect(end.line == 2)
}

// MARK: - TextBuffer.isCharacterSelected (normal mode)

@Test func testIsCharacterSelectedSingleLine() {
    let buf = TextBuffer()
    buf.lines = ["hello world"]
    buf.lineIndex = 0
    buf.columnIndex = 8  // cursor at col 8
    buf.selectionMark = (line: 0, column: 3)  // mark at col 3 → selection [3,8)

    #expect(!buf.isCharacterSelected(line: 0, col: 2))
    #expect(buf.isCharacterSelected(line: 0, col: 3))
    #expect(buf.isCharacterSelected(line: 0, col: 7))
    #expect(!buf.isCharacterSelected(line: 0, col: 8))
    #expect(!buf.isCharacterSelected(line: 1, col: 0))
}

@Test func testIsCharacterSelectedMultiLine() {
    let buf = TextBuffer()
    buf.lines = ["abc", "def", "ghi"]
    buf.lineIndex = 2
    buf.columnIndex = 2
    buf.selectionMark = (line: 0, column: 1)

    // line 0: from col 1 to end
    #expect(!buf.isCharacterSelected(line: 0, col: 0))
    #expect(buf.isCharacterSelected(line: 0, col: 1))
    #expect(buf.isCharacterSelected(line: 0, col: 2))
    // line 1: fully selected
    #expect(buf.isCharacterSelected(line: 1, col: 0))
    #expect(buf.isCharacterSelected(line: 1, col: 2))
    // line 2: up to cursor col (exclusive)
    #expect(buf.isCharacterSelected(line: 2, col: 0))
    #expect(buf.isCharacterSelected(line: 2, col: 1))
    #expect(!buf.isCharacterSelected(line: 2, col: 2))
}

@Test func testIsCharacterSelectedNoMark() {
    let buf = TextBuffer()
    buf.lines = ["hello"]
    buf.lineIndex = 0
    buf.columnIndex = 3
    #expect(!buf.isCharacterSelected(line: 0, col: 1))
}

// MARK: - TextBuffer.isLineSelected

@Test func testIsLineSelectedSingleLine() {
    let buf = TextBuffer()
    buf.lines = ["hello world"]
    buf.lineIndex = 0
    buf.columnIndex = 5
    buf.selectionMark = (line: 0, column: 2)

    #expect(buf.isLineSelected(line: 0))
    #expect(!buf.isLineSelected(line: 1))
}

@Test func testIsLineSelectedMultiLine() {
    let buf = TextBuffer()
    buf.lines = ["abc", "def", "ghi"]
    buf.lineIndex = 2
    buf.columnIndex = 1
    buf.selectionMark = (line: 0, column: 1)

    #expect(buf.isLineSelected(line: 0))
    #expect(buf.isLineSelected(line: 1))
    #expect(buf.isLineSelected(line: 2))
    #expect(!buf.isLineSelected(line: 3))
}

@Test func testIsLineSelectedNoMark() {
    let buf = TextBuffer()
    buf.lines = ["hello"]
    buf.lineIndex = 0
    buf.columnIndex = 3
    #expect(!buf.isLineSelected(line: 0))
}

// MARK: - selectionMark is per-buffer

@Test func testSelectionMarkPreservedAcrossBufferSwitch() {
    let editor = Editor()

    // Set mark in buffer A
    editor.buffer.lines = ["buffer A content"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 8
    editor.buffer.selectionMark = (line: 0, column: 2)

    // Open buffer B
    editor.openNewBuffer()
    editor.buffer.lines = ["buffer B content"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 5
    editor.buffer.selectionMark = (line: 0, column: 1)

    // Switch back to buffer A — mark must be intact
    editor.prevBuffer()
    #expect(editor.buffer.selectionMark?.line == 0)
    #expect(editor.buffer.selectionMark?.column == 2)

    // Switch to buffer B — mark must be intact
    editor.nextBuffer()
    #expect(editor.buffer.selectionMark?.line == 0)
    #expect(editor.buffer.selectionMark?.column == 1)
}

@Test func testShiftArrowKeyEnum() throws {
    let keyLeft: Key = .shiftArrowLeft
    let keyRight: Key = .shiftArrowRight
    let keyUp: Key = .shiftArrowUp
    let keyDown: Key = .shiftArrowDown
    let keyHome: Key = .shiftHome
    let keyEnd: Key = .shiftEnd
    let ctrlShiftKeyLeft: Key = .ctrlShiftArrowLeft
    let ctrlShiftKeyRight: Key = .ctrlShiftArrowRight
    let ctrlShiftKeyUp: Key = .ctrlShiftArrowUp
    let ctrlShiftKeyDown: Key = .ctrlShiftArrowDown
    #expect(keyLeft != keyRight)
    #expect(keyUp != keyDown)
    #expect(keyHome != keyEnd)
    #expect(keyHome != .home)
    #expect(keyEnd != .end)
    #expect(ctrlShiftKeyLeft != ctrlShiftKeyRight)
    #expect(ctrlShiftKeyUp != ctrlShiftKeyDown)
    #expect(ctrlShiftKeyLeft != keyLeft)
}

@Test func testTextModeShiftHomeAndShiftEndExtendSelection() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 3

    editor.processKey(.shiftHome)

    #expect(editor.buffer.selectionMark?.line == 0)
    #expect(editor.buffer.selectionMark?.column == 3)
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 0)
    #expect(editor.buffer.textRange(start: (line: 0, col: 0), end: (line: 0, col: 3)) == "abc")

    editor.processKey(.shiftEnd)

    #expect(editor.buffer.selectionMark?.line == 0)
    #expect(editor.buffer.selectionMark?.column == 3)
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 6)
    #expect(editor.buffer.textRange(start: (line: 0, col: 3), end: (line: 0, col: 6)) == "def")
}

@Test func testTextModeShiftPageUpAndShiftPageDownExtendSelection() throws {
    let editor = Editor()
    editor.buffer.lines = Array(repeating: "Line of text", count: 60)
    editor.buffer.lineIndex = 30
    editor.buffer.columnIndex = 4

    editor.processKey(.shiftPageUp)

    #expect(editor.buffer.selectionMark?.line == 30)
    #expect(editor.buffer.selectionMark?.column == 4)
    #expect(editor.buffer.lineIndex < 30)

    editor.processKey(.shiftPageDown)

    #expect(editor.buffer.selectionMark?.line == 30)
    #expect(editor.buffer.selectionMark?.column == 4)
    #expect(editor.buffer.lineIndex > 0)
}

@Test func testShiftKeysDoNotStartTextSelectionInCanvasMode() throws {
    let canvasEditor = Editor()
    canvasEditor.buffer.lines = ["abcdef"]
    canvasEditor.switchToCanvasMode()
    canvasEditor.buffer.lineIndex = 0
    canvasEditor.buffer.columnIndex = 3

    canvasEditor.processKey(.shiftHome)
    #expect(canvasEditor.buffer.selectionMark == nil)
    #expect(canvasEditor.buffer.columnIndex == 3)

    canvasEditor.processKey(.shiftEnd)
    #expect(canvasEditor.buffer.selectionMark == nil)

    canvasEditor.processKey(.shiftPageUp)
    #expect(canvasEditor.buffer.selectionMark == nil)

    canvasEditor.processKey(.shiftPageDown)
    #expect(canvasEditor.buffer.selectionMark == nil)
}

@Test func testTableModeShiftKeysExtendSelectionWithinCellBounds() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌─────────────────┐",
        "│ Header cell     │",
        "├─────────────────┤",
        "│ Multi-line row  │",
        "│ Second line row │",
        "└─────────────────┘",
    ]
    editor.buffer.lineIndex = 3
    editor.buffer.columnIndex = 5 // inside "Multi-line row"
    editor.tableModeController.toggleTableMode()

    editor.processKey(.shiftHome)
    #expect(editor.buffer.selectionMark?.line == 3)
    #expect(editor.buffer.selectionMark?.column == 5)
    #expect(editor.buffer.lineIndex == 3)
    #expect(editor.buffer.columnIndex == 1) // innerMinCol (after left border '│')

    editor.processKey(.shiftEnd)
    #expect(editor.buffer.lineIndex == 3)
    #expect(editor.buffer.columnIndex == 17) // innerMaxCol (before right border '|')

    editor.processKey(.shiftPageDown)
    #expect(editor.buffer.lineIndex == 4) // clamped within cell's innerMaxLine
    #expect(editor.buffer.columnIndex >= 2 && editor.buffer.columnIndex <= 17)

    editor.processKey(.shiftPageUp)
    #expect(editor.buffer.lineIndex == 3) // clamped within cell's innerMinLine
    #expect(editor.buffer.columnIndex >= 2 && editor.buffer.columnIndex <= 17)
}

@Test func testTextCopySelectionKeepsSelectionCursorAndBuffer() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 4
    editor.buffer.selectionMark = (line: 0, column: 1)

    editor.processKey(.alt("w"))

    #expect(editor.clipboardText == "bcd")
    #expect(editor.buffer.lines == ["abcdef"])
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 4)
    #expect(editor.buffer.selectionMark?.line == 0)
    #expect(editor.buffer.selectionMark?.column == 1)
    #expect(editor.buffer.isModified == false)
    #expect(editor.statusMessage == editor.l10n["status.copied_text"])
}

@Test func testCopyWithoutSelectionReportsNoSelection() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef"]

    editor.processKey(.alt("w"))

    #expect(editor.clipboardText == nil)
    #expect(editor.buffer.lines == ["abcdef"])
    #expect(editor.statusMessage == editor.l10n["status.no_selection"])
}

@Test func testTransformSelectedTextReplacesSelectionAndSupportsUndo() throws {
    let editor = Editor()
    editor.buffer.lines = ["foo 中文API測試 bar"]
    editor.buffer.selectionMark = (line: 0, column: 4)
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 11

    editor.transformSelectedText(id: "Zago-CJK-Spacing", label: editor.l10n["transform.cjk_spacing"])

    #expect(editor.buffer.lines == ["foo 中文 API 測試 bar"])
    #expect(editor.buffer.selectionMark == nil)
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 13)

    editor.performUndo()
    #expect(editor.buffer.lines == ["foo 中文API測試 bar"])
}

@Test func testTransformSelectedTextRequiresSelection() throws {
    let editor = Editor()
    editor.buffer.lines = ["中文API測試"]

    editor.transformSelectedText(id: "Zago-CJK-Spacing", label: editor.l10n["transform.cjk_spacing"])

    #expect(editor.buffer.lines == ["中文API測試"])
    #expect(editor.statusMessage == editor.l10n["status.no_text_selection"])
}

@Test func testTextCountsUseSelectionOrWholeDocument() throws {
    let editor = Editor()
    editor.buffer.lines = ["Hello world", "中文 API 測試"]

    editor.showTextCounts()
    #expect(editor.statusMessage == "[ Document: 21 chars, 5 words, 4 CJK chars, 2 lines ]")

    editor.buffer.selectionMark = (line: 0, column: 0)
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 5

    editor.showTextCounts()
    #expect(editor.statusMessage == "[ Selection: 5 chars, 1 word, 1 line ]")
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
    #expect(editor.statusMessage == editor.l10n["status.copied_block"])
}

@Test func testCanvasModeAltBTogglesBlockMarkLikeMarkKey() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef", "123456"]
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 1

    editor.processKey(.alt("b"))

    #expect(editor.buffer.canvasBlockMark?.line == 0)
    #expect(editor.buffer.canvasBlockMark?.visualColumn == 1)
    #expect(editor.buffer.canvasBlockMarkEnd?.line == 0)
    #expect(editor.buffer.canvasBlockMarkEnd?.visualColumn == 1)
    #expect(editor.statusMessage == editor.l10n["status.mark_set"])

    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 3
    editor.processKey(.alt("B"))

    #expect(editor.buffer.canvasBlockMark?.line == 0)
    #expect(editor.buffer.canvasBlockMark?.visualColumn == 1)
    #expect(editor.buffer.canvasBlockMarkEnd?.line == 1)
    #expect(editor.buffer.canvasBlockMarkEnd?.visualColumn == 3)
    #expect(editor.statusMessage == editor.l10n["status.mark_set"])
}

@Test func testNavigationAndSelectionCommands() throws {
    let editor = Editor()
    editor.buffer.lines = ["hello world zago", "second line text"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 0

    // Test MoveRightCommand & MoveLeftCommand
    let moveRight = MoveRightCommand()
    moveRight.execute(on: editor)
    #expect(editor.buffer.columnIndex == 1)

    let moveLeft = MoveLeftCommand()
    moveLeft.execute(on: editor)
    #expect(editor.buffer.columnIndex == 0)

    // Test MoveEndCommand & MoveHomeCommand
    let moveEnd = MoveEndCommand()
    moveEnd.execute(on: editor)
    #expect(editor.buffer.columnIndex == editor.buffer.lines[0].count)

    let moveHome = MoveHomeCommand()
    moveHome.execute(on: editor)
    #expect(editor.buffer.columnIndex == 0)

    // Test MovePgdnCommand & MovePgupCommand
    let movePgdn = MovePgdnCommand()
    movePgdn.execute(on: editor)
    let movePgup = MovePgupCommand()
    movePgup.execute(on: editor)

    // Test ToggleMarkCommand
    let markCmd = ToggleMarkCommand()
    markCmd.execute(on: editor)

    // Test CopyTextCommand & CutTextCommand & UncutTextCommand
    let copyCmd = CopyTextCommand()
    copyCmd.execute(on: editor)

    let cutCmd = CutTextCommand()
    cutCmd.execute(on: editor)

    let uncutCmd = UncutTextCommand()
    uncutCmd.execute(on: editor)
}

@Test func testUICommandsExecution() throws {
    let editor = Editor()

    let helpCmd = ShowHelpCommand()
    helpCmd.execute(on: editor)

    let logoRefCmd = LogoReferenceCommand()
    logoRefCmd.execute(on: editor)

    let logoWsCmd = LogoWorkspaceCommand()
    logoWsCmd.execute(on: editor)

    let toggleMenuCmd = ToggleMenuBarCommand()
    #expect(editor.isMenuBarActive == false)
    toggleMenuCmd.execute(on: editor)
    #expect(editor.isMenuBarActive == true)
}

@Test func testToggleMarkAndCancelMarkCommands() throws {
    let editor = Editor()
    editor.baseMode = .canvas
    #expect(editor.buffer.canvasBlockMark == nil)

    let toggleCmd = ToggleMarkCommand()
    // 1st press: set start point
    let firstToggleResult = toggleCmd.execute(on: editor)
    #expect(editor.buffer.canvasBlockMark != nil)
    #expect(firstToggleResult.statusMessage == editor.l10n["status.mark_set"])

    // 2nd press: set end point
    let secondToggleResult = toggleCmd.execute(on: editor)
    #expect(editor.buffer.canvasBlockMark != nil)
    #expect(secondToggleResult.statusMessage == editor.l10n["status.mark_set"])

    // Cancel mark using CancelSelectionCommand (^G / :unmark)
    let cancelCmd = CancelSelectionCommand()
    let cancelResult = cancelCmd.execute(on: editor)
    #expect(editor.buffer.canvasBlockMark == nil)
    #expect(cancelResult.statusMessage == editor.l10n["status.mark_unset"])
}

@Test func testNewlineAndEmptyLineSelectionRendering() throws {
    let editor = Editor()
    editor.displayConfig.enableSyntaxHighlight = false
    editor.displayConfig.showLineNumbers = false
    editor.buffer.lines = ["Hello", "", "World"]
    
    // Set selection from line 0, col 0 to line 2, col 3 ("Wor")
    editor.buffer.selectionMark = (line: 0, column: 0)
    editor.buffer.lineIndex = 2
    editor.buffer.columnIndex = 3
    
    let rendered = editor.renderer.renderDiff(editor: editor, rows: 10, cols: 20)
    
    // Line 0: "Hello" (all 5 chars inverted) + 1 extra inverted space for \n
    let expectedLine0 = "Hello".map { "\u{1B}[7m\($0)\u{1B}[m" }.joined() + "\u{1B}[7m \u{1B}[m"
    #expect(rendered.contains(expectedLine0))
    
    // Line 1: empty line "" -> exactly 1 inverted space for \n
    #expect(rendered.contains("\u{1B}[7m \u{1B}[m"))
    
    // Line 2: "Wor" inverted, "ld" normal (no trailing inverted space for \n)
    let expectedLine2 = "Wor".map { "\u{1B}[7m\($0)\u{1B}[m" }.joined() + "ld"
    #expect(rendered.contains(expectedLine2))
}

@Test func testSingleLineTextEditorShiftHomeAndEndSelection() {
    var editor = SingleLineTextEditor(text: "Hello World", cursorIndex: 5)
    
    // Shift + Home -> selection from index 5 to 0
    editor.selectHome()
    #expect(editor.cursorIndex == 0)
    #expect(editor.selectionAnchorIndex == 5)
    #expect(editor.selectionRange == 0..<5)
    #expect(editor.selectedText == "Hello")
    
    // Reset selection anchor and move cursor to index 5
    editor.selectionAnchorIndex = nil
    editor.cursorIndex = 5
    
    // Shift + End -> selection from index 5 to 11
    editor.selectEnd()
    #expect(editor.cursorIndex == 11)
    #expect(editor.selectionAnchorIndex == 5)
    #expect(editor.selectionRange == 5..<11)
    #expect(editor.selectedText == " World")
}

