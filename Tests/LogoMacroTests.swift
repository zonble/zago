import Foundation
import Dispatch
import Testing
import TextMetrics

@testable import Editor
@testable import LogoEngine

final class LogoTestResultBox: @unchecked Sendable {
    var value: String?
    var error: String?
    var status: String?
}

@Test func testLogoMacroEngine() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    // 1. Basic TYPE and MOVE
    logoEngine.execute("TYPE \"Hello\" MOVE END TYPE \" World\"")
    #expect(editor.buffer.lines[0] == "Hello World")

    // 2. REPEAT loop
    logoEngine.execute("REPEAT 3 [ TYPE \"!\" ]")
    #expect(editor.buffer.lines[0] == "Hello World!!!")

    // 3. TO ... END Procedure definition & EXEC
    logoEngine.execute("TO BULLET MOVE END TYPE \" - item\" END EXEC BULLET")
    #expect(editor.buffer.lines[0] == "Hello World!!! - item")

    // 4. Variables and Arithmetic test
    logoEngine.execute("MAKE \"i\" 1 MAKE \"x\" :i + 5 TYPE :x")
    #expect(editor.buffer.lines[0] == "Hello World!!! - item6")

    // 5. Direct Arithmetic TYPE output & Multiplication
    logoEngine.execute("TYPE \" calc: \" TYPE ( 10 + 20 ) TYPE \" mul: \" TYPE ( 4 * 5 )")
    #expect(editor.buffer.lines[0] == "Hello World!!! - item6 calc: 30 mul: 20")

    // 6. Unspaced and Chained Arithmetic (10+20, 1+2+3)
    logoEngine.execute("TYPE \" nospace: \" TYPE 10+20 TYPE \" chained: \" MAKE \"c\" 1 + 2 + 3 TYPE :c")
    #expect(editor.buffer.lines[0] == "Hello World!!! - item6 calc: 30 mul: 20 nospace: 30 chained: 6")

    // 7. DEL and BS
    logoEngine.execute("BS 3 TYPE \"25\"")
    #expect(editor.buffer.lines[0] == "Hello World!!! - item6 calc: 30 mul: 20 nospace: 30 chained25")

    // 8. Prompt History & Active Hardware Cursor position test
    editor.promptLogoMacro()
    let promptOutput = editor.renderer.render(editor: editor, rows: 24, cols: 80)
    #expect(promptOutput.contains("\u{1B}[22;"))  // Verify hardware cursor placed on row 22 (24-2) for active prompt

    editor.processKey(.char("T"))
    editor.processKey(.char("Y"))
    editor.processKey(.enter)
    #expect(editor.logoPromptHistory.last == "TY")

    // 10. SET Editor Configuration Settings test
    editor.displayConfig.showRuler = false
    logoEngine.execute("SET RULER ON")
    #expect(editor.displayConfig.showRuler == true)
    #expect(editor.displayConfig.showLineNumbers == true)
    logoEngine.execute("SET LINENUMBERS OFF")
    #expect(editor.displayConfig.showLineNumbers == false)
    logoEngine.execute("SET LINENUMBERS ON")
    #expect(editor.displayConfig.showLineNumbers == true)

    // 11. MSG Command Status Bar Output test
    logoEngine.execute("MAKE \"msg_val\" 42 MSG \"Current Val: \" + :msg_val")
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
    logoEngine.delegate = boxEditor
    logoEngine.execute("BOX \"Hello\"")
    #expect(boxEditor.buffer.lines.count >= 3)
    #expect(boxEditor.buffer.lines[0] == "┌───────┐")
    #expect(boxEditor.buffer.lines[1] == "│ Hello │")
    #expect(boxEditor.buffer.lines[2] == "└───────┘")

    let boxEditor2 = Editor()
    logoEngine.delegate = boxEditor2
    logoEngine.execute("BOX 6 3 \"double\"")
    #expect(boxEditor2.buffer.lines[0] == "╔════╗")
    #expect(boxEditor2.buffer.lines[1] == "║    ║")
    #expect(boxEditor2.buffer.lines[2] == "╚════╝")

    let cjkBoxEditor = Editor()
    logoEngine.delegate = cjkBoxEditor
    logoEngine.execute("BOX \"中文\"")
    #expect(cjkBoxEditor.buffer.lines.count >= 3)
    #expect(cjkBoxEditor.buffer.lines[0] == "┌──────┐")
    #expect(cjkBoxEditor.buffer.lines[1] == "│ 中文 │")
    #expect(cjkBoxEditor.buffer.lines[2] == "└──────┘")

    let roundBoxEditor = Editor()
    logoEngine.delegate = roundBoxEditor
    logoEngine.execute("BOX 6 3 \"round\"")
    #expect(roundBoxEditor.buffer.lines[0] == "╭────╮")
    #expect(roundBoxEditor.buffer.lines[1] == "│    │")
    #expect(roundBoxEditor.buffer.lines[2] == "╰────╯")

    let doubleRoundBoxEditor = Editor()
    logoEngine.delegate = doubleRoundBoxEditor
    logoEngine.execute("BOX 6 3 \"double-round\"")
    #expect(doubleRoundBoxEditor.buffer.lines[0] == "╭════╮")
    #expect(doubleRoundBoxEditor.buffer.lines[1] == "║    ║")
    #expect(doubleRoundBoxEditor.buffer.lines[2] == "╰════╯")

    // TDD Test Example 1: BOX with leading indent
    let indentEditor = Editor()
    indentEditor.buffer.lines = ["    ", "    ", "    "]
    indentEditor.buffer.lineIndex = 0
    indentEditor.buffer.columnIndex = 4
    logoEngine.delegate = indentEditor
    logoEngine.execute("BOX 14 3 \"ascii\"")
    #expect(indentEditor.buffer.lines[0] == "    +------------+")
    #expect(indentEditor.buffer.lines[1] == "    |            |")
    #expect(indentEditor.buffer.lines[2] == "    +------------+")

    // TDD Test Example 2: BOX inserts into each affected line and pushes trailing text right.
    let bgTextEditor = Editor()
    bgTextEditor.buffer.lines = ["AAAAAAAAAAA", "BBBBBBBBBBB", "CCCCCCCCCCC"]
    bgTextEditor.buffer.lineIndex = 0
    bgTextEditor.buffer.columnIndex = 3
    logoEngine.delegate = bgTextEditor
    logoEngine.execute("BOX 5 3 \"ascii\"")
    #expect(bgTextEditor.buffer.lines[0] == "AAA+---+AAAAAAAA")
    #expect(bgTextEditor.buffer.lines[1] == "BBB|   |BBBBBBBB")
    #expect(bgTextEditor.buffer.lines[2] == "CCC+---+CCCCCCCC")

    let overlayBoxEditor = Editor()
    overlayBoxEditor.buffer.lines = ["AAAAAAAAAAA", "BBBBBBBBBBB", "CCCCCCCCCCC"]
    overlayBoxEditor.buffer.lineIndex = 0
    overlayBoxEditor.buffer.columnIndex = 3
    logoEngine.delegate = overlayBoxEditor
    logoEngine.execute("DRAWBOX 5 3 \"ascii\"")
    #expect(overlayBoxEditor.buffer.lines[0] == "AAA+---+AAA")
    #expect(overlayBoxEditor.buffer.lines[1] == "BBB|   |BBB")
    #expect(overlayBoxEditor.buffer.lines[2] == "CCC+---+CCC")

    let suffixEditor = Editor()
    suffixEditor.buffer.lines = [
        "AAAAAAAAAA",
        "AAAAAAAAAA",
        "AAAAAAAAAA",
        "AAAAAAAAAA",
        "",
        "AAAAAAAAAA",
        "AAAAAAAAAAAAAAAAAA",
        "AAAAAAAAAAAAAAAAAA",
        "AAAAAAAAAAAAAAAAAA",
    ]
    suffixEditor.buffer.lineIndex = 6
    suffixEditor.buffer.columnIndex = 2
    logoEngine.delegate = suffixEditor
    logoEngine.execute("BOX 8 3 \"ascii\"")
    #expect(suffixEditor.buffer.lines[6] == "AA+------+AAAAAAAAAAAAAAAA")
    #expect(suffixEditor.buffer.lines[7] == "AA|      |AAAAAAAAAAAAAAAA")
    #expect(suffixEditor.buffer.lines[8] == "AA+------+AAAAAAAAAAAAAAAA")

    // 14. LOGO LINE and NEWLINE Command test
    let lineEditor = Editor()
    logoEngine.delegate = lineEditor
    logoEngine.execute("TYPE \"Header\" NL 2 LINE 10 NL TYPE \"Footer\"")
    #expect(lineEditor.buffer.lines.count == 4)
    #expect(lineEditor.buffer.lines[0] == "Header")
    #expect(lineEditor.buffer.lines[1] == "")
    #expect(lineEditor.buffer.lines[2] == "──────────")
    #expect(lineEditor.buffer.lines[3] == "Footer")

    // 15. LOGO VLINE Command test
    let vlineEditor = Editor()
    logoEngine.delegate = vlineEditor
    logoEngine.execute("VLINE 3 \"double\"")
    #expect(vlineEditor.buffer.lines.count == 3)
    #expect(vlineEditor.buffer.lines[0] == "║")
    #expect(vlineEditor.buffer.lines[1] == "║")
    #expect(vlineEditor.buffer.lines[2] == "║")

    let autoLineEditor = Editor()
    logoEngine.delegate = autoLineEditor
    logoEngine.execute("LINE")
    #expect(autoLineEditor.buffer.lines[0] == "──────────")

    let autoLineStopEditor = Editor()
    autoLineStopEditor.buffer.lines = ["   X"]
    logoEngine.delegate = autoLineStopEditor
    logoEngine.execute("GOTO 1 1 LINE")
    #expect(autoLineStopEditor.buffer.lines[0] == "───X")

    let autoLineFuseEditor = Editor()
    logoEngine.delegate = autoLineFuseEditor
    logoEngine.execute("BOX 6 3 GOTO 2 1 LINE")
    #expect(autoLineFuseEditor.buffer.lines[1] == "├────┤")

    let autoVlineFuseEditor = Editor()
    logoEngine.delegate = autoVlineFuseEditor
    logoEngine.execute("BOX 6 3 GOTO 1 3 VLINE")
    #expect(autoVlineFuseEditor.buffer.lines[0] == "┌─┬──┐")
    #expect(autoVlineFuseEditor.buffer.lines[1] == "│ │  │")
    #expect(autoVlineFuseEditor.buffer.lines[2] == "└─┴──┘")

    let explicitLineArrowEditor = Editor()
    logoEngine.delegate = explicitLineArrowEditor
    logoEngine.execute("LINE 8 ARROW")
    #expect(explicitLineArrowEditor.buffer.lines[0] == "───────→")

    let explicitLineBackArrowEditor = Editor()
    logoEngine.delegate = explicitLineBackArrowEditor
    logoEngine.execute("LINE 8 BACKARROW")
    #expect(explicitLineBackArrowEditor.buffer.lines[0] == "←───────")

    let explicitLineBothArrowEditor = Editor()
    logoEngine.delegate = explicitLineBothArrowEditor
    logoEngine.execute("LINE 8 BOTHARROW")
    #expect(explicitLineBothArrowEditor.buffer.lines[0] == "←──────→")

    let asciiLineArrowEditor = Editor()
    logoEngine.delegate = asciiLineArrowEditor
    logoEngine.execute("LINE 5 ASCII ARROW")
    #expect(asciiLineArrowEditor.buffer.lines[0] == "---->")

    let autoLineArrowEditor = Editor()
    logoEngine.delegate = autoLineArrowEditor
    logoEngine.execute("LINE ARROW")
    #expect(autoLineArrowEditor.buffer.lines[0] == "─────────→")

    let autoLineBothArrowEditor = Editor()
    logoEngine.delegate = autoLineBothArrowEditor
    logoEngine.execute("LINE BOTHARROW")
    #expect(autoLineBothArrowEditor.buffer.lines[0] == "←────────→")

    let autoLineArrowStopEditor = Editor()
    autoLineArrowStopEditor.buffer.lines = ["   X"]
    logoEngine.delegate = autoLineArrowStopEditor
    logoEngine.execute("GOTO 1 1 LINE ARROW")
    #expect(autoLineArrowStopEditor.buffer.lines[0] == "──→X")

    let autoLineArrowFuseEditor = Editor()
    logoEngine.delegate = autoLineArrowFuseEditor
    logoEngine.execute("DRAWBOX 6 3 GOTO 2 1 LINE ARROW")
    #expect(autoLineArrowFuseEditor.buffer.lines[1] == "├───→│")

    let lineArrowParserEditor = Editor()
    logoEngine.delegate = lineArrowParserEditor
    logoEngine.execute("LINE ARROW TYPE \"x\"")
    #expect(lineArrowParserEditor.buffer.lines[0] == "─────────→x")

    let explicitVlineArrowEditor = Editor()
    logoEngine.delegate = explicitVlineArrowEditor
    logoEngine.execute("VLINE 4 BOTHARROW")
    #expect(explicitVlineArrowEditor.buffer.lines == ["↑", "│", "│", "↓"])

    let asciiVlineArrowEditor = Editor()
    logoEngine.delegate = asciiVlineArrowEditor
    logoEngine.execute("VLINE 3 ASCII ARROW")
    #expect(asciiVlineArrowEditor.buffer.lines == ["|", "|", "v"])

    let autoVlineArrowEditor = Editor()
    logoEngine.delegate = autoVlineArrowEditor
    logoEngine.execute("VLINE ARROW")
    #expect(autoVlineArrowEditor.buffer.lines.count == 5)
    #expect(autoVlineArrowEditor.buffer.lines[0] == "│")
    #expect(autoVlineArrowEditor.buffer.lines[3] == "│")
    #expect(autoVlineArrowEditor.buffer.lines[4] == "↓")

    let autoVlineArrowStopEditor = Editor()
    autoVlineArrowStopEditor.buffer.lines = ["", "", "X"]
    logoEngine.delegate = autoVlineArrowStopEditor
    logoEngine.execute("GOTO 1 1 VLINE ARROW")
    #expect(autoVlineArrowStopEditor.buffer.lines == ["│", "↓", "X"])

    let autoVlineArrowTouchEditor = Editor()
    logoEngine.delegate = autoVlineArrowTouchEditor
    logoEngine.execute("DRAWBOX 6 3 GOTO 1 3 VLINE ARROW")
    #expect(autoVlineArrowTouchEditor.buffer.lines[0] == "┌─┬──┐")
    #expect(autoVlineArrowTouchEditor.buffer.lines[1] == "│ ↓  │")
    #expect(autoVlineArrowTouchEditor.buffer.lines[2] == "└────┘")

    // 16. LOGO DATE and TIME Command test
    let dateTimeEditor = Editor()
    logoEngine.delegate = dateTimeEditor
    logoEngine.execute("TYPE DATE \"yyyy-MM-dd\" TYPE \" \" TYPE TIME \"HH:mm\"")
    let outputText = dateTimeEditor.buffer.lines[0]
    #expect(outputText.contains("-"))
    #expect(outputText.contains(":"))

    // Test MAKE "i" DATE "YYYY/MM/DD" BOX :i
    let dateBoxEditor = Editor()
    logoEngine.delegate = dateBoxEditor
    logoEngine.execute("MAKE \"i\" DATE \"YYYY/MM/DD\" BOX :i")
    #expect(dateBoxEditor.buffer.lines.count >= 3)
    #expect(dateBoxEditor.buffer.lines[1].contains("/"))
    #expect(dateBoxEditor.buffer.lines[0].hasPrefix("┌"))

    // 17. Smart Line Junction Fusion (BOX + VLINE cross fusion)
    let fuseEditor = Editor()
    logoEngine.delegate = fuseEditor
    logoEngine.execute("BOX 6 3 GOTO 1 3 VLINE 3")
    #expect(fuseEditor.buffer.lines[0] == "┌─┬──┐")
    #expect(fuseEditor.buffer.lines[1] == "│ │  │")
    #expect(fuseEditor.buffer.lines[2] == "└─┴──┘")

    // 18. LOGO Turtle Graphics (PD, PU, FD, BK, RT, LT) test
    let turtleEditor = Editor()
    logoEngine.delegate = turtleEditor
    logoEngine.execute("PU FD 3 PD FD 3")
    #expect(turtleEditor.buffer.lines[0] == "  ───")
}

