import Foundation
import Testing

@testable import Drawing

@Suite struct DrawingTests {

    @Test func testBorderStyleParsingAndCharacters() {
        let single = BorderStyle.from("single")
        #expect(single == .single)
        #expect(single.tableCharacters.topLeft == "┌")

        let heavy = BorderStyle.from("heavy")
        #expect(heavy == .heavy)
        #expect(heavy.tableCharacters.topLeft == "┏")
        #expect(heavy.tableCharacters.horizontal == "━")
        #expect(heavy.tableCharacters.vertical == "┃")

        let double = BorderStyle.from("double")
        #expect(double == .double)
        #expect(double.tableCharacters.topLeft == "╔")

        #expect(single.tableCharacters(rounded: true).topLeft == "╭")

        let ascii = BorderStyle.from("ascii")
        #expect(ascii == .ascii)
        #expect(ascii.tableCharacters.topLeft == "+")

        let dashedStyles: [(String, Character, Character)] = [
            ("triple-dash", "┄", "┆"),
            ("heavy-triple-dash", "┅", "┇"),
            ("quadruple-dash", "┈", "┊"),
            ("heavy-quadruple-dash", "┉", "┋"),
            ("double-dash", "╌", "╎"),
            ("heavy-double-dash", "╍", "╏"),
        ]
        for (name, horizontal, vertical) in dashedStyles {
            let style = BorderStyle.from(name)
            #expect(style.rawValue == name)
            #expect(style.horizontalLineCharacter == horizontal)
            #expect(style.verticalLineCharacter == vertical)
        }
    }

    @Test func testStringArrayDrawingBufferReadWrite() {
        let buffer = StringArrayDrawingBuffer(lines: ["Hello World"])
        #expect(buffer.lineCount == 1)

        #expect(buffer.getCharacter(line: 0, visualColumn: 0) == "H")
        #expect(buffer.getCharacter(line: 0, visualColumn: 6) == "W")

        buffer.setCharacter(line: 0, visualColumn: 0, character: "h")
        #expect(buffer.lineString(at: 0) == "hello World")

        // CJK multi-byte character alignment test
        buffer.setCharacter(line: 1, visualColumn: 0, character: "中")
        buffer.setCharacter(line: 1, visualColumn: 2, character: "文")
        #expect(buffer.lineString(at: 1) == "中文")
        #expect(buffer.getCharacter(line: 1, visualColumn: 0) == "中")
        #expect(buffer.getCharacter(line: 1, visualColumn: 2) == "文")
    }

    @Test func testBoxDrawerSingleAndAscii() {
        let buffer = StringArrayDrawingBuffer()
        let drawer = BoxDrawer()

        drawer.drawBox(buffer: buffer, startLine: 0, startCol: 0, width: 5, height: 3, style: .single)

        #expect(buffer.lineCount == 3)
        #expect(buffer.lineString(at: 0) == "┌───┐")
        #expect(buffer.lineString(at: 1) == "│   │")
        #expect(buffer.lineString(at: 2) == "└───┘")

        let asciiBuffer = StringArrayDrawingBuffer()
        drawer.drawBox(buffer: asciiBuffer, startLine: 0, startCol: 0, width: 4, height: 3, style: .ascii)
        #expect(asciiBuffer.lineString(at: 0) == "+--+")
        #expect(asciiBuffer.lineString(at: 1) == "|  |")
        #expect(asciiBuffer.lineString(at: 2) == "+--+")
    }

    @Test func testArrowDrawerRightAndDown() {
        let buffer = StringArrayDrawingBuffer()
        let drawer = ArrowDrawer()

        // Solid Unicode Arrow (Default)
        drawer.drawLine(
            buffer: buffer, startLine: 0, startCol: 0, direction: .right, length: 4, hasArrow: true, arrowStyle: .solid)
        #expect(buffer.lineString(at: 0) == "───▶")

        // Hollow Unicode Arrow
        let hollowBuffer = StringArrayDrawingBuffer()
        drawer.drawLine(
            buffer: hollowBuffer, startLine: 0, startCol: 0, direction: .right, length: 4, hasArrow: true,
            arrowStyle: .hollow)
        #expect(hollowBuffer.lineString(at: 0) == "───▷")

        // Stemmed Unicode Arrow
        let stemmedBuffer = StringArrayDrawingBuffer()
        drawer.drawLine(
            buffer: stemmedBuffer, startLine: 0, startCol: 0, direction: .down, length: 3, hasArrow: true,
            arrowStyle: .stemmed)
        #expect(stemmedBuffer.lineString(at: 0) == "│")
        #expect(stemmedBuffer.lineString(at: 1) == "│")
        #expect(stemmedBuffer.lineString(at: 2) == "↓")

        // ASCII line can use solid Unicode arrow or default ASCII arrow
        let asciiBuffer = StringArrayDrawingBuffer()
        drawer.drawLine(
            buffer: asciiBuffer, startLine: 0, startCol: 0, direction: .right, length: 4, hasArrow: true, style: .ascii,
            arrowStyle: .ascii)
        #expect(asciiBuffer.lineString(at: 0) == "--->")

        let asciiSolidBuffer = StringArrayDrawingBuffer()
        drawer.drawLine(
            buffer: asciiSolidBuffer, startLine: 0, startCol: 0, direction: .right, length: 4, hasArrow: true, style: .ascii,
            arrowStyle: .solid)
        #expect(asciiSolidBuffer.lineString(at: 0) == "---▶")
    }

    @Test func testDashedLineCharacters() {
        let buffer = StringArrayDrawingBuffer()
        let drawer = ArrowDrawer()
        drawer.drawLine(buffer: buffer, startLine: 0, startCol: 0, direction: .right, length: 3, style: .tripleDash)
        #expect(buffer.lineString(at: 0) == "┄┄┄")

        drawer.drawLine(buffer: buffer, startLine: 1, startCol: 0, direction: .down, length: 3, style: .heavyDoubleDash)
        #expect(buffer.getCharacter(line: 1, visualColumn: 0) == "╏")
        #expect(buffer.getCharacter(line: 2, visualColumn: 0) == "╏")
        #expect(buffer.getCharacter(line: 3, visualColumn: 0) == "╏")
    }

    @Test func testTableCellDetectorInDrawingTarget() {
        let lines = [
            "┌───┬───┐",
            "│ A │ B │",
            "├───┼───┤",
            "│ C │ D │",
            "└───┴───┘",
        ]
        let detector = TableCellDetector()
        let cellA = detector.detectCell(in: lines, line: 1, col: 2)

        #expect(cellA != nil)
        #expect(cellA?.minLine == 0)
        #expect(cellA?.maxLine == 2)
        #expect(cellA?.minCol == 0)
        #expect(cellA?.maxCol == 4)
    }
}
