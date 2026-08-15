import Foundation
import Testing

@testable import Editor

@Test func testTableModeToggleAndNavigation() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│ Hello          │ World          │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 3

    // 1. Toggle Table Mode ON (Alt+T)
    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)
    #expect(editor.currentTableCell != nil)
    #expect(editor.currentTableCell?.minLine == 0)
    #expect(editor.currentTableCell?.maxLine == 2)

    // 2. Test typing character inside cell ('!')
    editor.processKey(.char("!"))
    #expect(editor.buffer.lines[1].contains("H!ello"))

    // 3. Test Tab navigation to next cell
    editor.processKey(.tab)
    #expect(editor.currentTableCell?.minCol == 17)  // Moved to cell 2

    // 4. Test Shift+Tab (Backtab) navigation back to previous cell
    editor.processKey(.backtab)
    #expect(editor.currentTableCell?.minCol == 0)  // Moved back to cell 1

    // 5. Toggle Table Mode OFF (Alt+T)
    editor.processKey(.alt("t"))
    #expect(editor.isTableModeActive == false)
    #expect(editor.currentTableCell == nil)
}

@Test func testCanvasTableModeBacktabSyncsVisualCursorToPreviousCell() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│ Left           │ Right          │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 20
    editor.switchToCanvasMode()
    editor.tableModeController.toggleTableMode()

    #expect(editor.isCanvasModeActive == true)
    #expect(editor.isTableModeActive == true)
    #expect(editor.currentTableCell?.minCol == 17)
    #expect(editor.canvasVisualColumn == 20)

    editor.processKey(.backtab)

    #expect(editor.currentTableCell?.minCol == 0)
    #expect(editor.buffer.columnIndex == 1)
    #expect(editor.canvasVisualColumn == 1)
    #expect(editor.renderer.render(editor: editor, rows: 8, cols: 40).contains("\u{1B}[3;7H"))
}

@Test func testTableModeNumericGotoStaysInCurrentCell() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│ first          │ other          │",
        "├────────────────┼────────────────┤",
        "│ second         │ target         │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 3
    editor.tableModeController.toggleTableMode()

    editor.promptLogoMacro()
    for ch in "4,20" {
        editor.processKey(.char(ch))
    }
    editor.processKey(.enter)

    #expect(editor.currentTableCell?.minLine == 0)
    #expect(editor.currentTableCell?.minCol == 0)
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 16)
}

@Test func testTableModeGotoPromptStaysInCurrentCell() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│ first          │ other          │",
        "├────────────────┼────────────────┤",
        "│ second         │ target         │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 3
    editor.tableModeController.toggleTableMode()

    editor.processKey(.alt("/"))
    for ch in "4 20" {
        editor.processKey(.char(ch))
    }
    editor.processKey(.enter)

    #expect(editor.currentTableCell?.minLine == 0)
    #expect(editor.currentTableCell?.minCol == 0)
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 16)
}

@Test func testTableModeSpellCheckIsScopedToCurrentCell() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│ 123            │ qxzywkwk       │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 3
    editor.tableModeController.toggleTableMode()

    editor.processKey(.ctrl("T"))

    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 3)
    if case .none = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Spell check should not prompt for a word outside the current table cell")
    }
}

@Test func testTableModeToggleCommentOnlyChangesCurrentCell() throws {
    let editor = Editor()
    editor.buffer.filePath = "main.swift"
    editor.buffer.lines = [
        "┌────────────────────┬────────────────────┐",
        "│ let x = 1          │ let y = 2          │",
        "└────────────────────┴────────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 3
    editor.tableModeController.toggleTableMode()

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)

    #expect(editor.buffer.lines[1] == "│ // let x = 1       │ let y = 2          │")
}

@Test func testTableModeCommentPrefixDoesNotBecomeCellBorder() throws {
    let line = "│ // let x = 1       │ let y = 2          │"
    let cell = TableCell(minLine: 0, maxLine: 2, minCol: 0, maxCol: 21)

    let borders = TableModeController.findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)

    #expect(borders.left == 0)
    #expect(borders.right == 21)
}