@Test func testTurtleSquareBoxDrawing() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    // Test drawing a complete 4x4 square using Turtle Graphics (4 cells per side)
    logoEngine.execute("PD REPEAT 4 [ FD 4 RT 90 ]")
    #expect(editor.buffer.lines.count >= 4)
    #expect(editor.buffer.lines[0] == "┌──┐")
    #expect(editor.buffer.lines[1] == "│  │")
    #expect(editor.buffer.lines[2] == "│  │")
    #expect(editor.buffer.lines[3] == "└──┘")
}

@Test func testTurtleLeftTurnAndBackward() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    // Test LT 90 (facing UP) and BK 3 (moving DOWN while facing UP)
    logoEngine.execute("LT 90 BK 3")
    #expect(editor.buffer.lines.count == 3)
    #expect(editor.buffer.lines[0] == "│")
    #expect(editor.buffer.lines[1] == "│")
    #expect(editor.buffer.lines[2] == "│")
}

@Test func testDoubleLineSmartJunctionFusion() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    // Test double line box fused with double line VLINE
    logoEngine.execute("BOX 6 3 \"double\" GOTO 1 3 VLINE 3 \"double\"")
    #expect(editor.buffer.lines[0] == "╔═╦══╗")
    #expect(editor.buffer.lines[1] == "║ ║  ║")
    #expect(editor.buffer.lines[2] == "╚═╩══╝")
}

@Test func testTurtleVariableLoopCombo() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    // Test variable dereferencing inside turtle drawing loop
    logoEngine.execute("MAKE \"dist\" 3 PD REPEAT 2 [ FD :dist RT 90 ]")
    #expect(editor.buffer.lines[0] == "──┐")
    #expect(editor.buffer.lines[1] == "  │")
    #expect(editor.buffer.lines[2] == "  │")
}

@Test func testAtomicUndoForTurtleScript() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)
    editor.buffer.lines = ["Original Text"]

    // Execute complex turtle script
    logoEngine.execute("GOTO 1 1 PD REPEAT 4 [ FD 5 RT 90 ]")
    #expect(editor.buffer.lines[0] != "Original Text")

    // Single ^Z Undo should revert the entire script in one step
    editor.performUndo()
    #expect(editor.buffer.lines == ["Original Text"])
}

