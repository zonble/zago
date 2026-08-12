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
        editor.processKey(.char(ch))
    }
}

private func makeEditor(
    fileIO: EditorFileIOStrategy = TestLocalEditorFileIOStrategy.shared,
    terminal: EditorTerminal = TestEditorTerminal.shared,
    filePaths: [String] = []
) -> Editor {
    Editor(
        options: EditorOptions(filePaths: filePaths, autoReload: false, language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: terminal),
        initialVariables: [:]
    )
}

@Suite struct EditorCoverageTests {
    @Test func testSavePathPromptEditingAndTrimming() {
        let editor = Editor(language: .en)
        var savedPath: String?

        editor.currentPromptMode = .saveFilePath(completion: { savedPath = $0 })

        typePrompt("old", in: editor)
        editor.processKey(.ctrl("U"))
        #expect(editor.promptInputText.isEmpty)

        typePrompt("  draft.txt  ", in: editor)
        editor.processKey(.home)
        #expect(editor.promptCursorIndex == 0)
        editor.processKey(.end)
        #expect(editor.promptCursorIndex == editor.promptInputText.count)
        editor.processKey(.arrowLeft)
        editor.processKey(.delete)
        editor.processKey(.backspace)
        editor.processKey(.enter)

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

        editor.processKey(.ctrlShift("B"))
        #expect(editor.promptCursorIndex == "alpha 測 ".count)
        editor.processKey(.ctrlShift("B"))
        #expect(editor.promptCursorIndex == "alpha ".count)
        editor.processKey(.ctrlShift("F"))
        #expect(editor.promptCursorIndex == "alpha 測".count)
        editor.processKey(.ctrlShift("F"))
        #expect(editor.promptCursorIndex == "alpha 測 beta".count)

        editor.promptCompletionText = "Tab: beta"
        editor.processKey(.esc)

        #expect(editor.promptInputText.isEmpty)
        #expect(editor.promptCompletionText == nil)
        #expect(editor.statusMessage == editor.l10n["status.cancelled"])
    }

    @Test func testSearchPromptRepeatsLastQueryAndCancels() {
        let editor = Editor(language: .en)
        editor.buffer.lines = ["zero", "alpha here", "alpha again"]
        editor.lastSearchQuery = "alpha"

        editor.promptSearch()
        editor.processKey(.enter)

        #expect(editor.buffer.lineIndex == 1)
        #expect(editor.buffer.columnIndex == 0)
        #expect(editor.buffer.activeSearchMatch?.query == "alpha")

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

    @Test func testCtrlXExitKeybindings() {
        let fileIO = MemoryEditorFileIOStrategy(files: ["/doc1.txt": "content1", "/doc2.txt": "content2"])

        // 1. Process .ctrl("X") on unmodified single buffer -> exits editor
        let editor1 = makeEditor(fileIO: fileIO, filePaths: ["/doc1.txt"])
        #expect(editor1.isRunning == true)
        editor1.processKey(.ctrl("X"))
        #expect(editor1.isRunning == false)

        // 2. Process .ctrl("x") on unmodified single buffer -> exits editor
        let editor2 = makeEditor(fileIO: fileIO, filePaths: ["/doc1.txt"])
        #expect(editor2.isRunning == true)
        editor2.processKey(.ctrl("x"))
        #expect(editor2.isRunning == false)

        // 3. Process .ctrl("x") on modified single buffer -> prompts confirmation, 'n' exits editor
        let editor3 = makeEditor(fileIO: fileIO, filePaths: ["/doc1.txt"])
        editor3.buffer.lines = ["modified"]
        editor3.buffer.isModified = true
        editor3.processKey(.ctrl("x"))
        if case .confirmExitSave = editor3.currentPromptMode {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "ctrl-x on modified buffer should trigger confirmExitSave prompt")
        }
        editor3.processKey(.char("n"))
        #expect(editor3.isRunning == false)

        // 4. Multi-buffer scenario: .ctrl("X") closes first buffer, second .ctrl("X") exits editor
        let multiEditor = makeEditor(fileIO: fileIO, filePaths: ["/doc1.txt", "/doc2.txt"])
        #expect(multiEditor.buffers.count == 2)
        multiEditor.processKey(.ctrl("X"))
        #expect(multiEditor.buffers.count == 1)
        #expect(multiEditor.isRunning == true)
        multiEditor.processKey(.ctrl("X"))
        #expect(multiEditor.isRunning == false)
    }

