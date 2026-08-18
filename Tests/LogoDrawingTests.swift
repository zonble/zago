import Foundation
import Testing
import TextMetrics

@testable import Editor
@testable import LogoEngine

@Test func testTurtleSquareBoxDrawing() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("PD REPEAT 4 [ FD 4 RT ]")
    #expect(editor.buffer.lines.count >= 4)
    #expect(editor.buffer.lines[0] == "┌──┐")
    #expect(editor.buffer.lines[1] == "│  │")
    #expect(editor.buffer.lines[2] == "│  │")
    #expect(editor.buffer.lines[3] == "└──┘")
}

@Test func testTurtleLeftTurnAndBackward() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("LT BK 3")
    #expect(editor.buffer.lines.count == 3)
    #expect(editor.buffer.lines[0] == "│")
    #expect(editor.buffer.lines[1] == "│")
    #expect(editor.buffer.lines[2] == "│")
}

@Test func testDoubleLineSmartJunctionFusion() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("BOX 6 3 \"double\" GOTO 1 3 VLINE 3 \"double\"")
    #expect(editor.buffer.lines[0] == "╔═╦══╗")
    #expect(editor.buffer.lines[1] == "║ ║  ║")
    #expect(editor.buffer.lines[2] == "╚═╩══╝")
}

@Test func testHeavyBoxAndLineSmartJunctionFusion() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("BOX 6 3 \"heavy\" GOTO 1 3 VLINE 3 \"heavy\"")
    #expect(editor.buffer.lines[0] == "┏━┳━━┓")
    #expect(editor.buffer.lines[1] == "┃ ┃  ┃")
    #expect(editor.buffer.lines[2] == "┗━┻━━┛")
}

@Test func testTurtleVariableLoopCombo() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("MAKE \"dist\" 3 PD REPEAT 2 [ FD :dist RT ]")
    #expect(editor.buffer.lines[0] == "──┐")
    #expect(editor.buffer.lines[1] == "  │")
    #expect(editor.buffer.lines[2] == "  │")
}

@Test func testTurtleSpiralDrawing() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("MAKE \"d\" 2 PD REPEAT 4 [ FD :d RT MAKE \"d\" ( :d + 2 ) ]")
    #expect(editor.buffer.lines.count >= 4)
    #expect(editor.buffer.lines[0] == "┌┐")
    #expect(editor.buffer.lines[1] == "││")
    #expect(editor.buffer.lines[2] == "││")
    #expect(editor.buffer.lines[3] == "└┘")
}

@Test func testTurtleForwardAcceptsParenthesizedDistanceExpression() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("SETH RIGHT PD FD (10 - 1)")
    #expect(editor.buffer.lines[0] == "─────────")
}

@Test func testBoxAcceptsExpressionDimensions() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("BOX (3 + 4) (2 + 2)")
    #expect(
        editor.buffer.lines == [
            "┌─────┐",
            "│     │",
            "│     │",
            "└─────┘",
        ])
}

@Test func testTurtleRepeatAcceptsExpressionDistanceAndBareHeading() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("SETH RIGHT REPEAT 10 [ FD (10 - :#) RIGHT ]")

    let drawing = editor.buffer.lines.joined(separator: "\n")
    #expect(editor.buffer.lines.count > 1)
    #expect(editor.buffer.lines[0].displayWidth > 1)
    #expect(drawing.contains("┌"))
    #expect(drawing.contains("┘"))
}

@Test func testLogoGotoAllowsVirtualColumnsForDrawing() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("NL REPEAT 10 [ GOTO 3 (:# * 5) VLINE 10 ]")

    let expectedLine = String((1...50).map { $0 % 5 == 0 ? "│" : " " }.joined())
    #expect(editor.buffer.lines.count >= 11)
    #expect(editor.buffer.lines[2] == expectedLine)
    #expect(editor.buffer.lines[9] == expectedLine)
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

