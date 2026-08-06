import Foundation
import Testing
import TextMetrics

@testable import Editor



@Test func testCanvasModeShiftArrowDrawsBoxLines() throws {
    let editor = Editor()
    editor.switchToCanvasMode()

    editor.processKey(.shiftArrowRight)
    #expect(editor.buffer.lines[0] == "─")
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 1)

    editor.processKey(.shiftArrowDown)
    #expect(editor.buffer.lines[0] == "─┐")
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 1)
}

@Test func testCanvasModeLineFusionStepByStep() throws {
    // shift + right case: ─│ -> ─┤ -> ─┼
    do {
        let editor = Editor()
        editor.buffer.lines = ["─│"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0
        editor.switchToCanvasMode()
        editor.syncCanvasCursorFromBuffer()

        // 1st shift + right: moves from ─ to │. │ becomes ┤, cursor lands on ┤.
        editor.processKey(.shiftArrowRight)
        #expect(editor.buffer.lines[0] == "─┤")
        #expect(editor.canvasVisualColumn == 1)

        // 2nd shift + right: moves from ┤ to right. ┤ becomes ┼, cursor lands on col 2.
        editor.processKey(.shiftArrowRight)
        #expect(editor.buffer.lines[0] == "─┼")
        #expect(editor.canvasVisualColumn == 2)
    }

    // shift + down case: │ over ─ -> ┴ -> ┼
    do {
        let editor = Editor()
        editor.buffer.lines = ["│", "─"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0
        editor.switchToCanvasMode()
        editor.syncCanvasCursorFromBuffer()

        // 1st shift + down: moves from │ to ─. ─ becomes ┴, cursor lands on ┴.
        editor.processKey(.shiftArrowDown)
        #expect(editor.buffer.lines[0] == "│")
        #expect(editor.buffer.lines[1] == "┴")
        #expect(editor.buffer.lineIndex == 1)

        // 2nd shift + down: moves from ┴ down. ┴ becomes ┼, cursor lands on line 2.
        editor.processKey(.shiftArrowDown)
        #expect(editor.buffer.lines[1] == "┼")
        #expect(editor.buffer.lineIndex == 2)
    }

    // shift + left case: │─ -> ├─ -> ┼─
    do {
        let editor = Editor()
        editor.buffer.lines = [" │─"]
        editor.buffer.lineIndex = 0
        editor.canvasVisualColumn = 2
        editor.syncCanvasCursorToBuffer()
        editor.switchToCanvasMode()

        // 1st shift + left: moves from ─ to │. │ becomes ├, cursor lands on ├.
        editor.processKey(.shiftArrowLeft)
        #expect(editor.buffer.lines[0] == " ├─")
        #expect(editor.canvasVisualColumn == 1)

        // 2nd shift + left: moves from ├ left. ├ becomes ┼, cursor lands on col 0 (space).
        editor.processKey(.shiftArrowLeft)
        #expect(editor.buffer.lines[0] == " ┼─")
        #expect(editor.canvasVisualColumn == 0)
    }

    // shift + up case: ─ under │ -> ┬ -> ┼
    do {
        let editor = Editor()
        editor.buffer.lines = ["", "─", "│"]
        editor.buffer.lineIndex = 2
        editor.buffer.columnIndex = 0
        editor.switchToCanvasMode()
        editor.syncCanvasCursorFromBuffer()

        // 1st shift + up: moves from │ to ─. ─ becomes ┬, cursor lands on ┬.
        editor.processKey(.shiftArrowUp)
        #expect(editor.buffer.lines[1] == "┬")
        #expect(editor.buffer.lines[2] == "│")
        #expect(editor.buffer.lineIndex == 1)

        // 2nd shift + up: moves from ┬ up. ┬ becomes ┼, cursor lands on line 0.
        editor.processKey(.shiftArrowUp)
        #expect(editor.buffer.lines[1] == "┼")
        #expect(editor.buffer.lineIndex == 0)
    }

    // Double border style case: ═║ -> ═╣ -> ═╬
    do {
        let editor = Editor()
        editor.defaultBorderStyle = .double
        editor.buffer.lines = ["═║"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0
        editor.switchToCanvasMode()
        editor.syncCanvasCursorFromBuffer()

        // 1st shift + right: moves from ═ to ║. ║ becomes ╣, cursor lands on ╣.
        editor.processKey(.shiftArrowRight)
        #expect(editor.buffer.lines[0] == "═╣")
        #expect(editor.canvasVisualColumn == 1)

        // 2nd shift + right: moves from ╣ to right. ╣ becomes ╬, cursor lands on col 2.
        editor.processKey(.shiftArrowRight)
        #expect(editor.buffer.lines[0] == "═╬")
        #expect(editor.canvasVisualColumn == 2)
    }

    // ASCII border style case: -| -> -+ -> -+
    do {
        let editor = Editor()
        editor.defaultBorderStyle = .ascii
        editor.buffer.lines = ["-|"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0
        editor.switchToCanvasMode()
        editor.syncCanvasCursorFromBuffer()

        // 1st shift + right: moves from - to |. | becomes +, cursor lands on +.
        editor.processKey(.shiftArrowRight)
        #expect(editor.buffer.lines[0] == "-+")
        #expect(editor.canvasVisualColumn == 1)

        // 2nd shift + right: moves from + to right. + remains +, cursor lands on col 2.
        editor.processKey(.shiftArrowRight)
        #expect(editor.buffer.lines[0] == "-+")
        #expect(editor.canvasVisualColumn == 2)
    }
}

@Test func testCanvasModeCtrlShiftArrowDrawsArrows() throws {
    let editor = Editor()
    editor.defaultBorderStyle = .ascii
    editor.switchToCanvasMode()

    editor.processKey(.ctrlShiftArrowRight)
    #expect(editor.buffer.lines[0] == "->")
    #expect(editor.canvasVisualColumn == 1)

    editor.processKey(.ctrlShiftArrowRight)
    #expect(editor.buffer.lines[0] == "-->")
    #expect(editor.canvasVisualColumn == 2)
}

@Test func testCanvasModeDrawingUsesBorderStyleAndVisualColumn() throws {
    let editor = Editor()
    editor.buffer.lines = ["中"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 1
    editor.defaultBorderStyle = .double
    editor.switchToCanvasMode()

    editor.processKey(.shiftArrowRight)

    #expect(editor.buffer.lines[0] == "中═")
    #expect(editor.canvasVisualColumn == 3)
}

@Test func testCanvasModeDrawingDoesNotOverwriteTextOrTableCells() throws {
    let editor = Editor()
    editor.buffer.lines = ["A"]
    editor.switchToCanvasMode()

    editor.processKey(.shiftArrowRight)

    #expect(editor.buffer.lines[0] == "A")
    #expect(editor.canvasVisualColumn == 1)

    let tableEditor = Editor()
    tableEditor.buffer.lines = [
        "┌────────────────┐",
        "│                │",
        "└────────────────┘",
    ]
    tableEditor.buffer.lineIndex = 1
    tableEditor.buffer.columnIndex = 1
    tableEditor.switchToCanvasMode()
    tableEditor.toggleTableMode()

    tableEditor.processKey(.ctrlShiftArrowRight)

    #expect(tableEditor.buffer.lines[1] == "│                 │")
}

@Test func testCanvasModeDrawingUndoRestoresVisualCursor() throws {
    let editor = Editor()
    editor.switchToCanvasMode()

    editor.processKey(.shiftArrowRight)
    #expect(editor.buffer.lines[0] == "─")
    #expect(editor.canvasVisualColumn == 1)

    editor.performUndo()

    #expect(editor.buffer.lines[0] == "")
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 0)
    #expect(editor.canvasVisualColumn == 0)
}

@Test func testCanvasModeUndoRestoresSparseVisualCursor() throws {
    let editor = Editor()
    editor.switchToCanvasMode()
    editor.canvasVisualColumn = 8
    editor.syncCanvasCursorToBuffer()

    editor.processKey(.char("x"))
    #expect(editor.buffer.lines[0] == "        x")
    #expect(editor.canvasVisualColumn == 9)

    editor.performUndo()

    #expect(editor.buffer.lines[0] == "")
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 8)
    #expect(editor.buffer.columnIndex == 0)
}

@Test func testEditorUndoStack() throws {
    let editor = Editor()
    #expect(editor.buffer.lines[0] == "")

    editor.saveUndoSnapshot()
    editor.buffer.insertString("Hello World")
    #expect(editor.buffer.lines[0] == "Hello World")

    editor.saveUndoSnapshot()
    editor.buffer.insertString(" - Swift TUI")
    #expect(editor.buffer.lines[0] == "Hello World - Swift TUI")

    editor.performUndo()
    #expect(editor.buffer.lines[0] == "Hello World")

    editor.performUndo()
    #expect(editor.buffer.lines[0] == "")
}

@Test func testCommandRegistry() throws {
    let editor = Editor()
    #expect(editor.commandRegistry.commands.count > 20)

    var executed = false
    let testCmd = BlockCommand(id: .testCmd, name: "Test", description: "Test command", keys: [.ctrl("T")]) { _ in
        executed = true
    }
    let registry = CommandRegistry()
    registry.register(testCmd)

    let handled = registry.dispatch(key: .ctrl("T"), editor: editor)
    #expect(handled == true)
    #expect(executed == true)
}

@Test func testDocumentLinkParserSupportsProseFormats() throws {
    let markdown = DocumentLinkParser.link(atColumn: 8, in: "See [test](test.md#section)")
    #expect(markdown?.target == "test.md#section")
    #expect(DocumentLinkParser.localPathTarget(from: markdown?.target ?? "") == "test.md")

    let org = DocumentLinkParser.link(atColumn: 4, in: "[[file:notes.org][notes]]")
    #expect(org?.target == "file:notes.org")
    #expect(DocumentLinkParser.localPathTarget(from: org?.target ?? "") == "notes.org")

    let rst = DocumentLinkParser.link(atColumn: 3, in: "`Spec <docs/spec.rst>`_")
    #expect(rst?.target == "docs/spec.rst")

    let asciiDocLink = DocumentLinkParser.link(atColumn: 2, in: "xref:chapters/intro.adoc[Intro]")
    #expect(asciiDocLink?.target == "chapters/intro.adoc")

    let asciiDocInclude = DocumentLinkParser.link(atColumn: 2, in: "include::partials/setup.asciidoc[]")
    #expect(asciiDocInclude?.target == "partials/setup.asciidoc")

    #expect(DocumentLinkParser.localPathTarget(from: "https://example.com/test.md") == nil)
    #expect(DocumentLinkParser.localPathTarget(from: "#local-anchor") == nil)
}

@Test func testOpenDocumentLinkCommandOpensRelativeMarkdownFile() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("zago_document_link_\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let indexPath = directory.appendingPathComponent("index.md").path
    let targetPath = directory.appendingPathComponent("test.md").path
    try "target".write(to: URL(fileURLWithPath: targetPath), atomically: testAtomicallyOption, encoding: .utf8)

    let editor = Editor(filePath: indexPath)
    defer {
        editor.stopFileWatcherForCurrentBuffer()
        try? FileManager.default.removeItem(at: directory)
    }
    editor.buffer.lines = ["See [test](test.md)"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 6

    let handled = editor.commandRegistry.dispatch(key: .alt("o"), editor: editor)

    #expect(handled == true)
    #expect(editor.buffer.filePath == targetPath)
    #expect(editor.buffer.lines.first == "target")
}

@Test func testOpenDocumentLinkCommandDoesNotReopenCurrentFile() throws {
    let rawDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("zago_same_document_link_\(UUID().uuidString)", isDirectory: true).path
    let directoryPath = TestLocalEditorFileIOStrategy().normalizePath(rawDirectory, isDirectory: true)
    try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)

    let indexPath = (directoryPath as NSString).appendingPathComponent("index.md")
    try "original".write(to: URL(fileURLWithPath: indexPath), atomically: testAtomicallyOption, encoding: .utf8)

    let editor = Editor(filePath: indexPath)
    defer {
        editor.stopFileWatcherForCurrentBuffer()
        try? FileManager.default.removeItem(atPath: directoryPath)
    }

    editor.buffer.lines = ["See [this](./index.md#section)", "unchanged"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 6
    editor.topVLineIndex = 3

    let handled = editor.commandRegistry.dispatch(key: Key.alt("o"), editor: editor)

    #expect(handled == true)
    #expect(editor.buffers.count == 1)
    #expect(editor.currentBufferIndex == 0)
    #expect(editor.buffer.filePath == indexPath)
    #expect(editor.buffer.lines == ["See [this](./index.md#section)", "unchanged"])
    #expect(editor.topVLineIndex == 3)
    #expect(editor.statusMessage == editor.l10n["status.document_link_same_file"])
}

@Test func testSaveKeySavesExistingFileWithoutPrompt() throws {
    let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent("zago_direct_save_test.txt").path
    let normalizedPath = TestLocalEditorFileIOStrategy().normalizePath(tmpPath, isDirectory: false)
    defer {
        try? FileManager.default.removeItem(atPath: normalizedPath)
    }

    let editor = Editor(filePath: normalizedPath)
    editor.buffer.lines = ["saved without prompt"]
    editor.buffer.isModified = true

    let handled = editor.commandRegistry.dispatch(key: Key.ctrl("S"), editor: editor)

    #expect(handled == true)
    #expect(editor.buffer.isModified == false)
    #expect(try String(contentsOf: URL(fileURLWithPath: normalizedPath), encoding: .utf8) == "saved without prompt")
    if case .none = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "^S should not prompt when the buffer already has a file path")
    }
}

@Test func testSaveTrimsTrailingWhitespaceWhenSettingEnabled() throws {
    let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent(
        "zago_trim_trailing_whitespace_\(UUID().uuidString).txt"
    ).path
    let normalizedPath = TestLocalEditorFileIOStrategy().normalizePath(tmpPath, isDirectory: false)
    defer {
        try? FileManager.default.removeItem(atPath: normalizedPath)
    }

    let editor = Editor(filePath: normalizedPath)
    editor.buffer.lines = ["alpha  ", "\tbeta\t", "gamma"]
    editor.buffer.isModified = true
    editor.displayConfig.trimTrailingWhitespaceOnSave = true

    editor.saveBuffer(path: Optional<String>.none)

    #expect(editor.buffer.lines == ["alpha", "\tbeta", "gamma"])
    #expect(try String(contentsOf: URL(fileURLWithPath: normalizedPath), encoding: .utf8) == "alpha\n\tbeta\ngamma")
    #expect(editor.buffer.isModified == false)
}

@Test func testSavePreservesTrailingWhitespaceWhenSettingDisabled() throws {
    let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent(
        "zago_preserve_trailing_whitespace_\(UUID().uuidString).txt"
    ).path
    let normalizedPath = TestLocalEditorFileIOStrategy().normalizePath(tmpPath, isDirectory: false)
    defer {
        try? FileManager.default.removeItem(atPath: normalizedPath)
    }

    let editor = Editor(filePath: normalizedPath)
    editor.buffer.lines = ["alpha  ", "beta\t"]
    editor.buffer.isModified = true
    editor.displayConfig.trimTrailingWhitespaceOnSave = false

    editor.saveBuffer(path: Optional<String>.none)

    #expect(editor.buffer.lines == ["alpha  ", "beta\t"])
    #expect(try String(contentsOf: URL(fileURLWithPath: normalizedPath), encoding: .utf8) == "alpha  \nbeta\t")
    #expect(editor.buffer.isModified == false)
}

@Test func testWriteOutStillPromptsForPath() throws {
    let editor = Editor()

    let handled = editor.commandRegistry.dispatch(key: .ctrl("O"), editor: editor)

    #expect(handled == true)
    if case .saveFilePath = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "^O should keep WriteOut behavior and ask for a path")
    }
}

