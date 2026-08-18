import ANSIStyle
import Foundation
import Testing
import TextMetrics

@testable import Editor

@Suite(.serialized)
struct RendererChromeTests {
    @Test func testDynamicHelpBarByPromptMode() throws {
        let renderer = Renderer()
        let editorEn = Editor(language: .en)

        // 1. LOGO macro prompt help bar (English)
        let logoHelp = renderer.renderHelpBar(cols: 120, promptMode: .logoMacro(completion: { _ in }), editor: editorEn)
        #expect(logoHelp.contains("BOX"))
        #expect(logoHelp.contains("DRAWBOX"))
        #expect(logoHelp.contains("TABLE"))
        #expect(logoHelp.contains("LINE"))
        #expect(logoHelp.contains("Complete"))

        // 2. Exit Confirmation prompt help bar (English)
        let exitHelp = renderer.renderHelpBar(
            cols: 80, promptMode: .confirmExitSave(completion: { _ in }), editor: editorEn)
        #expect(exitHelp.contains("Yes"))
        #expect(exitHelp.contains("No"))
        #expect(exitHelp.contains("Cancel"))

        // 3. Search input prompt help bar (English)
        let searchHelp = renderer.renderHelpBar(cols: 80, promptMode: .search(completion: { _ in }), editor: editorEn)
        #expect(!searchHelp.contains("Help"))
        #expect(searchHelp.contains("Cancel"))
        #expect(searchHelp.contains("Confirm"))
        #expect(searchHelp.contains("Clear"))
        #expect(searchHelp.contains("Move"))
        #expect(searchHelp.contains("Jump"))

        // 4. Default Nano help bar (English)
        let defaultHelp = renderer.renderHelpBar(cols: 80, promptMode: .none, editor: editorEn)
        #expect(defaultHelp.contains("F1"))
        #expect(defaultHelp.contains("Menu"))
        #expect(!defaultHelp.contains("^G"))
        #expect(defaultHelp.contains("^O"))
        #expect(defaultHelp.contains(editorEn.l10n.helpWriteOut))

        let editor = Editor(language: .en)
        editor.switchToCanvasMode()
        let canvasHelp = renderer.renderHelpBar(cols: 120, promptMode: .none, editor: editor)
        #expect(canvasHelp.contains("⇧+Arrow"))
        #expect(canvasHelp.contains("M+B"))
        #expect(canvasHelp.contains("^K"))
        #expect(canvasHelp.contains("^U"))
        #expect(canvasHelp.contains("F1"))
        #expect(canvasHelp.contains("^G"))
        #expect(!canvasHelp.contains(editor.l10n.helpGetHelp))

        // 5. Traditional Chinese help bar verification
        let editorZh = Editor(language: .zh_TW)
        let zhExitHelp = renderer.renderHelpBar(
            cols: 80, promptMode: .confirmExitSave(completion: { _ in }), editor: editorZh)
        #expect(zhExitHelp.contains("是"))
        #expect(zhExitHelp.contains("否"))
        #expect(zhExitHelp.contains("取消"))
    }

    @Test func testWideHelpBarUsesColumnsBeyondEighty() throws {
        let renderer = Renderer()
        let editor = Editor(language: .en)

        let standardHelp = renderer.renderHelpBar(cols: 80, promptMode: .none, editor: editor)
        let wideHelp = renderer.renderHelpBar(cols: 120, promptMode: .none, editor: editor)

        #expect(!standardHelp.contains("M+W"))
        #expect(wideHelp.contains("M+W"))
        #expect(wideHelp.contains("Copy Text"))

        let zhEditor = Editor(language: .zh_TW)
        let zhWideHelp = renderer.renderHelpBar(cols: 120, promptMode: .none, editor: zhEditor)
        #expect(zhWideHelp.contains("複製文字"))
        #expect(zhWideHelp.contains("復原"))
    }

    @Test func testCanvasModeRendersLocalizedEndOfFileMarker() throws {
        let editor = Editor()
        editor.buffer.lines = ["abc", "def"]
        editor.switchToCanvasMode()

        let output = editor.renderer.render(editor: editor, rows: 8, cols: 40)

        #expect(output.contains("~ \(editor.l10n["chrome.end_of_file"])"))
        #expect(output.contains("\u{1B}[90m"))
    }

