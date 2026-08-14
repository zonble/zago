import Foundation
import Testing
import TextMetrics

@testable import Editor

@Test func testTableModeCtrlKClearsCellTextWithoutDeletingTableRow() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│abcdef          │keep            │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1
    editor.tableModeController.toggleTableMode()

    editor.processKey(.ctrl("K"))

    #expect(
        editor.buffer.lines == [
            "┌────────────────┬────────────────┐",
            "│                │keep            │",
            "└────────────────┴────────────────┘",
        ])
    #expect(editor.clipboardText == "abcdef          ")
    #expect(editor.currentTableCell?.minCol == 0)
    #expect(editor.currentTableCell?.maxCol == 17)
}

@Test func testTableModeF9ClearsCellTextWithoutDeletingTableRow() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│abcdef          │keep            │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1
    editor.tableModeController.toggleTableMode()

    editor.processKey(.f9)

    #expect(
        editor.buffer.lines == [
            "┌────────────────┬────────────────┐",
            "│                │keep            │",
            "└────────────────┴────────────────┘",
        ])
    #expect(editor.clipboardText == "abcdef          ")
    #expect(editor.currentTableCell?.minCol == 0)
    #expect(editor.currentTableCell?.maxCol == 17)
}

@Test func testZagorcCustomKeybindingsDisabledInTableMode() throws {
    let editor = Editor()
    var config = EditorConfig()
    config.customKeyBinds[.ctrl("f")] = "logo: TYPE \"CUSTOM_MACRO\""
    editor.applyCustomConfig(config)

    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│cell 1          │cell 2          │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1
    editor.tableModeController.toggleTableMode()

    editor.processKey(.ctrl("F"))
    #expect(!editor.buffer.lines[1].contains("CUSTOM_MACRO"))
}

@Test func testTableModePasteAtCellBottomKeepsCursorInsideCell() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│                │right cell      │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1
    editor.tableModeController.toggleTableMode()

    editor.tableModeController.pasteTableCellText("12345678901234567890")

    #expect(editor.buffer.columnIndex == 16)
    #expect(editor.buffer.lines[1] == "│1234567890123456│right cell      │")
}

@Test func testCycleBorderStyleCommand() throws {
    let editor = Editor()
    #expect(editor.defaultBorderStyle == .single)

    editor.processKey(.alt("s"))
    #expect(editor.defaultBorderStyle == .heavy)

    editor.processKey(.alt("s"))
    #expect(editor.defaultBorderStyle == .double)

    editor.processKey(.alt("s"))
    #expect(editor.defaultBorderStyle == .round)

    editor.processKey(.alt("s"))
    #expect(editor.defaultBorderStyle == .doubleRound)

    editor.processKey(.alt("s"))
    #expect(editor.defaultBorderStyle == .ascii)

    editor.processKey(.alt("s"))
    #expect(editor.defaultBorderStyle == .asciiRound)

    editor.processKey(.alt("s"))
    #expect(editor.defaultBorderStyle == .single)
}

@Test func testTableModeCtrlJCenterCellText() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┐",
        "│ Hello          │",
        "└────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 2

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    editor.processKey(.ctrl("J"))

    let line = editor.buffer.lines[1]
    #expect(line == "│     Hello      │")
}

@Test func testCanvasTableModeCtrlJStillCentersCellText() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┐",
        "│ Hello          │",
        "└────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 2

    editor.tableModeController.toggleTableMode()
    editor.switchToCanvasMode()

    editor.processKey(.ctrl("J"))

    #expect(editor.buffer.lines[1] == "│     Hello      │")
    #expect(editor.statusMessage == "[ Cell Text Centered (^J) ]")

    editor.buffer.lines[1] = "│ Hello          │"
    _ = editor.commandRegistry.dispatch(key: .ctrl("J"), editor: editor)

    #expect(editor.buffer.lines[1] == "│     Hello      │")
}

@Test func testTableModeDeleteAndBackspaceDoNotCorruptBorders() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┐",
        "│ Hello World    │",
        "└────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    editor.processKey(.backspace)
    #expect(editor.buffer.lines[1] == "│ Hello World    │")
    #expect(editor.buffer.columnIndex == 1)

    editor.buffer.columnIndex = 2
    editor.processKey(.delete)
    #expect(editor.buffer.lines[1] == "│ ello World     │")
    #expect(editor.buffer.lines[1].count == 18)
    #expect(editor.buffer.lines[1].hasPrefix("│") && editor.buffer.lines[1].hasSuffix("│"))
}