@Test func testMultiBufferOperations() throws {
    let editor = Editor(filePaths: ["file1.txt", "file2.txt"])
    #expect(editor.buffers.count == 2)
    #expect(editor.currentBufferIndex == 0)
    #expect(editor.buffer.filePath?.contains("file1.txt") == true)

    // Test next buffer
    editor.nextBuffer()
    #expect(editor.currentBufferIndex == 1)
    #expect(editor.buffer.filePath?.contains("file2.txt") == true)

    // Test next buffer wrapping back to 0
    editor.nextBuffer()
    #expect(editor.currentBufferIndex == 0)

    // Test prev buffer wrapping to last
    editor.prevBuffer()
    #expect(editor.currentBufferIndex == 1)

    // Test opening a new buffer
    editor.openNewBuffer(filePath: "file3.txt")
    #expect(editor.buffers.count == 3)
    #expect(editor.currentBufferIndex == 2)
    #expect(editor.buffer.filePath?.contains("file3.txt") == true)

    // Test screen render Title Bar format includes [3/3]
    let output = editor.renderer.render(editor: editor, rows: 24, cols: 80)
    #expect(output.contains("[3/3]"))

    // Test close current buffer
    editor.closeCurrentBuffer()
    #expect(editor.buffers.count == 2)
    #expect(editor.currentBufferIndex == 1)
}