@Test func testTurtleSpiralDrawing() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    // Draw an expanding spiral using LOGO turtle loop and variable incrementing
    logoEngine.execute("MAKE \"d\" 2 PD REPEAT 4 [ FD :d RT 90 MAKE \"d\" ( :d + 2 ) ]")
    #expect(editor.buffer.lines.count >= 4, "lines were: \(editor.buffer.lines)")
    #expect(editor.buffer.lines[0] == "├┐")
    #expect(editor.buffer.lines[1] == "││")
    #expect(editor.buffer.lines[2] == "││")
    #expect(editor.buffer.lines[3] == "└┘")
}

@Test func testTurtleAutoExtendsLinesOnDownwardFD() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)
    #expect(editor.buffer.lines.count == 1)

    logoEngine.execute("SETH \"DOWN PD FD 10")
    #expect(editor.buffer.lines.count == 10)
    for line in editor.buffer.lines {
        #expect(line == "│")
    }
}

@Test func testTurtleDirectTableDrawing() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    // Directly draw a 2x2 grid table with outer box, inner vertical & horizontal dividers using turtle moves & fusion
    logoEngine.execute("PD REPEAT 4 [ FD 5 RT 90 ] PU GOTO 1 3 PD RT 90 FD 5 PU GOTO 3 1 PD LT 90 FD 5")
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
    logoEngine.delegate = ifEditor1
    logoEngine.execute("MAKE \"i\" 10 IF :i > 5 [ TYPE \"GREATER\" ]")
    #expect(ifEditor1.buffer.lines[0] == "GREATER")

    // 2. IF false
    let ifEditor2 = Editor()
    logoEngine.delegate = ifEditor2
    logoEngine.execute("MAKE \"i\" 2 IF :i > 5 [ TYPE \"GREATER\" ]")
    #expect(ifEditor2.buffer.lines[0] == "")

    // 3. IFELSE true branch
    let ifElseEditor1 = Editor()
    logoEngine.delegate = ifElseEditor1
    logoEngine.execute("MAKE \"i\" 10 IFELSE :i > 5 [ TYPE \"YES\" ] [ TYPE \"NO\" ]")
    #expect(ifElseEditor1.buffer.lines[0] == "YES")

    // 4. IFELSE false branch
    let ifElseEditor2 = Editor()
    logoEngine.delegate = ifElseEditor2
    logoEngine.execute("MAKE \"i\" 2 IFELSE :i > 5 [ TYPE \"YES\" ] [ TYPE \"NO\" ]")
    #expect(ifElseEditor2.buffer.lines[0] == "NO")

    // 5. IFELSE in REPEAT loop with equality comparison ==
    let loopEditor = Editor()
    logoEngine.delegate = loopEditor
    logoEngine.execute("MAKE \"i\" 1 REPEAT 3 [ IFELSE :i == 2 [ TYPE \"TWO\" ] [ TYPE :i ] MAKE \"i\" ( :i + 1 ) ]")
    #expect(loopEditor.buffer.lines[0] == "1TWO3")
}

@Test func testLogoFloatingPointArithmetic() throws {
    let logoEngine = LogoEngine()

    // 1. Double multiplication (3.5 * 10 = 35)
    let ed1 = Editor()
    logoEngine.delegate = ed1
    logoEngine.execute("TYPE ( 3.5 * 10 )")
    #expect(ed1.buffer.lines[0] == "35")

    // 2. Double addition (3.5 + 2.3 = 5.8)
    let ed2 = Editor()
    logoEngine.delegate = ed2
    logoEngine.execute("TYPE ( 3.5 + 2.3 )")
    #expect(ed2.buffer.lines[0] == "5.8")

    // 3. Variable with double arithmetic
    let ed3 = Editor()
    logoEngine.delegate = ed3
    logoEngine.execute("MAKE \"x\" 3.5 TYPE ( :x * 2 )")
    #expect(ed3.buffer.lines[0] == "7")

    // 4. Floating point condition
    let ed4 = Editor()
    logoEngine.delegate = ed4
    logoEngine.execute("IF 3.5 > 2.0 [ TYPE \"YES\" ]")
    #expect(ed4.buffer.lines[0] == "YES")

    let ed5 = Editor()
    logoEngine.delegate = ed5
    logoEngine.execute("SHOW MINUS 9 5")
    #expect(ed5.statusMessage == "4")

    let ed6 = Editor()
    logoEngine.delegate = ed6
    logoEngine.execute("SHOW MINUS 9")
    #expect(ed6.statusMessage == "-9")

    let ed7 = Editor()
    logoEngine.delegate = ed7
    logoEngine.execute("TYPE MINUS 9 5")
    #expect(ed7.buffer.lines[0] == "4")

    let ed8 = Editor()
    logoEngine.delegate = ed8
    logoEngine.execute("SHOW ARCTAN 1")
    #expect(ed8.statusMessage == "45")

    let ed9 = Editor()
    logoEngine.delegate = ed9
    logoEngine.execute("SHOW (ARCTAN 0 1)")
    #expect(ed9.statusMessage == "90")

    let ed10 = Editor()
    logoEngine.delegate = ed10
    logoEngine.execute("SHOW (RADARCTAN 0 1)")
    #expect(ed10.statusMessage == "1.5707963267948966")
}

@Test func testLogoBoxMultiLineTextWrapping() throws {
    let logoEngine = LogoEngine()

    // 1. Escaped \n line break inside BOX "Line 1\nLine 2"
    let ed1 = Editor()
    logoEngine.delegate = ed1
    logoEngine.execute("BOX \"Line 1\\nLine 2\"")
    #expect(ed1.buffer.lines[0] == "┌────────┐")
    #expect(ed1.buffer.lines[1] == "│ Line 1 │")
    #expect(ed1.buffer.lines[2] == "│ Line 2 │")
    #expect(ed1.buffer.lines[3] == "└────────┘")

    // 2. BOX width height "text" with center alignment
    let ed2 = Editor()
    logoEngine.delegate = ed2
    logoEngine.execute("BOX 16 4 \"Hello\\nWorld\" \"center\"")
    #expect(ed2.buffer.lines[0] == "┌──────────────┐")
    #expect(ed2.buffer.lines[1] == "│    Hello     │")
    #expect(ed2.buffer.lines[2] == "│    World     │")
    #expect(ed2.buffer.lines[3] == "└──────────────┘")

    // 3. Auto word wrapping when text length exceeds width
    let ed3 = Editor()
    logoEngine.delegate = ed3
    logoEngine.execute("BOX 12 3 \"Hello World\"")
    #expect(ed3.buffer.lines[0] == "┌──────────┐")
    #expect(ed3.buffer.lines[1] == "│ Hello    │")
    #expect(ed3.buffer.lines[2] == "│ World    │")
    #expect(ed3.buffer.lines[3] == "└──────────┘")
}

@Test func testLogoDataStructurePrimitives() throws {
    let logoEngine = LogoEngine()

    // 1. Constructors: WORD, LIST, SENTENCE, FPUT, LPUT, REVERSE, GENSYM
    let ed1 = Editor()
    logoEngine.delegate = ed1
    logoEngine.execute("TYPE WORD \"hello\" \"world\" TYPE \" \" TYPE LIST 1 2 TYPE \" \" TYPE SE [1 2] [3 4]")
    #expect(ed1.buffer.lines[0] == "helloworld [1 2] [1 2 3 4]")

    let ed2 = Editor()
    logoEngine.delegate = ed2
    logoEngine.execute("TYPE FPUT 0 [1 2] TYPE \" \" TYPE LPUT 3 [1 2] TYPE \" \" TYPE REVERSE \"abc\"")
    #expect(ed2.buffer.lines[0] == "[0 1 2] [1 2 3] cba")

    // 2. Selectors: FIRST, LAST, BUTFIRST (BF), BUTLAST (BL), ITEM, REMDUP
    let ed3 = Editor()
    logoEngine.delegate = ed3
    logoEngine.execute(
        "TYPE FIRST [10 20] TYPE \" \" TYPE LAST \"abc\" TYPE \" \" TYPE BF [10 20 30] TYPE \" \" TYPE BL \"abc\" TYPE \" \" TYPE ITEM 2 [10 20 30]"
    )
    #expect(ed3.buffer.lines[0] == "10 c [20 30] ab 20")

    let ed4 = Editor()
    logoEngine.delegate = ed4
    logoEngine.execute("TYPE REMDUP \"banana\" TYPE \" \" TYPE REMDUP [1 2 2 3 1]")
    #expect(ed4.buffer.lines[0] == "ban [1 2 3]")

    // 3. Mutators & Stack / Queue: PUSH, POP, QUEUE, DEQUEUE, SETITEM
    let ed5 = Editor()
    logoEngine.delegate = ed5
    logoEngine.execute(
        "MAKE \"s\" [2 1] PUSH \"s\" 3 TYPE :s TYPE \" pop: \" TYPE POP \"s\" TYPE \" remaining: \" TYPE :s")
    #expect(ed5.buffer.lines[0] == "[3 2 1] pop: 3 remaining: [2 1]")

    let ed6 = Editor()
    logoEngine.delegate = ed6
    logoEngine.execute(
        "MAKE \"q\" [1 2] QUEUE \"q\" 3 TYPE :q TYPE \" deq: \" TYPE DEQUEUE \"q\" TYPE \" remaining: \" TYPE :q")
    #expect(ed6.buffer.lines[0] == "[1 2 3] deq: 1 remaining: [2 3]")

    // 4. Predicates & Queries: WORD?, LIST?, NUMBER?, EMPTY?, MEMBER?, COUNT, ASCII, CHAR, UPPERCASE, LOWERCASE
    let ed7 = Editor()
    logoEngine.delegate = ed7
    logoEngine.execute(
        "TYPE LIST? [1 2] TYPE \" \" TYPE NUMBER? 123 TYPE \" \" TYPE EMPTY? \"\" TYPE \" \" TYPE MEMBER? \"b\" [a b c]"
    )
    #expect(ed7.buffer.lines[0] == "true true true true")

    let ed8 = Editor()
    logoEngine.delegate = ed8
    logoEngine.execute(
        "TYPE COUNT [1 2 3] TYPE \" \" TYPE ASCII \"a\" TYPE \" \" TYPE CHAR 97 TYPE \" \" TYPE UPPERCASE \"abc\" TYPE \" \" TYPE LOWERCASE \"XYZ\""
    )
    #expect(ed8.buffer.lines[0] == "3 97 a ABC xyz")
}

