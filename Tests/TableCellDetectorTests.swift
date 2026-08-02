import Foundation
import Testing

@testable import Editor

@Test func testTableCellDetectorSingleUnicode() throws {
    let detector = TableCellDetector()
    let lines = [
        "┌────────────────┬────────────────┐",
        "│ Cell 1         │ Cell 2         │",
        "├────────────────┼────────────────┤",
        "│ Cell 3         │ Cell 4         │",
        "└────────────────┴────────────────┘",
    ]

    let cell1 = detector.detectCell(in: lines, line: 1, col: 5)
    #expect(cell1 != nil)
    #expect(cell1?.minLine == 0)
    #expect(cell1?.maxLine == 2)
    #expect(cell1?.minCol == 0)
    #expect(cell1?.maxCol == 17)
    #expect(cell1?.style == .single)

    let cell4 = detector.detectCell(in: lines, line: 3, col: 20)
    #expect(cell4 != nil)
    #expect(cell4?.minLine == 2)
    #expect(cell4?.maxLine == 4)
    #expect(cell4?.minCol == 17)
    #expect(cell4?.maxCol == 34)
}

@Test func testTableCellDetectorTreatsJunctionAsVerticalBoundary() throws {
    let detector = TableCellDetector()
    let lines = [
        "┌────────────────┬─",
        "│ Cell           ├─",
        "└────────────────┴─",
    ]

    let cell = detector.detectCell(in: lines, line: 1, col: 5)
    #expect(cell != nil)
    #expect(cell?.minLine == 0)
    #expect(cell?.maxLine == 2)
    #expect(cell?.minCol == 0)
    #expect(cell?.maxCol == 17)
    #expect(cell?.style == .single)
}

@Test func testTableCellDetectorMarkdownTable() throws {
    let detector = TableCellDetector()
    let lines = [
        "| Header 1       | Header 2       |",
        "| -------------- | -------------- |",
        "| Data 1         | Data 2         |",
    ]

    let cell = detector.detectCell(in: lines, line: 2, col: 5)
    #expect(cell != nil)
    #expect(cell?.minLine == 1)
    #expect(cell?.maxLine == 3)
    #expect(cell?.style == .single)
}