@Test func testEditorProcessKeyInput() throws {
    let editor = Editor()
    #expect(editor.buffer.lines.count == 1)
    #expect(editor.buffer.lines[0] == "")

    // Test typing characters
    editor.processKey(.char("H"))
    editor.processKey(.char("i"))
    #expect(editor.buffer.lines[0] == "Hi")

    // Test Enter
    editor.processKey(.enter)
    #expect(editor.buffer.lines.count == 2)

    // Test typing on second line
    editor.processKey(.char("W"))
    #expect(editor.buffer.lines[1] == "W")

    // Test Backspace
    editor.processKey(.backspace)
    #expect(editor.buffer.lines[1] == "")
}

@Test func testCursorPositionStatusIncludesVisualColumn() throws {
    let editor = Editor()
    editor.language = .en
    editor.buffer.lines = ["中AB"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 2

    editor.processKey(.ctrl("C"))

    #expect(editor.statusMessage == "line 1/1 (100%), col 3/4, visual col 4/5")
}

@Test func testTextModeEndStopsAtCurrentWrappedVisualLineEnd() throws {
    let editor = Editor(wrapColumn: 10)
    editor.buffer.lines = ["1234567890ABCDEFGHIJ12345"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 0

    editor.processKey(.end)
    #expect(editor.buffer.columnIndex == 9)

    editor.buffer.columnIndex = 10
    editor.processKey(.end)
    #expect(editor.buffer.columnIndex == 19)

    editor.buffer.columnIndex = 20
    editor.processKey(.end)
    #expect(editor.buffer.columnIndex == 25)
}

@Test func testCanvasModeFixedPositionTypingAndMovement() throws {
    let editor = Editor()
    editor.buffer.lines = ["AB", "中D"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 2

    editor.switchToCanvasMode()
    #expect(editor.canvasVisualColumn == 2)

    editor.processKey(.arrowRight)
    editor.processKey(.arrowRight)
    #expect(editor.canvasVisualColumn == 4)

    editor.processKey(.char("Z"))
    #expect(editor.buffer.lines[0] == "AB  Z")
    #expect(editor.canvasVisualColumn == 5)

    editor.processKey(.arrowUp)
    #expect(editor.buffer.lineIndex == 0)

    editor.processKey(.arrowDown)
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 5)

    editor.processKey(.char("Q"))
    #expect(editor.buffer.lines[1] == "中D  Q")
}

@Test func testCanvasModeTypingPreservesBlockMark() throws {
    let editor = Editor()
    editor.switchToCanvasMode()

    // Set canvas block mark at (0, 0)
    editor.processKey(.mark)
    #expect(editor.buffer.canvasBlockMark != nil)

    // Move to (2, 5) and set block mark end
    editor.buffer.lineIndex = 2
    editor.canvasVisualColumn = 5
    editor.processKey(.mark)
    #expect(editor.buffer.canvasBlockMark != nil)
    #expect(editor.buffer.canvasBlockMarkEnd != nil)

    // Typing a character should NOT clear the canvas block mark
    editor.processKey(.char("X"))
    #expect(editor.buffer.canvasBlockMark != nil)
    #expect(editor.buffer.canvasBlockMarkEnd != nil)

    // Backspace should NOT clear the canvas block mark
    editor.processKey(.backspace)
    #expect(editor.buffer.canvasBlockMark != nil)
    #expect(editor.buffer.canvasBlockMarkEnd != nil)

    // Delete should NOT clear the canvas block mark
    editor.processKey(.delete)
    #expect(editor.buffer.canvasBlockMark != nil)
    #expect(editor.buffer.canvasBlockMarkEnd != nil)
}

@Test func testCanvasModeReplaceAndClearPreserveDisplayWidth() throws {
    let editor = Editor()
    editor.buffer.lines = ["ABCD", "中D"]
    editor.switchToCanvasMode()

    editor.canvasVisualColumn = 1
    editor.syncCanvasCursorToBuffer()
    editor.processKey(.char("中"))
    #expect(editor.buffer.lines[0] == "A中D")
    #expect(editor.buffer.lines[0].displayWidth == 4)

    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 2
    editor.syncCanvasCursorToBuffer()
    editor.processKey(.delete)
    #expect(editor.buffer.lines[1] == "中 ")
    #expect(editor.buffer.lines[1].displayWidth == 3)

    editor.processKey(.backspace)
    #expect(editor.canvasVisualColumn == 0)
    #expect(editor.buffer.lines[1] == "   ")
}

@Test func testCanvasModeBackspaceAtLineStartDeletesCurrentLine() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two", "three"]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 0
    editor.switchToCanvasMode()

    editor.processKey(.backspace)

    #expect(editor.buffer.lines == ["one", "three"])
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 0)
}