    @Test func testInsertFilePromptSuccessErrorAndCancellation() {
        let fileIO = MemoryEditorFileIOStrategy(files: ["/snippet.txt": "AA\nBB"])
        let editor = makeEditor(fileIO: fileIO)

        editor.promptInsertFilePath()
        typePrompt("/snippet.txt", in: editor)
        editor.processKey(.enter)

        #expect(editor.buffer.lines == ["AA", "BB"])
        #expect(editor.statusMessage == editor.l10n.insertedLines(2))

        editor.promptInsertFilePath()
        typePrompt("/missing.txt", in: editor)
        editor.processKey(.enter)
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
        editor.processKey(.char("\""))
        editor.processKey(.enter)

        #expect(editor.buffer.lines == ["a'''ef", "u'''yz"])
        #expect(editor.statusMessage == editor.l10n["status.filled_block"])

        editor.promptGotoLine()
        typePrompt("2, 5", in: editor)
        editor.processKey(.enter)

        #expect(editor.buffer.lineIndex == 1)
        #expect(editor.canvasVisualColumn == 4)
    }

    @Test func testTableDimensionsPromptInMarkdownAndOrgMode() {
        let markdownEditor = Editor(language: .en)
        markdownEditor.buffer.filePath = "notes.md"
        markdownEditor.promptTableDimensions()
        markdownEditor.promptInputText = "2 2"
        markdownEditor.promptCursorIndex = markdownEditor.promptInputText.count
        markdownEditor.processKey(.enter)

        #expect(markdownEditor.buffer.lines[0] == "| Header 1 | Header 2 |")
        #expect(markdownEditor.buffer.lines[1] == "| -------- | -------- |")
        #expect(markdownEditor.buffer.lines[2] == "| Cell 1.1 | Cell 1.2 |")
        #expect(markdownEditor.buffer.lines[3] == "| Cell 2.1 | Cell 2.2 |")

        let orgEditor = Editor(language: .en)
        orgEditor.buffer.filePath = "notes.org"
        orgEditor.promptTableDimensions()
        orgEditor.promptInputText = "1 2"
        orgEditor.promptCursorIndex = orgEditor.promptInputText.count
        orgEditor.processKey(.enter)

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

        // Test Esc cancellation returns nil
        let cancelTerminal = QueuedEditorTerminal(keys: [.esc])
        let cancelEditor = makeEditor(terminal: cancelTerminal)
        cancelEditor.isInteractiveMode = true
        let cancelDelegate: LogoEngineDelegate = cancelEditor
        #expect(cancelDelegate.logoEngine(cancelEditor.logoEngine, readWordWithPrompt: "? ") == nil)

        let cancelCharTerminal = QueuedEditorTerminal(keys: [.ctrl("c")])
        let cancelCharEditor = makeEditor(terminal: cancelCharTerminal)
        cancelCharEditor.isInteractiveMode = true
        let cancelCharDelegate: LogoEngineDelegate = cancelCharEditor
        #expect(cancelCharDelegate.logoEngine(cancelCharEditor.logoEngine, readCharWithPrompt: "?") == nil)
    }

    @Test func testMockAISuggestionCommandAndDebugModeConfig() {
        let editor = Editor()
        let cmd = MockAISuggestionCommand()

        #expect(cmd.commandBarAliases.contains("mock-ai"))
        #expect(cmd.commandBarAliases.contains(":mock-ai"))

        // Execute without arguments
        cmd.execute(on: editor)
        #expect(editor.proposalQueue.count == 1)
        #expect(editor.proposalQueue.currentProposal?.clientName == "Mock-AI")
        #expect(editor.proposalQueue.currentProposal?.reason == "Mock AI Proposal")

        // Execute with custom arguments
        editor.promptInputText = "Drafted payment flow"
        cmd.execute(on: editor)
        #expect(editor.proposalQueue.count == 2)
        #expect(editor.proposalQueue.currentProposal?.reason.contains("Drafted payment flow") == true)

        // ConfigLoader debugMode test
        let configLoader = ConfigLoader(provider: InMemoryConfigFileProvider(homePath: "/home/user", currentPath: "/home/user"))
        var config = EditorConfig()
        configLoader.parseConfigContent("set debug true", into: &config)
        #expect(config.debugMode == true)
        configLoader.parseConfigContent("set debug false", into: &config)
        #expect(config.debugMode == false)
    }

