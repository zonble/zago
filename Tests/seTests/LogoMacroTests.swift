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

    // 17. Smart Line Junction Fusion (BOX + VLINE cross fusion)
    let fuseEditor = Editor()
    logoEngine.execute("BOX 6 3 GOTO 1 3 VLINE 3", on: fuseEditor)
    #expect(fuseEditor.buffer.lines[0] == "┌─┬──┐")
    #expect(fuseEditor.buffer.lines[1] == "│ │  │")
    #expect(fuseEditor.buffer.lines[2] == "└─┴──┘")
}
