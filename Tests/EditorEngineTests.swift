import Foundation
import Testing
import TextMetrics

@testable import Editor

@Test func testBufferCoordinatorMaintainsActiveBufferAndClampsIndex() throws {
    let first = TextBuffer()
    let second = TextBuffer()
    let coordinator = BufferCoordinator(buffers: [first, second])

    #expect(coordinator.count == 2)
    #expect(coordinator.activeIndex == 0)
    #expect(coordinator.activeBuffer.id == first.id)

    coordinator.activeIndex = 99
    #expect(coordinator.activeIndex == 1)
    #expect(coordinator.activeBuffer.id == second.id)

    coordinator.activeIndex = -4
    #expect(coordinator.activeIndex == 0)
    #expect(coordinator.activeBuffer.id == first.id)

    let third = TextBuffer()
    coordinator.appendAndActivate(third)
    #expect(coordinator.count == 3)
    #expect(coordinator.activeIndex == 2)
    #expect(coordinator.activeBuffer.id == third.id)

    #expect(coordinator.nextIndex() == 0)
    #expect(coordinator.previousIndex() == 1)

    #expect(coordinator.removeActive() == true)
    #expect(coordinator.count == 2)
    #expect(coordinator.activeIndex == 1)
    #expect(coordinator.activeBuffer.id == second.id)
}