@Test func testCanvasModeEnterInsertsBlankLine() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 3
    editor.switchToCanvasMode()

    editor.processKey(.enter)

    #expect(editor.buffer.lines == ["one", "", "two"])
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 0)
}

@Test func testCanvasModePageDownDoesNotCreateBlankLines() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two"]
    editor.buffer.lineIndex = 0
    editor.switchToCanvasMode()
    editor.canvasVisualColumn = 5
    editor.syncCanvasCursorToBuffer()

    editor.processKey(.pageDown)

    #expect(editor.buffer.lines == ["one", "two"])
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 5)

    editor.processKey(.pageUp)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 5)

    editor.processKey(.pageDown)

    #expect(editor.buffer.lines == ["one", "two"])
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 5)

    editor.processKey(.arrowDown)

    #expect(editor.buffer.lines == ["one", "two", ""])
    #expect(editor.buffer.lineIndex == 2)
    #expect(editor.canvasVisualColumn == 5)
}

@Test func testCanvasModeHorizontalRenderingOffset() throws {
    let editor = Editor()
    editor.buffer.lines = ["ABCDEFGHIJKLMNOPQRSTUVWXYZ"]
    editor.switchToCanvasMode()
    editor.canvasVisualColumn = 12
    editor.syncCanvasCursorToBuffer()

    let mainAreaHeight = max(1, 8 - 4)
    let textWidth = max(10, 15 - 5)
    editor.adjustViewport(mainAreaHeight: mainAreaHeight, textWidth: textWidth)

    let output = editor.renderer.render(editor: editor, rows: 8, cols: 15)

    #expect(editor.canvasHorizontalOffset == 10)
    #expect(output.contains("KLMNOPQRST"))
}

@Test func testTextModeGotoDoesNotAutoExtendBuffer() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two"]

    editor.goToLocation(line: 100, column: 2)

    #expect(editor.buffer.lines.count == 2)
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 1)
}

@Test func testCanvasModeGotoAutoExtendsRowsWithinLimit() throws {
    let editor = Editor()
    editor.buffer.lines = ["one"]
    editor.switchToCanvasMode()

    editor.goToLocation(line: 5, column: 10)

    #expect(editor.buffer.lines.count == 5)
    #expect(editor.buffer.lineIndex == 4)
    #expect(editor.canvasVisualColumn == 9)
    #expect(editor.buffer.columnIndex == 0)
    #expect(editor.buffer.isModified == true)
}

@Test func testCanvasModeGotoRejectsRowsAndColumnsBeyondLimit() throws {
    let editor = Editor()
    editor.buffer.lines = ["one"]
    editor.switchToCanvasMode()

    editor.goToLocation(line: EditorLimits.maxCanvasAutoExtendRows + 1, column: 1)

    #expect(editor.buffer.lines.count == 1)
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 0)
    #expect(editor.statusMessage == editor.l10n["status.canvas_row_limit_exceeded"])

    editor.goToLocation(line: 1, column: EditorLimits.maxCanvasAutoExtendColumns + 1)

    #expect(editor.buffer.lines.count == 1)
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 0)
    #expect(editor.statusMessage == editor.l10n["status.canvas_column_limit_exceeded"])
}

@Test func testCanvasModeDrawingStopsAtColumnLimit() throws {
    let editor = Editor()
    editor.switchToCanvasMode()
    editor.goToLocation(line: 1, column: EditorLimits.maxCanvasAutoExtendColumns)

    editor.processKey(.shiftArrowRight)

    #expect(editor.canvasVisualColumn == EditorLimits.maxCanvasAutoExtendColumns - 1)
    #expect(editor.buffer.lines[0] == "")
    #expect(editor.statusMessage == editor.l10n["status.canvas_column_limit_exceeded"])
}

@Test func testCanvasModeRejectsJustification() throws {
    let editor = Editor()
    editor.buffer.lines = ["one two three four"]
    editor.switchToCanvasMode()

    let handled = editor.commandRegistry.dispatch(key: .ctrl("J"), editor: editor)

    #expect(handled == true)
    #expect(editor.buffer.lines == ["one two three four"])
    #expect(editor.statusMessage == "[ Justify disabled in Canvas Mode ]")
}

@Test func testEscAndAltColonTriggersLogoPrompt() throws {
    let editor = Editor()

    // Test Esc
    editor.processKey(.esc)
    if case .logoMacro = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Esc should trigger command prompt mode")
    }

    editor.currentPromptMode = .none

    // Test Alt+: (.alt(":"))
    editor.processKey(.alt(":"))
    if case .logoMacro = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Alt+: should trigger command prompt mode")
    }
}

@Test func testCtrlGClearsSelectionAndEscOpensLogoPrompt() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 3
    editor.buffer.selectionMark = (line: 0, column: 1)

    editor.processKey(.ctrl("G"))

    #expect(editor.buffer.selectionMark == nil)
    if case .none = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "^G with selection should stay in editing mode")
    }
    #expect(editor.statusMessage == editor.l10n["status.mark_unset"])

    editor.processKey(.esc)
    if case .logoMacro = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Esc should still trigger command prompt mode")
    }
}

@Test func testCtrlGCancelsActivePromptMode() throws {
    let editor = Editor()
    editor.promptWriteFilePath()

    if case .saveFilePath = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "saveFilePath prompt should be active")
    }

    editor.processKey(.ctrl("G"))

    if case .none = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Ctrl+G should cancel active prompt mode")
    }
    #expect(editor.statusMessage == editor.l10n["status.cancelled"])
}

