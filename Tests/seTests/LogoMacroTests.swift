import Testing
import Foundation
@testable import Editor
@testable import LogoEngine

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
    let promptOutput = editor.generateScreenOutput(rows: 24, cols: 80)
    #expect(promptOutput.contains("\u{1B}[22;")) // Verify hardware cursor placed on row 22 (24-2) for active prompt

    editor.processKey(.char("T"))
    editor.processKey(.char("Y"))
    editor.processKey(.enter)
    #expect(editor.logoPromptHistory.last == "TY")

    // 10. SET Editor Configuration Settings test
    editor.displayConfig.showRuler = false
    logoEngine.execute("SET RULER ON")
    #expect(editor.displayConfig.showRuler == true)

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

    // TDD Test Example 2: BOX overlay in middle of background text
    let bgTextEditor = Editor()
    bgTextEditor.buffer.lines = ["AAAAAAAAAAA", "BBBBBBBBBBB", "CCCCCCCCCCC"]
    bgTextEditor.buffer.lineIndex = 0
    bgTextEditor.buffer.columnIndex = 3
    logoEngine.delegate = bgTextEditor
    logoEngine.execute("BOX 5 3 \"ascii\"")
    #expect(bgTextEditor.buffer.lines[0] == "AAA+---+AAA")
    #expect(bgTextEditor.buffer.lines[1] == "BBB|   |BBB")
    #expect(bgTextEditor.buffer.lines[2] == "CCC+---+CCC")

    // 14. LOGO LINE and NEWLINE Command test
    let lineEditor = Editor()
    logoEngine.delegate = lineEditor
    logoEngine.execute("TYPE \"Header\" NL 2 LINE 10 TYPE \"Footer\"")
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
    #expect(editor.buffer.lines.count >= 4)
    #expect(editor.buffer.lines[0] == "├┐")
    #expect(editor.buffer.lines[1] == "││")
    #expect(editor.buffer.lines[2] == "││")
    #expect(editor.buffer.lines[3] == "└┘")
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
    logoEngine.execute("TYPE FIRST [10 20] TYPE \" \" TYPE LAST \"abc\" TYPE \" \" TYPE BF [10 20 30] TYPE \" \" TYPE BL \"abc\" TYPE \" \" TYPE ITEM 2 [10 20 30]")
    #expect(ed3.buffer.lines[0] == "10 c [20 30] ab 20")

    let ed4 = Editor()
    logoEngine.delegate = ed4
    logoEngine.execute("TYPE REMDUP \"banana\" TYPE \" \" TYPE REMDUP [1 2 2 3 1]")
    #expect(ed4.buffer.lines[0] == "ban [1 2 3]")

    // 3. Mutators & Stack / Queue: PUSH, POP, QUEUE, DEQUEUE, SETITEM
    let ed5 = Editor()
    logoEngine.delegate = ed5
    logoEngine.execute("MAKE \"s\" [2 1] PUSH \"s\" 3 TYPE :s TYPE \" pop: \" TYPE POP \"s\" TYPE \" remaining: \" TYPE :s")
    #expect(ed5.buffer.lines[0] == "[3 2 1] pop: 3 remaining: [2 1]")

    let ed6 = Editor()
    logoEngine.delegate = ed6
    logoEngine.execute("MAKE \"q\" [1 2] QUEUE \"q\" 3 TYPE :q TYPE \" deq: \" TYPE DEQUEUE \"q\" TYPE \" remaining: \" TYPE :q")
    #expect(ed6.buffer.lines[0] == "[1 2 3] deq: 1 remaining: [2 3]")

    // 4. Predicates & Queries: WORD?, LIST?, NUMBER?, EMPTY?, MEMBER?, COUNT, ASCII, CHAR, UPPERCASE, LOWERCASE
    let ed7 = Editor()
    logoEngine.delegate = ed7
    logoEngine.execute("TYPE LIST? [1 2] TYPE \" \" TYPE NUMBER? 123 TYPE \" \" TYPE EMPTY? \"\" TYPE \" \" TYPE MEMBER? \"b\" [a b c]")
    #expect(ed7.buffer.lines[0] == "1 1 1 1")

    let ed8 = Editor()
    logoEngine.delegate = ed8
    logoEngine.execute("TYPE COUNT [1 2 3] TYPE \" \" TYPE ASCII \"a\" TYPE \" \" TYPE CHAR 97 TYPE \" \" TYPE UPPERCASE \"abc\" TYPE \" \" TYPE LOWERCASE \"XYZ\"")
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


