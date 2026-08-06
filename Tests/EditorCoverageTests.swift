import Foundation
import Testing

@testable import Config
@testable import Editor
@testable import LogoEngine

private final class QueuedEditorTerminal: EditorTerminal, @unchecked Sendable {
    private var keys: [Key]

    init(keys: [Key]) {
        self.keys = keys
    }

    func enableRawMode() throws {}
    func disableRawMode() {}
    func getWindowSize() -> (rows: Int, cols: Int) { (24, 80) }
    func readKey() -> Key { keys.isEmpty ? .esc : keys.removeFirst() }
    func readPendingText(firstChar: Character) -> String { String(firstChar) }
    func write(_ text: String) {}
    func hideCursor() {}
    func showCursor() {}
    func clearScreen() {}
}

private func typePrompt(_ text: String, in editor: Editor) {
    for ch in text {
        editor.processPromptKey(.char(ch))
    }
}

private func makeEditor(
    fileIO: EditorFileIOStrategy = TestLocalEditorFileIOStrategy.shared,
    terminal: EditorTerminal = TestEditorTerminal.shared,
    filePaths: [String] = []
) -> Editor {
    Editor(
        options: EditorOptions(filePaths: filePaths, autoReload: false, language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: terminal)
    )
}

@Suite struct EditorCoverageTests {
    @Test func testSavePathPromptEditingAndTrimming() {
        let editor = Editor(language: .en)
        var savedPath: String?

        editor.currentPromptMode = .saveFilePath(completion: { savedPath = $0 })

        typePrompt("old", in: editor)
        editor.processPromptKey(.ctrl("U"))
        #expect(editor.promptInputText.isEmpty)

        typePrompt("  draft.txt  ", in: editor)
        editor.processPromptKey(.home)
        #expect(editor.promptCursorIndex == 0)
        editor.processPromptKey(.end)
        #expect(editor.promptCursorIndex == editor.promptInputText.count)
        editor.processPromptKey(.arrowLeft)
        editor.processPromptKey(.delete)
        editor.processPromptKey(.backspace)
        editor.processPromptKey(.enter)

        #expect(savedPath == "draft.txt")
        if case .none = editor.currentPromptMode {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }

    @Test func testLogoPromptWordNavigationAndCancellation() {
        let editor = Editor(language: .en)

        editor.promptLogoMacro()
        typePrompt("alpha 測 beta", in: editor)

        editor.processPromptKey(.ctrlShift("B"))
        #expect(editor.promptCursorIndex == "alpha 測 ".count)
        editor.processPromptKey(.ctrlShift("B"))
        #expect(editor.promptCursorIndex == "alpha ".count)
        editor.processPromptKey(.ctrlShift("F"))
        #expect(editor.promptCursorIndex == "alpha 測".count)
        editor.processPromptKey(.ctrlShift("F"))
        #expect(editor.promptCursorIndex == "alpha 測 beta".count)

        editor.promptCompletionText = "Tab: beta"
        editor.processPromptKey(.esc)

        #expect(editor.promptInputText.isEmpty)
        #expect(editor.promptCompletionText == nil)
        #expect(editor.statusMessage == editor.l10n["status.cancelled"])
    }

    @Test func testSearchPromptRepeatsLastQueryAndCancels() {
        let editor = Editor(language: .en)
        editor.buffer.lines = ["zero", "alpha here", "alpha again"]
        editor.lastSearchQuery = "alpha"

        editor.promptSearch()
        editor.processPromptKey(.enter)

        #expect(editor.buffer.lineIndex == 1)
        #expect(editor.buffer.columnIndex == 0)
        #expect(editor.activeSearchMatch?.query == "alpha")

        editor.promptSearch()
        editor.processKey(.esc)
        #expect(editor.statusMessage == editor.l10n["status.cancelled_search"])
    }

    @Test func testExitPromptsHandleCancellationAndClosing() {
        let fileIO = MemoryEditorFileIOStrategy(files: ["/doc.txt": "old"])

        let cancelEditor = makeEditor(fileIO: fileIO, filePaths: ["/doc.txt"])
        cancelEditor.buffer.lines = ["changed"]
        cancelEditor.buffer.isModified = true
        cancelEditor.promptExitSaveConfirm()
        cancelEditor.processKey(.esc)
        #expect(cancelEditor.statusMessage == cancelEditor.l10n["status.cancelled_exit"])
        #expect(cancelEditor.isRunning == true)

        let closeEditor = makeEditor(fileIO: fileIO, filePaths: ["/doc.txt"])
        closeEditor.buffer.lines = ["changed"]
        closeEditor.buffer.isModified = true
        closeEditor.promptExitSaveConfirm()
        closeEditor.processKey(.char("n"))
        #expect(closeEditor.isRunning == false)

        let unsavedEditor = makeEditor(fileIO: fileIO)
        unsavedEditor.buffer.lines = ["draft"]
        unsavedEditor.buffer.isModified = true
        unsavedEditor.promptSaveAndExit()
        if case .saveFilePath = unsavedEditor.currentPromptMode {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "promptSaveAndExit should ask for a path when the buffer is unnamed")
        }
        unsavedEditor.processKey(.ctrl("G"))
        #expect(unsavedEditor.isRunning == true)
        #expect(unsavedEditor.statusMessage == unsavedEditor.l10n["status.cancelled"])
    }