@Test func testTurtleStopsAtTopAndLeftBoundaries() throws {
    let topBoundaryEditor = Editor()
    let logoEngine = LogoEngine(delegate: topBoundaryEditor)

    logoEngine.execute("SETH \"UP PD FD 5")
    #expect(topBoundaryEditor.buffer.lines == [""])

    let leftBoundaryEditor = Editor()
    logoEngine.delegate = leftBoundaryEditor
    logoEngine.execute("SETH \"LEFT PD FD 5")
    #expect(leftBoundaryEditor.buffer.lines == [""])
}

@Test func testTurtleDrawsToMinimumBoundaryThenStops() throws {
    let upToBoundaryEditor = Editor()
    let logoEngine = LogoEngine(delegate: upToBoundaryEditor)

    logoEngine.execute("SETH \"DOWN PU FD 3 SETH \"UP PD FD 5")
    #expect(upToBoundaryEditor.buffer.lines == ["│", "│", "│"])

    let leftToBoundaryEditor = Editor()
    leftToBoundaryEditor.buffer.columnIndex = 2
    logoEngine.delegate = leftToBoundaryEditor
    logoEngine.execute("SETH \"LEFT PD FD 5")
    #expect(leftToBoundaryEditor.buffer.lines == ["───"])
}

@Test func testTurtleDirectTableDrawing() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("PD REPEAT 4 [ FD 5 RT ] PU GOTO 1 3 PD RT FD 5 PU GOTO 3 1 PD LT FD 5")
    #expect(editor.buffer.lines.count >= 5)
    #expect(editor.buffer.lines[0] == "┌─┬─┐")
    #expect(editor.buffer.lines[1] == "│ │ │")
    #expect(editor.buffer.lines[2] == "├─┼─┤")
    #expect(editor.buffer.lines[3] == "│ │ │")
    #expect(editor.buffer.lines[4] == "└─┴─┘")
}

@Test func testSetHeadingAndHeadingPrimitives() throws {
    #expect(LogoEngine.isStatementCommand("SETH"))

    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("SETH RIGHT HEADING")
    #expect(logoEngine.lastResult == "RIGHT")

    logoEngine.execute("SETHEADING DOWN HEADING")
    #expect(logoEngine.lastResult == "DOWN")

    logoEngine.execute("SETH LEFT HEADING")
    #expect(logoEngine.lastResult == "LEFT")

    logoEngine.execute("SETH UP HEADING")
    #expect(logoEngine.lastResult == "UP")
}

@Test func testSetHeadingRejectsNumericAngles() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("SETH RIGHT SETH 180 HEADING")
    #expect(logoEngine.lastResult == "RIGHT")
}

@Test func testTurnRightAndLeftTakeNoArguments() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("SETH UP RT HEADING")
    #expect(logoEngine.lastResult == "RIGHT")

    logoEngine.execute("LT HEADING")
    #expect(logoEngine.lastResult == "UP")
}

@Test func testCanvasModeLogoShapesStartAtVisualCursorColumn() throws {
    let editor = Editor()
    editor.switchToCanvasMode()
    editor.buffer.lines = ["\tHello"]
    editor.canvasVisualColumn = 10

    let logoEngine = editor.logoEngine
    logoEngine.execute("BOX 6 3 \"ascii\"")

    #expect(editor.buffer.lines[0].hasPrefix("\tHello"))
    #expect(editor.buffer.lines[0].contains("+----+"))
}

@Test func testBoxWithoutArgumentsUsesCanvasBlockFrameInCanvasMode() throws {
    let editor = Editor()
    editor.switchToCanvasMode()
    editor.buffer.lines = ["", "", "", ""]
    editor.buffer.canvasBlockMark = (line: 1, visualColumn: 2)
    editor.buffer.canvasBlockMarkEnd = (line: 3, visualColumn: 8)

    editor.logoEngine.execute("BOX")

    #expect(editor.buffer.lines[1] == "  ┌─────┐")
    #expect(editor.buffer.lines[2] == "  │     │")
    #expect(editor.buffer.lines[3] == "  └─────┘")
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 9)
}

