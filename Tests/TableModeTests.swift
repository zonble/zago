import Foundation
import Testing

@testable import Editor

@Test func testTableCellDetectorSingleUnicode() throws {
    let detector = TableCellDetector()
    let lines = [
        "┌────────────────┬────────────────┐",
        "│ Cell 1         │ Cell 2         │",
        "├────────────────┼────────────────┤",
        "│ Cell 3         │ Cell 4         │",
        "└────────────────┴────────────────┘",
    ]

    // Detect cell around cursor at line 1, col 5 ("Cell 1")
    let cell1 = detector.detectCell(in: lines, line: 1, col: 5)
    #expect(cell1 != nil)
    #expect(cell1?.minLine == 0)
    #expect(cell1?.maxLine == 2)
    #expect(cell1?.minCol == 0)
    #expect(cell1?.maxCol == 17)
    #expect(cell1?.style == .single)

    // Detect cell around cursor at line 3, col 20 ("Cell 4")
    let cell4 = detector.detectCell(in: lines, line: 3, col: 20)
    #expect(cell4 != nil)
    #expect(cell4?.minLine == 2)
    #expect(cell4?.maxLine == 4)
    #expect(cell4?.minCol == 17)
    #expect(cell4?.maxCol == 34)
}

@Test func testTableCellDetectorTreatsJunctionAsVerticalBoundary() throws {
    let detector = TableCellDetector()
    let lines = [
        "┌────────────────┬─",
        "│ Cell           ├─",
        "└────────────────┴─",
    ]

    let cell = detector.detectCell(in: lines, line: 1, col: 5)
    #expect(cell != nil)
    #expect(cell?.minLine == 0)
    #expect(cell?.maxLine == 2)
    #expect(cell?.minCol == 0)
    #expect(cell?.maxCol == 17)
    #expect(cell?.style == .single)
}

@Test func testTableCellDetectorMarkdownTable() throws {
    let detector = TableCellDetector()
    let lines = [
        "| Header 1       | Header 2       |",
        "| -------------- | -------------- |",
        "| Data 1         | Data 2         |",
    ]

    // Detect markdown cell at line 2, col 5 ("Data 1")
    let cell = detector.detectCell(in: lines, line: 2, col: 5)
    #expect(cell != nil)
    #expect(cell?.minLine == 1)
    #expect(cell?.maxLine == 3)
    #expect(cell?.style == .markdown)
}

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

@Test func testCreateTableConfirmPrompt() throws {
    let editor = Editor()
    #expect(editor.isTableModeActive == false)

    // Press Alt+T when no box exists around cursor
    editor.processKey(.alt("t"))

    // Verify prompt is confirmCreateTable
    if case .confirmCreateTable = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Alt+T when no table exists should trigger confirmCreateTable prompt")
    }

    // Press 'Y' to confirm creation
    editor.processKey(.char("Y"))
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

    // Type CJK Chinese characters ("測試")
    for ch in "測試" {
        editor.processKey(.char(ch))
    }

    #expect(editor.isTableModeActive == true)
    let line = editor.buffer.lines[1]
    // Right border MUST still be '│'
    #expect(line.contains("│測試") && line.contains("│"))
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

    let screenOutput = editor.generateScreenOutput(rows: 10, cols: 40)
    // Verify output contains green background ANSI code "\u{1B}[42;" or "\u{1B}[42m"
    #expect(screenOutput.contains("\u{1B}[42;"))
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

    editor.selectionMark = (line: 1, column: 1)
    editor.buffer.columnIndex = 17
    editor.processKey(.ctrl("Q"))

    #expect(editor.buffer.lines[1] == "│TYPE \"ABCDEFGHIJABCDEFGH│")
    #expect(editor.buffer.lines[1].count == 26)
    #expect(editor.buffer.lines[1].last == "│")
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

    editor.selectionMark = (line: 1, column: 1)
    editor.buffer.columnIndex = 8
    editor.processKey(.ctrl("Q"))

    #expect(editor.buffer.lines == [
        "┌────────────┐",
        "│BOX 8 3     │",
        "└────────────┘",
    ])
    #expect(editor.statusMessage == "[ BOX disabled in Table Mode ]")

    editor.buffer.lines[1] = "│DRAWBOX 8 3 │"
    editor.selectionMark = (line: 1, column: 1)
    editor.buffer.columnIndex = 12
    editor.processKey(.ctrl("Q"))

    #expect(editor.buffer.lines == [
        "┌────────────┐",
        "│DRAWBOX 8 3 │",
        "└────────────┘",
    ])
    #expect(editor.statusMessage == "[ DRAWBOX disabled in Table Mode ]")

    editor.buffer.lines[1] = "│TABLE       │"
    editor.selectionMark = (line: 1, column: 1)
    editor.buffer.columnIndex = 6
    editor.processKey(.ctrl("Q"))

    #expect(editor.buffer.lines == [
        "┌────────────┐",
        "│TABLE       │",
        "└────────────┘",
    ])
    #expect(editor.statusMessage == "[ TABLE disabled in Table Mode ]")
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

    editor.selectionMark = (line: 1, column: 1)
    editor.buffer.columnIndex = 8
    editor.processKey(.ctrl("Q"))

    #expect(editor.buffer.lines == [
        "┌────────────┐",
        "│MAKEBOX     │",
        "└────────────┘",
    ])
    #expect(editor.statusMessage == "[ BOX disabled in Table Mode ]")

    editor.logoEngine.execute("TO PAINTBOX DRAWBOX 8 3 END")
    editor.buffer.lines[1] = "│PAINTBOX    │"
    editor.selectionMark = (line: 1, column: 1)
    editor.buffer.columnIndex = 9
    editor.processKey(.ctrl("Q"))

    #expect(editor.buffer.lines == [
        "┌────────────┐",
        "│PAINTBOX    │",
        "└────────────┘",
    ])
    #expect(editor.statusMessage == "[ DRAWBOX disabled in Table Mode ]")
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

@Test func testTableModeShiftTabNavigatesBackward() throws {
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

    // Press Shift+Tab from Row 2 Cell 1
    editor.processKey(.shiftArrowLeft)

    // Must jump to Row 1 Cell 2 (last cell of row above)!
    #expect(editor.currentTableCell?.minLine == 0)
    #expect(editor.currentTableCell?.minCol == 17)
}

@Test func testCycleTableStyleCommand() throws {
    let editor = Editor()
    #expect(editor.defaultTableBorderStyle == .single)

    // Press Alt+S to cycle table style
    editor.processKey(.alt("s"))
    #expect(editor.defaultTableBorderStyle == .double)

    editor.processKey(.alt("s"))
    #expect(editor.defaultTableBorderStyle == .round)

    editor.processKey(.alt("s"))
    #expect(editor.defaultTableBorderStyle == .ascii)

    editor.processKey(.alt("s"))
    #expect(editor.defaultTableBorderStyle == .markdown)

    editor.processKey(.alt("s"))
    #expect(editor.defaultTableBorderStyle == .single)
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