    @Test func testInsertFilePromptSuccessErrorAndCancellation() {
        let fileIO = MemoryEditorFileIOStrategy(files: ["/snippet.txt": "AA\nBB"])
        let editor = makeEditor(fileIO: fileIO)

        editor.promptInsertFilePath()
        typePrompt("/snippet.txt", in: editor)
        editor.processPromptKey(.enter)

        #expect(editor.buffer.lines == ["AA", "BB"])
        #expect(editor.statusMessage == editor.l10n.insertedLines(2))

        editor.promptInsertFilePath()
        typePrompt("/missing.txt", in: editor)
        editor.processPromptKey(.enter)
        #expect(editor.statusMessage.contains("MemoryEditorFileIOStrategy"))

        editor.promptInsertFilePath()
        editor.processKey(.esc)
        #expect(editor.statusMessage == editor.l10n["status.cancelled_insert"])
    }

    @Test func testFillTextPromptAndGotoLineInCanvasMode() {
        let editor = Editor(language: .en)
        editor.buffer.lines = ["abcdef", "uvwxyz"]
        editor.switchToCanvasMode()

        editor.buffer.lineIndex = 0
        editor.canvasVisualColumn = 1
        editor.processKey(.mark)
        editor.buffer.lineIndex = 1
        editor.canvasVisualColumn = 3
        editor.processKey(.mark)

        editor.promptFillText()
        editor.processPromptKey(.char("\""))
        editor.processPromptKey(.enter)

        #expect(editor.buffer.lines == ["a'''ef", "u'''yz"])
        #expect(editor.statusMessage == editor.l10n["status.filled_block"])

        editor.promptGotoLine()
        typePrompt("2, 5", in: editor)
        editor.processPromptKey(.enter)

        #expect(editor.buffer.lineIndex == 1)
        #expect(editor.canvasVisualColumn == 4)
    }