    @Test func testTextModeDoesNotRenderEndOfFileMarker() throws {
        let editor = Editor()
        editor.buffer.lines = ["abc", "def"]

        let output = editor.renderer.render(editor: editor, rows: 8, cols: 40)

        #expect(!output.contains("~ \(editor.l10n["chrome.end_of_file"])"))
    }

    @Test func testIdleStatusLineModeIndicators() throws {
        let editor = Editor(language: .en)
        let renderer = editor.renderer

        #expect(renderer.renderIdleStatusLine(editor: editor, cols: 80).trimmingCharacters(in: .whitespaces).isEmpty)

        editor.switchToCanvasMode()
        let canvasStatus = renderer.renderIdleStatusLine(editor: editor, cols: 80)
        #expect(canvasStatus.contains("CANVAS"))
        #expect(canvasStatus.contains("(F8 / M+V to exit)"))
        #expect(!canvasStatus.contains("[ Canvas Mode ]"))

        editor.overlayMode = .none
        editor.isTableModeActive = true
        let tableStatus = renderer.renderIdleStatusLine(editor: editor, cols: 80)
        #expect(tableStatus.contains("CANVAS | TABLE"))

        editor.language = .zh_TW
        let localizedStatus = renderer.renderIdleStatusLine(editor: editor, cols: 80)
        #expect(localizedStatus.contains("畫布 | 表格"))
        #expect(localizedStatus.contains("(F8 / M+V 退出)"))
        #expect(!localizedStatus.contains("CANVAS | TABLE"))
    }

    @Test func testRendererModularComponents() throws {
        let editor = Editor()
        let renderer = editor.renderer

        // Test Title Bar component
        let titleBarOutput = renderer.renderTitleOrMenuBar(editor: editor, cols: 80)
        #expect(titleBarOutput.contains("zago"))

        // Test Ruler Bar component
        let rulerOutput = renderer.generateWordStarRuler(width: 30)
        #expect(rulerOutput == "----!----1----!----2----!----3")

        // Test Line Number Gutter component
        let gutterOutput = renderer.renderLineNumberGutter(
            editor: editor, lineNumber: 5, isFirstSubLine: true, showLineNumbers: true)
        #expect(gutterOutput.contains("5"))

        editor.buffer.lineIndex = 4
        editor.debuggerController.toggleBreakpoint(in: editor.buffer)
        let breakpointGutter = renderer.renderLineNumberGutter(
            editor: editor, lineNumber: 5, isFirstSubLine: true, showLineNumbers: true)
        #expect(!breakpointGutter.contains("●"))

        editor.displayConfig.showLineNumbers = false
        editor.buffer.lines = ["one", "two"]
        editor.buffer.lineIndex = 0
        editor.debuggerController.toggleBreakpoint(in: editor.buffer)
        let renderedBreakpoint = renderer.render(editor: editor, rows: 8, cols: 40)
        #expect(renderedBreakpoint.contains("●one"))
        #expect(ScreenGeometry(rows: 8, cols: 40, editor: editor).gutterWidth == 1)

        // Test full screen render
        let fullOutput = renderer.render(editor: editor, rows: 24, cols: 80)
        #expect(fullOutput.hasPrefix("\u{1B}[?7l\u{1B}[H"))
    }

    @Test func testRendererIsPureAndReadOnlyWithoutSideEffects() throws {
        let editor = Editor()
        let buffer = TextBuffer()
        buffer.lines = (1...50).map { "Line \($0)" }
        editor.buffer = buffer
        editor.buffer.lineIndex = 40
        editor.topVLineIndex = 0

        let renderer = editor.renderer
        let initialTop = editor.topVLineIndex

        // Calling renderer.render directly should NOT mutate editor.topVLineIndex (Pure Read-Only)
        _ = renderer.render(editor: editor, rows: 20, cols: 80)
        #expect(editor.topVLineIndex == initialTop)

        // Viewport adjustment is explicitly invoked by Editor
        editor.adjustViewport(mainAreaHeight: 15, textWidth: 75)
        #expect(editor.topVLineIndex > 0)
    }