@Test func testTableModeToggleCommentSelectionOnlyChangesCurrentCell() throws {
    let editor = Editor()
    editor.buffer.filePath = "main.swift"
    editor.buffer.lines = [
        "┌────────────────────┬────────────────────┐",
        "│ // let x = 1       │ // let y = 2       │",
        "│ // let z = 3       │ // let w = 4       │",
        "└────────────────────┴────────────────────┘",
    ]
    editor.buffer.lineIndex = 2
    editor.buffer.columnIndex = 10
    editor.tableModeController.enterTableMode(with: TableCell(minLine: 0, maxLine: 3, minCol: 0, maxCol: 21))
    editor.buffer.selectionMark = (line: 1, column: 1)

    _ = editor.commandRegistry.dispatch(id: .editToggleComment, editor: editor)

    #expect(editor.buffer.lines[1] == "│ let x = 1          │ // let y = 2       │")
    #expect(editor.buffer.lines[2] == "│ let z = 3          │ // let w = 4       │")
}

@Test func testCreateTableDimensionsPrompt() throws {
    let editor = Editor()
    #expect(editor.isTableModeActive == false)

    // Press Alt+T when no box exists around cursor
    editor.processKey(.alt("t"))

    // Verify prompt is tableDimensions (pre-filled with "3 3 16")
    if case .tableDimensions = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Alt+T when no table exists should trigger tableDimensions prompt")
    }

    // Press Enter to accept default 3x3 table dimensions
    editor.processKey(.enter)
    #expect(editor.isTableModeActive == true)
    #expect(editor.currentTableCell != nil)
    #expect(editor.buffer.lines.count >= 4)
}

@Test func testTableModeDoesNotActivateOnBoxFrame() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌──────────────────┐",
        "│                  │",
        "│                  │",
        "│                  │",
        "└──────────────────┘",
    ]
    editor.buffer.lineIndex = 4
    editor.buffer.columnIndex = 16

    editor.processKey(.f7)

    #expect(editor.isTableModeActive == false)
    #expect(editor.currentTableCell == nil)
    let promptIsNone: Bool
    if case .none = editor.currentPromptMode {
        promptIsNone = true
    } else {
        promptIsNone = false
    }
    #expect(promptIsNone)
}

@Test func testTableModeBacktabSkipsConnectorAndEntersCellAbove() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────┐",
        "│        │",
        "│        │",
        "│        │",
        "└──┬─────┘",
        "   │",
        "┌──┴─────────────┬────────────────┐",
        "│          x     │                │",
        "├────────────────┼────────────────┤",
        "│                │                │",
        "├────────────────┼────────────────┤",
        "│                │                │",
        "├────────────────┼────────────────┤",
        "│                │                │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 7
    editor.buffer.columnIndex = 11

    editor.tableModeController.toggleTableMode()
    #expect(editor.currentTableCell?.minLine == 6)
    #expect(editor.currentTableCell?.minCol == 0)

    editor.processKey(.backtab)

    #expect(editor.currentTableCell?.minLine == 0)
    #expect(editor.currentTableCell?.maxLine == 4)
    #expect(editor.buffer.lineIndex == 3)
}

@Test func testTableModeCellTypingAndBackspaceKeepBordersAligned() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│                │                │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1  // First position inside Cell 1

    // 1. Toggle Table Mode ON (Alt+T)
    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)
    let initialLine = editor.buffer.lines[1]
    #expect(initialLine.count == 35)
    #expect(initialLine[initialLine.index(initialLine.startIndex, offsetBy: 17)] == "│")  // Right border of cell 1

    // 2. Type "Hello"
    for ch in "Hello" {
        editor.processKey(.char(ch))
    }

    // Table Mode MUST STILL BE ACTIVE!
    #expect(editor.isTableModeActive == true)

    // Line length MUST STILL BE 35, right border MUST STILL BE AT index 17!
    let lineAfterTyping = editor.buffer.lines[1]
    #expect(lineAfterTyping.count == 35)
    #expect(lineAfterTyping[lineAfterTyping.index(lineAfterTyping.startIndex, offsetBy: 17)] == "│")
    #expect(lineAfterTyping.contains("│Hello           │"))

    // 3. Backspace "Hello"
    for _ in 0..<5 {
        editor.processKey(.backspace)
    }

    // Table Mode MUST STILL BE ACTIVE!
    #expect(editor.isTableModeActive == true)

    let lineAfterBackspace = editor.buffer.lines[1]
    #expect(lineAfterBackspace.count == 35)
    #expect(lineAfterBackspace[lineAfterBackspace.index(lineAfterBackspace.startIndex, offsetBy: 17)] == "│")
    #expect(lineAfterBackspace.contains("│                │"))
}