    @Test func testTableDimensionsPromptInMarkdownAndOrgMode() {
        let markdownEditor = Editor(language: .en)
        markdownEditor.buffer.filePath = "notes.md"
        markdownEditor.promptTableDimensions()
        markdownEditor.promptInputText = "2 2"
        markdownEditor.promptCursorIndex = markdownEditor.promptInputText.count
        markdownEditor.processPromptKey(.enter)

        #expect(markdownEditor.buffer.lines[0] == "| Header 1 | Header 2 |")
        #expect(markdownEditor.buffer.lines[1] == "| -------- | -------- |")
        #expect(markdownEditor.buffer.lines[2] == "| Cell 1.1 | Cell 1.2 |")
        #expect(markdownEditor.buffer.lines[3] == "| Cell 2.1 | Cell 2.2 |")

        let orgEditor = Editor(language: .en)
        orgEditor.buffer.filePath = "notes.org"
        orgEditor.promptTableDimensions()
        orgEditor.promptInputText = "1 2"
        orgEditor.promptCursorIndex = orgEditor.promptInputText.count
        orgEditor.processPromptKey(.enter)

        #expect(orgEditor.buffer.lines[0] == "| Header 1 | Header 2 |")
        #expect(orgEditor.buffer.lines[1] == "|----------+----------|")
        #expect(orgEditor.buffer.lines[2] == "| Cell 1.1 | Cell 1.2 |")
    }

    @Test func testInteractiveLogoReadWordAndReadChar() {
        let wordTerminal = QueuedEditorTerminal(keys: [
            .char("h"), .char("e"), .char("l"), .char("l"), .char("o"),
            .arrowLeft, .backspace, .char("a"), .end, .char("!"), .enter,
        ])
        let wordEditor = makeEditor(terminal: wordTerminal)
        wordEditor.isInteractiveMode = true
        let wordDelegate: LogoEngineDelegate = wordEditor

        let word = wordDelegate.logoEngine(wordEditor.logoEngine, readWordWithPrompt: "? ")
        #expect(word == "helao!")
        if case .none = wordEditor.currentPromptMode {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }

        let newlineTerminal = QueuedEditorTerminal(keys: [.resize, .unknown, .enter])
        let newlineEditor = makeEditor(terminal: newlineTerminal)
        newlineEditor.isInteractiveMode = true
        let newlineDelegate: LogoEngineDelegate = newlineEditor
        #expect(newlineDelegate.logoEngine(newlineEditor.logoEngine, readCharWithPrompt: "?") == "\n")

        let charTerminal = QueuedEditorTerminal(keys: [.char("Z")])
        let charEditor = makeEditor(terminal: charTerminal)
        charEditor.isInteractiveMode = true
        let charDelegate: LogoEngineDelegate = charEditor
        #expect(charDelegate.logoEngine(charEditor.logoEngine, readCharWithPrompt: "?") == "Z")
    }