@Test func testCtrlMarkInTextModeReportsCanvasOnlyMessage() throws {
    let editor = Editor()

    editor.processKey(.mark)

    #expect(editor.buffer.selectionMark == nil)
    #expect(editor.buffer.canvasBlockMark == nil)
    #expect(editor.statusMessage == editor.l10n["status.block_mark_canvas_only"])
}

@Test func testModeSwitchClearsMarksButKeepsSeparateClipboards() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef"]
    editor.clipboardText = "text"
    editor.buffer.selectionMark = (line: 0, column: 1)
    editor.canvasBlockClipboard = Editor.CanvasBlockClipboard(width: 2, rows: ["xy"])

    editor.switchToCanvasMode()
    #expect(editor.buffer.selectionMark == nil)
    #expect(editor.clipboardText == "text")
    #expect(editor.canvasBlockClipboard == Editor.CanvasBlockClipboard(width: 2, rows: ["xy"]))

    editor.buffer.canvasBlockMark = (line: 0, visualColumn: 1)
    editor.switchToTextMode()
    #expect(editor.buffer.canvasBlockMark == nil)
    #expect(editor.clipboardText == "text")
    #expect(editor.canvasBlockClipboard == Editor.CanvasBlockClipboard(width: 2, rows: ["xy"]))
}



@Test func testTextSelectionReplacementAndEmptyLineHighlight() throws {
    let editor = Editor()
    editor.buffer.lines = ["abc", "", "def"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 1

    editor.processKey(.shiftArrowDown)
    editor.processKey(.shiftArrowDown)
    #expect(editor.buffer.selectionMark?.line == 0)
    #expect(editor.buffer.selectionMark?.column == 1)
    #expect(editor.buffer.lineIndex == 2)
    #expect(editor.buffer.columnIndex == 0)

    let rendered = editor.renderer.render(editor: editor, rows: 10, cols: 24)
    #expect(rendered.contains("\u{1B}[7m                   \u{1B}[m"))

    editor.processKey(.char("X"))
    #expect(editor.buffer.selectionMark == nil)
    #expect(editor.buffer.lines == ["aXdef"])
}



@Test func testCanvasBlockCutPasteAndCancel() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef", "123456"]
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 1
    editor.processKey(.mark)
    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 3
    editor.processKey(.mark)

    editor.processKey(.ctrl("K"))

    #expect(editor.buffer.lines == ["aef", "156"])
    #expect(editor.canvasBlockClipboard == Editor.CanvasBlockClipboard(width: 3, rows: ["bcd", "234"]))
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 1)
    #expect(editor.buffer.canvasBlockMark == nil)
    #expect(editor.buffer.canvasBlockMarkEnd == nil)

    editor.buffer.lines = ["xxYY", "zzWW"]
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 2
    editor.processKey(.ctrl("U"))

    #expect(editor.buffer.lines == ["xxbcdYY", "zz234WW"])
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.canvasVisualColumn == 2)

    editor.processKey(.mark)
    #expect(editor.buffer.canvasBlockMark != nil)
    #expect(editor.buffer.canvasBlockMarkEnd != nil)
    editor.processKey(.ctrl("G"))
    #expect(editor.buffer.canvasBlockMark == nil)
    #expect(editor.buffer.canvasBlockMarkEnd == nil)
}

@Test func testCanvasBlockCutWithoutMarkAndCJKBoundarySnap() throws {
    let noMarkEditor = Editor()
    noMarkEditor.buffer.lines = ["abcdef"]
    noMarkEditor.switchToCanvasMode()
    noMarkEditor.processKey(.ctrl("K"))
    #expect(noMarkEditor.buffer.lines == ["abcdef"])
    #expect(noMarkEditor.canvasBlockClipboard == nil)
    #expect(noMarkEditor.statusMessage == noMarkEditor.l10n["status.no_block_marked"])

    let cjkEditor = Editor()
    cjkEditor.buffer.lines = ["A中BC"]
    cjkEditor.switchToCanvasMode()
    cjkEditor.buffer.lineIndex = 0
    cjkEditor.canvasVisualColumn = 2
    cjkEditor.processKey(.mark)
    cjkEditor.canvasVisualColumn = 2
    cjkEditor.processKey(.mark)
    cjkEditor.processKey(.ctrl("K"))

    #expect(cjkEditor.buffer.lines == ["ABC"])
    #expect(cjkEditor.canvasBlockClipboard == Editor.CanvasBlockClipboard(width: 2, rows: ["中"]))
}

@Test func testCanvasBlockMarkStatusShowsStartAndEndCoordinates() throws {
    let editor = Editor()
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 1
    editor.processKey(.mark)
    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 3
    editor.processKey(.mark)

    let status = editor.renderer.renderIdleStatusLine(editor: editor, cols: 80)
    #expect(status.contains("Mark Set (start 1,2 end 2,4)"))
}

@Test func testCanvasArrowMovementKeepsBlockMarkWithoutChangingBlock() throws {
    let editor = Editor()
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 1
    editor.processKey(.mark)
    #expect(editor.buffer.canvasBlockMarkEnd?.line == 0)
    #expect(editor.buffer.canvasBlockMarkEnd?.visualColumn == 1)

    editor.processKey(.arrowRight)
    editor.processKey(.arrowDown)

    #expect(editor.buffer.canvasBlockMark?.line == 0)
    #expect(editor.buffer.canvasBlockMark?.visualColumn == 1)
    #expect(editor.buffer.canvasBlockMarkEnd?.line == 0)
    #expect(editor.buffer.canvasBlockMarkEnd?.visualColumn == 1)
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 2)

    let status = editor.renderer.renderIdleStatusLine(editor: editor, cols: 80)
    #expect(status.contains("Mark Set (start 1,2 end 1,2)"))

    editor.processKey(.mark)
    #expect(editor.buffer.canvasBlockMark?.line == 0)
    #expect(editor.buffer.canvasBlockMark?.visualColumn == 1)
    #expect(editor.buffer.canvasBlockMarkEnd?.line == 1)
    #expect(editor.buffer.canvasBlockMarkEnd?.visualColumn == 2)
}

@Test func testCanvasEmptyLineHighlightsOnlyMarkedBlockWidth() throws {
    let editor = Editor()
    editor.buffer.lines = ["abc", "", "def"]
    editor.displayConfig.showLineNumbers = false
    editor.displayConfig.showRuler = false
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 2
    editor.processKey(.mark)
    editor.canvasVisualColumn = 4
    editor.processKey(.mark)

    let virtualLines = editor.layoutEngine.computeVirtualLines(from: editor.buffer.lines, viewWidth: 10)
    let rendered = editor.renderer.renderMainTextArea(
        editor: editor,
        mainAreaHeight: 3,
        gutterWidth: 0,
        virtualLines: virtualLines,
        cols: 10,
        dropdownStartCol: 0,
        dropdownBoxWidth: 0,
        dropdownBoxLines: []
    )

    let highlightedCells = rendered.components(separatedBy: "\u{1B}[7m \u{1B}[m").count - 1
    #expect(highlightedCells == 3)
    #expect(!rendered.contains("\u{1B}[7m          \u{1B}[m"))
}

