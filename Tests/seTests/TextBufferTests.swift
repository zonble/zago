import Testing
import Foundation
@testable import Editor

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

@Test func testVirtualLineHomeAndEndNavigation() throws {
    let engine = LayoutEngine(wrapColumn: 10)
    let lines = ["1234567890ABCDEFGHIJ12345"] // 25 characters
    let virtualLines = engine.computeVirtualLines(from: lines, viewWidth: 80)

    #expect(virtualLines.count == 3)

    // SubLine 0: "1234567890" (startCol 0, endCol 10)
    let home0 = virtualLines[0].startCol // 0
    let end0 = virtualLines[0].endCol - 1 // 9 (last char of subline 0)
    let (vLineHome0, vColHome0) = engine.getVirtualCursor(lineIndex: 0, columnIndex: home0, virtualLines: virtualLines)
    let (vLineEnd0, vColEnd0) = engine.getVirtualCursor(lineIndex: 0, columnIndex: end0, virtualLines: virtualLines)
    #expect(vLineHome0 == 0)
    #expect(vColHome0 == 0)
    #expect(vLineEnd0 == 0)
    #expect(vColEnd0 == 9)

    // SubLine 1: "ABCDEFGHIJ" (startCol 10, endCol 20)
    let home1 = virtualLines[1].startCol // 10
    let end1 = virtualLines[1].endCol - 1 // 19 (last char of subline 1)
    let (vLineHome1, vColHome1) = engine.getVirtualCursor(lineIndex: 0, columnIndex: home1, virtualLines: virtualLines)
    let (vLineEnd1, vColEnd1) = engine.getVirtualCursor(lineIndex: 0, columnIndex: end1, virtualLines: virtualLines)
    #expect(vLineHome1 == 1)
    #expect(vColHome1 == 0)
    #expect(vLineEnd1 == 1)
    #expect(vColEnd1 == 9)

    // SubLine 2: "12345" (startCol 20, endCol 25, last subline of buffer line)
    let home2 = virtualLines[2].startCol // 20
    let end2 = virtualLines[2].endCol     // 25
    let (vLineHome2, vColHome2) = engine.getVirtualCursor(lineIndex: 0, columnIndex: home2, virtualLines: virtualLines)
    let (vLineEnd2, vColEnd2) = engine.getVirtualCursor(lineIndex: 0, columnIndex: end2, virtualLines: virtualLines)
    #expect(vLineHome2 == 2)
    #expect(vColHome2 == 0)
    #expect(vLineEnd2 == 2)
    #expect(vColEnd2 == 5)
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

@Test func testTextBufferFileOperations() throws {
    let tempDir = FileManager.default.temporaryDirectory
    let tempFile = tempDir.appendingPathComponent("test_se_\(UUID().uuidString).txt").path

    let buffer = TextBuffer()
    buffer.lines = ["Line 1", "Line 2", "Line 3"]
    try buffer.saveFile(to: tempFile)
    #expect(FileManager.default.fileExists(atPath: tempFile))

    let newBuffer = TextBuffer()
    let count = try newBuffer.insertFile(at: tempFile)
    #expect(count == 3)
    #expect(newBuffer.lines[0] == "Line 1")
    #expect(newBuffer.lines[1] == "Line 2")
    #expect(newBuffer.lines[2] == "Line 3")

    try? FileManager.default.removeItem(atPath: tempFile)
}

@Test func testTextBufferDeleteAndClamp() throws {
    let buffer = TextBuffer()
    buffer.lines = ["ABC"]
    buffer.lineIndex = 0
    buffer.columnIndex = 1

    buffer.delete() // Deletes 'B'
    #expect(buffer.lines[0] == "AC")

    buffer.columnIndex = 100
    buffer.clampCursor()
    #expect(buffer.columnIndex == 2)
}