@Test func testDrawBoxWithoutArgumentsUsesCanvasBlockFrameAsOverlay() throws {
    let editor = Editor()
    editor.switchToCanvasMode()
    editor.buffer.lines = ["abcdefghij", "0123456789"]
    editor.buffer.canvasBlockMark = (line: 0, visualColumn: 2)
    editor.buffer.canvasBlockMarkEnd = (line: 1, visualColumn: 6)

    editor.logoEngine.execute("DRAWBOX")

    #expect(editor.buffer.lines[0] == "ab┌───┐hij")
    #expect(editor.buffer.lines[1] == "01└───┘789")
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 7)
}

@Test func testLogoEngineLineAndVLineVariants() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("LINE 5 \"double\" \"arrow\"")
    #expect(editor.buffer.lines[0].contains("═"))

    let expressionLineEditor = Editor()
    let expressionLineEngine = LogoEngine(delegate: expressionLineEditor)
    expressionLineEngine.execute("LINE (2 + 3) DOUBLE")
    #expect(expressionLineEditor.buffer.lines[0] == "═════")

    let editor2 = Editor()
    let logoEngine2 = LogoEngine(delegate: editor2)
    logoEngine2.execute("VLINE 3 \"double\"")
    #expect(editor2.buffer.lines.count >= 3)
    #expect(editor2.buffer.lines[0].contains("║"))
}

@Test func testLogoLineWithCJKTextDoesNotOverwriteCJKCharacters() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    editor.buffer.lines = [
        "┌──────────┐        ┌──────────┐",
        "│ 你好谷歌 │        │ 你好嗎？ │",
        "└──────────┘        └──────────┘",
    ]
    editor.buffer.lineIndex = 1
    // Character index 7 is right after "你好谷歌 " inside the box:
    editor.buffer.columnIndex = 7

    logoEngine.execute("LINE")

    let line1 = editor.buffer.lines[1]
    #expect(line1.hasPrefix("│ 你好谷歌 "))
    #expect(line1.contains("├────────┤"))
    #expect(line1.contains("你好嗎？"))
}

@Test func testLogoVlineBetweenStackedBoxesDoesNotOverwriteUpperBoxText() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    editor.buffer.lines = [
        "┌──────┐",
        "│ 你好 │",
        "└──────┘",
        "",
        "",
        "┌──────┐",
        "│ 你好 │",
        "└──────┘",
    ]
    editor.buffer.lineIndex = 2
    editor.buffer.columnIndex = 3

    logoEngine.execute("VLINE")

    #expect(editor.buffer.lines[1] == "│ 你好 │")
    #expect(editor.buffer.lines[2].contains("┬"))
    #expect(editor.buffer.lines[3].contains("│"))
    #expect(editor.buffer.lines[5].contains("┴"))
}

@Test func testVlineOnLineBetweenDoubleBoxesConnectsCleanly() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    editor.buffer.lines = [
        "╔══════╗",
        "║ 你好 ║",
        "╚══════╝",
        "   x",
        "",
        "",
        "",
        "",
        "╔══════╗",
        "║ 你好 ║",
        "╚══════╝",
    ]
    editor.buffer.lineIndex = 3
    editor.buffer.columnIndex = 3

    logoEngine.execute("VLINE \"double\"")

    #expect(editor.buffer.lines[2].contains("╦"))
    #expect(editor.buffer.lines[3] == "   ║")
    #expect(editor.buffer.lines[4] == "   ║")
    #expect(editor.buffer.lines[8].contains("╩"))
}

@Test func testAutoVlineBetweenSingleStyleBoxes() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    editor.buffer.lines = [
        "┌──────┐",
        "│ 你好 │",
        "└──────┘",
        "   x",
        "",
        "",
        "┌──────┐",
        "│ 你好 │",
        "└──────┘",
    ]
    editor.buffer.lineIndex = 3
    editor.buffer.columnIndex = 3

    logoEngine.execute("VLINE")

    #expect(editor.buffer.lines[2].contains("┬"))
    #expect(editor.buffer.lines[3] == "   │")
    #expect(editor.buffer.lines[4] == "   │")
    #expect(editor.buffer.lines[6].contains("┴"))
}