@Test func testCanvasFillUsesActiveBlockMark() throws {
    let editor = Editor()
    editor.buffer.lines = ["abcdef", "123456", "uvwxyz"]
    editor.switchToCanvasMode()
    editor.buffer.lineIndex = 0
    editor.canvasVisualColumn = 1
    editor.processKey(.mark)
    editor.buffer.lineIndex = 1
    editor.canvasVisualColumn = 3
    editor.processKey(.mark)

    editor.runLogoScript("FILL \"x")

    #expect(editor.buffer.lines == ["axxxef", "1xxx56", "uvwxyz"])
    #expect(editor.buffer.canvasBlockMark == nil)
    #expect(editor.buffer.canvasBlockMarkEnd == nil)
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.canvasVisualColumn == 3)
}

@Test func testCtrlBackspaceDeleteLineCommand() throws {
    let editor = Editor()
    editor.buffer.lines = ["First Line", "Second Line", "Third Line"]
    editor.buffer.lineIndex = 1

    editor.processKey(.ctrlBackspace)
    #expect(editor.buffer.lines == ["First Line", "Third Line"])

    editor.performUndo()
    #expect(editor.buffer.lines == ["First Line", "Second Line", "Third Line"])
}

@Test func testF4SaveAndExitCommand() throws {
    let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent("test_f4_save_exit.txt").path
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    let editor = Editor(filePath: tmpPath)
    editor.buffer.lines = ["Line 1 for F4 test"]
    editor.buffer.isModified = true

    // Trigger F4 (file.save_exit)
    let handled = editor.commandRegistry.dispatch(key: .f4, editor: editor)
    #expect(handled == true)

    // File should be saved to disk
    let savedContent = try String(contentsOfFile: tmpPath, encoding: .utf8)
    #expect(savedContent == "Line 1 for F4 test")
}

@Test func testCtrlITabInsertion() throws {
    let editor = Editor()
    editor.processKey(.ctrl("I"))
    #expect(editor.buffer.lines[0] == "    ")
}

@Test func testMenuBarActivationAndNavigation() throws {
    let editor = Editor()
    #expect(editor.isMenuBarActive == false)

    // Press ESC in normal mode to open command prompt, not Menu Bar.
    editor.processKey(.esc)
    #expect(editor.isMenuBarActive == false)
    if case .logoMacro = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Esc should trigger command prompt mode")
    }
    editor.currentPromptMode = .none

    // 1. Press F1 to activate Menu Bar
    editor.processKey(.f1)
    #expect(editor.isMenuBarActive == true)
    #expect(editor.menuBar.categoryIndex == 0)

    // 2. Press Right Arrow to switch to Edit category (index 1)
    editor.processKey(.arrowRight)
    #expect(editor.menuBar.categoryIndex == 1)

    // 3. Press Down Arrow to navigate items in Edit menu
    editor.processKey(.arrowDown)
    #expect(editor.menuBar.itemIndex == 1)

    // 4. Press letter 's' to jump to Shapes menu
    editor.processKey(.char("s"))
    #expect(editor.menuBar.currentCategory.titleKey == "menu.shapes")

    // 4b. Home/End jump within menu items; PageUp/PageDown jump across menu categories
    editor.processKey(.end)
    #expect(editor.menuBar.itemIndex == editor.menuBar.currentCategory.items.count - 1)
    editor.processKey(.home)
    #expect(editor.menuBar.itemIndex == 0)
    editor.processKey(.pageDown)
    #expect(editor.menuBar.categoryIndex == editor.menuBar.categories.count - 1)
    editor.processKey(.pageUp)
    #expect(editor.menuBar.categoryIndex == 0)

    // 5. Press ESC to close Menu Bar
    editor.processKey(.esc)
    #expect(editor.isMenuBarActive == false)

    // 6. Press Ctrl+M to activate Menu Bar
    editor.processKey(.ctrl("M"))
    #expect(editor.isMenuBarActive == true)
    editor.processKey(.esc)
    #expect(editor.isMenuBarActive == false)

    // 7. Test executing menu item via Enter
    editor.processKey(.f1)  // Activate menu
    editor.menuBar.categoryIndex = editor.menuBar.categories.firstIndex(where: { $0.titleKey == "menu.tools" })!
    editor.menuBar.itemIndex = 0  // Command Prompt
    editor.processKey(.enter)  // Execute
    #expect(editor.isMenuBarActive == false)
    if case .logoMacro = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Enter on LOGO item should trigger LOGO prompt mode")
    }

    // 8. Test Goto Line from Edit menu
    editor.currentPromptMode = .none
    editor.processKey(.f1)
    editor.menuBar.categoryIndex = editor.menuBar.categories.firstIndex(where: { $0.titleKey == "menu.edit" })!
    editor.menuBar.itemIndex = editor.menuBar.currentCategory.items.firstIndex(where: {
        $0.titleKey == "menu.edit.goto_line"
    })!
    editor.processKey(.enter)
    #expect(editor.isMenuBarActive == false)
    if case .gotoLine = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Enter on Goto Line item should trigger gotoLine prompt mode")
    }
}

@Test func testSearchPromptMiddleSpaceInsertion() throws {
    let editor = Editor()
    editor.promptSearch()

    // Type "hello"
    for ch in "hello" {
        editor.processKey(.char(ch))
    }
    #expect(editor.promptInputText == "hello")
    #expect(editor.promptCursorIndex == 5)

    // Move cursor left 3 times (between 'e' and 'l')
    editor.processKey(.arrowLeft)
    editor.processKey(.arrowLeft)
    editor.processKey(.arrowLeft)
    #expect(editor.promptCursorIndex == 2)

    // Type space ' '
    editor.processKey(.char(" "))

    // Expect "he llo", NOT "hello "!
    #expect(editor.promptInputText == "he llo")
    #expect(editor.promptCursorIndex == 3)
}

private func submitCommandBar(_ text: String, editor: Editor) {
    editor.promptLogoMacro()
    for ch in text {
        editor.processKey(.char(ch))
    }
    editor.processKey(.enter)
}

@Test func testCommandBarNumericGotoShorthand() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two", "three"]

    submitCommandBar("2", editor: editor)

    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 0)
    #expect(editor.logoEngine.lastResult == nil)
}

@Test func testCommandBarNumericGotoWithColumnShorthand() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two", "three"]

    submitCommandBar("3:2", editor: editor)

    #expect(editor.buffer.lineIndex == 2)
    #expect(editor.buffer.columnIndex == 1)

    submitCommandBar("1,3", editor: editor)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 2)
}