    @Test func testExternalExecuteLogoCreatesProposalWithoutMutatingBuffer() {
        let editor = makeEditor()
        editor.buffer.lines = ["alpha", "beta"]
        editor.buffer.lineIndex = 1
        editor.buffer.columnIndex = 0

        let result = editor.externalExecuteLogo(
            clientId: "agent-1",
            clientName: "Agent",
            script: "TYPE \"inserted\"",
            mode: "headful",
            viewportRows: 24,
            viewportCols: 80
        )

        #expect(result.success)
        #expect(result.result == "inserted")
        #expect(editor.buffer.lines == ["alpha", "beta"])
        #expect(editor.proposalQueue.count == 1)
        let proposal = editor.proposalQueue.currentProposal
        #expect(proposal?.clientId == "agent-1")
        #expect(proposal?.clientName == "Agent")
        #expect(proposal?.affectedFiles.first?.bufferId == editor.buffer.id)
        #expect(proposal?.affectedFiles.first?.chunks.first?.targetLine == 2)
        #expect(proposal?.affectedFiles.first?.chunks.first?.targetCol == 1)
        #expect(proposal?.affectedFiles.first?.chunks.first?.lines == ["inserted"])
        #expect(proposal?.affectedFiles.first?.chunks.first?.insertMode == .d1Insert)
    }

    @Test func testProposalOverlayBoxWidthAlignmentAndVirtualLineExpansion() {
        let editor = Editor()
        editor.buffer.lines = ["Line 1", "Line 2", "Line 3"]

        let cmd = MockAISuggestionCommand()
        cmd.execute(on: editor)

        let baseVLines = editor.layoutEngine.computeVirtualLines(from: editor.buffer.lines, viewWidth: 80)
        let expanded = editor.renderer.expandVirtualLinesWithProposal(
            virtualLines: baseVLines,
            editor: editor,
            textWidth: 80
        )

        #expect(expanded.count > baseVLines.count)

        let overlayLines = expanded.filter { $0.isProposalOverlay }
        #expect(!overlayLines.isEmpty)

        // Verify top border, content lines, and bottom border have 100% identical display width
        let widths = Set(overlayLines.map { $0.text.displayWidth })
        #expect(widths.count == 1)

        // Verify subLineIndex: top border is 0 (shows line number), subsequent box lines are > 0 (blank gutter)
        #expect(overlayLines.first?.subLineIndex == 0)
        #expect(overlayLines.dropFirst().allSatisfy { $0.subLineIndex > 0 })

        // Verify renderSubLineInfo is suppressed (returns nil) for proposal overlay lines
        for overlayLine in overlayLines {
            #expect(editor.renderer.renderSubLineInfo(editor: editor, virtualLine: overlayLine, subLineCount: 5, isEnabled: true) == nil)
        }
    }

    @Test func testReadOnlyAndDirectoryBufferSuppressesAIProposals() {
        let editor = Editor()
        editor.buffer.isReadOnly = true

        let cmd = MockAISuggestionCommand()
        cmd.execute(on: editor)

        #expect(editor.proposalQueue.isEmpty)

        let baseVLines = editor.layoutEngine.computeVirtualLines(from: editor.buffer.lines, viewWidth: 80)
        let expanded = editor.renderer.expandVirtualLinesWithProposal(
            virtualLines: baseVLines,
            editor: editor,
            textWidth: 80
        )
        #expect(expanded.count == baseVLines.count)
        #expect(expanded.filter { $0.isProposalOverlay }.isEmpty)
    }

    @Test func testDeletingLinesAboveProposalAdjustsProposalTargetLine() {
        let editor = Editor()
        editor.buffer.lines = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
        editor.buffer.lineIndex = 5

        let cmd = MockAISuggestionCommand()
        cmd.execute(on: editor)

        #expect(editor.proposalQueue.currentProposal?.affectedFiles.first?.chunks.first?.targetLine == 6)

        // Delete line 2 above proposal site
        editor.buffer.lineIndex = 1
        editor.buffer.deleteLine()

        // Proposal targetLine should automatically shift from 6 to 5
        #expect(editor.proposalQueue.currentProposal?.affectedFiles.first?.chunks.first?.targetLine == 5)
    }

    @Test func testAcceptProposalExitsTableModeIfGridIsBroken() {
        let editor = Editor()
        let tableLines = [
            "┌────────────────┬────────────────┐",
            "│ Header 1       │ Header 2       │",
            "├────────────────┼────────────────┤",
            "│ Cell 1         │ Cell 2         │",
            "└────────────────┴────────────────┘"
        ]
        editor.buffer.lines = tableLines
        editor.buffer.lineIndex = 1
        editor.buffer.columnIndex = 2

        let controller = TableModeController(editor: editor)
        controller.toggleTableMode()
        #expect(editor.isTableModeActive == true)

        let chunk = ProposalChunk(
            targetLine: 2,
            targetCol: 1,
            lines: ["Broken non-table text line 1", "Broken non-table text line 2"],
            insertMode: .d1Insert,
            type: .text
        )
        let fileProposal = AffectedFileProposal(filePath: "active", bufferId: editor.buffer.id, chunks: [chunk])
        let proposal = AIProposal(clientId: "test", clientName: "Test", reason: "Insert breaking lines", affectedFiles: [fileProposal])
        editor.proposalQueue.pushProposal(proposal)

        let acceptCmd = AcceptProposalCommand()
        acceptCmd.execute(on: editor)

        #expect(editor.isTableModeActive == false)
        #expect(editor.currentTableCell == nil)
    }

