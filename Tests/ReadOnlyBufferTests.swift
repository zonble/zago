import Testing

@testable import Editor

@Suite struct ReadOnlyBufferTests {

    @Test func testCutLineAndCutSelectionBlockedInReadOnlyBuffer() throws {
        let editor = Editor()
        editor.buffer.lines = ["Line 1", "Line 2", "Line 3"]
        editor.buffer.isReadOnly = true

        // 1. Cut line with ^K (Classic)
        editor.processKey(.ctrl("k"))
        #expect(editor.buffer.lines == ["Line 1", "Line 2", "Line 3"])
        #expect(editor.statusMessage == editor.l10n["status.read_only"])

        // 2. Cut line with ^X (Modern)
        editor.apply(.keymap(.modern))
        editor.processKey(.ctrl("x"))
        #expect(editor.buffer.lines == ["Line 1", "Line 2", "Line 3"])
        #expect(editor.statusMessage == editor.l10n["status.read_only"])

        // 3. Cut selection with ^X / ^K
        editor.buffer.selectionMark = (line: 0, column: 0)
        editor.buffer.columnIndex = 4
        editor.processKey(.ctrl("x"))
        #expect(editor.buffer.lines == ["Line 1", "Line 2", "Line 3"])
        #expect(editor.statusMessage == editor.l10n["status.read_only"])
    }

    @Test func testDeleteAndBackspaceBlockedInReadOnlyBuffer() throws {
        let editor = Editor()
        editor.buffer.lines = ["Hello World"]
        editor.buffer.isReadOnly = true

        // 1. Backspace
        editor.buffer.columnIndex = 5
        editor.processKey(.backspace)
        #expect(editor.buffer.lines[0] == "Hello World")
        #expect(editor.statusMessage == editor.l10n["status.read_only"])

        // 2. Delete key
        editor.processKey(.delete)
        #expect(editor.buffer.lines[0] == "Hello World")
        #expect(editor.statusMessage == editor.l10n["status.read_only"])

        // 3. Ctrl+D (Classic Delete)
        editor.processKey(.ctrl("d"))
        #expect(editor.buffer.lines[0] == "Hello World")
        #expect(editor.statusMessage == editor.l10n["status.read_only"])

        // 4. Ctrl+Backspace (Delete line)
        editor.processKey(.ctrlBackspace)
        #expect(editor.buffer.lines[0] == "Hello World")
        #expect(editor.statusMessage == editor.l10n["status.read_only"])
    }

    @Test func testTypingAndEnterBlockedInReadOnlyBuffer() throws {
        let editor = Editor()
        editor.buffer.lines = ["Sample Text"]
        editor.buffer.isReadOnly = true

        // Typing character
        editor.processKey(.char("A"))
        #expect(editor.buffer.lines[0] == "Sample Text")
        #expect(editor.statusMessage == editor.l10n["status.read_only"])

        // Enter key
        editor.processKey(.enter)
        #expect(editor.buffer.lines.count == 1)
        #expect(editor.statusMessage == editor.l10n["status.read_only"])
    }

    @Test func testPasteAndUncutBlockedInReadOnlyBuffer() throws {
        let editor = Editor()
        editor.buffer.lines = ["Original Line"]
        editor.buffer.isReadOnly = true
        editor.clipboardText = "Pasted Content"

        // 1. ^U (Classic Uncut)
        editor.processKey(.ctrl("u"))
        #expect(editor.buffer.lines == ["Original Line"])
        #expect(editor.statusMessage == editor.l10n["status.read_only"])

        // 2. ^V (Modern Paste)
        editor.apply(.keymap(.modern))
        editor.processKey(.ctrl("v"))
        #expect(editor.buffer.lines == ["Original Line"])
        #expect(editor.statusMessage == editor.l10n["status.read_only"])
    }