@Test func testTableModeDeleteLineOnlyDeletesCurrentCellLine() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────┬────┐",
        "│ABCD│WXYZ│",
        "│EFGH│QRST│",
        "└────┴────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    editor.deleteCurrentLine()

    #expect(editor.buffer.lines.count == 4)
    #expect(editor.buffer.lines[0] == "┌────┬────┐")
    #expect(editor.buffer.lines[1] == "│EFGH│WXYZ│")
    #expect(editor.buffer.lines[2] == "│    │QRST│")
    #expect(editor.buffer.lines[3] == "└────┴────┘")
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 1)

    let logoEditor = Editor()
    logoEditor.buffer.lines = [
        "┌────┬────┐",
        "│ABCD│WXYZ│",
        "│EFGH│QRST│",
        "└────┴────┘",
    ]
    logoEditor.buffer.lineIndex = 1
    logoEditor.buffer.columnIndex = 6

    logoEditor.tableModeController.toggleTableMode()
    #expect(logoEditor.isTableModeActive == true)

    logoEditor.logoEngine.execute("DELETELINE")

    #expect(logoEditor.buffer.lines.count == 4)
    #expect(logoEditor.buffer.lines[0] == "┌────┬────┐")
    #expect(logoEditor.buffer.lines[1] == "│ABCD│QRST│")
    #expect(logoEditor.buffer.lines[2] == "│EFGH│    │")
    #expect(logoEditor.buffer.lines[3] == "└────┴────┘")
}

@Test func testTableModeLogoSplitLineDoesNotSplitBufferLine() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────┬────┐",
        "│ABCD│WXYZ│",
        "│EFGH│QRST│",
        "└────┴────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    editor.logoEngine.execute("SPLITLINE")

    #expect(editor.buffer.lines.count == 4)
    #expect(editor.buffer.lines[0] == "┌────┬────┐")
    #expect(editor.buffer.lines[1] == "│ABCD│WXYZ│")
    #expect(editor.buffer.lines[2] == "│EFGH│QRST│")
    #expect(editor.buffer.lines[3] == "└────┴────┘")
    #expect(editor.buffer.lineIndex == 2)
    #expect(editor.buffer.columnIndex == 1)
}

@Test func testTableModeLogoJoinOnlyJoinsCurrentCellLines() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────┬────┐",
        "│AB  │WXYZ│",
        "│CD  │QRST│",
        "└────┴────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    editor.logoEngine.execute("JOIN")

    #expect(editor.buffer.lines.count == 4)
    #expect(editor.buffer.lines[0] == "┌────┬────┐")
    #expect(editor.buffer.lines[1] == "│ABCD│WXYZ│")
    #expect(editor.buffer.lines[2] == "│    │QRST│")
    #expect(editor.buffer.lines[3] == "└────┴────┘")
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 4)

    editor.buffer.lines = [
        "┌────┬────┐",
        "│AB  │WXYZ│",
        "│CD  │QRST│",
        "└────┴────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1
    editor.tableModeController.enterTableMode(with: TableCell(minLine: 0, maxLine: 3, minCol: 0, maxCol: 5))

    editor.logoEngine.execute("JOIN \"-")

    #expect(editor.buffer.lines.count == 4)
    #expect(editor.buffer.lines[1] == "│AB-C│WXYZ│")
    #expect(editor.buffer.lines[2] == "│D   │QRST│")
    #expect(editor.buffer.columnIndex == 4)
}

@Test func testTableModeTypingAtCellEndDoesNotShiftBorders() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┐",
        "│                │",
        "└────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    let initialWidth = editor.buffer.lines[1].displayWidth

    editor.processKey(.end)
    #expect(editor.buffer.columnIndex == 16)

    editor.processKey(.char("X"))

    let line = editor.buffer.lines[1]
    #expect(line.displayWidth == initialWidth)
    #expect(line.count == 18)
    #expect(line.hasPrefix("│") && line.hasSuffix("│"))
    #expect(line == "│               X│")

    editor.buffer.lines[1] = "│1234567890123456│"
    editor.buffer.columnIndex = 16
    editor.processKey(.char("Z"))

    #expect(editor.buffer.lines[1] == "│1234567890123456│")
    #expect(editor.buffer.lines[1].displayWidth == initialWidth)
}

