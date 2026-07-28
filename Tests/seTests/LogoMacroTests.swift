import Testing
import Foundation
@testable import Editor

@Test func testLogoMacroEngine() throws {
    let editor = Editor()
    let logoEngine = LogoEngine()

    // 1. Basic TYPE and MOVE
    logoEngine.execute("TYPE \"Hello\" MOVE END TYPE \" World\"", on: editor)
    #expect(editor.buffer.lines[0] == "Hello World")

    // 2. REPEAT loop
    logoEngine.execute("REPEAT 3 [ TYPE \"!\" ]", on: editor)
    #expect(editor.buffer.lines[0] == "Hello World!!!")

    // 3. TO ... END Procedure definition & EXEC
    logoEngine.execute("TO BULLET MOVE END TYPE \" - item\" END EXEC BULLET", on: editor)
    #expect(editor.buffer.lines[0] == "Hello World!!! - item")

    // 4. Variables and Arithmetic test
    logoEngine.execute("MAKE \"i\" 1 MAKE \"x\" :i + 5 TYPE :x", on: editor)
    #expect(editor.buffer.lines[0] == "Hello World!!! - item6")

    // 5. Direct Arithmetic TYPE output & Multiplication
    logoEngine.execute("TYPE \" calc: \" TYPE ( 10 + 20 ) TYPE \" mul: \" TYPE ( 4 * 5 )", on: editor)
    #expect(editor.buffer.lines[0] == "Hello World!!! - item6 calc: 30 mul: 20")

    // 6. Unspaced and Chained Arithmetic (10+20, 1+2+3)
    logoEngine.execute("TYPE \" nospace: \" TYPE 10+20 TYPE \" chained: \" MAKE \"c\" 1 + 2 + 3 TYPE :c", on: editor)
    #expect(editor.buffer.lines[0] == "Hello World!!! - item6 calc: 30 mul: 20 nospace: 30 chained: 6")

    // 7. DEL and BS
    logoEngine.execute("BS 3 TYPE \"25\"", on: editor)
    #expect(editor.buffer.lines[0] == "Hello World!!! - item6 calc: 30 mul: 20 nospace: 30 chained25")

    // 8. Prompt History & Active Hardware Cursor position test
    editor.promptLogoMacro()
    let promptOutput = editor.generateScreenOutput(rows: 24, cols: 80)
    #expect(promptOutput.contains("\u{1B}[22;")) // Verify hardware cursor placed on row 22 (24-2) for active prompt

    editor.processKey(.char("T"))
    editor.processKey(.char("Y"))
    editor.processKey(.enter)
    #expect(editor.logoPromptHistory.last == "TY")

    // 10. SET Editor Configuration Settings test
    editor.displayConfig.showRuler = false
    logoEngine.execute("SET RULER ON", on: editor)
    #expect(editor.displayConfig.showRuler == true)

    // 11. MSG Command Status Bar Output test
    logoEngine.execute("MAKE \"msg_val\" 42 MSG \"Current Val: \" + :msg_val", on: editor)
    #expect(editor.statusMessage == "Current Val: 42")

    // Prompt mode execution of MSG & Home/End/Left/Right inline editing test
    editor.promptLogoMacro()
    editor.processKey(.char("M"))
    editor.processKey(.char("S"))
    editor.processKey(.char("G"))
    editor.processKey(.char(" "))
    editor.processKey(.char("\""))
    editor.processKey(.char("H"))
    editor.processKey(.char("i"))
    editor.processKey(.char("\""))
    #expect(editor.promptCursorIndex == 8)

    editor.processKey(.home)
    #expect(editor.promptCursorIndex == 0)

    editor.processKey(.end)
    #expect(editor.promptCursorIndex == 8)

    editor.processKey(.arrowLeft)
    #expect(editor.promptCursorIndex == 7)

    // 13. LOGO BOX Command test
    let boxEditor = Editor()
    logoEngine.execute("BOX \"Hello\"", on: boxEditor)
    #expect(boxEditor.buffer.lines.count >= 3)
    #expect(boxEditor.buffer.lines[0] == "┌───────┐")
    #expect(boxEditor.buffer.lines[1] == "│ Hello │")
    #expect(boxEditor.buffer.lines[2] == "└───────┘")

    let boxEditor2 = Editor()
    logoEngine.execute("BOX 6 3 \"double\"", on: boxEditor2)
    #expect(boxEditor2.buffer.lines[0] == "╔════╗")
    #expect(boxEditor2.buffer.lines[1] == "║    ║")
    #expect(boxEditor2.buffer.lines[2] == "╚════╝")

    // TDD Test Example 1: BOX with leading indent
    let indentEditor = Editor()
    indentEditor.buffer.lines = ["    ", "    ", "    "]
    indentEditor.buffer.lineIndex = 0
    indentEditor.buffer.columnIndex = 4
    logoEngine.execute("BOX 14 3 \"ascii\"", on: indentEditor)
    #expect(indentEditor.buffer.lines[0] == "    +------------+")
    #expect(indentEditor.buffer.lines[1] == "    |            |")
    #expect(indentEditor.buffer.lines[2] == "    +------------+")

    // TDD Test Example 2: BOX overlay in middle of background text
    let bgTextEditor = Editor()
    bgTextEditor.buffer.lines = ["AAAAAA", "BBBBBB", "CCCCCC"]
    bgTextEditor.buffer.lineIndex = 0
    bgTextEditor.buffer.columnIndex = 3
    logoEngine.execute("BOX 5 3 \"ascii\"", on: bgTextEditor)
    #expect(bgTextEditor.buffer.lines[0] == "AAA+---+AAA")
    #expect(bgTextEditor.buffer.lines[1] == "BBB|   |BBB")
    #expect(bgTextEditor.buffer.lines[2] == "CCC+---+CCC")

    // 14. LOGO LINE and NEWLINE Command test
    let lineEditor = Editor()
    logoEngine.execute("TYPE \"Header\" NL 2 LINE 10 TYPE \"Footer\"", on: lineEditor)
    #expect(lineEditor.buffer.lines.count == 4)
    #expect(lineEditor.buffer.lines[0] == "Header")
    #expect(lineEditor.buffer.lines[1] == "")
    #expect(lineEditor.buffer.lines[2] == "──────────")
    #expect(lineEditor.buffer.lines[3] == "Footer")

    // 15. LOGO VLINE Command test
    let vlineEditor = Editor()
    logoEngine.execute("VLINE 3 \"double\"", on: vlineEditor)
    #expect(vlineEditor.buffer.lines.count == 3)
    #expect(vlineEditor.buffer.lines[0] == "║")
    #expect(vlineEditor.buffer.lines[1] == "║")
    #expect(vlineEditor.buffer.lines[2] == "║")

    // 16. LOGO DATE and TIME Command test
    let dateTimeEditor = Editor()
    logoEngine.execute("DATE \"yyyy-MM-dd\" TYPE \" \" TIME \"HH:mm\"", on: dateTimeEditor)
    let outputText = dateTimeEditor.buffer.lines[0]
    #expect(outputText.contains("-"))
    #expect(outputText.contains(":"))

    // Test MAKE "i" DATE "YYYY/MM/DD" BOX :i
    let dateBoxEditor = Editor()
    logoEngine.execute("MAKE \"i\" DATE \"YYYY/MM/DD\" BOX :i", on: dateBoxEditor)
    #expect(dateBoxEditor.buffer.lines.count >= 3)
    #expect(dateBoxEditor.buffer.lines[1].contains("/"))
    #expect(dateBoxEditor.buffer.lines[0].hasPrefix("┌"))

    // 17. Smart Line Junction Fusion (BOX + VLINE cross fusion)
    let fuseEditor = Editor()
    logoEngine.execute("BOX 6 3 GOTO 1 3 VLINE 3", on: fuseEditor)
    #expect(fuseEditor.buffer.lines[0] == "┌─┬──┐")
    #expect(fuseEditor.buffer.lines[1] == "│ │  │")
    #expect(fuseEditor.buffer.lines[2] == "└─┴──┘")

    // 18. LOGO Turtle Graphics (PD, PU, FD, BK, RT, LT) test
    let turtleEditor = Editor()
    logoEngine.execute("PU FD 3 PD FD 3", on: turtleEditor)
    #expect(turtleEditor.buffer.lines[0] == "  ───")
}

