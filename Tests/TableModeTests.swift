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
    editor.toggleTableMode()
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

    // 4. Toggle Table Mode OFF (Alt+T)
    editor.processKey(.alt("t"))
    #expect(editor.isTableModeActive == false)
    #expect(editor.currentTableCell == nil)
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
    editor.toggleTableMode()
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

    editor.toggleTableMode()
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

    editor.toggleTableMode()
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

    editor.toggleTableMode()
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

    editor.toggleTableMode()
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

    editor.toggleTableMode()
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

    editor.toggleTableMode()
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

    editor.toggleTableMode()
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
    editor.toggleTableMode()

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
    editor.toggleTableMode()

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
    editor.toggleTableMode()

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
    editor.toggleTableMode()

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
    #expect(editor.statusMessage == "[ GOTO disabled in Table Mode ]")
    #expect(editor.buffer.lineIndex == 1)
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
    editor.toggleTableMode()

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

    editor.toggleTableMode()
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

    editor.toggleTableMode()
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

    editor.toggleTableMode()
    #expect(editor.currentTableCell?.minCol == 0)

    // Press Right Arrow at rightmost col
    editor.processKey(.arrowRight)

    // Must jump to Cell 2!
    #expect(editor.currentTableCell?.minCol == 17)

    // Move cursor to leftmost col of Cell 2
    editor.buffer.columnIndex = 18
    editor.clampTableModeCursor()

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

    rightEditor.toggleTableMode()
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

    downEditor.toggleTableMode()
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

    editor.toggleTableMode()
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
    deleteEditor.toggleTableMode()

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
    backspaceEditor.toggleTableMode()

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
    editor.toggleTableMode()

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
    editor.toggleTableMode()

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