@Test func testTableModeCJKCharacterInsertion() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│                │                │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    let initialWidth = editor.buffer.lines[1].displayWidth

    // Type CJK Chinese characters ("測試")
    for ch in "測試" {
        editor.processKey(.char(ch))
    }

    #expect(editor.isTableModeActive == true)
    let line = editor.buffer.lines[1]
    #expect(line.contains("│測試") && line.contains("│"))
    // Total display width MUST remain unchanged (35 display columns)
    #expect(line.displayWidth == initialWidth)
}

@Test func testTableModeCJKCharacterBorderAlignmentAndBackspace() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│                │                │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    let initialLineWidth = editor.buffer.lines[1].displayWidth

    // Type 6 CJK characters (display width 12)
    let inputString = "測試中文表格"
    for ch in inputString {
        editor.processKey(.char(ch))
    }

    let lineAfterCJK = editor.buffer.lines[1]
    // 1. Display width MUST stay strictly 35
    #expect(lineAfterCJK.displayWidth == initialLineWidth)
    // 2. Contains CJK string
    #expect(lineAfterCJK.contains("│測試中文表格"))

    // Type ASCII character
    editor.processKey(.char("!"))
    let lineAfterASCII = editor.buffer.lines[1]
    #expect(lineAfterASCII.displayWidth == initialLineWidth)

    // Backspace ASCII character
    editor.processKey(.backspace)
    #expect(editor.buffer.lines[1].displayWidth == initialLineWidth)

    // Backspace all CJK characters one by one
    for _ in 0..<inputString.count {
        editor.processKey(.backspace)
        #expect(editor.buffer.lines[1].displayWidth == initialLineWidth)
    }

    // Verify line returned to empty cell state with intact borders
    #expect(editor.buffer.lines[1] == "│                │                │")
}

@Test func testTableModeTabToNextRow() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│ Row1 Cell1     │ Row1 Cell2     │",
        "├────────────────┼────────────────┤",
        "│ Row2 Cell1     │ Row2 Cell2     │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 20  // Inside Row1 Cell2 (last cell of row 1)

    editor.tableModeController.toggleTableMode()
    #expect(editor.currentTableCell?.minCol == 17)  // Locked to Row1 Cell2

    // Press Tab from last cell of Row 1
    editor.processKey(.tab)

    // Must jump to Row 2 Cell 1!
    #expect(editor.isTableModeActive == true)
    #expect(editor.currentTableCell?.minLine == 2)
    #expect(editor.currentTableCell?.minCol == 0)  // First cell of Row 2
}

@Test func testTableModeTabNavigatesAcrossConnectorToRightBox() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────┐   ┌────────────────────────────┐",
        "│        │   │            zzzz            │",
        "│ aaaaa  ├───┤            zzzz            │",
        "└─┬──────┘   └────────────────────────────┘",
        "  │",
        "┌─┴────────────────────────────────────┐",
        "│                                      │",
        "│                                      │",
        "│                                      │",
        "└──────────────────────────────────────┘",
    ]
    editor.buffer.lineIndex = 2
    editor.buffer.columnIndex = 3

    editor.tableModeController.toggleTableMode()
    #expect(editor.currentTableCell?.minCol == 0)
    #expect(editor.currentTableCell?.maxCol == 9)

    editor.processKey(.tab)

    #expect(editor.isTableModeActive == true)
    #expect(editor.currentTableCell?.minCol == 13)
    #expect(editor.currentTableCell?.maxCol == 42)
    #expect(editor.buffer.lineIndex == 2)
    #expect(editor.buffer.columnIndex == 14)
}

@Test func testTableModeGreenBackgroundRendering() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┐",
        "│ Active Cell    │",
        "└────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 2

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    let screenOutput = editor.renderer.render(editor: editor, rows: 10, cols: 40)
    // Verify output contains green background ANSI code "\u{1B}[42;" or "\u{1B}[42m"
    #expect(screenOutput.contains("\u{1B}[42;"))
}