@Test func testLogoEngineDelegatePattern() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)
    logoEngine.execute("TYPE \"Hello Delegate\" NL BOX \"Delegate Text\"")
    #expect(editor.buffer.lines[0] == "Hello Delegate")
    #expect(editor.buffer.lines[1] == "┌───────────────┐")
    #expect(editor.buffer.lines[2] == "│ Delegate Text │")
    #expect(editor.buffer.lines[3] == "└───────────────┘")
}

@Test func testBoxDateExpression() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)
    logoEngine.execute("BOX DATE \"YYYY\"")
    let currentYear = String(Calendar.current.component(.year, from: Date()))
    #expect(editor.buffer.lines.count >= 3)
    #expect(editor.buffer.lines[1].contains(currentYear))
}

@Test func testLastResultEvaluation() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("1 + 2")
    #expect(logoEngine.lastResult == "3")

    logoEngine.execute("WORD \"Hello\" \"World\"")
    #expect(logoEngine.lastResult == "HelloWorld")

    logoEngine.execute("DATE \"yyyy\"")
    let currentYear = String(Calendar.current.component(.year, from: Date()))
    #expect(logoEngine.lastResult == currentYear)
}

@Test func testDeleteLineLogoCommand() throws {
    let editor = Editor()
    editor.buffer.lines = ["Line 1", "Line 2", "Line 3", "Line 4"]
    editor.buffer.lineIndex = 1
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("DELETELINE")
    #expect(editor.buffer.lines == ["Line 1", "Line 3", "Line 4"])

    logoEngine.execute("DL 2")
    #expect(editor.buffer.lines == ["Line 1"])
}

@Test func testLogoPredicates() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    // 1. WORD? / WORDP
    logoEngine.execute("WORDP \"a\"")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("WORDP 123")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("WORD? [1 2]")
    #expect(logoEngine.lastResult == "false")

    // 2. LIST? / LISTP
    logoEngine.execute("LISTP [1 2 3]")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("LIST? \"abc\"")
    #expect(logoEngine.lastResult == "false")

    // 3. ARRAY? / ARRAYP
    logoEngine.execute("ARRAYP {1 2}")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("ARRAY? [1 2]")
    #expect(logoEngine.lastResult == "false")

    // 4. NUMBER? / NUMBERP
    logoEngine.execute("NUMBERP 123.45")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("NUMBER? \"abc\"")
    #expect(logoEngine.lastResult == "false")

    // 5. EMPTY? / EMPTYP
    logoEngine.execute("EMPTYP \"\"")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("EMPTY? []")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("EMPTY? \"a\"")
    #expect(logoEngine.lastResult == "false")

    // 6. EQUAL? / EQUALP / =
    logoEngine.execute("EQUALP [1 2] [1 2]")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("EQUAL? 12 12.0")
    #expect(logoEngine.lastResult == "true")

    // 7. NOTEQUAL? / NOTEQUALP
    logoEngine.execute("NOTEQUALP \"a\" \"b\"")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("NOTEQUAL? 1 1")
    #expect(logoEngine.lastResult == "false")

    // 8. BEFORE? / BEFOREP
    logoEngine.execute("BEFOREP \"apple\" \"banana\"")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("BEFORE? \"banana\" \"apple\"")
    #expect(logoEngine.lastResult == "false")

    // 9. .EQ (Identity Equality)
    logoEngine.execute(".EQ \"test\" \"test\"")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute(".EQ 12 12.0")
    #expect(logoEngine.lastResult == "false")

    // 10. SUBSTRING? / SUBSTRINGP
    logoEngine.execute("SUBSTRINGP \"cat\" \"caterpillar\"")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("SUBSTRING? \"dog\" \"caterpillar\"")
    #expect(logoEngine.lastResult == "false")

    // 11. MEMBER? / MEMBERP
    logoEngine.execute("MEMBERP \"b\" [a b c]")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("MEMBER? \"x\" [a b c]")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("MEMBER \"a\" \"banana\"")
    #expect(logoEngine.lastResult == "anana")

    logoEngine.execute("MEMBER 2 [1 2 3 4]")
    #expect(logoEngine.lastResult == "[2 3 4]")

    logoEngine.execute("PARSE \"1+2\"")
    #expect(logoEngine.lastResult == "[1 + 2]")

    // 12. Procedure/name introspection predicates
    logoEngine.execute("PRIMITIVE? \"SUM")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("PRIMITIVEP \"MISSINGPROC")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("TO FOO OUTPUT 1 END")
    logoEngine.execute("DEFINED? \"FOO")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("DEFINEDP \"SUM")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("PROCEDURE? \"SUM")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("PROCEDUREP \"FOO")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("PROCEDURE? \"MISSINGPROC")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("MAKE \"x 10")
    logoEngine.execute("NAME? \"x")
    #expect(logoEngine.lastResult == "true")
    logoEngine.execute("NAMEP \"y")
    #expect(logoEngine.lastResult == "false")
}

@Test func testLogoByeStopsTopLevelExecution() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("TYPE \"a\" BYE TYPE \"b\"")

    #expect(editor.buffer.lines[0] == "a")
    #expect(logoEngine.byeFlag == true)
}

@Test func testSection4ArithmeticPrimitives() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    // Basic Operations
    logoEngine.execute("SUM 10 20")
    #expect(logoEngine.lastResult == "30")

    logoEngine.execute("SUM [1 2 3 4 5]")
    #expect(logoEngine.lastResult == "15")

    logoEngine.execute("SUM {1 2 3 4 5}")
    #expect(logoEngine.lastResult == "15")

    logoEngine.execute("(SUM 1 2 3 4 5)")
    #expect(logoEngine.lastResult == "15")

    logoEngine.execute("(SUM [1 2] 3 [4 5])")
    #expect(logoEngine.lastResult == "15")

    logoEngine.execute("MIN 10 20")
    #expect(logoEngine.lastResult == "10")

    logoEngine.execute("MAX 10 20")
    #expect(logoEngine.lastResult == "20")

    logoEngine.execute("MIN [3 1 4 1 5]")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("MAX {3 1 4 1 5}")
    #expect(logoEngine.lastResult == "5")

    logoEngine.execute("(MIN 3 1 4 1 5)")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("(MAX [3 1] 4 [1 5])")
    #expect(logoEngine.lastResult == "5")

    logoEngine.execute("DIFFERENCE 20 5")
    #expect(logoEngine.lastResult == "15")

    logoEngine.execute("PRODUCT 4 5")
    #expect(logoEngine.lastResult == "20")

    logoEngine.execute("QUOTIENT 20 4")
    #expect(logoEngine.lastResult == "5")

    logoEngine.execute("QUOTIENT 4")
    #expect(logoEngine.lastResult == "0.25")

    logoEngine.execute("POWER 2 3")
    #expect(logoEngine.lastResult == "8")

    logoEngine.execute("REMAINDER 10 3")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("MODULO -10 3")
    #expect(logoEngine.lastResult == "2")

    logoEngine.execute("MINUS 42")
    #expect(logoEngine.lastResult == "-42")

    logoEngine.execute("ABS -15")
    #expect(logoEngine.lastResult == "15")

    logoEngine.execute("INT 3.7")
    #expect(logoEngine.lastResult == "3")

    logoEngine.execute("ROUND 3.7")
    #expect(logoEngine.lastResult == "4")

    // Infix Operators
    logoEngine.execute("10 + 5")
    #expect(logoEngine.lastResult == "15")

    logoEngine.execute("20 - 4")
    #expect(logoEngine.lastResult == "16")

    logoEngine.execute("3 * 7")
    #expect(logoEngine.lastResult == "21")

    logoEngine.execute("15 / 3")
    #expect(logoEngine.lastResult == "5")

    logoEngine.execute("2 ^ 4")
    #expect(logoEngine.lastResult == "16")

    logoEngine.execute("10 % 3")
    #expect(logoEngine.lastResult == "1")

    // Exponential & Logarithm
    logoEngine.execute("SQRT 16")
    #expect(logoEngine.lastResult == "4")

    logoEngine.execute("EXP 0")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("LOG10 100")
    #expect(logoEngine.lastResult == "2")

    logoEngine.execute("LN 1")
    #expect(logoEngine.lastResult == "0")

    // Trigonometry (Degree & Radian)
    logoEngine.execute("SIN 90")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("COS 0")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("TAN 0")
    #expect(logoEngine.lastResult == "0")

    logoEngine.execute("ARCTAN 1")
    #expect(logoEngine.lastResult == "45")

    logoEngine.execute("RADSIN 0")
    #expect(logoEngine.lastResult == "0")

    logoEngine.execute("RADCOS 0")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("RADTAN 0")
    #expect(logoEngine.lastResult == "0")

    logoEngine.execute("RADARCTAN 0")
    #expect(logoEngine.lastResult == "0")

    // Sequences & Random & Formatting
    logoEngine.execute("ISEQ 1 5")
    #expect(logoEngine.lastResult == "[1 2 3 4 5]")

    logoEngine.execute("RANGE 1 5")
    #expect(logoEngine.lastResult == "[1 2 3 4 5]")

    logoEngine.execute("RANGE 5 1")
    #expect(logoEngine.lastResult == "[5 4 3 2 1]")

    logoEngine.execute("RANGE 1 10 2")
    #expect(logoEngine.lastResult == "[1 3 5 7 9]")

    logoEngine.execute("RSEQ 0 10 3")
    #expect(logoEngine.lastResult == "[0 5 10]")

    logoEngine.execute("RANDOM 10")
    #expect(logoEngine.lastResult != nil)

    logoEngine.execute("RERANDOM")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("FORM (1.0 / 3.0) 10 3")
    #expect(logoEngine.lastResult == "     0.333")

    // Bitwise Operations
    logoEngine.execute("BITAND 6 3")
    #expect(logoEngine.lastResult == "2")

    logoEngine.execute("BITOR 6 3")
    #expect(logoEngine.lastResult == "7")

    logoEngine.execute("BITXOR 6 3")
    #expect(logoEngine.lastResult == "5")

    logoEngine.execute("BITNOT 0")
    #expect(logoEngine.lastResult == "-1")

    logoEngine.execute("ASHIFT 1 3")
    #expect(logoEngine.lastResult == "8")

    logoEngine.execute("LSHIFT 1 3")
    #expect(logoEngine.lastResult == "8")
}