@Test func testTableModeTypingNearCellEndWrapsInsideCell() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────┐",
        "│      a │",
        "│        │",
        "│        │",
        "└────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 8

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    editor.processKey(.char("b"))
    editor.processKey(.char("c"))
    editor.processKey(.char("d"))

    #expect(editor.buffer.lines[0] == "┌────────┐")
    #expect(editor.buffer.lines[1] == "│      ab│")
    #expect(editor.buffer.lines[2] == "│cd      │")
    #expect(editor.buffer.lines[3] == "│        │")
    #expect(editor.buffer.lines[4] == "└────────┘")
    #expect(editor.buffer.lineIndex == 2)
    #expect(editor.buffer.columnIndex == 3)
}

@Test func testCanvasTableModeTypingOutsideCellDoesNotWritePastBorder() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────┐",
        "│    │",
        "└────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1

    editor.tableModeController.toggleTableMode()
    editor.switchToCanvasMode()
    editor.canvasVisualColumn = 20
    editor.syncCanvasCursorToBuffer()

    editor.processKey(.char("X"))

    #expect(editor.buffer.lines[1] == "│   X│")
    #expect(editor.buffer.lines[1].displayWidth == 6)
    #expect(editor.canvasVisualColumn == 5)

    editor.buffer.lines[1] = "│中中│"
    editor.buffer.columnIndex = 3
    editor.syncCanvasCursorFromBuffer()
    editor.processKey(.char("Y"))

    #expect(editor.buffer.lines[1] == "│中中│")
    #expect(editor.buffer.lines[1].displayWidth == 6)
}

@Test func testTableModeCJKMultiCharTypingSequenceOrder() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌──────────────────┐",
        "│                  │",
        "└──────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    let initialWidth = editor.buffer.lines[1].displayWidth

    editor.processKey(.end)

    for ch in "中文輸入法" {
        editor.processKey(.char(ch))
    }

    let line = editor.buffer.lines[1]
    #expect(line.displayWidth == initialWidth)
    #expect(line.hasPrefix("│") && line.hasSuffix("│"))
    #expect(line.contains("中文輸入法"))
    #expect(line == "│        中文輸入法│")
}

@Test func testTableModeEmojiKeepsCellWidthAndCursorPosition() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────┐",
        "│    │",
        "└────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1

    editor.tableModeController.toggleTableMode()
    let initialWidth = editor.buffer.lines[1].displayWidth

    editor.processKey(.char("❌"))

    #expect(editor.buffer.lines[1] == "│❌  │")
    #expect(editor.buffer.lines[1].displayWidth == initialWidth)
    #expect(editor.buffer.lines[1].visualColumn(forCharacterOffset: editor.buffer.columnIndex) == 3)
}

@Test func testTableModeVisualColumnUpDownNavigationWithCJK() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│   文輸入法中   │    asdadsad    │",
        "├────────────────┼────────────────┤",
        "│     asdasd     │                │",
        "├────────────────┼────────────────┤",
        "│     asdasd     │     asdads     │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 3
    editor.buffer.columnIndex = 6

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    editor.processKey(.arrowUp)

    #expect(editor.buffer.lineIndex == 1)
    let line1Text = editor.buffer.lines[1]
    #expect(line1Text.contains("文輸入法中"))
    #expect(editor.buffer.columnIndex >= 1 && editor.buffer.columnIndex <= 8)

    editor.processKey(.arrowDown)

    #expect(editor.buffer.lineIndex == 3)
}

@Test func testTableModeCtrlShiftArrowCellResizing() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────┬────────┐",
        "│ Cell 1 │ Cell 2 │",
        "├────────┼────────┤",
        "│ Cell 3 │ Cell 4 │",
        "└────────┴────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 3

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    let initialCell = editor.currentTableCell
    #expect(initialCell?.maxCol == 9)

    editor.processKey(.ctrlShiftArrowRight)
    #expect(editor.currentTableCell?.maxCol == 10)
    #expect(editor.buffer.lines[0] == "┌─────────┬────────┐")
    #expect(editor.buffer.lines[1] == "│ Cell 1  │ Cell 2 │")

    editor.processKey(.ctrlShiftArrowLeft)
    #expect(editor.currentTableCell?.maxCol == 9)
    #expect(editor.buffer.lines[0] == "┌────────┬────────┐")

    editor.processKey(.ctrlShiftArrowDown)
    #expect(editor.currentTableCell?.maxLine == 3)
    #expect(editor.buffer.lines.count == 6)
    #expect(editor.buffer.lines[2] == "│        │        │")

    editor.processKey(.ctrlShiftArrowUp)
    #expect(editor.currentTableCell?.maxLine == 2)
    #expect(editor.buffer.lines.count == 5)

    editor.buffer.lineIndex = 3
    editor.buffer.columnIndex = 3
    editor.currentTableCell = TableCellDetector().detectCell(in: editor.buffer.lines, line: 3, col: 3)

    editor.processKey(.ctrlShiftArrowRight)
    #expect(editor.buffer.lines[0] == "┌─────────┬────────┐")
    #expect(editor.buffer.lines[2] == "├─────────┼────────┤")
    #expect(editor.buffer.lines[4] == "└─────────┴────────┘")
}