@Test func testTableModeCJKGreenBackgroundDoesNotOverflowBorders() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│                │                │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    // Type CJK Chinese characters ("測試")
    for ch in "測試" {
        editor.processKey(.char(ch))
    }

    let screenOutput = editor.renderer.render(editor: editor, rows: 10, cols: 50)

    // Green background code is "\u{1B}[42;97;1m"
    // Border character '│' MUST NOT be wrapped in green background ANSI code!
    #expect(!screenOutput.contains("\u{1B}[42;97;1m│"))
    // Green background MUST be applied to CJK characters inside the active cell
    #expect(screenOutput.contains("\u{1B}[42;97;1m測"))
    #expect(screenOutput.contains("\u{1B}[42;97;1m試"))
}

@Test func testTableModeCellOverflowBlocked() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────┐",
        "│    │",
        "└────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1  // 4 spaces inside cell (cols 1..4)

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    // Type 5 characters into cell of capacity 4
    for ch in "12345" {
        editor.processKey(.char(ch))
    }

    // 5th character MUST be blocked! Line MUST remain "│1234│"
    let line = editor.buffer.lines[1]
    #expect(line == "│1234│")
}

@Test func testTableModeCtrlQLogoPrintDoesNotOverflowCell() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────────────┐",
        "│TYPE \"ABCDEFGHIJ        │",
        "└────────────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 2
    editor.tableModeController.toggleTableMode()

    editor.buffer.selectionMark = (line: 1, column: 1)
    editor.buffer.columnIndex = 17
    editor.processKey(.ctrl("Q"))

    #expect(editor.buffer.lines[1] == "│TYPE \"ABCDEFGHIJABCDEFGH│")
    #expect(editor.buffer.lines[1].count == 26)
    #expect(editor.buffer.lines[1].last == "│")
}

@Test func testTableModeFillFillsCurrentCell() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌──────┐",
        "│      │",
        "│      │",
        "└──────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 2
    editor.tableModeController.toggleTableMode()

    let didRun = editor.runLogoScript("FILL \"中")

    #expect(didRun == true)
    #expect(
        editor.buffer.lines == [
            "┌──────┐",
            "│中中中│",
            "│中中中│",
            "└──────┘",
        ])
    #expect(editor.statusMessage == "[ Filled cell ]")
    #expect(editor.isTableModeActive == true)
    #expect(editor.currentTableCell != nil)
}

@Test func testTableModeCtrlQFillFillsCurrentCell() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────┐",
        "│FILL \"x     │",
        "└────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 2
    editor.tableModeController.toggleTableMode()

    editor.buffer.selectionMark = (line: 1, column: 1)
    editor.buffer.columnIndex = 8
    editor.processKey(.ctrl("Q"))

    #expect(
        editor.buffer.lines == [
            "┌────────────┐",
            "│xxxxxxxxxxxx│",
            "└────────────┘",
        ])
    #expect(editor.statusMessage == "[ Filled cell ]")
}

@Test func testTableModeCtrlQBlocksLogoDrawingCommands() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────┐",
        "│BOX 8 3     │",
        "└────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 2
    editor.tableModeController.toggleTableMode()

    editor.buffer.selectionMark = (line: 1, column: 1)
    editor.buffer.columnIndex = 8
    editor.processKey(.ctrl("Q"))

    #expect(
        editor.buffer.lines == [
            "┌────────────┐",
            "│BOX 8 3     │",
            "└────────────┘",
        ])
    #expect(editor.statusMessage == "[ BOX disabled in Table Mode ]")

    editor.buffer.lines[1] = "│DRAWBOX 8 3 │"
    editor.buffer.selectionMark = (line: 1, column: 1)
    editor.buffer.columnIndex = 12
    editor.processKey(.ctrl("Q"))

    #expect(
        editor.buffer.lines == [
            "┌────────────┐",
            "│DRAWBOX 8 3 │",
            "└────────────┘",
        ])
    #expect(editor.statusMessage == "[ DRAWBOX disabled in Table Mode ]")

    editor.buffer.lines[1] = "│TABLE       │"
    editor.buffer.selectionMark = (line: 1, column: 1)
    editor.buffer.columnIndex = 6
    editor.processKey(.ctrl("Q"))

    #expect(
        editor.buffer.lines == [
            "┌────────────┐",
            "│TABLE       │",
            "└────────────┘",
        ])
    #expect(editor.statusMessage == "[ TABLE disabled in Table Mode ]")

    editor.buffer.lines[1] = "│GOTO 1 1    │"
    editor.buffer.selectionMark = (line: 1, column: 1)
    editor.buffer.columnIndex = 11
    editor.processKey(.ctrl("Q"))
    #expect(editor.statusMessage == "[ GOTO disabled in Table Mode ]")

    editor.goToLocation(line: 1, column: 1)
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 1)
}