@Test func testSection5LogicalOperations() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("TRUE")
    #expect(logoEngine.lastResult == "true")

    logoEngine.execute("FALSE")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("AND TRUE FALSE")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("OR TRUE FALSE")
    #expect(logoEngine.lastResult == "true")

    logoEngine.execute("XOR TRUE TRUE")
    #expect(logoEngine.lastResult == "false")

    logoEngine.execute("NOT FALSE")
    #expect(logoEngine.lastResult == "true")
}

@Test func testRecursiveProcedureWithParameters() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    let fibProcedure = """
        TO FIB :N
          IFELSE :N <= 1 [ OUTPUT :N ] [ OUTPUT (FIB :N - 1) + (FIB :N - 2) ]
        END
        """

    logoEngine.execute(fibProcedure)

    logoEngine.execute("FIB 1")
    #expect(logoEngine.lastResult == "1", "FIB 1 failed: \(logoEngine.lastResult ?? "nil")")

    logoEngine.execute("FIB 2")
    #expect(logoEngine.lastResult == "1", "FIB 2 failed: \(logoEngine.lastResult ?? "nil")")

    logoEngine.execute("FIB 3")
    #expect(logoEngine.lastResult == "2", "FIB 3 failed: \(logoEngine.lastResult ?? "nil")")

    let semaphore = DispatchSemaphore(value: 0)
    let fib10Result = LogoTestResultBox()
    let fib10Thread = Thread {
        let threadEditor = Editor()
        let threadEngine = LogoEngine(delegate: threadEditor)
        threadEngine.execute(fibProcedure)
        threadEngine.execute("FIB 10")
        fib10Result.value = threadEngine.lastResult
        semaphore.signal()
    }
    fib10Thread.stackSize = 8 * 1024 * 1024
    fib10Thread.start()
    semaphore.wait()
    #expect(fib10Result.value == "55", "FIB 10 failed: \(fib10Result.value ?? "nil")")
}

@Test func testSection81ControlStructures() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    // RUN & RUNRESULT
    logoEngine.execute("RUN [ MAKE \"A 42 ]")
    #expect(logoEngine.variables["a"] == "42", "variables['a'] was \(logoEngine.variables["a"] ?? "nil")")

    // NAME & THING
    logoEngine.execute("MAKE \"X 10 THING \"X")
    #expect(logoEngine.lastResult == "10", "THING \"X was \(logoEngine.lastResult ?? "nil")")

    logoEngine.execute("MAKE \"VARNAME \"X THING :VARNAME")
    #expect(logoEngine.lastResult == "10", "THING :VARNAME was \(logoEngine.lastResult ?? "nil")")

    logoEngine.execute("NAME 42 \"ANSWER THING \"ANSWER")
    #expect(logoEngine.lastResult == "42", "NAME/THING answer was \(logoEngine.lastResult ?? "nil")")

    logoEngine.execute("MAKE \"SLOT \"NAME NAME \"Ada :SLOT THING \"NAME")
    #expect(logoEngine.lastResult == "Ada", "dynamic NAME/THING was \(logoEngine.lastResult ?? "nil")")

    logoEngine.execute("RUNRESULT [ OUTPUT 1 + 2 ]")
    #expect(logoEngine.lastResult == "[3]", "RUNRESULT output was \(logoEngine.lastResult ?? "nil")")

    logoEngine.execute("RUNRESULT [ MAKE \"B 10 ]")
    #expect(logoEngine.lastResult == "[]", "RUNRESULT empty was \(logoEngine.lastResult ?? "nil")")

    // REPEAT & REPCOUNT / #
    logoEngine.execute("MAKE \"SUM 0 REPEAT 5 [ MAKE \"SUM :SUM + # ]")
    #expect(logoEngine.variables["sum"] == "15", "all variables: \(logoEngine.variables)")

    logoEngine.execute("MAKE \"SUM2 0 REPEAT 4 [ MAKE \"SUM2 :SUM2 + REPCOUNT ]")
    #expect(logoEngine.variables["sum2"] == "10", "variables['sum2'] was \(logoEngine.variables["sum2"] ?? "nil")")

    // FOREVER & STOP
    logoEngine.execute(
        """
        TO TESTFOREVER
          MAKE "N 0
          FOREVER [
            MAKE "N :N + 1
            IF :N == 3 [ STOP ]
          ]
        END
        TESTFOREVER
        """)
    #expect(logoEngine.variables["n"] == "3", "variables['n'] was \(logoEngine.variables["n"] ?? "nil")")

    // TEST, IFTRUE, IFFALSE
    logoEngine.execute("TEST 2 > 1  IFTRUE [ MAKE \"ANS \"yep ] IFFALSE [ MAKE \"ANS \"nope ]")
    #expect(logoEngine.variables["ans"] == "yep", "variables['ans'] was \(logoEngine.variables["ans"] ?? "nil")")

    logoEngine.execute("TEST 1 > 2  IFTRUE [ MAKE \"ANS \"yep ] IFFALSE [ MAKE \"ANS \"nope ]")
    #expect(logoEngine.variables["ans"] == "nope", "variables['ans'] was \(logoEngine.variables["ans"] ?? "nil")")

    // FOR loop
    logoEngine.execute("MAKE \"FORSUM 0 FOR [ I 1 5 1 ] [ MAKE \"FORSUM :FORSUM + :I ]")
    #expect(
        logoEngine.variables["forsum"] == "15", "variables['forsum'] was \(logoEngine.variables["forsum"] ?? "nil")")

    // DOTIMES loop
    logoEngine.execute("MAKE \"DOTSUM 0 DOTIMES [ I 5 ] [ MAKE \"DOTSUM :DOTSUM + :I ]")
    #expect(
        logoEngine.variables["dotsum"] == "10", "variables['dotsum'] was \(logoEngine.variables["dotsum"] ?? "nil")")

    // WHILE loop
    logoEngine.execute("MAKE \"W 0 WHILE :W < 5 [ MAKE \"W :W + 1 ]")
    #expect(logoEngine.variables["w"] == "5", "variables['w'] was \(logoEngine.variables["w"] ?? "nil")")

    // UNTIL loop
    logoEngine.execute("MAKE \"U 0 UNTIL :U == 5 [ MAKE \"U :U + 1 ]")
    #expect(logoEngine.variables["u"] == "5", "variables['u'] was \(logoEngine.variables["u"] ?? "nil")")

    // DO.WHILE loop
    logoEngine.execute("MAKE \"DW 0 DO.WHILE [ MAKE \"DW :DW + 1 ] :DW < 3")
    #expect(logoEngine.variables["dw"] == "3", "variables['dw'] was \(logoEngine.variables["dw"] ?? "nil")")

    // DO.UNTIL loop
    logoEngine.execute("MAKE \"DU 0 DO.UNTIL [ MAKE \"DU :DU + 1 ] :DU == 3")
    #expect(logoEngine.variables["du"] == "3", "variables['du'] was \(logoEngine.variables["du"] ?? "nil")")

    // CASE
    logoEngine.execute("CASE \"B [ [ [\"A] \"first ] [ [\"B] \"second ] [ ELSE \"other ] ]")
    #expect(logoEngine.lastResult == "second", "CASE lastResult was \(logoEngine.lastResult ?? "nil")")

    // COND
    logoEngine.execute("COND [ [ [1 > 2] \"no ] [ [2 > 1] \"yes ] [ ELSE \"other ] ]")
    #expect(logoEngine.lastResult == "yes", "COND lastResult was \(logoEngine.lastResult ?? "nil")")

    // IGNORE
    logoEngine.execute("IGNORE 1 + 2")

    // CATCH & THROW & ERROR
    logoEngine.execute("CATCH \"T [ THROW \"T \"hello ]")
    #expect(logoEngine.lastResult == "hello", "CATCH lastResult was \(logoEngine.lastResult ?? "nil")")
}

