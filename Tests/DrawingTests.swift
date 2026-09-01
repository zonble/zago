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

    @Test func testDoubleAndHeavyArrowsAndDSL() {
        #expect(arrowHead(for: .right, arrowStyle: .double) == "⇒")
        #expect(arrowHead(for: .left, arrowStyle: .double) == "⇐")
        #expect(arrowHead(for: .up, arrowStyle: .double) == "⇑")
        #expect(arrowHead(for: .down, arrowStyle: .double) == "⇓")

        #expect(arrowHead(for: .right, arrowStyle: .heavy) == "⮕")
        #expect(arrowHead(for: .left, arrowStyle: .heavy) == "⬅")
        #expect(arrowHead(for: .up, arrowStyle: .heavy) == "⬆")
        #expect(arrowHead(for: .down, arrowStyle: .heavy) == "⬇")

        #expect(arrowHead(for: .right, arrowStyle: .diamond) == "◇")
        #expect(arrowHead(for: .right, arrowStyle: .solidDiamond) == "◆")
        #expect(arrowHead(for: .right, arrowStyle: .circle) == "●")
        #expect(arrowHead(for: .right, arrowStyle: .openCircle) == "○")
        #expect(arrowHead(for: .right, arrowStyle: .cross) == "✕")
        #expect(arrowHead(for: .left, arrowStyle: .crow) == "⤙")
        #expect(arrowHead(for: .right, arrowStyle: .crow) == "⤚")
        #expect(arrowHead(for: .up, arrowStyle: .crow) == "⤘")
        #expect(arrowHead(for: .down, arrowStyle: .crow) == "⤛")
        #expect(arrowHead(for: .left, arrowStyle: .harpoon) == "↼")
        #expect(arrowHead(for: .right, arrowStyle: .harpoon) == "⇀")
        #expect(arrowHead(for: .up, arrowStyle: .harpoon) == "↿")
        #expect(arrowHead(for: .down, arrowStyle: .harpoon) == "⇂")

        let doubleDsl = StyleDSL.parseLineStyle("<=|==|=>")
        #expect(doubleDsl?.border == .double)
        #expect(doubleDsl?.arrowMode == .both)
        #expect(doubleDsl?.startArrowStyle == .double)
        #expect(doubleDsl?.endArrowStyle == .double)

        let heavyDsl = StyleDSL.parseLineStyle("<+|+|+>")
        #expect(heavyDsl?.border == .heavy)
        #expect(heavyDsl?.arrowMode == .both)
        #expect(heavyDsl?.startArrowStyle == .heavy)
        #expect(heavyDsl?.endArrowStyle == .heavy)

        let diamondDsl = StyleDSL.parseLineStyle("<>->")
        #expect(diamondDsl?.border == .single)
        #expect(diamondDsl?.arrowMode == .both)
        #expect(diamondDsl?.startArrowStyle == .diamond)
        #expect(diamondDsl?.endArrowStyle == .ascii)

        let solidDiamondDsl = StyleDSL.parseLineStyle("<*>->")
        #expect(solidDiamondDsl?.border == .single)
        #expect(solidDiamondDsl?.arrowMode == .both)
        #expect(solidDiamondDsl?.startArrowStyle == .solidDiamond)
        #expect(solidDiamondDsl?.endArrowStyle == .ascii)

        let solidCircleDsl = StyleDSL.parseLineStyle("*---*")
        #expect(solidCircleDsl?.border == .tripleDash)
        #expect(solidCircleDsl?.arrowMode == .both)
        #expect(solidCircleDsl?.startArrowStyle == .circle)
        #expect(solidCircleDsl?.endArrowStyle == .circle)

        let openCircleDsl = StyleDSL.parseLineStyle("o---o")
        #expect(openCircleDsl?.border == .tripleDash)
        #expect(openCircleDsl?.arrowMode == .both)
        #expect(openCircleDsl?.startArrowStyle == .openCircle)
        #expect(openCircleDsl?.endArrowStyle == .openCircle)

        let openCircleUpperDsl = StyleDSL.parseLineStyle("O-O")
        #expect(openCircleUpperDsl?.border == .single)
        #expect(openCircleUpperDsl?.startArrowStyle == .openCircle)
        #expect(openCircleUpperDsl?.endArrowStyle == .openCircle)

        let crossDsl = StyleDSL.parseLineStyle("x---x")
        #expect(crossDsl?.border == .tripleDash)
        #expect(crossDsl?.arrowMode == .both)
        #expect(crossDsl?.startArrowStyle == .cross)
        #expect(crossDsl?.endArrowStyle == .cross)

        let crossUpperDsl = StyleDSL.parseLineStyle("X-X")
        #expect(crossUpperDsl?.border == .single)
        #expect(crossUpperDsl?.startArrowStyle == .cross)
        #expect(crossUpperDsl?.endArrowStyle == .cross)

        let harpoonDsl = StyleDSL.parseLineStyle("<^-^>")
        #expect(harpoonDsl?.border == .single)
        #expect(harpoonDsl?.arrowMode == .both)
        #expect(harpoonDsl?.startArrowStyle == .harpoon)
        #expect(harpoonDsl?.endArrowStyle == .harpoon)

        let drawer = ArrowDrawer()
        let dblBuffer = StringArrayDrawingBuffer()
        drawer.drawLine(
            buffer: dblBuffer, startLine: 0, startCol: 0, direction: .right, length: 4, hasArrow: true, style: .double,
            arrowStyle: .double)
        #expect(dblBuffer.lineString(at: 0) == "═══⇒")

        let hvyBuffer = StringArrayDrawingBuffer()
        drawer.drawLine(
            buffer: hvyBuffer, startLine: 0, startCol: 0, direction: .right, length: 4, hasArrow: true, style: .heavy,
            arrowStyle: .heavy)
        #expect(hvyBuffer.lineString(at: 0) == "━━━➡")

        let diamondBuffer = StringArrayDrawingBuffer()
        drawer.drawLine(
            buffer: diamondBuffer, startLine: 0, startCol: 0, direction: .right, length: 4, hasArrow: true, style: .single,
            arrowStyle: .diamond)
        #expect(diamondBuffer.lineString(at: 0) == "───◇")
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