    @Test func testLogoDelegateActionsMutateEditorState() {
        let editor = Editor(language: .en)
        let delegate: LogoEngineDelegate = editor

        editor.buffer.lines = ["中ab"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0

        delegate.logoEngine(editor.logoEngine, performAction: .updateColumnIndex(5))
        #expect(editor.buffer.columnIndex == 4)

        delegate.logoEngine(editor.logoEngine, performAction: .updateLineIndex(2))
        #expect(editor.buffer.lineIndex == 2)
        #expect(editor.buffer.lines.count == 3)

        delegate.logoEngine(editor.logoEngine, performAction: .ensureLineExists(index: 4))
        #expect(editor.buffer.lines.count == 5)

        delegate.logoEngine(editor.logoEngine, performAction: .setLine(index: 4, text: "tail"))
        #expect(editor.buffer.lines[4] == "tail")

        delegate.logoEngine(editor.logoEngine, performAction: .setBorderStyle("bogus"))
        #expect(editor.statusMessage == editor.l10n.unknownTableBorder("bogus"))

        delegate.logoEngine(editor.logoEngine, performAction: .setBorderStyle("double"))
        #expect(editor.defaultBorderStyle == .double)

        delegate.logoEngine(editor.logoEngine, performAction: .markModified)
        #expect(editor.buffer.isModified == true)

        delegate.logoEngine(editor.logoEngine, performAction: .clearBuffer)
        #expect(editor.buffer.lines == [""])
        #expect(editor.buffer.lineIndex == 0)
        #expect(editor.buffer.columnIndex == 0)
    }

    @Test func testLogoDelegateQueriesReflectSelectionsBuffersAndModes() throws {
        let editor = Editor(filePath: "first.txt", language: .en)
        editor.openNewBuffer(filePath: "second.txt")
        editor.currentBufferIndex = 0
        editor.buffer.lines = ["A中B", "tail"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 4
        editor.buffer.isModified = true

        let delegate: LogoEngineDelegate = editor

        #expect(delegate.logoEngine(editor.logoEngine, queryState: .currentColumnIndex) as? Int == 5)
        #expect(delegate.logoEngine(editor.logoEngine, queryState: .bufferList) as? [String] == ["first.txt", "second.txt"])
        #expect(delegate.logoEngine(editor.logoEngine, queryState: .currentBufferIndex) as? Int == 0)
        #expect(delegate.logoEngine(editor.logoEngine, queryState: .bufferText) as? String == "A中B\ntail")
        #expect(delegate.logoEngine(editor.logoEngine, queryState: .isModified) as? Bool == true)
        #expect(delegate.logoEngine(editor.logoEngine, queryState: .fileName) as? String == "first.txt")

        editor.selectionMark = (line: 0, column: 1)
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 2
        #expect(delegate.logoEngine(editor.logoEngine, queryState: .selectionText) as? String == "中")

        editor.selectionMark = (line: 0, column: 0)
        editor.buffer.lineIndex = 1
        editor.buffer.columnIndex = 4
        #expect(delegate.logoEngine(editor.logoEngine, queryState: .selectionText) as? String == "A中B\ntail")

        editor.switchToCanvasMode()
        editor.buffer.lineIndex = 0
        editor.canvasVisualColumn = 1
        editor.processKey(.mark)
        editor.canvasVisualColumn = 3
        editor.processKey(.mark)

        #expect(delegate.logoEngine(editor.logoEngine, queryState: .hasCanvasBlockMark) as? Bool == true)
        #expect(
            delegate.logoEngine(editor.logoEngine, queryState: .canvasBlockFrame) as? LogoCanvasBlockFrame
                == LogoCanvasBlockFrame(lineIndex: 0, visualColumn: 1, width: 3, height: 1)
        )

        let tableEditor = Editor(language: .en)
        tableEditor.createTable(rows: 1, cols: 1, cellWidth: 3, enterMode: true, saveSnapshot: false)
        let tableDelegate: LogoEngineDelegate = tableEditor
        #expect(tableDelegate.logoEngine(tableEditor.logoEngine, queryState: .hasTableCell) as? Bool == true)
        #expect(tableDelegate.logoEngine(tableEditor.logoEngine, queryState: .defaultBorderStyle) as? BorderStyle == .single)
    }

    @Test func testRunLogoScriptUsesStatusesAndBlocksTableOnlyPrimitives() {
        let editor = Editor(language: .en)

        #expect(editor.runLogoScript("SUM 1 2", resultPrefix: "[R] ", successStatus: "ok") == true)
        #expect(editor.statusMessage == "[R] 3")

        #expect(editor.runLogoScript("MAKE \"v 1", successStatus: "done") == true)
        #expect(editor.statusMessage == "done")

        let tableEditor = Editor(language: .en)
        tableEditor.logoEngine.execute("TO BOXIT BOX 1 1 END")
        tableEditor.createTable(rows: 1, cols: 1, cellWidth: 3, enterMode: true, saveSnapshot: false)

        #expect(tableEditor.runLogoScript("BOXIT") == false)
        #expect(tableEditor.statusMessage == tableEditor.l10n.disabledInTableMode("BOX"))

        #expect(tableEditor.runLogoScript("GOTO 1 1") == false)
        #expect(tableEditor.statusMessage == tableEditor.l10n.disabledInTableMode("GOTO"))
    }
}