@Test func testSection82TemplateIteration() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    // APPLY
    logoEngine.execute("APPLY [? * ?] [5]")
    #expect(logoEngine.lastResult == "25")

    logoEngine.execute("APPLY [?1 + ?2] [3 4]")
    #expect(logoEngine.lastResult == "7")

    logoEngine.execute("APPLY [[X Y] :X * :Y] [3 4]")
    #expect(logoEngine.lastResult == "12")

    logoEngine.execute("APPLY [[X Y] [OUTPUT :X + :Y]] [3 4]")
    #expect(logoEngine.lastResult == "7")

    // FOREACH
    logoEngine.execute("MAKE \"ACC \" FOREACH [A B C] [ MAKE \"ACC WORD :ACC ? ]")
    #expect(logoEngine.variables["acc"] == "ABC")

    // MAP
    logoEngine.execute("MAP [? * ?] [1 2 3]")
    #expect(logoEngine.lastResult == "[1 4 9]")

    // MAP.SE
    logoEngine.execute("MAP.SE [?REST] [1 2 3 4]")
    #expect(logoEngine.lastResult == "[2 3 4 3 4 4]")

    // FILTER
    logoEngine.execute("FILTER [? % 2 == 1] [1 2 3 4 5]")
    #expect(logoEngine.lastResult == "[1 3 5]")

    // FIND
    logoEngine.execute("FIND [? % 2 == 0] [1 3 4 7]")
    #expect(logoEngine.lastResult == "4")

    // REDUCE
    logoEngine.execute("REDUCE [?1 + ?2] [1 2 3 4 5]")
    #expect(logoEngine.lastResult == "15")

    // CROSSMAP
    logoEngine.execute("CROSSMAP [WORD ?1 ?2] [[A B] [X Y]]")
    #expect(logoEngine.lastResult == "[AX AY BX BY]")
}

@Test func testForeachQuotedWordLists() throws {
    let dummyEditor = Editor()
    let logoEngine = LogoEngine(delegate: dummyEditor)

    // 1. foreach ["a "b "c] [ make "acc word :acc ? ]
    logoEngine.execute("MAKE \"ACC \"\" FOREACH [\"a \"b \"c] [ MAKE \"ACC WORD :ACC ? ]")
    #expect(logoEngine.variables["acc"] == "abc")

    // 2. foreach ["a" "b" "c"] [ make "acc word :acc ? ]
    logoEngine.execute("MAKE \"ACC \"\" FOREACH [\"a\" \"b\" \"c\"] [ MAKE \"ACC WORD :ACC ? ]")
    #expect(logoEngine.variables["acc"] == "abc")

    // 3. foreach ["a" "b "c] [ make "acc word :acc ? ]
    logoEngine.execute("MAKE \"ACC \"\" FOREACH [\"a\" \"b \"c] [ MAKE \"ACC WORD :ACC ? ]")
    #expect(logoEngine.variables["acc"] == "abc")

    // 4. Editor PRINT testing for all 3 list quote formats
    let editor = Editor()
    editor.logoEngine.execute("FOREACH [\"a \"b \"c] [ PRINT ? ]")
    #expect(editor.buffer.lines == ["abc"])

    editor.buffer.lines = [""]
    editor.buffer.columnIndex = 0
    editor.logoEngine.execute("FOREACH [\"a\" \"b\" \"c\"] [ PRINT ? ]")
    #expect(editor.buffer.lines == ["abc"])

    editor.buffer.lines = [""]
    editor.buffer.columnIndex = 0
    editor.logoEngine.execute("FOREACH [\"a\" \"b \"c] [ PRINT ? ]")
    #expect(editor.buffer.lines == ["abc"])
}

@Test func testTypeApplyExpressionWithoutParentheses() throws {
    let editor = Editor()
    editor.logoEngine.execute("TYPE APPLY [?1 + ?2] [1 2]")
    #expect(editor.buffer.lines == ["3"])

    editor.buffer.lines = [""]
    editor.buffer.columnIndex = 0
    editor.logoEngine.execute("PRINT APPLY [?1 + ?2] [1 2]")
    #expect(editor.buffer.lines == ["3"])
}

@Test func testVariadicWordPrimitiveInParentheses() throws {
    let editor = Editor()
    editor.logoEngine.execute("SHOW (WORD \"a \"b \"c)")
    #expect(editor.statusMessage == "abc")

    editor.buffer.lines = [""]
    editor.buffer.columnIndex = 0
    editor.logoEngine.execute("PRINT (WORD \"x \"y \"z \"w)")
    #expect(editor.buffer.lines == ["xyzw"])
}

@Test func testVariadicListPrimitiveWithArithmeticExpressions() throws {
    let editor = Editor()
    editor.logoEngine.execute("SHOW (LIST 1+2 2+3 3+4)")
    #expect(editor.statusMessage == "[3 5 7]")
}

@Test func testMDArrayPrimitive() throws {
    let editor = Editor()
    editor.logoEngine.execute("SHOW (MDARRAY [3 5] 0)")
    #expect(!editor.statusMessage.isEmpty)
    #expect(editor.statusMessage.hasPrefix("{") && editor.statusMessage.hasSuffix("}"))
}

@Test func testMDItemAndMDSetItemPrimitives() throws {
    let editor = Editor()
    // 1. MDITEM reading element
    editor.logoEngine.execute("SHOW MDITEM [2 1] {{\"a \"b} {\"c \"d}}")
    #expect(editor.statusMessage == "c")

    // 2. MDSETITEM updating element
    editor.logoEngine.execute("MAKE \"m {{\"a \"b} {\"c \"d}} MDSETITEM [2 1] :m \"X SHOW MDITEM [2 1] :m")
    #expect(editor.statusMessage == "X")
}

@Test func testPickPrimitive() throws {
    let editor = Editor()

    // 1. Pick from List
    editor.logoEngine.execute("SHOW PICK [ 1 2 3 ]")
    #expect(["1", "2", "3"].contains(editor.statusMessage))

    // 2. Pick from Word
    editor.logoEngine.execute("SHOW PICK \"abc")
    #expect(["a", "b", "c"].contains(editor.statusMessage))

    // 3. Pick from Array
    editor.logoEngine.execute("SHOW PICK { \"x \"y \"z }")
    #expect(["x", "y", "z"].contains(editor.statusMessage))
}

@Test func testRemoveAndRemdupPrimitives() throws {
    let editor = Editor()

    // 1. REMOVE from List
    editor.logoEngine.execute("SHOW REMOVE \"b [ a b c ]")
    #expect(editor.statusMessage == "[a c]")

    // 2. REMOVE from Word
    editor.logoEngine.execute("SHOW REMOVE \"a \"banana")
    #expect(editor.statusMessage == "bnn")

    // 3. REMDUP from List
    editor.logoEngine.execute("SHOW REMDUP [ a b a c b ]")
    #expect(editor.statusMessage == "[a b c]")

    // 4. REMDUP from Word
    editor.logoEngine.execute("SHOW REMDUP \"banana")
    #expect(editor.statusMessage == "ban")
}

@Test func testSplitAndQuotedPrimitives() throws {
    let editor = Editor()

    // 1. SPLIT word
    editor.logoEngine.execute("SHOW SPLIT \"a \"banana")
    #expect(editor.statusMessage == "[b n n]")

    // 2. SPLIT list
    editor.logoEngine.execute("SHOW SPLIT 3 [1 2 3 4 1 2 3 4]")
    #expect(editor.statusMessage == "[[1 2] [4 1 2] [4]]")

    // 3. QUOTED word
    editor.logoEngine.execute("SHOW QUOTED \"abc")
    #expect(editor.statusMessage == "\"abc")

    // 4. QUOTED number
    editor.logoEngine.execute("SHOW QUOTED 123")
    #expect(editor.statusMessage == "\"123")
}

@Test func testSetFirstAndSetBFPrimitives() throws {
    let editor = Editor()

    // 1. .SETFIRST on List
    editor.logoEngine.execute("MAKE \"a [ 1 2 3 ] .SETFIRST :a \"7 SHOW :a")
    #expect(editor.statusMessage == "[7 2 3]")

    // 2. .SETFIRST on Array
    editor.logoEngine.execute("MAKE \"a { 1 2 3 } .SETFIRST :a \"7 SHOW :a")
    #expect(editor.statusMessage == "{7 2 3}")

    // 3. .SETBF on List
    editor.logoEngine.execute("MAKE \"a [ 1 2 3 ] .SETBF :a [ 8 9 ] SHOW :a")
    #expect(editor.statusMessage == "[1 8 9]")
}

@Test func testFirstsAndButFirstsPrimitives() throws {
    let editor = Editor()
    editor.logoEngine.execute("SHOW FIRSTS [ [1 2 3] [a b c] ]")
    #expect(editor.statusMessage == "[1 a]")

    editor.logoEngine.execute("SHOW FIRSTS [ abc def ]")
    #expect(editor.statusMessage == "[a d]")

    editor.logoEngine.execute("SHOW BUTFIRSTS [ [1 2 3] [a b c] ]")
    #expect(editor.statusMessage == "[[2 3] [b c]]")

    editor.logoEngine.execute("SHOW BFS [ abc def ]")
    #expect(editor.statusMessage == "[bc ef]")
}