@Test func testTableModeBlocksProcedureContainingLogoDrawingCommand() throws {
    let editor = Editor()
    editor.logoEngine.execute("TO MAKEBOX BOX 8 3 END")
    editor.buffer.lines = [
        "┌────────────┐",
        "│MAKEBOX     │",
        "└────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 2
    editor.tableModeController.toggleTableMode()

    editor.buffer.selectionMark = (line: 1, column: 1)
    editor.buffer.columnIndex = 8
    editor.processKey(.ctrl("Q"))

    #expect(
        editor.buffer.lines == [
            "┌────────────┐",
            "│MAKEBOX     │",
            "└────────────┘",
        ])
    #expect(editor.statusMessage == "[ BOX disabled in Table Mode ]")

    editor.logoEngine.execute("TO PAINTBOX DRAWBOX 8 3 END")
    editor.buffer.lines[1] = "│PAINTBOX    │"
    editor.buffer.selectionMark = (line: 1, column: 1)
    editor.buffer.columnIndex = 9
    editor.processKey(.ctrl("Q"))

    #expect(
        editor.buffer.lines == [
            "┌────────────┐",
            "│PAINTBOX    │",
            "└────────────┘",
        ])
    #expect(editor.statusMessage == "[ DRAWBOX disabled in Table Mode ]")
}

@Test func testTableModeHomeAndEndNavigation() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│ Hello World    │                │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 5  // Inside Cell 1

    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    // Press Home (.home)
    editor.processKey(.home)
    #expect(editor.buffer.columnIndex == 1)  // Front of cell

    // Press End (.end)
    editor.processKey(.end)
    #expect(editor.buffer.columnIndex == 16)  // End of cell

    // Press Ctrl+A (^A)
    editor.processKey(.ctrl("a"))
    #expect(editor.buffer.columnIndex == 1)  // Front of cell

    // Press Ctrl+E (^E)
    editor.processKey(.ctrl("e"))
    #expect(editor.buffer.columnIndex == 16)  // End of cell

    // Test CJK cell
    editor.buffer.lines[1] = "│ 測試中文表格   │                │"
    editor.buffer.columnIndex = 4

    // Press Home
    editor.processKey(.home)
    #expect(editor.buffer.columnIndex == 1)  // Front of CJK cell

    // Press End
    editor.processKey(.end)
    #expect(editor.buffer.columnIndex == 10)  // End of CJK cell (rightBorder - 1)
}

@Test func testTableModeUpDownArrowNavigation() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│ Row1 Cell1     │ Row1 Cell2     │",
        "├────────────────┼────────────────┤",
        "│ Row2 Cell1     │ Row2 Cell2     │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 2  // Row 1 Cell 1

    editor.tableModeController.toggleTableMode()
    #expect(editor.currentTableCell?.minLine == 0)

    // Press Down Arrow from Row 1 Cell 1
    editor.processKey(.arrowDown)

    // Must jump to Row 2 Cell 1!
    #expect(editor.currentTableCell?.minLine == 2)

    // Press Up Arrow from Row 2 Cell 1
    editor.processKey(.arrowUp)

    // Must jump back to Row 1 Cell 1!
    #expect(editor.currentTableCell?.minLine == 0)
}