    @Test func testAcceptProposalClearsActiveSelectionMark() {
        let editor = Editor()
        editor.buffer.lines = ["line 1", "line 2", "line 3"]
        editor.buffer.lineIndex = 1
        editor.buffer.columnIndex = 0
        editor.buffer.selectionMark = (line: 0, column: 0)

        let chunk = ProposalChunk(targetLine: 2, targetCol: 1, lines: ["inserted"], insertMode: .d1Insert, type: .text)
        let proposal = AIProposal(clientId: "test", clientName: "Test", reason: "Test", affectedFiles: [
            AffectedFileProposal(filePath: "active", bufferId: editor.buffer.id, chunks: [chunk])
        ])
        editor.proposalQueue.pushProposal(proposal)

        let acceptCmd = AcceptProposalCommand()
        acceptCmd.execute(on: editor)

        #expect(editor.buffer.selectionMark == nil)
    }

    @Test func testUndoAfterAcceptProposalRestoresTableModeState() {
        let editor = Editor()
        let tableLines = [
            "┌────────────────┬────────────────┐",
            "│ Header 1       │ Header 2       │",
            "├────────────────┼────────────────┤",
            "│ Cell 1         │ Cell 2         │",
            "└────────────────┴────────────────┘"
        ]
        editor.buffer.lines = tableLines
        editor.buffer.lineIndex = 1
        editor.buffer.columnIndex = 2

        let controller = TableModeController(editor: editor)
        controller.toggleTableMode()
        #expect(editor.isTableModeActive == true)
        let originalCell = editor.currentTableCell

        let chunk = ProposalChunk(
            targetLine: 2,
            targetCol: 1,
            lines: ["Breaking table line 1", "Breaking table line 2"],
            insertMode: .d1Insert,
            type: .text
        )
        let proposal = AIProposal(clientId: "test", clientName: "Test", reason: "Breaking", affectedFiles: [
            AffectedFileProposal(filePath: "active", bufferId: editor.buffer.id, chunks: [chunk])
        ])
        editor.proposalQueue.pushProposal(proposal)

        let acceptCmd = AcceptProposalCommand()
        acceptCmd.execute(on: editor)

        // Exited Table Mode due to broken table grid
        #expect(editor.isTableModeActive == false)

        // Perform Undo (^Z)
        editor.performUndo()

        // Table Mode state and cell should be restored!
        #expect(editor.isTableModeActive == true)
        #expect(editor.currentTableCell?.minLine == originalCell?.minLine)
    }

    @Test func testAcceptProposalAppliesToTargetBufferInMultiBufferEditor() {
        let buf1 = TextBuffer()
        buf1.filePath = "/path/to/file1.txt"
        buf1.lines = ["file1 line 1"]

        let buf2 = TextBuffer()
        buf2.filePath = "/path/to/file2.txt"
        buf2.lines = ["file2 line 1"]

        let editor = Editor()
        editor.buffers = [buf1, buf2]
        editor.currentBufferIndex = 0 // active is file1.txt

        let chunk = ProposalChunk(targetLine: 1, targetCol: 1, lines: ["inserted file2"], insertMode: .d1Insert, type: .text)
        let proposal = AIProposal(clientId: "test", clientName: "Test", reason: "Target file2", affectedFiles: [
            AffectedFileProposal(filePath: "/path/to/file2.txt", bufferId: buf2.id, chunks: [chunk])
        ])
        editor.proposalQueue.pushProposal(proposal)

        let acceptCmd = AcceptProposalCommand()
        acceptCmd.execute(on: editor)

        // buf2 should receive the insertion even though active buffer index is 0 (file1.txt)
        #expect(buf2.lines.contains("inserted file2"))
        #expect(!buf1.lines.contains("inserted file2"))
    }