@Test func testBufferCoordinatorNeverExposesEmptyStorage() throws {
    let coordinator = BufferCoordinator(buffers: [])

    #expect(coordinator.count == 1)
    #expect(coordinator.activeIndex == 0)
    #expect(coordinator.activeBuffer.lines == [""])

    coordinator.buffers = []
    #expect(coordinator.count == 1)
    #expect(coordinator.activeIndex == 0)

    #expect(coordinator.removeActive() == false)
    #expect(coordinator.count == 1)
    #expect(coordinator.activeIndex == 0)

    let replacement = TextBuffer()
    coordinator.buffers = [replacement]
    #expect(coordinator.count == 1)
    #expect(coordinator.activeBuffer.id == replacement.id)
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

@Test func testCtrlShiftZRedoesUndoAndNewEditClearsRedo() throws {
    let editor = Editor()

    editor.processKey(.char("a"))
    editor.processKey(.char("b"))
    #expect(editor.buffer.lines[0] == "ab")

    editor.processKey(.ctrl("z"))
    #expect(editor.buffer.lines[0] == "a")

    editor.processKey(.ctrlShift("z"))
    #expect(editor.buffer.lines[0] == "ab")

    editor.processKey(.ctrl("z"))
    editor.processKey(.char("c"))
    editor.processKey(.ctrlShift("z"))
    #expect(editor.buffer.lines[0] == "ac")
}

@Test func testSwitchingBufferPreservesPerBufferUndoHistory() throws {
    let editor = Editor()
    editor.openNewBuffer()
    let buf0Index = 0
    let buf1Index = 1

    editor.switchToBuffer(index: buf0Index)
    editor.saveUndoSnapshot()
    editor.buffer.insertString("Buffer 0 Initial")
    editor.saveUndoSnapshot()
    editor.buffer.insertString(" - Edit 1")

    editor.switchToBuffer(index: buf1Index)
    editor.saveUndoSnapshot()
    editor.buffer.insertString("Buffer 1 Initial")
    editor.saveUndoSnapshot()
    editor.buffer.insertString(" - Edit 2")

    // Undo on Buffer 1
    editor.performUndo()
    #expect(editor.buffer.lines[0] == "Buffer 1 Initial")

    // Switch back to Buffer 0 and Undo
    editor.switchToBuffer(index: buf0Index)
    #expect(editor.buffer.lines[0] == "Buffer 0 Initial - Edit 1")
    editor.performUndo()
    #expect(editor.buffer.lines[0] == "Buffer 0 Initial")
}

@Test func testCommandRegistry() throws {
    let editor = Editor()
    #expect(editor.commandRegistry.commands.count > 20)

    var executed = false
    let testCmd = BlockCommand(id: .testCmd, name: "Test", description: "Test command") { _ in
        executed = true
    }
    let registry = CommandRegistry()
    registry.register(testCmd)
    registry.bind(key: .ctrl("T"), command: testCmd)

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
    #expect(editor.buffer.filePath == editor.fileIOStrategy.normalizePath(targetPath, isDirectory: false))
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
    #expect(editor.buffer.filePath == editor.fileIOStrategy.normalizePath(indexPath, isDirectory: false))
    #expect(editor.buffer.lines == ["See [this](./index.md#section)", "unchanged"])
    #expect(editor.statusMessage == String(format: editor.l10n["status.jumped_to_anchor"], "section"))
}

@Test func testAnchorLinkJumpsWithinSameFile() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("zago_anchor_jump_\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    // 1. Markdown Anchor Jump
    let mdPath = directory.appendingPathComponent("doc.md").path
    let mdEditor = Editor(filePath: mdPath)
    defer { mdEditor.stopFileWatcherForCurrentBuffer() }
    mdEditor.buffer.lines = [
        "Link to [Installation](#installation-guide)",
        "",
        "## Installation Guide",
        "Details here",
    ]
    mdEditor.buffer.lineIndex = 0
    mdEditor.buffer.columnIndex = 12
    let mdHandled = mdEditor.commandRegistry.dispatch(key: .alt("o"), editor: mdEditor)
    #expect(mdHandled == true)
    #expect(mdEditor.buffer.lineIndex == 2)

    // 2. Org-mode Anchor Jump
    let orgPath = directory.appendingPathComponent("doc.org").path
    let orgEditor = Editor(filePath: orgPath)
    defer { orgEditor.stopFileWatcherForCurrentBuffer() }
    orgEditor.buffer.lines = [
        "Jump to [[#my-custom-id]]",
        "",
        "* Setup Section",
        ":PROPERTIES:",
        ":CUSTOM_ID: my-custom-id",
        ":END:",
    ]
    orgEditor.buffer.lineIndex = 0
    orgEditor.buffer.columnIndex = 10
    let orgHandled = orgEditor.commandRegistry.dispatch(key: .alt("o"), editor: orgEditor)
    #expect(orgHandled == true)
    #expect(orgEditor.buffer.lineIndex == 4)

    // 3. reStructuredText Anchor Jump
    let rstPath = directory.appendingPathComponent("doc.rst").path
    let rstEditor = Editor(filePath: rstPath)
    defer { rstEditor.stopFileWatcherForCurrentBuffer() }
    rstEditor.buffer.lines = [
        "See `Quickstart`_",
        "",
        ".. _Quickstart:",
        "",
        "Quickstart Title",
        "================",
    ]
    rstEditor.buffer.lineIndex = 0
    rstEditor.buffer.columnIndex = 5
    let rstHandled = rstEditor.commandRegistry.dispatch(key: .alt("o"), editor: rstEditor)
    #expect(rstHandled == true)
    #expect(rstEditor.buffer.lineIndex == 2)

    // 4. AsciiDoc Anchor Jump
    let adocPath = directory.appendingPathComponent("doc.adoc").path
    let adocEditor = Editor(filePath: adocPath)
    defer { adocEditor.stopFileWatcherForCurrentBuffer() }
    adocEditor.buffer.lines = [
        "See <<intro-section,Intro>>",
        "",
        "[[intro-section]]",
        "== Introduction",
    ]
    adocEditor.buffer.lineIndex = 0
    adocEditor.buffer.columnIndex = 6
    let adocHandled = adocEditor.commandRegistry.dispatch(key: .alt("o"), editor: adocEditor)
    #expect(adocHandled == true)
    #expect(adocEditor.buffer.lineIndex == 2)
}

@Test func testSaveKeySavesExistingFileWithoutPrompt() throws {
    let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent(
        "zago_direct_save_test_\(UUID().uuidString).txt"
    ).path
    let normalizedPath = TestLocalEditorFileIOStrategy().normalizePath(tmpPath, isDirectory: false)
    defer {
        try? FileManager.default.removeItem(atPath: normalizedPath)
    }

    let editor = Editor(filePath: normalizedPath)
    editor.displayConfig.autoReload = false
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

@Test func testTextModeGotoDoesNotAutoExtendBuffer() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two"]

    editor.goToLocation(line: 100, column: 2)

    #expect(editor.buffer.lines.count == 2)
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 1)
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
    #expect(rendered.contains("\u{1B}[7m \u{1B}[m"))
    #expect(!rendered.contains("\u{1B}[7m                   \u{1B}[m"))

    editor.processKey(.char("X"))
    #expect(editor.buffer.selectionMark == nil)
    #expect(editor.buffer.lines == ["aXdef"])
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
    let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent(
        "test_f4_save_exit_\(UUID().uuidString).txt"
    ).path
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

    // 4b. PageUp/PageDown jump within menu items (vertical dropdown list); Home/End jump across menu categories (horizontal bar)
    editor.processKey(.pageDown)
    #expect(editor.menuBar.itemIndex == editor.menuBar.currentCategory.items.count - 1)
    editor.processKey(.pageUp)
    #expect(editor.menuBar.itemIndex == 0)
    editor.processKey(.end)
    #expect(editor.menuBar.categoryIndex == editor.menuBar.categories.count - 1)
    editor.processKey(.home)
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
    editor.menuBar.itemIndex = editor.menuBar.currentCategory.items.firstIndex(where: {
        $0.titleKey == "menu.tools.logo"
    })!
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

@Test func testJoinLineAndSplitLineCommands() throws {
    let editor = Editor()
    editor.buffer.lines = ["hello", "world", "again"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 2

    _ = editor.commandRegistry.dispatch(id: .editJoinLine, editor: editor)
    #expect(editor.buffer.lines == ["hello world", "again"])
    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 6)

    editor.buffer.columnIndex = 5
    _ = editor.commandRegistry.dispatch(id: .editSplitLine, editor: editor)
    #expect(editor.buffer.lines == ["hello", " world", "again"])
    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 0)
}