@Test func testTurtleSquareBoxDrawing() throws {
    let editor = Editor()
    let logoEngine = LogoEngine()

    // Test drawing a complete 4x4 square using Turtle Graphics (4 cells per side)
    logoEngine.execute("PD REPEAT 4 [ FD 4 RT 90 ]", on: editor)
    #expect(editor.buffer.lines.count >= 4)
    #expect(editor.buffer.lines[0] == "┌──┐")
    #expect(editor.buffer.lines[1] == "│  │")
    #expect(editor.buffer.lines[2] == "│  │")
    #expect(editor.buffer.lines[3] == "└──┘")
}

@Test func testTurtleLeftTurnAndBackward() throws {
    let editor = Editor()
    let logoEngine = LogoEngine()

    // Test LT 90 (facing UP) and BK 3 (moving DOWN while facing UP)
    logoEngine.execute("LT 90 BK 3", on: editor)
    #expect(editor.buffer.lines.count == 3)
    #expect(editor.buffer.lines[0] == "│")
    #expect(editor.buffer.lines[1] == "│")
    #expect(editor.buffer.lines[2] == "│")
}

@Test func testDoubleLineSmartJunctionFusion() throws {
    let editor = Editor()
    let logoEngine = LogoEngine()

    // Test double line box fused with double line VLINE
    logoEngine.execute("BOX 6 3 \"double\" GOTO 1 3 VLINE 3 \"double\"", on: editor)
    #expect(editor.buffer.lines[0] == "╔═╦══╗")
    #expect(editor.buffer.lines[1] == "║ ║  ║")
    #expect(editor.buffer.lines[2] == "╚═╩══╝")
}