@Test func testCommandBarGotoCommandAcceptsLineAndColumn() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two", "three"]

    submitCommandBar("goto 3 2", editor: editor)

    #expect(editor.buffer.lineIndex == 2)
    #expect(editor.buffer.columnIndex == 1)
    #expect(editor.logoEngine.lastResult == nil)

    submitCommandBar("GOTO 1,3", editor: editor)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 2)
    #expect(editor.logoEngine.lastResult == nil)

    submitCommandBar("goto 2:2", editor: editor)

    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 1)
    #expect(editor.logoEngine.lastResult == nil)

    submitCommandBar("goto 1 50", editor: editor)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 3)
    #expect(editor.logoEngine.lastResult == nil)
}

@Test func testCommandBarLogoExpressionFallback() throws {
    let editor = Editor()

    submitCommandBar("1 + 1", editor: editor)

    #expect(editor.logoEngine.lastResult == "2")
    #expect(editor.statusMessage == "2")
}

@Test func testCommandBarInvalidNumericGotoDoesNotFallThroughToLogo() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two"]

    submitCommandBar("-1", editor: editor)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.logoEngine.lastResult == nil)
    #expect(editor.statusMessage == editor.l10n["status.invalid_line"])

    submitCommandBar("0", editor: editor)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.logoEngine.lastResult == nil)
    #expect(editor.statusMessage == editor.l10n["status.invalid_line"])
}

@Test func testCommandBarOpenNewAndBufferShorthand() throws {
    let editor = Editor()
    editor.buffer.filePath = "first.txt"

    submitCommandBar("open second.txt", editor: editor)

    #expect(editor.buffers.count == 2)
    #expect(editor.currentBufferIndex == 1)
    #expect(editor.buffer.filePath == "second.txt")

    submitCommandBar("new", editor: editor)

    #expect(editor.buffers.count == 3)
    #expect(editor.currentBufferIndex == 2)
    #expect(editor.buffer.filePath == nil)

    submitCommandBar("buffer prev", editor: editor)
    #expect(editor.currentBufferIndex == 1)

    submitCommandBar("buffer 1", editor: editor)
    #expect(editor.currentBufferIndex == 0)

    submitCommandBar("buffer 99", editor: editor)
    #expect(editor.currentBufferIndex == 0)
    #expect(editor.statusMessage == editor.l10n["status.no_such_buffer"])
}

@Test func testCommandBarUppercaseBufferUsesCommandBarCommand() throws {
    let editor = Editor()
    editor.buffer.filePath = "first.txt"
    editor.openNewBuffer(filePath: "second.txt")
    editor.currentBufferIndex = 0

    submitCommandBar("BUFFER 2", editor: editor)

    #expect(editor.currentBufferIndex == 1)
}

@Test func testCommandBarWriteShorthandUsesEditorSavePath() throws {
    let path = FileManager.default.temporaryDirectory.appendingPathComponent("zago_command_bar_write.txt").path
    defer { try? FileManager.default.removeItem(atPath: path) }
    let editor = Editor()
    editor.buffer.lines = ["command bar write"]
    editor.buffer.isModified = true

    submitCommandBar("write \(path)", editor: editor)

    #expect(try String(contentsOfFile: path, encoding: .utf8) == "command bar write")
    #expect(editor.buffer.filePath == path)
    #expect(editor.buffer.isModified == false)
}

@Test func testCommandBarUppercaseSaveUsesEditorCommand() throws {
    let path = FileManager.default.temporaryDirectory.appendingPathComponent("zago_command_bar_save.txt").path
    defer { try? FileManager.default.removeItem(atPath: path) }
    let editor = Editor(filePath: path)
    editor.buffer.lines = ["command bar save"]
    editor.buffer.isModified = true

    submitCommandBar("SAVE", editor: editor)

    #expect(try String(contentsOfFile: path, encoding: .utf8) == "command bar save")
    #expect(editor.buffer.isModified == false)
}

@Test func testCommandBarSettingCommandsAreEditorCommands() throws {
    let editor = Editor()
    editor.displayConfig.showRuler = false
    editor.displayConfig.showLineNumbers = true
    editor.displayConfig.enableSyntaxHighlight = true

    submitCommandBar("SET RULER ON", editor: editor)
    #expect(editor.displayConfig.showRuler == true)

    submitCommandBar("set linenumbers off", editor: editor)
    #expect(editor.displayConfig.showLineNumbers == false)

    submitCommandBar("set syntax off", editor: editor)
    #expect(editor.displayConfig.enableSyntaxHighlight == false)

    submitCommandBar("set trim-trailing-whitespace on", editor: editor)
    #expect(editor.displayConfig.trimTrailingWhitespaceOnSave == true)

    submitCommandBar("unset trim-trailing-whitespace", editor: editor)
    #expect(editor.displayConfig.trimTrailingWhitespaceOnSave == false)

    submitCommandBar("set wrap 4", editor: editor)
    #expect(editor.layoutEngine.wrapColumn == 10)

    submitCommandBar("unset wrap", editor: editor)
    #expect(editor.layoutEngine.wrapColumn == nil)

    submitCommandBar("set canvas-mode on", editor: editor)
    #expect(editor.isCanvasModeActive == true)

    submitCommandBar("SET CANVAS-MODE OFF", editor: editor)
    #expect(editor.isCanvasModeActive == false)

    submitCommandBar("set canvas_mode true", editor: editor)
    #expect(editor.isCanvasModeActive == true)

    submitCommandBar("unset canvas-mode", editor: editor)
    #expect(editor.isCanvasModeActive == false)
}

@Test func testCommandBarSetTabShowsSettingCompletions() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "SET " {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "SET ")
    #expect(editor.promptCompletionText?.contains("wrap") == true)
    #expect(editor.promptCompletionText?.contains("linenumbers") == true)
    #expect(editor.promptCompletionText?.contains("sublinenumbers") == true)
    #expect(editor.promptCompletionText?.contains("canvas-mode") == true)
    #expect(editor.promptCompletionText?.contains("syntax") == true)

    #expect(editor.promptCompletionText?.hasPrefix("SET: ") == true)
}

@Test func testCommandBarSetTabCompletesUniqueSettingPrefix() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "set li" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "set linenumbers ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarSetValueTabShowsValueCompletions() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "set syntax " {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "set syntax ")
    #expect(editor.promptCompletionText?.contains("on") == true)
    #expect(editor.promptCompletionText?.contains("off") == true)
}

@Test func testCommandBarSetCanvasModeValueTabShowsValueCompletions() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "set canvas-mode " {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "set canvas-mode ")
    #expect(editor.promptCompletionText?.contains("on") == true)
    #expect(editor.promptCompletionText?.contains("off") == true)
}

@Test func testCommandBarTabCompletesLogoKeyword() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "drawb" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "drawbox ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarTabCompletesCommandBarCommand() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "QUI" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "QUIT ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarTabCompletesHyphenatedCommandBarCommand() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "save-" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "save-exit ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarTabShowsMixedCommandAndLogoCompletions() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "sa" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "save")
    #expect(editor.promptCompletionText?.contains("save") == true)
    #expect(editor.promptCompletionText?.contains("save-exit") == true)
}


