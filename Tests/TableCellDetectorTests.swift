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

@Test func testTableCellDetectorRejectsCursorOnFrame() throws {
    let detector = TableCellDetector()
    let lines = [
        "┌──────────────────┐",
        "│                  │",
        "│                  │",
        "│                  │",
        "└──────────────────┘",
    ]

    #expect(detector.detectCell(in: lines, line: 4, col: 16) == nil)
    #expect(detector.detectCell(in: lines, line: 1, col: 0) == nil)
    #expect(detector.detectCell(in: lines, line: 2, col: 8) != nil)
}

@Test func testTableCellDetectorRecognizesHeavyStyle() throws {
    let detector = TableCellDetector()
    let lines = [
        "┏━━━┓",
        "┃   ┃",
        "┗━━━┛",
    ]

    #expect(detector.detectCell(in: lines, line: 1, col: 2)?.style == .heavy)
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

@Test func testTableCellDetectorWithCJKInDiagram() throws {
    let detector = TableCellDetector()
    let lines = [
        "┌────────┐          ┌────────┐",
        "│        │          │        │",
        "│  起點  x          │  終點  │",
        "│        │          │        │",
        "└────────┘          └────────┘",
    ]

    // Cursor at line 1, where 'z' was (col 23)
    let cell1 = detector.detectCell(in: lines, line: 1, col: 23)
    #expect(cell1 != nil)
    #expect(cell1?.minLine == 0)
    #expect(cell1?.maxLine == 4)
    #expect(cell1?.minCol == 20)
    #expect(cell1?.maxCol == 29)

    // Cursor at line 2 inside right box (col 21, '終')
    let cell2 = detector.detectCell(in: lines, line: 2, col: 21)
    #expect(cell2 != nil)
    #expect(cell2?.minLine == 0)
    #expect(cell2?.maxLine == 4)
    #expect(cell2?.minCol == 20)
    #expect(cell2?.maxCol == 29)
}

@Test func testTableCellDetectorConnectedBoxWithCJK() throws {
    let detector = TableCellDetector()
    let lines = [
        "┌────────┐          ┌────────┐",
        "│        │          │        │",
        "│  起點  │          │  終點  │",
        "│        ├──────────┤        │",
        "└────────┘          └────────┘",
    ]

    // Cursor at line 2 on '點' of '終點' (character col 22)
    let cell = detector.detectCell(in: lines, line: 2, col: 22)
    #expect(cell != nil)
    #expect(cell?.minLine == 0)
    #expect(cell?.maxLine == 4)
    #expect(cell?.minCol == 20)
    #expect(cell?.maxCol == 29)
}

@Test func testTableCellDetectorRejectsGapBetweenConnectedAndDisconnectedBoxes() throws {
    let detector = TableCellDetector()
    let lines = [
        "┌────────┐          ┌────────┐",
        "│        │          │        │",
        "│  起點  │          │  終點  │",
        "│        ├──────────┤        │",
        "└────────┘          └────────┘",
        "┌────────┐          ┌────────┐",
        "│        │          │        │",
        "│  起點  x          │  終點  │",
        "│        │          │        │",
        "└────────┘          └────────┘",
    ]

    // Cursor at line 5 at col 17 (the 'z' position, space between boxes on row 5)
    let cell = detector.detectCell(in: lines, line: 5, col: 17)
    #expect(cell == nil)
}