@Test func testLogoEditorBufferPrimitives() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    // 1. Buffer Queries (1-indexed)
    editor.buffer.lines = ["First Line", "Second Line", "Third Line"]
    editor.buffer.lineIndex = 1  // 2nd line
    editor.buffer.columnIndex = 4  // 5th col

    logoEngine.execute("ROW")
    #expect(logoEngine.lastResult == "2")

    logoEngine.execute("COL")
    #expect(logoEngine.lastResult == "5")

    logoEngine.execute("LINECOUNT")
    #expect(logoEngine.lastResult == "3")

    logoEngine.execute("GETLINE 1")
    #expect(logoEngine.lastResult == "First Line")

    logoEngine.execute("GETLINE 2")
    #expect(logoEngine.lastResult == "Second Line")

    logoEngine.execute("BUFFERTEXT")
    #expect(logoEngine.lastResult == "First Line\nSecond Line\nThird Line")

    logoEngine.execute("MODIFIED?")
    #expect(logoEngine.lastResult == "0")

    // 2. Buffer Mutations & Cursor Positioning
    logoEngine.execute("GOTOLINE 1")
    #expect(editor.buffer.lineIndex == 0)

    logoEngine.execute("GOTOCOL 1")
    #expect(editor.buffer.columnIndex == 0)

    logoEngine.execute("SETLINE 1 \"New First Line\"")
    #expect(editor.buffer.lines[0] == "New First Line")

    // 3. Multi-Buffer Commands
    logoEngine.execute("BUFFERS")
    #expect(logoEngine.lastResult != nil)

    logoEngine.execute("BUFFER")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("OPENBUFFER \"test_buffer.txt\"")
    #expect(editor.buffers.count == 2)
    #expect(editor.currentBufferIndex == 1)

    logoEngine.execute("EDIT \"pe2_edit.txt\"")
    #expect(editor.buffers.count == 3)
    #expect(editor.currentBufferIndex == 2)

    logoEngine.execute("PREVBUFFER")
    #expect(editor.currentBufferIndex == 1)

    logoEngine.execute("NEXTBUFFER")
    #expect(editor.currentBufferIndex == 2)

    logoEngine.execute("CLOSEBUFFER")
    #expect(editor.buffers.count == 2)
    #expect(editor.currentBufferIndex == 1)

    logoEngine.execute("CLEARBUFFER")
    #expect(editor.buffer.lines == [""])
}

@Test func testPe2CompatibleFileCommands() throws {
    let savePath = FileManager.default.temporaryDirectory.appendingPathComponent("se_pe2_save.txt").path
    let filePath = FileManager.default.temporaryDirectory.appendingPathComponent("se_pe2_file.txt").path
    defer {
        try? FileManager.default.removeItem(atPath: savePath)
        try? FileManager.default.removeItem(atPath: filePath)
    }

    let editor = Editor(filePath: savePath)
    let logoEngine = LogoEngine(delegate: editor)

    editor.buffer.lines = ["saved by SAVE"]
    editor.buffer.isModified = true
    logoEngine.execute("SAVE")
    #expect(try String(contentsOfFile: savePath, encoding: .utf8) == "saved by SAVE")
    #expect(editor.buffer.isModified == false)
    #expect(editor.buffers.count == 1)

    editor.openNewBuffer()
    editor.buffer.lines = ["saved and closed by FILE"]
    editor.buffer.isModified = true
    logoEngine.execute("FILE \"\(filePath)\"")
    #expect(try String(contentsOfFile: filePath, encoding: .utf8) == "saved and closed by FILE")
    #expect(editor.buffers.count == 1)
    #expect(editor.currentBufferIndex == 0)
}

@Test func testEditorCommandLineTextCommands() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)
    editor.buffer.lines = ["alpha", "beta", "gamma"]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 2

    logoEngine.execute("TOP")
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 0)

    logoEngine.execute("BOTTOM")
    #expect(editor.buffer.lineIndex == 2)
    #expect(editor.buffer.columnIndex == 5)

    logoEngine.execute("LINESTART")
    #expect(editor.buffer.columnIndex == 0)
    logoEngine.execute("LINEEND")
    #expect(editor.buffer.columnIndex == 5)

    logoEngine.execute("PREPEND \"<\" APPEND \">\"")
    #expect(editor.buffer.lines[2] == "<gamma>")

    logoEngine.execute("INSERT \"!")
    #expect(editor.buffer.lines[2] == "<gamma>!")

    logoEngine.execute("CHANGE \"gamma\" \"delta\"")
    #expect(editor.buffer.lines[2] == "<delta>!")

    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = editor.buffer.lines[0].count
    logoEngine.execute("JOIN \" \"")
    #expect(editor.buffer.lines == ["alpha beta", "<delta>!"])
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == "alpha ".count)

    editor.buffer.columnIndex = 5
    logoEngine.execute("SPLITLINE")
    #expect(editor.buffer.lines == ["alpha", " beta", "<delta>!"])
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 0)

    logoEngine.execute("SET TAB 2")
    editor.selectionMark = (line: 0, column: 0)
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 0
    logoEngine.execute("INDENT 2")
    #expect(editor.buffer.lines[0] == "    alpha")
    #expect(editor.buffer.lines[1] == "     beta")

    logoEngine.execute("OUTDENT")
    #expect(editor.buffer.lines[0] == "  alpha")
    #expect(editor.buffer.lines[1] == "   beta")
}

@Test func testLogoTableCommandCreatesAndConfiguresTables() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("TABLE 2 2")
    #expect(editor.isTableModeActive == false)
    #expect(editor.buffer.lines[0] == "┌────────────────┬────────────────┐")
    #expect(editor.buffer.lines[1] == "│                │                │")
    #expect(editor.buffer.lines[2] == "├────────────────┼────────────────┤")
    #expect(editor.buffer.lines[4] == "└────────────────┴────────────────┘")

    editor.buffer.lines = [""]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 0
    logoEngine.execute("TABLE 2 2 4")
    #expect(editor.buffer.lines[0] == "┌────┬────┐")
    #expect(editor.buffer.lines[1] == "│    │    │")
    #expect(editor.buffer.lines[2] == "├────┼────┤")
    #expect(editor.buffer.lines[4] == "└────┴────┘")

    editor.buffer.lines = [""]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 0
    logoEngine.execute("TABLE 999 999 999")
    #expect(editor.buffer.lines.count == 101)
    #expect(editor.buffer.lines[0].count == 821)

    editor.buffer.lines = [""]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 0
    logoEngine.execute("TABLE 0 0 0")
    #expect(editor.buffer.lines[0] == "┌─┐")
    #expect(editor.buffer.lines[1] == "│ │")
    #expect(editor.buffer.lines[2] == "└─┘")

    editor.buffer.lines = [""]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 0
    logoEngine.execute("TABLE BORDER ROUND TABLE")
    #expect(editor.defaultTableBorderStyle == .round)
    #expect(editor.buffer.lines[0].hasPrefix("╭"))
    #expect(editor.buffer.lines[0].hasSuffix("╮"))
    #expect(editor.isTableModeActive == false)

    logoEngine.execute("TABLE BORDER ASCII")
    #expect(editor.defaultTableBorderStyle == .ascii)

    logoEngine.execute("TABLE NEXTSTYLE")
    #expect(editor.defaultTableBorderStyle == .markdown)

    editor.defaultTableBorderStyle = .single
    editor.buffer.lines = ["before", "after"]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 0
    logoEngine.execute("TABLE 1 1")
    #expect(editor.buffer.lines[1] == "┌────────────────┐")
    #expect(editor.buffer.lines[2] == "│                │")
    #expect(editor.buffer.lines[3] == "└────────────────┘")
    #expect(editor.buffer.lines[4] == "after")

    editor.buffer.lines = ["    tail"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 4
    logoEngine.execute("TABLE 1 1")
    #expect(editor.buffer.lines[0] == "    ┌────────────────┐")
    #expect(editor.buffer.lines[1] == "    │                │")
    #expect(editor.buffer.lines[2] == "    └────────────────┘")
    #expect(editor.buffer.lines[3] == "tail")
}

@Test func testLogoSortPrimitive() {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    // 1. Basic numeric sorting
    logoEngine.execute("MAKE \"a SORT [3 12 2]")
    #expect(logoEngine.variables["a"] == "[2 3 12]")

    // 2. String/Word sorting
    logoEngine.execute("MAKE \"b SORT \"cba")
    #expect(logoEngine.variables["b"] == "abc")

    // 3. Descending keyword
    logoEngine.execute("MAKE \"c SORT \"DESC [1 5 2]")
    #expect(logoEngine.variables["c"] == "[5 2 1]")

    // 4. Custom template predicate comparator
    logoEngine.execute("MAKE \"d SORT [10 3 5] [?1 > ?2]")
    #expect(logoEngine.variables["d"] == "[10 5 3]")
}

@Test func testPersistentLogoEngineState() {
    let editor = Editor()

    // Execution 1: Define variable and procedure on editor.logoEngine
    editor.logoEngine.execute("MAKE \"val 42 TO GREET TYPE \"Hi END")

    // Execution 2: Use previously defined variable and procedure on the persistent editor.logoEngine
    editor.logoEngine.execute("TYPE :val GREET")
    #expect(editor.buffer.lines[0] == "42Hi")
}