    @Test func testScreenGeometryCalculationAndConsumption() throws {
        let editor = Editor()
        let geometryNoRuler = ScreenGeometry(rows: 24, cols: 80, showRuler: false, showGutter: true)
        #expect(geometryNoRuler.mainAreaHeight == 20)
        #expect(geometryNoRuler.gutterWidth == 5)
        #expect(geometryNoRuler.textWidth == 75)

        let geometryWithRuler = ScreenGeometry(rows: 24, cols: 80, showRuler: true, showGutter: false)
        #expect(geometryWithRuler.mainAreaHeight == 19)
        #expect(geometryWithRuler.gutterWidth == 0)
        #expect(geometryWithRuler.textWidth == 80)

        let geometry = ScreenGeometry(rows: 25, cols: 80, editor: editor)
        #expect(geometry.rows == 25)
        #expect(geometry.cols == 80)
        #expect(geometry.showRuler == false)
        #expect(geometry.showGutter == true)
        #expect(geometry.mainAreaHeight == 21)
        #expect(geometry.gutterWidth == 5)
        #expect(geometry.textWidth == 75)

        // Renderer accepts geometry without re-calculating layout
        let output = editor.renderer.render(editor: editor, geometry: geometry)
        #expect(!output.isEmpty)
    }

    @Test func testPromptControllerLifecycleAndHelpShortcuts() throws {
        let editor = Editor()
        let controller = editor.promptController

        #expect(controller.isActive == false)
        #expect(controller.promptHelpShortcuts() == nil)

        controller.mode = .search(completion: { _ in })
        #expect(controller.isActive == true)
        let shortcuts = controller.promptHelpShortcuts()
        #expect(shortcuts != nil)
        #expect(shortcuts?.count == 3)

        controller.reset()
        #expect(controller.isActive == false)
        #expect(controller.inputText.isEmpty)
        #expect(controller.cursorIndex == 0)
    }

    @Test func testCommandRegistryFastLookupAndDispatch() throws {
        let editor = Editor()
        #expect(editor.commandRegistry.dispatch(id: .moveRight, editor: editor) == true)
        #expect(editor.commandRegistry.dispatch(idString: "move.right", editor: editor) == true)
        #expect(editor.commandRegistry.dispatch(idString: "nonExistentCommand", editor: editor) == false)
    }

    @Test func testMenuBarCategoryHighlightStability() throws {
        let editor = Editor()
        editor.isMenuBarActive = true
        let cols = 80

        // Render with category 0 highlighted
        editor.menuBar.categoryIndex = 0
        let line0 = editor.renderer.renderTitleOrMenuBar(editor: editor, cols: cols)

        // Render with category 1 highlighted
        editor.menuBar.categoryIndex = 1
        let line1 = editor.renderer.renderTitleOrMenuBar(editor: editor, cols: cols)

        // Render with category 2 highlighted
        editor.menuBar.categoryIndex = 2
        let line2 = editor.renderer.renderTitleOrMenuBar(editor: editor, cols: cols)

        // Verify raw display lengths of all category selections are strictly identical (no horizontal jumping)
        let clean0 = line0.replacingOccurrences(of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)
        let clean1 = line1.replacingOccurrences(of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)
        let clean2 = line2.replacingOccurrences(of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)

        #expect(clean0.contains("[File]"))
        #expect(!clean0.contains("[ File ]"))
        #expect(clean0.count == clean1.count)
        #expect(clean1.count == clean2.count)

        // Verify dropdown overlay column offset is aligned directly with category index
        editor.menuBar.categoryIndex = 0
        let (startCol0, _, _) = editor.renderer.generateDropdownOverlayLines(editor: editor, cols: cols)
        #expect(startCol0 == 1)

        editor.menuBar.categoryIndex = 1
        let (startCol1, _, _) = editor.renderer.generateDropdownOverlayLines(editor: editor, cols: cols)
        let title0Width = editor.l10n[editor.menuBar.categories[0].titleKey].displayWidth
        #expect(startCol1 == 1 + title0Width + 2)

        editor.menuBar.categoryIndex = 2
        let (startCol2, _, _) = editor.renderer.generateDropdownOverlayLines(editor: editor, cols: cols)
        let title1Width = editor.l10n[editor.menuBar.categories[1].titleKey].displayWidth
        #expect(startCol2 == 1 + title0Width + 2 + title1Width + 2)
    }