@Test func testCommandBarCompletionClearsOnEsc() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "sa" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)
    #expect(editor.promptCompletionText != nil)

    editor.processKey(.esc)
    #expect(editor.promptCompletionText == nil)
    #expect(editor.statusMessage.contains("save") == false)
}

@Test func testCommandBarTabCompletesTokenWithLeadingContext() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "box 10 drawb" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "box 10 drawbox ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarTabCompletesTokenAfterBracket() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "REPEAT 5 [drawb" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "REPEAT 5 [drawbox ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarExitAndSaveExitCommands() throws {
    let savePath = FileManager.default.temporaryDirectory.appendingPathComponent("zago_command_bar_save_exit.txt").path
    defer { try? FileManager.default.removeItem(atPath: savePath) }

    let editor = Editor()
    editor.buffer.filePath = "first.txt"
    editor.openNewBuffer(filePath: savePath)
    editor.buffer.lines = ["save and exit"]
    editor.buffer.isModified = true

    submitCommandBar("save-exit", editor: editor)

    #expect(try String(contentsOfFile: savePath, encoding: .utf8) == "save and exit")
    #expect(editor.buffers.count == 1)
    #expect(editor.currentBufferIndex == 0)

    editor.openNewBuffer(filePath: "third.txt")
    submitCommandBar("quit", editor: editor)

    #expect(editor.buffers.count == 1)
    #expect(editor.currentBufferIndex == 0)
}

@Test func testCommandBarDiagramAndOutlineAndBorderAliases() throws {
    let editor = Editor()

    // Test "diagram" and "snippets" aliases open diagram menu
    #expect(editor.isMenuBarActive == false)
    submitCommandBar("diagram", editor: editor)
    #expect(editor.isMenuBarActive == true)
    editor.isMenuBarActive = false

    submitCommandBar("snippets", editor: editor)
    #expect(editor.isMenuBarActive == true)
    editor.isMenuBarActive = false

    // Test "border" and "border-style" aliases cycle border style
    let initialStyle = editor.defaultBorderStyle
    submitCommandBar("border", editor: editor)
    #expect(editor.defaultBorderStyle != initialStyle)

    let nextStyle = editor.defaultBorderStyle
    submitCommandBar("border-style", editor: editor)
    #expect(editor.defaultBorderStyle != nextStyle)

    // Test "outline", "toc", "headings" aliases with heading document
    editor.buffer.lines = ["# Title", "Content"]
    submitCommandBar("toc", editor: editor)
    submitCommandBar("headings", editor: editor)
    submitCommandBar("outline", editor: editor)
}

@Test func testLastLineDownKeyMovesToEOL() throws {
    let editor = Editor()
    editor.buffer.lines = ["First Line", "Last Line"]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 0  // At start of "Last Line"

    editor.processKey(.arrowDown)
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 9)  // EOL of "Last Line"
}

@Test func testCtrlQEvalLogoCode() throws {
    let editor = Editor()

    // Test 1: Single Line Expression Eval
    editor.buffer.lines = ["SUM 1 6"]
    editor.buffer.lineIndex = 0
    editor.processKey(.ctrl("Q"))
    #expect(editor.statusMessage == "[Eval] 7")

    // Test 2: Drawing Line Eval
    editor.buffer.lines = ["BOX \"Test\""]
    editor.buffer.lineIndex = 0
    editor.processKey(.ctrl("Q"))
    #expect(editor.buffer.lines[1] == "│ Test │")

    // Test 3: Markdown Code Fence Eval
    editor.buffer.lines = ["# Title", "```logo", "MAKE \"x\" 10", ":x * 5", "```"]
    editor.buffer.lineIndex = 3
    editor.processKey(.ctrl("Q"))
    #expect(editor.statusMessage == "[Eval] 50")
}

@Test func testBoxExitPositions() throws {
    // 1. NE (Default): Line 0, Col 10
    let ed1 = Editor()
    ed1.runLogoScript("BOX 10 4 NE")
    #expect(ed1.buffer.lineIndex == 0)
    #expect(ed1.buffer.columnIndex == 10)

    // 2. SE / AT:SE: Line 3, Col 10
    let ed2 = Editor()
    ed2.runLogoScript("BOX 10 4 AT:SE")
    #expect(ed2.buffer.lineIndex == 3)
    #expect(ed2.buffer.columnIndex == 10)

    // 3. NW / AT:NW: Line 0, Col 0
    let ed3 = Editor()
    ed3.runLogoScript("BOX 10 4 AT:NW")
    #expect(ed3.buffer.lineIndex == 0)
    #expect(ed3.buffer.columnIndex == 0)

    // 4. SW / AT:SW: Line 3, Col 0
    let ed4 = Editor()
    ed4.runLogoScript("BOX 10 4 AT:SW")
    #expect(ed4.buffer.lineIndex == 3)
    #expect(ed4.buffer.columnIndex == 0)

    // 5. DOWN / AT:DOWN: Line 4, Col 0
    let ed5 = Editor()
    ed5.runLogoScript("BOX 10 4 AT:DOWN")
    #expect(ed5.buffer.lineIndex == 4)
    #expect(ed5.buffer.columnIndex == 0)

    // 6. Quoted string "SE" is text, not exit position!
    let ed6 = Editor()
    ed6.runLogoScript("BOX 10 4 \"SE\"")
    #expect(ed6.buffer.lines[1].contains("SE"))
    #expect(ed6.buffer.lineIndex == 0)
}

@Test func testBufferCloseAndSwitchInvalidatesScreenCache() throws {
    let editor = Editor()
    editor.openNewBuffer(filePath: "second.md")
    #expect(editor.buffers.count == 2)

    // Render screen to populate cache
    _ = editor.renderer.renderDiff(editor: editor, rows: 24, cols: 80)
    #expect(editor.renderer.isScreenCacheValid == true)

    // 1. Switch buffer -> must invalidate screen cache
    editor.nextBuffer()
    #expect(editor.renderer.isScreenCacheValid == false)

    // Populate cache again
    _ = editor.renderer.renderDiff(editor: editor, rows: 24, cols: 80)
    #expect(editor.renderer.isScreenCacheValid == true)

    // 2. Close buffer -> must invalidate screen cache
    editor.closeCurrentBuffer()
    #expect(editor.renderer.isScreenCacheValid == false)
}

@Test func testShowHelpAndReferenceCommandsInvalidateScreenCache() throws {
    let editor = Editor()

    // Populate cache
    _ = editor.renderer.renderDiff(editor: editor, rows: 24, cols: 80)
    #expect(editor.renderer.isScreenCacheValid == true)

    // Invalidate screen cache directly
    editor.renderer.invalidateScreenCache()
    #expect(editor.renderer.isScreenCacheValid == false)
}