@Test func testTableModeHelpBar() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────┬────────┐",
        "│ Cell 1 │ Cell 2 │",
        "└────────┴────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 3
    editor.tableModeController.toggleTableMode()

    let renderer = Renderer()
    let helpBar = renderer.renderHelpBar(cols: 80, promptMode: .none, editor: editor)

    #expect(helpBar.contains("F7"))
    #expect(helpBar.contains("Tab"))
    #expect(helpBar.contains("C+⇧+←/→"))
    #expect(helpBar.contains("C+⇧+↑/↓"))

    editor.language = .zh_TW
    let localizedHelpBar = renderer.renderHelpBar(cols: 80, promptMode: .none, editor: editor)
    #expect(localizedHelpBar.contains("離開表格"))
    #expect(localizedHelpBar.contains("下個儲存格"))
    #expect(localizedHelpBar.contains("選取文字"))
    #expect(!localizedHelpBar.contains("Exit Table"))
    #expect(!localizedHelpBar.contains("Select"))
}

@Test func testTableModeCtrlUPasteDoesNotCorruptBorders() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────┬────────┐",
        "│        │ Cell 2 │",
        "└────────┴────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 2
    editor.tableModeController.toggleTableMode()

    editor.clipboardText = "Hello"

    editor.processKey(.ctrl("u"))

    #expect(editor.buffer.lines[0] == "┌────────┬────────┐")
    #expect(editor.buffer.lines[1] == "│ Hello  │ Cell 2 │")
    #expect(editor.buffer.lines[2] == "└────────┴────────┘")
}

@Test func testTableModeRowShrinkDoesNotDeleteNonEmptyLines() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────┬────────┐",
        "│ Line 1 │ Cell 2 │",
        "│ Line 2 │        │",
        "└────────┴────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 2
    editor.tableModeController.toggleTableMode()

    editor.processKey(.ctrlShiftArrowUp)

    #expect(editor.buffer.lines.count == 4)
    #expect(editor.buffer.lines[1] == "│ Line 1 │ Cell 2 │")
    #expect(editor.buffer.lines[2] == "│ Line 2 │        │")
}

@Test func testTableModeConnectorAutoConsumeAndCollisionPrevention() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌─┐     ┌───┐",
        "│y│     │   │",
        "│ ├─────┤   │",
        "└─┘     └───┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1
    editor.tableModeController.toggleTableMode()

    editor.processKey(.ctrlShiftArrowRight)
    #expect(editor.buffer.lines[0] == "┌──┐    ┌───┐")
    #expect(editor.buffer.lines[1] == "│y │    │   │")
    #expect(editor.buffer.lines[2] == "│  ├────┤   │")
    #expect(editor.buffer.lines[3] == "└──┘    └───┘")

    let collidingEditor = Editor()
    collidingEditor.buffer.lines = [
        "┌─┐┌───┐",
        "│y││   │",
        "└─┘└───┘",
    ]
    collidingEditor.buffer.lineIndex = 1
    collidingEditor.buffer.columnIndex = 1
    collidingEditor.tableModeController.toggleTableMode()

    collidingEditor.processKey(.ctrlShiftArrowRight)
    #expect(collidingEditor.buffer.lines[1] == "│y││   │")
}

@Test func testTableModePageUpAndPageDownClampsToCell() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┐",
        "│ Line 1         │",
        "│ Line 2         │",
        "│ Line 3         │",
        "└────────────────┘",
    ]
    editor.buffer.lineIndex = 2
    editor.buffer.columnIndex = 3
    editor.tableModeController.toggleTableMode()

    #expect(editor.isTableModeActive == true)
    #expect(editor.currentTableCell?.innerMinLine == 1)
    #expect(editor.currentTableCell?.innerMaxLine == 3)

    editor.processKey(.pageUp)
    #expect(editor.buffer.lineIndex == 1)

    editor.processKey(.pageUp)
    #expect(editor.buffer.lineIndex == 1)

    editor.processKey(.pageDown)
    #expect(editor.buffer.lineIndex == 3)

    editor.processKey(.pageDown)
    #expect(editor.buffer.lineIndex == 3)
}