    @Test func testMenuBarUnderlinesShortcutKeys() throws {
        let renderer = Renderer()

        let enEditor = Editor(language: .en)
        enEditor.isMenuBarActive = true
        let enLine = renderer.renderTitleOrMenuBar(editor: enEditor, cols: 80)
        #expect(enLine.contains("\(ANSIStyle.underline)F\(ANSIStyle.underlineOff)ile"))
        #expect(enLine.contains("\(ANSIStyle.underline)E\(ANSIStyle.underlineOff)dit"))

        let zhEditor = Editor(language: .zh_TW)
        zhEditor.isMenuBarActive = true
        let zhLine = renderer.renderTitleOrMenuBar(editor: zhEditor, cols: 80)
        #expect(zhLine.contains("檔案(\(ANSIStyle.underline)F\(ANSIStyle.underlineOff))"))
        #expect(zhLine.contains("編輯(\(ANSIStyle.underline)E\(ANSIStyle.underlineOff))"))
    }

    @Test func testMenuDropdownItemsShowShortcutKeys() throws {
        let renderer = Renderer()

        let enEditor = Editor(language: .en)
        enEditor.isMenuBarActive = true
        enEditor.menuBar.categoryIndex = 0
        let (_, _, enLines) = renderer.generateDropdownOverlayLines(editor: enEditor, cols: 80)
        #expect(enLines.contains(where: { $0.contains("\(ANSIStyle.underline)N\(ANSIStyle.underlineOff)ew Buffer") }))

        let zhEditor = Editor(language: .zh_TW)
        zhEditor.isMenuBarActive = true
        zhEditor.menuBar.categoryIndex = 0
        let (_, _, zhLines) = renderer.generateDropdownOverlayLines(editor: zhEditor, cols: 80)
        #expect(zhLines.contains(where: { $0.contains("新建空白頁 (\(ANSIStyle.underline)N\(ANSIStyle.underlineOff))") }))
    }

    @Test func testMenuDropdownReservesCheckboxColumnForEveryItem() throws {
        let editor = Editor(language: .en)
        editor.isMenuBarActive = true
        editor.menuBar.categoryIndex = editor.menuBar.categories.firstIndex(where: { $0.titleKey == "menu.borders" })!

        var (_, _, lines) = editor.renderer.generateDropdownOverlayLines(editor: editor, cols: 80)
        let cleanChecked = lines[1].replacingOccurrences(of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)
        let cleanUnchecked = lines[2].replacingOccurrences(
            of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)
        #expect(cleanChecked.contains("│ ✓ Single"))
        #expect(cleanUnchecked.contains("│   Heavy"))

        editor.menuBar.categoryIndex = editor.menuBar.categories.firstIndex(where: { $0.titleKey == "menu.shapes" })!
        (_, _, lines) = editor.renderer.generateDropdownOverlayLines(editor: editor, cols: 80)
        let cleanPlain = lines[1].replacingOccurrences(of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)
        #expect(cleanPlain.contains("│   Box"))
    }

    @Test func testMenuOverlayReplacesWideCharactersCrossingBoundariesWithSpaces() throws {
        let renderer = Renderer()
        func stripCSI(_ text: String) -> String {
            text.replacingOccurrences(of: "\u{1B}\\[[0-9;]*[A-Za-z]", with: "", options: .regularExpression)
        }

        let leftOverlap = renderer.sliceOverlayLine(
            baseFullLineStr: "AB中C",
            boxLine: "[MENU]",
            dropdownStartCol: 3,
            dropdownBoxWidth: 6,
            cols: 12
        )
        let cleanLeft = stripCSI(leftOverlap)

        #expect(cleanLeft.hasPrefix("AB [MENU]"))
        #expect(!cleanLeft.contains("中"))

        let rightOverlap = renderer.sliceOverlayLine(
            baseFullLineStr: "ABC中Z",
            boxLine: "MENU",
            dropdownStartCol: 0,
            dropdownBoxWidth: 4,
            cols: 8
        )
        let cleanRight = stripCSI(rightOverlap)

        #expect(cleanRight.hasPrefix("MENU Z"))
        #expect(!cleanRight.contains("中"))

        let emojiBeforeMenu = renderer.sliceOverlayLine(
            baseFullLineStr: "A❌BC",
            boxLine: "MENU",
            dropdownStartCol: 3,
            dropdownBoxWidth: 4,
            cols: 10
        )
        let cleanEmoji = stripCSI(emojiBeforeMenu)
        #expect(cleanEmoji.hasPrefix("A❌MENU"))
        #expect(emojiBeforeMenu.contains("\u{1B}[4G"))
        #expect(emojiBeforeMenu.contains("\u{1B}[8G"))
    }

