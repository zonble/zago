import Foundation
import Testing

@testable import Editor

@Test func testShiftArrowKeyEnum() throws {
    let keyLeft: Key = .shiftArrowLeft
    let keyRight: Key = .shiftArrowRight
    let keyUp: Key = .shiftArrowUp
    let keyDown: Key = .shiftArrowDown
    let keyHome: Key = .shiftHome
    let keyEnd: Key = .shiftEnd
    let ctrlShiftKeyLeft: Key = .ctrlShiftArrowLeft
    let ctrlShiftKeyRight: Key = .ctrlShiftArrowRight
    let ctrlShiftKeyUp: Key = .ctrlShiftArrowUp
    let ctrlShiftKeyDown: Key = .ctrlShiftArrowDown
    #expect(keyLeft != keyRight)
    #expect(keyUp != keyDown)
    #expect(keyHome != keyEnd)
    #expect(keyHome != .home)
    #expect(keyEnd != .end)
    #expect(ctrlShiftKeyLeft != ctrlShiftKeyRight)
    #expect(ctrlShiftKeyUp != ctrlShiftKeyDown)
    #expect(ctrlShiftKeyLeft != keyLeft)
}

@Test func testTextModeShiftHomeAndShiftEndExtendSelection() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 3

    editor.processKey(.shiftHome)

    #expect(editor.selectionMark?.line == 0)
    #expect(editor.selectionMark?.column == 3)
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 0)
    #expect(editor.buffer.textRange(start: (line: 0, col: 0), end: (line: 0, col: 3)) == "abc")

    editor.processKey(.shiftEnd)

    #expect(editor.selectionMark?.line == 0)
    #expect(editor.selectionMark?.column == 3)
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 6)
    #expect(editor.buffer.textRange(start: (line: 0, col: 3), end: (line: 0, col: 6)) == "def")
}

@Test func testShiftHomeAndShiftEndDoNotStartTextSelectionOutsideTextMode() throws {
    let canvasEditor = Editor()
    canvasEditor.buffer.lines = ["abcdef"]
    canvasEditor.switchToCanvasMode()
    canvasEditor.buffer.lineIndex = 0
    canvasEditor.buffer.columnIndex = 3

    canvasEditor.processKey(.shiftHome)
    #expect(canvasEditor.selectionMark == nil)
    #expect(canvasEditor.buffer.columnIndex == 3)

    let tableEditor = Editor()
    tableEditor.buffer.lines = ["abcdef"]
    tableEditor.isTableModeActive = true
    tableEditor.buffer.lineIndex = 0
    tableEditor.buffer.columnIndex = 3

    tableEditor.processKey(.shiftEnd)
    #expect(tableEditor.selectionMark == nil)
    #expect(tableEditor.buffer.columnIndex == 3)
}

@Test func testTextCopySelectionKeepsSelectionCursorAndBuffer() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 4
    editor.selectionMark = (line: 0, column: 1)

    editor.processKey(.alt("w"))

    #expect(editor.clipboardText == "bcd")
    #expect(editor.buffer.lines == ["abcdef"])
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 4)
    #expect(editor.selectionMark?.line == 0)
    #expect(editor.selectionMark?.column == 1)
    #expect(editor.buffer.isModified == false)
    #expect(editor.statusMessage == L10n["status.copied_text"])
}

@Test func testCopyWithoutSelectionReportsNoSelection() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef"]

    editor.processKey(.alt("w"))

    #expect(editor.clipboardText == nil)
    #expect(editor.buffer.lines == ["abcdef"])
    #expect(editor.statusMessage == L10n["status.no_selection"])
}

@Test func testTransformSelectedTextReplacesSelectionAndSupportsUndo() throws {
    let editor = Editor()
    editor.buffer.lines = ["foo 中文API測試 bar"]
    editor.selectionMark = (line: 0, column: 4)
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 11

    editor.transformSelectedText(id: "Zago-CJK-Spacing", label: L10n["transform.cjk_spacing"])

    #expect(editor.buffer.lines == ["foo 中文 API 測試 bar"])
    #expect(editor.selectionMark == nil)
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 13)

    editor.performUndo()
    #expect(editor.buffer.lines == ["foo 中文API測試 bar"])
}

@Test func testTransformSelectedTextRequiresSelection() throws {
    let editor = Editor()
    editor.buffer.lines = ["中文API測試"]

    editor.transformSelectedText(id: "Zago-CJK-Spacing", label: L10n["transform.cjk_spacing"])

    #expect(editor.buffer.lines == ["中文API測試"])
    #expect(editor.statusMessage == L10n["status.no_text_selection"])
}

@Test func testTextCountsUseSelectionOrWholeDocument() throws {
    let editor = Editor()
    editor.buffer.lines = ["Hello world", "中文 API 測試"]

    editor.showTextCounts()
    #expect(editor.statusMessage == "[ Document: 21 chars, 5 words, 4 CJK chars, 2 lines ]")

    editor.selectionMark = (line: 0, column: 0)
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 5

    editor.showTextCounts()
    #expect(editor.statusMessage == "[ Selection: 5 chars, 1 word, 1 line ]")
}

@Test func testCanvasCopyBlockKeepsMarkCursorAndBuffer() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef", "123456"]
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 1
    editor.processKey(.mark)
    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 3
    editor.processKey(.mark)

    editor.processKey(.alt("W"))

    #expect(editor.canvasBlockClipboard == Editor.CanvasBlockClipboard(width: 3, rows: ["bcd", "234"]))
    #expect(editor.buffer.lines == ["abcdef", "123456"])
    #expect(editor.statusMessage == L10n["status.copied_block"])
}

@Test func testCanvasModeAltBTogglesBlockMarkLikeMarkKey() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef", "123456"]
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 1

    editor.processKey(.alt("b"))

    #expect(editor.canvasBlockMark?.line == 0)
    #expect(editor.canvasBlockMark?.visualColumn == 1)
    #expect(editor.canvasBlockMarkEnd?.line == 0)
    #expect(editor.canvasBlockMarkEnd?.visualColumn == 1)
    #expect(editor.statusMessage == L10n["status.mark_set"])

    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 3
    editor.processKey(.alt("B"))

    #expect(editor.canvasBlockMark?.line == 0)
    #expect(editor.canvasBlockMark?.visualColumn == 1)
    #expect(editor.canvasBlockMarkEnd?.line == 1)
    #expect(editor.canvasBlockMarkEnd?.visualColumn == 3)
    #expect(editor.statusMessage == L10n["status.mark_set"])
}
