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
    #expect(editor.buffer.lines == [
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
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("SETH RIGHT HEADING")
    #expect(logoEngine.lastResult == "90")

    logoEngine.execute("SETHEADING DOWN HEADING")
    #expect(logoEngine.lastResult == "180")

    logoEngine.execute("SETH LEFT HEADING")
    #expect(logoEngine.lastResult == "270")

    logoEngine.execute("SETH UP HEADING")
    #expect(logoEngine.lastResult == "0")
}

@Test func testSetHeadingRejectsNumericAngles() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("SETH RIGHT SETH 180 HEADING")
    #expect(logoEngine.lastResult == "90")
}

@Test func testTurnRightAndLeftTakeNoArguments() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("SETH UP RT HEADING")
    #expect(logoEngine.lastResult == "90")

    logoEngine.execute("LT HEADING")
    #expect(logoEngine.lastResult == "0")
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
        "└──────────┘        └──────────┘"
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
        "└──────┘"
    ]
    editor.buffer.lineIndex = 2
    editor.buffer.columnIndex = 3

    logoEngine.execute("VLINE")

    #expect(editor.buffer.lines[1] == "│ 你好 │")
    #expect(editor.buffer.lines[2].contains("┬"))
    #expect(editor.buffer.lines[3].contains("│"))
    #expect(editor.buffer.lines[5].contains("┴"))
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