@Test func testTableModeLeftRightArrowCellBoundaryJump() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│ Row1 Cell1     │ Row1 Cell2     │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 16  // Rightmost col of Cell 1 (cell.innerMaxCol = 16)

    editor.tableModeController.toggleTableMode()
    #expect(editor.currentTableCell?.minCol == 0)

    // Press Right Arrow at rightmost col
    editor.processKey(.arrowRight)

    // Must jump to Cell 2!
    #expect(editor.currentTableCell?.minCol == 17)

    // Move cursor to leftmost col of Cell 2
    editor.buffer.columnIndex = 18
    editor.tableModeController.clampTableModeCursor()

    // Press Left Arrow at leftmost col
    editor.processKey(.arrowLeft)

    // Must jump back to Cell 1!
    #expect(editor.currentTableCell?.minCol == 0)
}

@Test func testTableModeArrowKeysDoNotCrossTablesOrConnectors() throws {
    let rightEditor = Editor()
    rightEditor.buffer.lines = [
        "┌────────┐   ┌────────────────────────────┐",
        "│        │   │            zzzz            │",
        "│ aaaaa  ├───┤            zzzz            │",
        "└────────┘   └────────────────────────────┘",
    ]
    rightEditor.buffer.lineIndex = 2
    rightEditor.buffer.columnIndex = 8

    rightEditor.tableModeController.toggleTableMode()
    #expect(rightEditor.currentTableCell?.minCol == 0)

    rightEditor.processKey(.arrowRight)

    #expect(rightEditor.currentTableCell?.minCol == 0)
    #expect(rightEditor.currentTableCell?.maxCol == 9)

    let downEditor = Editor()
    downEditor.buffer.lines = [
        "┌────┐",
        "│ aa │",
        "└────┘",
        "",
        "┌────┐",
        "│ bb │",
        "└────┘",
    ]
    downEditor.buffer.lineIndex = 1
    downEditor.buffer.columnIndex = 2

    downEditor.tableModeController.toggleTableMode()
    #expect(downEditor.currentTableCell?.minLine == 0)

    downEditor.processKey(.arrowDown)

    #expect(downEditor.currentTableCell?.minLine == 0)
    #expect(downEditor.buffer.lineIndex == 1)
}

@Test func testTableModeShiftArrowExtendsSelectionWithinCell() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│ Row1 Cell1     │ Row1 Cell2     │",
        "├────────────────┼────────────────┤",
        "│ Row2 Cell1     │ Row2 Cell2     │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 3
    editor.buffer.columnIndex = 2  // Row 2 Cell 1

    editor.tableModeController.toggleTableMode()
    #expect(editor.currentTableCell?.minLine == 2)

    editor.processKey(.shiftArrowLeft)
    editor.processKey(.shiftArrowLeft)

    #expect(editor.currentTableCell?.minLine == 2)
    #expect(editor.currentTableCell?.minCol == 0)
    #expect(editor.buffer.selectionMark?.line == 3)
    #expect(editor.buffer.selectionMark?.column == 2)
    #expect(editor.buffer.lineIndex == 3)
    #expect(editor.buffer.columnIndex == 1)

    editor.processKey(.shiftArrowRight)

    #expect(editor.buffer.selectionMark?.line == 3)
    #expect(editor.buffer.selectionMark?.column == 2)
    #expect(editor.buffer.lineIndex == 3)
    #expect(editor.buffer.columnIndex == 2)
}

@Test func testTableModeDeleteAndBackspaceClearSelectionWithoutMovingBorders() throws {
    let deleteEditor = Editor()
    deleteEditor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│abcdef          │keep            │",
        "└────────────────┴────────────────┘",
    ]
    deleteEditor.buffer.lineIndex = 1
    deleteEditor.buffer.columnIndex = 1
    deleteEditor.tableModeController.toggleTableMode()

    deleteEditor.processKey(.shiftArrowRight)
    deleteEditor.processKey(.shiftArrowRight)
    deleteEditor.processKey(.shiftArrowRight)
    deleteEditor.processKey(.delete)

    #expect(deleteEditor.buffer.lines[1] == "│   def          │keep            │")
    #expect(deleteEditor.buffer.selectionMark == nil)
    #expect(deleteEditor.currentTableCell?.minCol == 0)
    #expect(deleteEditor.currentTableCell?.maxCol == 17)

    let backspaceEditor = Editor()
    backspaceEditor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│abcdef          │keep            │",
        "└────────────────┴────────────────┘",
    ]
    backspaceEditor.buffer.lineIndex = 1
    backspaceEditor.buffer.columnIndex = 1
    backspaceEditor.tableModeController.toggleTableMode()

    backspaceEditor.processKey(.shiftArrowRight)
    backspaceEditor.processKey(.shiftArrowRight)
    backspaceEditor.processKey(.shiftArrowRight)
    backspaceEditor.processKey(.backspace)

    #expect(backspaceEditor.buffer.lines[1] == "│   def          │keep            │")
    #expect(backspaceEditor.buffer.selectionMark == nil)
    #expect(backspaceEditor.currentTableCell?.minCol == 0)
    #expect(backspaceEditor.currentTableCell?.maxCol == 17)
}