@Test func testCustomLogoBindingUsesPersistentEditorEngine() {
    let editor = Editor()
    var config = EditorConfig()
    config.customKeyBinds[.alt("y")] = "logo: MAKE \"val 7 TO GREET TYPE \"Hi END"
    config.customKeyBinds[.alt("z")] = "logo: TYPE :val GREET"
    editor.applyCustomConfig(config)

    #expect(editor.commandRegistry.dispatch(key: .alt("y"), editor: editor))
    #expect(editor.commandRegistry.dispatch(key: .alt("z"), editor: editor))
    #expect(editor.buffer.lines[0] == "7Hi")
}

@Test func testSercLogoPreludeAndNamedScriptRunOnPersistentEngine() {
    let editor = Editor()
    var config = EditorConfig()
    config.logoPrelude = """
        MAKE "name "Ada
        TO GREET
          TYPE :name
        END
        """
    config.logoScripts["run-greet"] = """
        GREET
        TYPE "!
        """
    config.customKeyBinds[.alt("g")] = "logo:run-greet"
    editor.applyCustomConfig(config)

    #expect(editor.commandRegistry.dispatch(key: .alt("g"), editor: editor))
    #expect(editor.buffer.lines[0] == "Ada!")
}

@Test func testLogoFillPrimitive() {
    let editor = Editor()
    let logoEngine = editor.logoEngine

    // 1. Line Fill with ASCII & CJK (Width = 10, CJK character "測" has displayWidth = 2)
    logoEngine.execute("CLEARBUFFER FILL 10 \"測\"")
    #expect(editor.buffer.lines[0] == "測測測測測")
    #expect(editor.buffer.lines[0].displayWidth == 10)

    // 2. Line Fill with Odd width (Width = 9, 4 CJK "測" + 1 space = 9)
    logoEngine.execute("CLEARBUFFER FILL 9 \"測\"")
    #expect(editor.buffer.lines[0] == "測測測測 ")
    #expect(editor.buffer.lines[0].displayWidth == 9)

    // 3. Mode 3: Box Fill width height
    logoEngine.execute("CLEARBUFFER GOTO 1 1 FILL 5 3 \"*\"")
    #expect(editor.buffer.lines[0] == "*****")
    #expect(editor.buffer.lines[1] == "*****")
    #expect(editor.buffer.lines[2] == "*****")

    // 4. Mode 1: Flood Fill enclosed region
    logoEngine.execute("CLEARBUFFER BOX 5 5 \"single\" GOTO 2 2 FILL \".\"")
    #expect(editor.buffer.lines[1] == "│...│")
    #expect(editor.buffer.lines[2] == "│...│")
    #expect(editor.buffer.lines[3] == "│...│")

    // 5. Overlay fill uses visual columns when the existing line contains CJK text.
    logoEngine.execute("CLEARBUFFER TYPE \"中ab尾\" GOTO 1 3 FILL 2 \"*\"")
    #expect(editor.buffer.lines[0] == "中**尾")
    #expect(editor.buffer.lines[0].displayWidth == 6)

    // 6. Overlay fill keeps visual width when the fill pattern is CJK.
    logoEngine.execute("CLEARBUFFER TYPE \"abcdef\" GOTO 1 2 FILL 4 \"測\"")
    #expect(editor.buffer.lines[0] == "a測測f")
    #expect(editor.buffer.lines[0].displayWidth == 6)

    // 7. Overlay fill pads when the replaced region cuts through a CJK character.
    logoEngine.execute("CLEARBUFFER TYPE \"A測B\" GOTO 1 2 FILL 1 \"*\"")
    #expect(editor.buffer.lines[0] == "A* B")
    #expect(editor.buffer.lines[0].displayWidth == 4)

    // 8. Flood fill with CJK pattern fills display columns, not character count.
    logoEngine.execute("CLEARBUFFER BOX 30 4 GOTO 2 2 FILL \"你\"")
    #expect(editor.buffer.lines[0] == "┌────────────────────────────┐")
    #expect(editor.buffer.lines[1] == "│你你你你你你你你你你你你你你│")
    #expect(editor.buffer.lines[2] == "│你你你你你你你你你你你你你你│")
    #expect(editor.buffer.lines[3] == "└────────────────────────────┘")
    #expect(editor.buffer.lines[1].displayWidth == 30)

    // 9. Flood fill supports multi-character patterns.
    logoEngine.execute("CLEARBUFFER BOX 30 4 GOTO 2 2 FILL \"hi\"")
    #expect(editor.buffer.lines[1] == "│hihihihihihihihihihihihihihi│")
    #expect(editor.buffer.lines[2] == "│hihihihihihihihihihihihihihi│")
    #expect(editor.buffer.lines[1].displayWidth == 30)

    // 10. Flood fill without an enclosed region is rejected instead of filling the open buffer.
    logoEngine.execute("CLEARBUFFER TYPE \"open area\" GOTO 1 1 FILL \".\"")
    #expect(editor.buffer.lines == ["open area"])
    #expect(editor.statusMessage == "[ Fill requires an enclosed region or explicit size ]")
}

@Test func testLogoSemicolonComments() {
    let editor = Editor()
    let logoEngine = editor.logoEngine

    #expect(logoEngine.tokenize("; whole line comment").isEmpty)
    #expect(logoEngine.tokenize("TYPE \"A\" ; inline comment") == ["TYPE", "\"A\""])
    #expect(logoEngine.tokenize("TYPE \"A;B\" ; inline comment") == ["TYPE", "\"A;B\""])
    #expect(logoEngine.tokenize("TYPE \";") == ["TYPE", "\";"])
    #expect(logoEngine.tokenize("REPEAT 2 [ TYPE # ; comment inside block\n ]") == [
        "REPEAT", "2", "[", "TYPE", "#", "]"
    ])

    logoEngine.execute("""
    ; setup comment
    TYPE "A
    ; skipped command: TYPE "x
    TYPE "B ; inline comment
    """)
    #expect(editor.buffer.lines[0] == "AB")

    logoEngine.execute("CLEARBUFFER TYPE \";")
    #expect(editor.buffer.lines[0] == ";")

    logoEngine.execute("CLEARBUFFER TYPE \"hello;world\" ; inline comment")
    #expect(editor.buffer.lines[0] == "hello;world")

    logoEngine.execute("CLEARBUFFER REPEAT 3 [ TYPE # ; keep loop counter, drop comment\n ]")
    #expect(editor.buffer.lines[0] == "123")

    logoEngine.execute("CLEARBUFFER TYPE \"#\"")
    #expect(editor.buffer.lines[0] == "#")
}

@Test func testUnknownOrExpressionCommandDoesNotHang() {
    let editor = Editor()
    let logoEngine = editor.logoEngine

    // Executing numbers, unknown keywords, or standalone expressions should return safely without hanging
    logoEngine.execute("123")
    #expect(logoEngine.lastResult == "123")

    logoEngine.execute("UNKNOWN_COMMAND_ABC 456")
    #expect(logoEngine.lastResult == "456")
}

@Test func testLogoEditingCommandArgumentBoundaries() {
    let editor = Editor()
    let logoEngine = editor.logoEngine

    logoEngine.execute("TYPE \"x\"")
    #expect(editor.buffer.lines[0] == "x")

    logoEngine.execute("CLEARBUFFER TYPE \"a\" TYPE \"b\"")
    #expect(editor.buffer.lines[0] == "ab")

    logoEngine.execute("CLEARBUFFER TYPE \"Hello\" MOVE END TYPE \" World\"")
    #expect(editor.buffer.lines[0] == "Hello World")

    logoEngine.execute("SHOW \"done\"")
    #expect(editor.statusMessage == "done")

    logoEngine.execute("CLEARBUFFER TYPE \"mid\" PREPEND \"<\" APPEND \">\"")
    #expect(editor.buffer.lines[0] == "<mid>")
}

@Test func testSetHeadingAndHeadingPrimitives() {
    let editor = Editor()
    let logoEngine = editor.logoEngine

    #expect(logoEngine.heading == 90)

    logoEngine.execute("SETHEADING 0")
    #expect(logoEngine.heading == 0)

    logoEngine.execute("SETH \"RIGHT")
    #expect(logoEngine.heading == 90)

    logoEngine.execute("SETH \"DOWN")
    #expect(logoEngine.heading == 180)

    logoEngine.execute("SETH \"LEFT")
    #expect(logoEngine.heading == 270)

    logoEngine.execute("SETH \"UP")
    #expect(logoEngine.heading == 0)

    logoEngine.execute("TYPE HEADING")
    #expect(editor.buffer.lines[0] == "0")
}

@Test func testRecursiveProcedureLimitFailsSafely() {
    let semaphore = DispatchSemaphore(value: 0)
    let result = LogoTestResultBox()
    let thread = Thread {
        let editor = Editor()
        let logoEngine = editor.logoEngine
        logoEngine.execute("""
        TO LOOP
          OUTPUT LOOP
        END
        LOOP
        """)
        result.error = logoEngine.lastError
        result.status = editor.statusMessage
        semaphore.signal()
    }
    thread.stackSize = 8 * 1024 * 1024
    thread.start()
    semaphore.wait()

    #expect(result.error == "[Procedure recursion limit exceeded: LOOP]")
    #expect(result.status == "[Procedure recursion limit exceeded: LOOP]")
}