    @Test func testFormattingCommandsBlockedInReadOnlyBuffer() throws {
        let editor = Editor()
        editor.buffer.lines = [
            "This is a long line intended to test paragraph justification behavior in read only buffer mode.",
            "Second line here.",
        ]
        editor.buffer.isReadOnly = true

        // 1. Justify (^J)
        editor.processKey(.ctrl("j"))
        #expect(editor.statusMessage == editor.l10n["status.read_only"])

        // 2. Toggle Comment (Ctrl+/)
        editor.processKey(.ctrl("/"))
        #expect(editor.statusMessage == editor.l10n["status.read_only"])

        // 3. Join Line (M-J)
        editor.processKey(.alt("j"))
        #expect(editor.buffer.lines.count == 2)
        #expect(editor.statusMessage == editor.l10n["status.read_only"])

        // 4. Split Line (M-K)
        editor.processKey(.alt("k"))
        #expect(editor.buffer.lines.count == 2)
        #expect(editor.statusMessage == editor.l10n["status.read_only"])

        // 5. Tab / Backtab
        editor.processKey(.tab)
        #expect(editor.statusMessage == editor.l10n["status.read_only"])
        editor.processKey(.backtab)
        #expect(editor.statusMessage == editor.l10n["status.read_only"])
    }

    @Test func testSearchReplaceAndSubstituteBlockedInReadOnlyBuffer() throws {
        let editor = Editor()
        editor.buffer.lines = ["apple banana cherry"]
        editor.buffer.isReadOnly = true

        // 1. Prompt Search and Replace
        editor.promptSearchAndReplace()
        #expect(!editor.promptController.isActive)
        #expect(editor.statusMessage == editor.l10n["status.read_only"])

        // 2. Substitute command :s/apple/orange/
        let subRes = editor.commandBarRegistry.dispatch("s/apple/orange/", editor: editor)
        #expect(subRes == .handled)
        #expect(editor.buffer.lines[0] == "apple banana cherry")
        #expect(editor.statusMessage == editor.l10n["status.read_only"])

        // 3. File Insert
        editor.promptInsertFilePath()
        #expect(!editor.promptController.isActive)
        #expect(editor.statusMessage == editor.l10n["status.read_only"])
    }

    @Test func testCanvasDrawingBlockedInReadOnlyBuffer() throws {
        let editor = Editor()
        editor.buffer.lines = ["   ", "   ", "   "]
        editor.buffer.isReadOnly = true

        // 1. Switching to canvas mode is blocked
        editor.switchToCanvasMode()
        #expect(editor.baseMode == .text)
        #expect(editor.statusMessage == editor.l10n["status.buffer_readonly_bracketed"])

        // 2. Toggle table mode is blocked
        editor.tableModeController.toggleTableMode()
        #expect(!editor.isTableModeActive)
        #expect(editor.statusMessage == editor.l10n["status.buffer_readonly_bracketed"])

        // 3. If baseMode is canvas, drawing is blocked
        editor.baseMode = .canvas
        editor.processKey(.shiftArrowRight)
        #expect(editor.buffer.lines == ["   ", "   ", "   "])
        #expect(editor.statusMessage == editor.l10n["status.read_only"])

        editor.processKey(.ctrlShiftArrowRight)
        #expect(editor.buffer.lines == ["   ", "   ", "   "])
        #expect(editor.statusMessage == editor.l10n["status.read_only"])
    }

    @Test func testNavigationAndCopyAllowedInReadOnlyBuffer() throws {
        let editor = Editor()
        editor.buffer.lines = ["First Line", "Second Line"]
        editor.buffer.isReadOnly = true

        // 1. Navigation works
        editor.processKey(.arrowDown)
        #expect(editor.buffer.lineIndex == 1)
        editor.processKey(.arrowUp)
        #expect(editor.buffer.lineIndex == 0)

        // 2. Selection works
        editor.processKey(.shiftArrowRight)
        #expect(editor.buffer.selectionMark != nil)

        // 3. Copy works
        editor.processKey(.alt("w"))
        #expect(editor.clipboardText == "F")
        #expect(editor.statusMessage == editor.l10n["status.copied_text"])

        // 4. Search works
        editor.searchController.performSearch(query: "Second")
        #expect(editor.buffer.lineIndex == 1)
    }

    @Test func testReadOnlyStatusLocalization() throws {
        let editorEn = Editor(language: .en)
        #expect(editorEn.l10n["status.read_only"] == "The buffer is read-only")

        let editorZh = Editor(language: .zh_TW)
        #expect(editorZh.l10n["status.read_only"] == "此緩衝區為唯讀")
    }
}