@Test func testAutoLineBetweenLeftAndRightSingleBoxes() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    editor.buffer.lines = [
        "┌───┐       ┌───┐",
        "│ A │       │ B │",
        "└───┘       └───┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 5

    logoEngine.execute("LINE")

    #expect(editor.buffer.lines[1] == "│ A ├───────┤ B │")
}

@Test func testAutoLineBetweenLeftAndRightDoubleBoxes() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    editor.buffer.lines = [
        "╔═══╗       ╔═══╗",
        "║ A ║       ║ B ║",
        "╚═══╝       ╚═══╝",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 5

    logoEngine.execute("LINE \"double\"")

    #expect(editor.buffer.lines[1] == "║ A ╠═══════╣ B ║")
}

@Test func testAutoLineWithArrowBetweenBoxes() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    editor.buffer.lines = [
        "┌───┐       ┌───┐",
        "│ A │       │ B │",
        "└───┘       └───┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 5

    logoEngine.execute("LINE ARROW")

    #expect(editor.buffer.lines[1] == "│ A ├──────▶│ B │")
}

@Test func testAutoLineBothArrowBetweenBoxes() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    editor.buffer.lines = [
        "┌────┐              ┌───────┐",
        "│ hi │              │ there │",
        "└────┘              └───────┘",
    ]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 6

    logoEngine.execute("LINE BOTHARROW")

    #expect(editor.buffer.lines[1] == "│ hi │◀────────────▶│ there │")
}

@Test func testAutoVlineBothArrowBetweenStackedBoxes() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    editor.buffer.lines = [
        "┌────┐",
        "│ hi │",
        "└────┘",
        "  x",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "┌───────┐",
        "│ there │",
        "└───────┘",
    ]
    editor.buffer.lineIndex = 3
    editor.buffer.columnIndex = 2

    logoEngine.execute("VLINE BOTHARROW")

    #expect(editor.buffer.lines[2] == "└────┘")
    #expect(editor.buffer.lines[3] == "  ▲")
    #expect(editor.buffer.lines[10] == "  ▼")
    #expect(editor.buffer.lines[11] == "┌───────┐")
}

@Test func testPadLeftWithNumericStringAndCustomChar() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute(
        """
        MAKE "price1 "15"
        MAKE "p1 PADLEFT :price1 5 "0"
        TYPE :p1
        """)

    #expect(editor.buffer.lines[0] == "00015")
}

@Test func testBoxQuotedNumericStringTreatedAsText() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    // 1. Quoted numeric string: BOX "10" -> draws box around text "10"
    logoEngine.execute("BOX \"10\"")
    #expect(editor.buffer.lines[0] == "┌────┐")
    #expect(editor.buffer.lines[1] == "│ 10 │")
    #expect(editor.buffer.lines[2] == "└────┘")

    // 2. Expression: BOX WORD "10" -> draws box around text "10"
    editor.buffer.lines = [""]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 0
    logoEngine.execute("BOX WORD \"10\"")
    #expect(editor.buffer.lines[0] == "┌────┐")
    #expect(editor.buffer.lines[1] == "│ 10 │")
    #expect(editor.buffer.lines[2] == "└────┘")

    // 3. Raw unquoted number: BOX 10 3 -> draws 10-wide empty frame
    editor.buffer.lines = [""]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 0
    logoEngine.execute("BOX 10 3")
    #expect(editor.buffer.lines[0] == "┌────────┐")
    #expect(editor.buffer.lines[1] == "│        │")
    #expect(editor.buffer.lines[2] == "└────────┘")
}

@Test func testUnknownCommandReporting() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("MAAK \"x 10")
    #expect(logoEngine.hasUncaughtError)
    #expect(logoEngine.lastError?.message == "[LOGO Error: I don't know how to MAAK]")
}

