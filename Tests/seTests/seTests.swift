import Testing
@testable import se

@Test func testTextBufferBasicEditing() throws {
    let buffer = TextBuffer()
    #expect(buffer.lines == [""])
    #expect(buffer.lineIndex == 0)
    #expect(buffer.columnIndex == 0)

    buffer.insert(character: "H")
    buffer.insert(character: "e")
    buffer.insert(character: "l")
    buffer.insert(character: "l")
    buffer.insert(character: "o")
    #expect(buffer.lines == ["Hello"])
    #expect(buffer.columnIndex == 5)

    buffer.insertNewline()
    #expect(buffer.lines == ["Hello", ""])
    #expect(buffer.lineIndex == 1)
    #expect(buffer.columnIndex == 0)

    buffer.insert(character: "W")
    buffer.insert(character: "o")
    buffer.insert(character: "r")
    buffer.insert(character: "l")
    buffer.insert(character: "d")
    #expect(buffer.lines == ["Hello", "World"])

    buffer.backspace()
    #expect(buffer.lines == ["Hello", "Worl"])
}

@Test func testSoftwrapLayoutEngine() throws {
    let engine = LayoutEngine(wrapColumn: 10)
    let lines = ["1234567890ABCDEFGHIJ12345"] // 25 characters

    let virtualLines = engine.computeVirtualLines(from: lines, viewWidth: 80)
    #expect(virtualLines.count == 3)
    #expect(virtualLines[0].text == "1234567890")
    #expect(virtualLines[1].text == "ABCDEFGHIJ")
    #expect(virtualLines[2].text == "12345")

    // 檢查從真實游標 (0, 15) 能映射至虛擬行 (1, 5)
    let (vLine, vCol) = engine.getVirtualCursor(lineIndex: 0, columnIndex: 15, virtualLines: virtualLines)
    #expect(vLine == 1)
    #expect(vCol == 5)

    // 檢查從虛擬行 (1, 5) 映射回真實游標 (0, 15)
    let (bLine, bCol) = engine.getBufferCursor(vLineIndex: 1, vColIndex: 5, virtualLines: virtualLines)
    #expect(bLine == 0)
    #expect(bCol == 15)
}

@Test func testChineseDisplayWidthAndSoftwrap() throws {
    let ch: Character = "中"
    #expect(ch.displayWidth == 2)

    let str = "中文測試"
    #expect(str.displayWidth == 8)
    #expect(str.paddedToDisplayWidth(10) == "中文測試  ")

    // 測試全形字軟折行: wrapColumn = 6 (可容納 3 個中文字)
    let engine = LayoutEngine(wrapColumn: 6)
    let lines = ["一二三四五六"] // 6 個中文字，總顯示寬度 12
    let virtualLines = engine.computeVirtualLines(from: lines, viewWidth: 80)

    #expect(virtualLines.count == 2)
    #expect(virtualLines[0].text == "一二三")
    #expect(virtualLines[1].text == "四五六")
}

@Test func testJustifyParagraph() throws {
    let buffer = TextBuffer()
    buffer.lines = [
        "Swift is a powerful and intuitive",
        "programming language created by Apple",
        "for building apps.",
        "",
        "Second paragraph."
    ]
    buffer.lineIndex = 0

    // 對第一個段落進行 Justify 重排 (限制寬度 30)
    buffer.justifyParagraph(targetWidth: 30)

    #expect(buffer.lines[0] == "Swift is a powerful and")
    #expect(buffer.lines[1] == "intuitive programming language")
    #expect(buffer.lines[2] == "created by Apple for building")
    #expect(buffer.lines[3] == "apps.")
    #expect(buffer.lines[4] == "")
    #expect(buffer.lines[5] == "Second paragraph.")
}