@Test func testTurtleVariableLoopCombo() throws {
    let editor = Editor()
    let logoEngine = LogoEngine()

    // Test variable dereferencing inside turtle drawing loop
    logoEngine.execute("MAKE \"dist\" 3 PD REPEAT 2 [ FD :dist RT 90 ]", on: editor)
    #expect(editor.buffer.lines[0] == "──┐")
    #expect(editor.buffer.lines[1] == "  │")
    #expect(editor.buffer.lines[2] == "  │")
}

@Test func testAtomicUndoForTurtleScript() throws {
    let editor = Editor()
    let logoEngine = LogoEngine()
    editor.buffer.lines = ["Original Text"]

    // Execute complex turtle script
    logoEngine.execute("GOTO 1 1 PD REPEAT 4 [ FD 5 RT 90 ]", on: editor)
    #expect(editor.buffer.lines[0] != "Original Text")

    // Single ^Z Undo should revert the entire script in one step
    editor.performUndo()
    #expect(editor.buffer.lines == ["Original Text"])
}

@Test func testTurtleSpiralDrawing() throws {
    let editor = Editor()
    let logoEngine = LogoEngine()

    // Draw an expanding spiral using LOGO turtle loop and variable incrementing
    logoEngine.execute("MAKE \"d\" 2 PD REPEAT 4 [ FD :d RT 90 MAKE \"d\" ( :d + 2 ) ]", on: editor)
    #expect(editor.buffer.lines.count >= 4)
    #expect(editor.buffer.lines[0] == "├┐")
    #expect(editor.buffer.lines[1] == "││")
    #expect(editor.buffer.lines[2] == "││")
    #expect(editor.buffer.lines[3] == "└┘")
}

@Test func testTurtleDirectTableDrawing() throws {
    let editor = Editor()
    let logoEngine = LogoEngine()

    // Directly draw a 2x2 grid table with outer box, inner vertical & horizontal dividers using turtle moves & fusion
    logoEngine.execute("PD REPEAT 4 [ FD 5 RT 90 ] PU GOTO 1 3 PD RT 90 FD 5 PU GOTO 3 1 PD LT 90 FD 5", on: editor)
    #expect(editor.buffer.lines.count >= 5)
    #expect(editor.buffer.lines[0] == "┌─┬─┐")
    #expect(editor.buffer.lines[1] == "│ │ │")
    #expect(editor.buffer.lines[2] == "├─┼─┤")
    #expect(editor.buffer.lines[3] == "│ │ │")
    #expect(editor.buffer.lines[4] == "└─┴─┘")
}

@Test func testLogoIfAndIfElseConditionals() throws {
    let logoEngine = LogoEngine()

    // 1. IF true
    let ifEditor1 = Editor()
    logoEngine.execute("MAKE \"i\" 10 IF :i > 5 [ TYPE \"GREATER\" ]", on: ifEditor1)
    #expect(ifEditor1.buffer.lines[0] == "GREATER")

    // 2. IF false
    let ifEditor2 = Editor()
    logoEngine.execute("MAKE \"i\" 2 IF :i > 5 [ TYPE \"GREATER\" ]", on: ifEditor2)
    #expect(ifEditor2.buffer.lines[0] == "")

    // 3. IFELSE true branch
    let ifElseEditor1 = Editor()
    logoEngine.execute("MAKE \"i\" 10 IFELSE :i > 5 [ TYPE \"YES\" ] [ TYPE \"NO\" ]", on: ifElseEditor1)
    #expect(ifElseEditor1.buffer.lines[0] == "YES")

    // 4. IFELSE false branch
    let ifElseEditor2 = Editor()
    logoEngine.execute("MAKE \"i\" 2 IFELSE :i > 5 [ TYPE \"YES\" ] [ TYPE \"NO\" ]", on: ifElseEditor2)
    #expect(ifElseEditor2.buffer.lines[0] == "NO")

    // 5. IFELSE in REPEAT loop with equality comparison ==
    let loopEditor = Editor()
    logoEngine.execute("MAKE \"i\" 1 REPEAT 3 [ IFELSE :i == 2 [ TYPE \"TWO\" ] [ TYPE :i ] MAKE \"i\" ( :i + 1 ) ]", on: loopEditor)
    #expect(loopEditor.buffer.lines[0] == "1TWO3")
}

@Test func testLogoFloatingPointArithmetic() throws {
    let logoEngine = LogoEngine()

    // 1. Double multiplication (3.5 * 10 = 35)
    let ed1 = Editor()
    logoEngine.execute("TYPE ( 3.5 * 10 )", on: ed1)
    #expect(ed1.buffer.lines[0] == "35")

    // 2. Double addition (3.5 + 2.3 = 5.8)
    let ed2 = Editor()
    logoEngine.execute("TYPE ( 3.5 + 2.3 )", on: ed2)
    #expect(ed2.buffer.lines[0] == "5.8")

    // 3. Variable with double arithmetic
    let ed3 = Editor()
    logoEngine.execute("MAKE \"x\" 3.5 TYPE ( :x * 2 )", on: ed3)
    #expect(ed3.buffer.lines[0] == "7")

    // 4. Floating point condition
    let ed4 = Editor()
    logoEngine.execute("IF 3.5 > 2.0 [ TYPE \"YES\" ]", on: ed4)
    #expect(ed4.buffer.lines[0] == "YES")
}