    @Test func testAIProposalUILocalizationStrings() {
        let l10nEN = L10n(language: .en)
        let l10nZH = L10n(language: .zh_TW)

        #expect(l10nEN["ai.proposal.action_hint"] == "[M+A Accept | M+R Reject]")
        #expect(l10nZH["ai.proposal.action_hint"] == "[M+A 接受提案 | M+R 拒絕提案]")

        #expect(l10nEN["ai.proposal.readonly_cannot_modify"] == "[AI Proposal] Cannot modify read-only buffer")
        #expect(l10nZH["ai.proposal.readonly_cannot_modify"] == "[AI 提案] 無法修改唯讀 Buffer")

        #expect(l10nEN["ai.proposal.queue_empty"] == "[AI Proposal] Queue is empty")
        #expect(l10nZH["ai.proposal.queue_empty"] == "[AI 提案] 佇列為空")

        #expect(l10nEN["help.ai_accept"] == "Accept AI")
        #expect(l10nZH["help.ai_accept"] == "接受 AI")
        #expect(l10nEN["help.ai_reject"] == "Reject AI")
        #expect(l10nZH["help.ai_reject"] == "拒絕 AI")
        #expect(l10nEN["help.ai_next_proposal"] == "Next Prop")
        #expect(l10nZH["help.ai_next_proposal"] == "下個提案")
        #expect(l10nEN["help.ai_previous_proposal"] == "Prev Prop")
        #expect(l10nZH["help.ai_previous_proposal"] == "上個提案")
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

        #expect(delegate.logoEngine(editor.logoEngine, queryState: .currentColumnIndex)?.integerValue == 5)
        #expect(
            delegate.logoEngine(editor.logoEngine, queryState: .bufferList)?.stringsValue == ["first.txt", "second.txt"])
        #expect(delegate.logoEngine(editor.logoEngine, queryState: .currentBufferIndex)?.integerValue == 0)
        #expect(delegate.logoEngine(editor.logoEngine, queryState: .bufferText)?.stringValue == "A中B\ntail")
        #expect(delegate.logoEngine(editor.logoEngine, queryState: .isModified)?.boolValue == true)
        #expect(delegate.logoEngine(editor.logoEngine, queryState: .fileName)?.stringValue == "first.txt")

        editor.buffer.selectionMark = (line: 0, column: 1)
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 2
        #expect(delegate.logoEngine(editor.logoEngine, queryState: .selectionText)?.stringValue == "中")

        editor.buffer.selectionMark = (line: 0, column: 0)
        editor.buffer.lineIndex = 1
        editor.buffer.columnIndex = 4
        #expect(delegate.logoEngine(editor.logoEngine, queryState: .selectionText)?.stringValue == "A中B\ntail")

        editor.switchToCanvasMode()
        editor.buffer.lineIndex = 0
        editor.canvasVisualColumn = 1
        editor.processKey(.mark)
        editor.canvasVisualColumn = 3
        editor.processKey(.mark)

        #expect(delegate.logoEngine(editor.logoEngine, queryState: .hasCanvasBlockMark)?.boolValue == true)
        #expect(
            delegate.logoEngine(editor.logoEngine, queryState: .canvasBlockFrame)?.canvasBlockFrameValue
                == LogoCanvasBlockFrame(lineIndex: 0, visualColumn: 1, width: 3, height: 1)
        )

        let tableEditor = Editor(language: .en)
        tableEditor.tableModeController.createTable(
            rows: 1, cols: 1, cellWidth: 3, enterMode: true, saveSnapshot: false)
        let tableDelegate: LogoEngineDelegate = tableEditor
        #expect(tableDelegate.logoEngine(tableEditor.logoEngine, queryState: .hasTableCell)?.boolValue == true)
        #expect(
            tableDelegate.logoEngine(tableEditor.logoEngine, queryState: .defaultBorderStyle)?.borderStyleValue == .single
        )
    }

    @Test func testRunLogoScriptUsesStatusesAndBlocksTableOnlyPrimitives() {
        let editor = Editor(language: .en)

        #expect(editor.runLogoScript("SUM 1 2", resultPrefix: "[R] ", successStatus: "ok") == true)
        #expect(editor.statusMessage == "[R] 3")

        #expect(editor.runLogoScript("MAKE \"v 1", successStatus: "done") == true)
        #expect(editor.statusMessage == "done")

        let tableEditor = Editor(language: .en)
        tableEditor.logoEngine.execute("TO BOXIT BOX 1 1 END")
        tableEditor.tableModeController.createTable(
            rows: 1, cols: 1, cellWidth: 3, enterMode: true, saveSnapshot: false)

        #expect(tableEditor.runLogoScript("BOXIT") == false)
        #expect(tableEditor.statusMessage == tableEditor.l10n.disabledInTableMode("BOX"))

        #expect(tableEditor.runLogoScript("GOTO 1 1") == false)
        #expect(tableEditor.statusMessage == tableEditor.l10n.disabledInTableMode("GOTO"))
    }
}