@Test func testTableModeCtrlKClearsCellTextWithoutDeletingTableRow() throws {
    let editor = Editor()
    editor.buffer.lines = [
        "┌────────────────┬────────────────┐",
        "│abcdef          │keep            │",
        "└────────────────┴────────────────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 1
    editor.toggleTableMode()

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
    editor.toggleTableMode()

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
    editor.toggleTableMode()

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
    editor.toggleTableMode()

    editor.pasteTableCellText("12345678901234567890")

    #expect(editor.buffer.columnIndex == 16)
    #expect(editor.buffer.lines[1] == "│1234567890123456│right cell      │")
}

@Test func testCycleBorderStyleCommand() throws {
    let editor = Editor()
    #expect(editor.defaultBorderStyle == .single)

    // Press Alt+S to cycle border style
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

    editor.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    // Press Ctrl+J (^J) inside Table Mode to center text in cell
    editor.processKey(.ctrl("J"))

    // Line 1 inner width is 16 spaces. "Hello" has width 5.
    // Padding needed = 11. Left padding = 5, Right padding = 6.
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

    editor.toggleTableMode()
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
    editor.buffer.columnIndex = 1  // At left inner boundary 'H'

    editor.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    // 1. Press Backspace at left inner boundary
    editor.processKey(.backspace)
    // Line MUST NOT be modified or corrupted, border at index 0 MUST still be '┌' or '│'
    #expect(editor.buffer.lines[1] == "│ Hello World    │")
    #expect(editor.buffer.columnIndex == 1)

    // 2. Move cursor to 'H' (col 2) and press Delete
    editor.buffer.columnIndex = 2
    editor.processKey(.delete)
    // 'H' deleted, padded with space at right, border MUST NOT move!
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

    editor.toggleTableMode()
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

    logoEditor.toggleTableMode()
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

    editor.toggleTableMode()
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

    editor.toggleTableMode()
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
    editor.enterTableMode(with: TableCell(minLine: 0, maxLine: 3, minCol: 0, maxCol: 5))

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

    editor.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    let initialWidth = editor.buffer.lines[1].displayWidth

    // Move to end of cell (col 16)
    editor.processKey(.end)
    #expect(editor.buffer.columnIndex == 16)

    // Type character 'X' at end of cell
    editor.processKey(.char("X"))

    let line = editor.buffer.lines[1]
    #expect(line.displayWidth == initialWidth)
    #expect(line.count == 18)
    #expect(line.hasPrefix("│") && line.hasSuffix("│"))
    #expect(line == "│               X│")

    // Type when cell is completely filled
    editor.buffer.lines[1] = "│1234567890123456│"
    editor.buffer.columnIndex = 16
    editor.processKey(.char("Z"))

    // Cell MUST NOT absorb 'Z' or expand line
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

    editor.toggleTableMode()
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

    editor.toggleTableMode()
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

    editor.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    let initialWidth = editor.buffer.lines[1].displayWidth

    // Move to end of cell (.end)
    editor.processKey(.end)

    // Type "中文輸入法" sequentially at end of cell
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

    editor.toggleTableMode()
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
    // Cursor on Line 4 (index 3), inside "asdasd" at 'a' (col 6)
    editor.buffer.lineIndex = 3
    editor.buffer.columnIndex = 6

    editor.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    // Press Up Arrow (.arrowUp)
    editor.processKey(.arrowUp)

    // MUST move to Line 2 (index 1), inside cell 1 ("文輸入法中")!
    #expect(editor.buffer.lineIndex == 1)
    let line1Text = editor.buffer.lines[1]
    #expect(line1Text.contains("文輸入法中"))
    #expect(editor.buffer.columnIndex >= 1 && editor.buffer.columnIndex <= 8)

    // Press Down Arrow (.arrowDown)
    editor.processKey(.arrowDown)

    // MUST move back down to Line 4 (index 3), inside cell 1 ("asdasd")!
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

    editor.toggleTableMode()
    #expect(editor.isTableModeActive == true)

    // Initial maxCol of cell 1 is 9
    let initialCell = editor.currentTableCell
    #expect(initialCell?.maxCol == 9)

    // Press Ctrl+Shift+Right -> Expand column width
    editor.processKey(.ctrlShiftArrowRight)
    #expect(editor.currentTableCell?.maxCol == 10)
    #expect(editor.buffer.lines[0] == "┌─────────┬────────┐")
    #expect(editor.buffer.lines[1] == "│ Cell 1  │ Cell 2 │")

    // Press Ctrl+Shift+Left -> Shrink column width back
    editor.processKey(.ctrlShiftArrowLeft)
    #expect(editor.currentTableCell?.maxCol == 9)
    #expect(editor.buffer.lines[0] == "┌────────┬────────┐")

    // Press Ctrl+Shift+Down -> Expand row height
    editor.processKey(.ctrlShiftArrowDown)
    #expect(editor.currentTableCell?.maxLine == 3)
    #expect(editor.buffer.lines.count == 6)
    #expect(editor.buffer.lines[2] == "│        │        │")

    // Press Ctrl+Shift+Up -> Shrink row height back
    editor.processKey(.ctrlShiftArrowUp)
    #expect(editor.currentTableCell?.maxLine == 2)
    #expect(editor.buffer.lines.count == 5)

    // Move to Cell 3 in Row 2 (line 3)
    editor.buffer.lineIndex = 3
    editor.buffer.columnIndex = 3
    editor.currentTableCell = TableCellDetector().detectCell(in: editor.buffer.lines, line: 3, col: 3)

    // Expand column 1 width from Row 2
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
    editor.toggleTableMode()

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
    editor.toggleTableMode()

    editor.clipboardText = "Hello"

    // Press Ctrl+U in Table Mode
    editor.processKey(.ctrl("u"))

    // Verify cell contents and intact borders
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
    editor.toggleTableMode()

    // Try to shrink height when both inner lines have text
    editor.processKey(.ctrlShiftArrowUp)

    // Verify height did NOT shrink and Line 2 was NOT deleted
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
    editor.toggleTableMode()

    // Expand Left Box 1 width -> Should consume 1 connector char '─' without moving Right Box 2
    editor.processKey(.ctrlShiftArrowRight)
    #expect(editor.buffer.lines[0] == "┌──┐    ┌───┐")
    #expect(editor.buffer.lines[1] == "│y │    │   │")
    #expect(editor.buffer.lines[2] == "│  ├────┤   │")
    #expect(editor.buffer.lines[3] == "└──┘    └───┘")

    // Test direct collision prevention:
    let collidingEditor = Editor()
    collidingEditor.buffer.lines = [
        "┌─┐┌───┐",
        "│y││   │",
        "└─┘└───┘",
    ]
    collidingEditor.buffer.lineIndex = 1
    collidingEditor.buffer.columnIndex = 1
    collidingEditor.toggleTableMode()

    collidingEditor.processKey(.ctrlShiftArrowRight)
    // Verify width was NOT expanded into colliding Box 2
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
    editor.buffer.lineIndex = 2  // "│ Line 2         │"
    editor.buffer.columnIndex = 3
    editor.toggleTableMode()

    #expect(editor.isTableModeActive == true)
    #expect(editor.currentTableCell?.innerMinLine == 1)
    #expect(editor.currentTableCell?.innerMaxLine == 3)

    // Press PageUp -> should move to top line of cell (line 1), NOT outside cell
    editor.processKey(.pageUp)
    #expect(editor.buffer.lineIndex == 1)

    // Press PageUp again -> should stay at top line of cell (line 1)
    editor.processKey(.pageUp)
    #expect(editor.buffer.lineIndex == 1)

    // Press PageDown -> should move to bottom line of cell (line 3), NOT outside cell
    editor.processKey(.pageDown)
    #expect(editor.buffer.lineIndex == 3)

    // Press PageDown again -> should stay at bottom line of cell (line 3)
    editor.processKey(.pageDown)
    #expect(editor.buffer.lineIndex == 3)
}