@Test func testTableModeMultiLineSelectionDoesNotExceedCellBorders() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│line 1          │right cell      │",
        "│line 2          │right cell      │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1
    editor.tableModeController.toggleTableMode()

    editor.buffer.selectionMark = (line: 1, column: 1)
    editor.buffer.lineIndex = 2
    editor.buffer.columnIndex = 7

    #expect(!editor.buffer.isCharacterSelected(line: 1, col: 0))
    #expect(editor.buffer.isCharacterSelected(line: 1, col: 1))
    #expect(editor.buffer.isCharacterSelected(line: 1, col: 6))
    #expect(!editor.buffer.isCharacterSelected(line: 1, col: 17))
    #expect(!editor.buffer.isCharacterSelected(line: 1, col: 18))

    #expect(!editor.buffer.isCharacterSelected(line: 2, col: 0))
    #expect(editor.buffer.isCharacterSelected(line: 2, col: 1))
    #expect(editor.buffer.isCharacterSelected(line: 2, col: 6))
    #expect(!editor.buffer.isCharacterSelected(line: 2, col: 7))
    #expect(!editor.buffer.isCharacterSelected(line: 2, col: 17))
}

@Test func testTableModeSingleLineSelectionInMultiLineCellDoesNotHighlightUnselectedLines() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│aaaa            │right cell      │",
        "│                │right cell      │",
        "│                │right cell      │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1
    editor.tableModeController.toggleTableMode()

    editor.buffer.selectionMark = (line: 1, column: 1)
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 3

    #expect(editor.buffer.isCharacterSelected(line: 1, col: 1))
    #expect(editor.buffer.isCharacterSelected(line: 1, col: 2))
    #expect(!editor.buffer.isCharacterSelected(line: 1, col: 3))
    #expect(!editor.buffer.isCharacterSelected(line: 1, col: 4))

    #expect(!editor.buffer.isCharacterSelected(line: 2, col: 1))
    #expect(!editor.buffer.isCharacterSelected(line: 2, col: 2))
    #expect(!editor.buffer.isCharacterSelected(line: 3, col: 1))
    #expect(!editor.buffer.isCharacterSelected(line: 3, col: 2))
}

@Test func testTableModeModernKeymapCopyCutPaste() throws {
    let editor = Editor()
    editor.apply(.keymap(.modern))
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│ Hello          │ World          │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 3

    // 1. Toggle Table Mode ON
    editor.tableModeController.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    // 2. Test Copy (Ctrl+C) in Modern Mode inside cell
    editor.processKey(.ctrl("c"))
    #expect(editor.clipboardText?.contains("Hello") == true)
    #expect(editor.buffer.lines[1].contains("Hello")) // Cell text still intact

    // 3. Move to second cell and Paste (Ctrl+V)
    editor.processKey(.tab)
    #expect(editor.currentTableCell?.minCol == 17)
    // Cut second cell text first with Ctrl+X
    editor.processKey(.ctrl("x"))
    #expect(editor.clipboardText?.contains("World") == true)
    #expect(!editor.buffer.lines[1].contains("World"))

    // Paste with Ctrl+V (not PageDown!)
    editor.clipboardText = "Test"
    editor.processKey(.ctrl("v"))
    #expect(editor.buffer.lines[1].contains("Test"))

    // 4. Test secondary aliases (^K / ^U) also work in Modern table mode
    editor.processKey(.ctrl("k"))
    #expect(editor.clipboardText?.contains("Test") == true)
    editor.clipboardText = "Alias"
    editor.processKey(.ctrl("u"))
    #expect(editor.buffer.lines[1].contains("Alias"))
}