@Test func testAllExampleLogoScriptsExecuteWithoutErrors() throws {
    let fm = FileManager.default
    let examplesUrl = URL(fileURLWithPath: fm.currentDirectoryPath).appendingPathComponent("examples")
        .appendingPathComponent("logo")
    let files = try fm.contentsOfDirectory(at: examplesUrl, includingPropertiesForKeys: nil)
        .filter { $0.pathExtension == "logo" }

    #expect(!files.isEmpty)

    for file in files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
        if file.lastPathComponent == "error_handling_demo.logo" || file.lastPathComponent == "game.logo" { continue }

        let script = try String(contentsOf: file, encoding: .utf8)
        let editor = Editor()
        editor.logoEngine.execute(script)

        #expect(
            !editor.logoEngine.hasUncaughtError,
            "Example script failed: \(file.lastPathComponent) with error: \(editor.logoEngine.lastError?.message ?? "")"
        )
    }
}

@Test func testLogoEngineControlCommands() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("MAKE \"i 1 WHILE [:i <= 3] [ TYPE :i MAKE \"i :i + 1 ]")
    #expect(editor.buffer.lines[0] == "123")

    let editor2 = Editor()
    let logoEngine2 = LogoEngine(delegate: editor2)
    logoEngine2.execute("FOR [j 1 3 1] [ TYPE :j ]")
    #expect(editor2.buffer.lines[0] == "123")

    let editor3 = Editor()
    let logoEngine3 = LogoEngine(delegate: editor3)
    logoEngine3.execute("TO FOO LOCAL \"x MAKE \"x 42 TYPE :x END FOO")
    #expect(editor3.buffer.lines[0] == "42")

    let editor4 = Editor()
    let logoEngine4 = LogoEngine(delegate: editor4)
    logoEngine4.execute("CATCH \"err [ THROW \"err ]")
    #expect(logoEngine4.lastError != nil || logoEngine4.currentThrowTag == nil)
}

@Test func testBoxWithCJKAndAsciiStyle() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("BOX \"奇怪\" ascii")
    #expect(editor.buffer.lines[0] == "+------+")
    #expect(editor.buffer.lines[1] == "| 奇怪 |")
    #expect(editor.buffer.lines[2] == "+------+")
}

@Test func testLineAndVlineEvaluateTemplateAndVariableArguments() throws {
    let editor1 = Editor()
    let logoEngine1 = LogoEngine(delegate: editor1)
    logoEngine1.execute("MAKE \"len\" 10 MAKE \"st\" \"double\" LINE :len :st")
    #expect(editor1.buffer.lines[0] == "══════════")

    let editor2 = Editor()
    let logoEngine2 = LogoEngine(delegate: editor2)
    logoEngine2.execute("FOREACH [10 5] [ LINE ? NL ]")
    #expect(editor2.buffer.lines[0] == "──────────")
    #expect(editor2.buffer.lines[1] == "─────")

    let editor3 = Editor()
    let logoEngine3 = LogoEngine(delegate: editor3)
    logoEngine3.execute("FOREACH [\"double \"ascii] [ LINE 5 ? NL ]")
    #expect(editor3.buffer.lines[0] == "═════")
    #expect(editor3.buffer.lines[1] == "-----")

    let editor4 = Editor()
    let logoEngine4 = LogoEngine(delegate: editor4)
    logoEngine4.execute("FOREACH [\"single \"double \"ascii] [[x] LINE 4 :x NL]")
    #expect(editor4.buffer.lines[0] == "────")
    #expect(editor4.buffer.lines[1] == "════")
    #expect(editor4.buffer.lines[2] == "----")

    let editor5 = Editor()
    let logoEngine5 = LogoEngine(delegate: editor5)
    logoEngine5.execute("FOREACH [\"single \"double \"ascii] [[x] LINE 4 x NL]")
    #expect(editor5.buffer.lines[0] == "────")
    #expect(editor5.buffer.lines[1] == "════")
    #expect(editor5.buffer.lines[2] == "----")

    let editor6 = Editor()
    let logoEngine6 = LogoEngine(delegate: editor6)
    logoEngine6.execute("FOREACH [\"solid\" \"stemmed\" \"hollow\" \"small\"] [ LINE 4 DOUBLE ARROW ? NL ]")
    #expect(editor6.buffer.lines[0] == "═══▶")
    #expect(editor6.buffer.lines[1] == "═══→")
    #expect(editor6.buffer.lines[2] == "═══▷")
    #expect(editor6.buffer.lines[3] == "═══▸")
}

