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

    // Verify real cursor (0, 15) maps to virtual cursor (1, 5)
    let (vLine, vCol) = engine.getVirtualCursor(lineIndex: 0, columnIndex: 15, virtualLines: virtualLines)
    #expect(vLine == 1)
    #expect(vCol == 5)

    // Verify virtual cursor (1, 5) maps back to real cursor (0, 15)
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

    // Test CJK softwrap: wrapColumn = 6 (accommodates 3 CJK characters per line)
    let engine = LayoutEngine(wrapColumn: 6)
    let lines = ["一二三四五六"] // 6 CJK characters, total display width 12
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

    // Justify the first paragraph with target width 30
    buffer.justifyParagraph(targetWidth: 30)

    #expect(buffer.lines[0] == "Swift is a powerful and")
    #expect(buffer.lines[1] == "intuitive programming language")
    #expect(buffer.lines[2] == "created by Apple for building")
    #expect(buffer.lines[3] == "apps.")
    #expect(buffer.lines[4] == "")
    #expect(buffer.lines[5] == "Second paragraph.")
}

@Test func testChineseAndMixedJustifyParagraph() throws {
    let buffer = TextBuffer()
    buffer.lines = [
        "這是一段很長的中文字段落，用來測試視覺對齊演算法",
        "是否能在指定寬度內正確折行。"
    ]
    buffer.lineIndex = 0

    // Justify Chinese paragraph with target width 12 (6 CJK characters per line)
    buffer.justifyParagraph(targetWidth: 12)

    #expect(buffer.lines[0] == "這是一段很長")
    #expect(buffer.lines[1] == "的中文字段落")
    #expect(buffer.lines[2] == "，用來測試視")
    #expect(buffer.lines[3] == "覺對齊演算法")
    #expect(buffer.lines[4] == "是否能在指定")
    #expect(buffer.lines[5] == "寬度內正確折")
    #expect(buffer.lines[6] == "行。")
}

@Test func testCutRangeAndInsertString() throws {
    let buffer = TextBuffer()
    buffer.lines = ["Hello World!", "Second Line"]

    // Cut "World" (line 0, col 6 to line 0, col 11)
    let cut = buffer.cutRange(start: (0, 6), end: (0, 11))
    #expect(cut == "World")
    #expect(buffer.lines[0] == "Hello !")

    // Insert "Swift " at (0, 6)
    buffer.lineIndex = 0
    buffer.columnIndex = 6
    buffer.insertString("Swift ")
    #expect(buffer.lines[0] == "Hello Swift !")
}