    @Test func testMenuBarCursorPositioningBottomRight() throws {
        let editor = Editor()
        editor.buffer.lines = ["Hello World"]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0

        let rows = 24
        let cols = 80

        // 1. When menu bar is inactive (isMenuBarActive == false)
        editor.isMenuBarActive = false
        let normalOutput = editor.renderer.render(editor: editor, rows: rows, cols: cols)
        #expect(!normalOutput.contains("\u{1B}[\(rows);\(cols)H"))

        // 2. When menu bar is active (isMenuBarActive == true)
        editor.isMenuBarActive = true
        let menuActiveOutput = editor.renderer.render(editor: editor, rows: rows, cols: cols)
        #expect(menuActiveOutput.contains("\u{1B}[\(rows);\(cols)H"))

        // 3. When menu bar is toggled back off (isMenuBarActive == false)
        editor.isMenuBarActive = false
        let menuClosedOutput = editor.renderer.render(editor: editor, rows: rows, cols: cols)
        #expect(!menuClosedOutput.contains("\u{1B}[\(rows);\(cols)H"))
    }

    @Test func testLineNumberColorPreservedWhenMenuBarActive() throws {
        let editor = Editor()
        editor.buffer.lines = ["Line 1", "Line 2", "Line 3", "Line 4", "Line 5", "Line 6", "Line 7"]

        // 1. Menu inactive -> Line numbers have \u{1B}[90m (dim gray)
        editor.isMenuBarActive = false
        let outputInactive = editor.renderer.render(editor: editor, rows: 24, cols: 80)
        #expect(outputInactive.contains("\u{1B}[90m   1 \u{1B}[0m"))

        // 2. Menu active with category 3 (dropdown offset at col > 20) -> Line numbers MUST STILL have \u{1B}[90m (dim gray)
        editor.isMenuBarActive = true
        editor.menuBar.categoryIndex = 3
        let outputActive = editor.renderer.render(editor: editor, rows: 24, cols: 80)
        #expect(outputActive.contains("\u{1B}[90m   1 \u{1B}[0m"))
    }

    @Test func testSmartTabBlockIndentOutdentAndListNesting() throws {
        let editor = Editor()
        editor.buffer.lines = [
            "First line",
            "Second line",
            "- List item 1",
            "  - Nested item",
            "hello world",
        ]

        // 1. Test Block Indent on multi-line text selection
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0
        editor.buffer.selectionMark = (line: 1, column: 5)
        #expect(editor.buffer.selectionMark != nil)

        // Press Tab -> Block Indent by tabSize (4 spaces)
        editor.processKey(.tab)
        #expect(editor.buffer.lines[0] == "    First line")
        #expect(editor.buffer.lines[1] == "    Second line")
        #expect(editor.buffer.selectionMark != nil)

        // Press Shift+Tab (Backtab) -> Block Outdent by 4 spaces
        editor.processKey(.backtab)
        #expect(editor.buffer.lines[0] == "First line")
        #expect(editor.buffer.lines[1] == "Second line")

        // Clear selection
        editor.buffer.selectionMark = nil

        // 2. Test Smart List Indent (adds listIndentSize = 2 spaces)
        editor.buffer.lineIndex = 2
        editor.buffer.columnIndex = 0
        editor.processKey(.tab)
        #expect(editor.buffer.lines[2] == "  - List item 1")

        // Shift+Tab on list line -> Outdents by 2 spaces
        editor.processKey(.backtab)
        #expect(editor.buffer.lines[2] == "- List item 1")

        // 3. Test Word Boundary Tab Stop Alignment
        editor.buffer.lineIndex = 4
        editor.buffer.columnIndex = 2  // "he|llo world" (col 2, tabSize 4 -> aligns to col 4)
        editor.processKey(.tab)
        #expect(editor.buffer.lines[4] == "he  llo world")
        #expect(editor.buffer.columnIndex == 4)
    }
}