@Test func testBoxEvaluateTemplateAndVariableArguments() throws {
    let editor1 = Editor()
    let logoEngine1 = LogoEngine(delegate: editor1)
    logoEngine1.execute("MAKE \"st\" \"round\" BOX 6 3 \"Hi\" :st")
    #expect(editor1.buffer.lines[0] == "╭────╮")
    #expect(editor1.buffer.lines[1] == "│ Hi │")
    #expect(editor1.buffer.lines[2] == "╰────╯")

    let editor2 = Editor()
    let logoEngine2 = LogoEngine(delegate: editor2)
    logoEngine2.execute("FOREACH [\"double \"round] [ GOTO ( ( # - 1 ) * 4 + 1 ) 1 BOX 6 3 \"A\" ? ]")
    #expect(editor2.buffer.lines[0] == "╔════╗")
    #expect(editor2.buffer.lines[4] == "╰────╯")
}

@Test func testTableAndFillEvaluateTemplateAndVariableArguments() throws {
    let editor1 = Editor()
    let logoEngine1 = LogoEngine(delegate: editor1)
    logoEngine1.execute("MAKE \"st\" \"double\" TABLE BORDER :st TABLE 3 3")
    #expect(editor1.buffer.lines[0].contains("╔"))

    let editor2 = Editor()
    let logoEngine2 = LogoEngine(delegate: editor2)
    logoEngine2.execute("FOREACH [\"#\" \"*\"] [ GOTO ( ( # - 1 ) * 2 + 1 ) 1 FILL 4 2 ? ]")
    #expect(editor2.buffer.lines[0] == "####")
    #expect(editor2.buffer.lines[2] == "****")
}

@Test func testInsetCommandInBoxAndCanvasAreas() throws {
    let editor1 = Editor()
    let logoEngine1 = LogoEngine(delegate: editor1)
    logoEngine1.execute("BOX 10 5 GOTO 2 2 INSET \"Hello\"")
    #expect(editor1.buffer.lines[0] == "┌────────┐")
    #expect(editor1.buffer.lines[1] == "│        │")
    #expect(editor1.buffer.lines[2] == "│ Hello  │")
    #expect(editor1.buffer.lines[3] == "│        │")
    #expect(editor1.buffer.lines[4] == "└────────┘")

    let editor2 = Editor()
    let logoEngine2 = LogoEngine(delegate: editor2)
    logoEngine2.execute("INSET 10 3 \"Center\"")
    #expect(editor2.buffer.lines[1] == "  Center  ")

    let editor3 = Editor()
    let logoEngine3 = LogoEngine(delegate: editor3)
    logoEngine3.execute("INSET 10 \"Hi\"")
    #expect(editor3.buffer.lines[0] == "    Hi    ")
}

@Test func testFactorialProcedureWithReduceAndForeach() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)
    let script = """
        to factorial :x
            ifelse :x < 1 [ output 1 ] [ output reduce [?1 * ?2] (iseq 1 :x) ]
        end

        foreach (iseq 1 5) [ type (factorial ?) type " " ]
        """
    logoEngine.execute(script)
    #expect(editor.buffer.lines[0] == "1 2 6 24 120 ")

    let editor2 = Editor()
    let logoEngine2 = LogoEngine(delegate: editor2)
    let script2 = """
        to double_val :x
            return :x * 2
        end

        type (double_val 21)
        """
    logoEngine2.execute(script2)
    #expect(editor2.buffer.lines[0] == "42")
}
