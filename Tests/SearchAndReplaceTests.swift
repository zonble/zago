import LogoEngine
import Testing

@testable import Editor

@Suite struct SearchAndReplaceTests {

    @Test func testSearchCommandBarCommand() throws {
        let editor = Editor()
        editor.buffer.lines = [
            "Hello World",
            "This is a test line",
            "Find the target word here",
        ]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0

        // Search for "target" using /target
        let res = editor.commandBarRegistry.dispatch("/target", editor: editor)
        #expect(res == .handled)
        #expect(editor.buffer.lineIndex == 2)
        #expect(editor.buffer.columnIndex == 9)
        #expect(editor.lastSearchQuery == "target")
        #expect(editor.buffer.activeSearchMatch?.query == "target")

        // Search again using empty / to repeat search
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0
        let resRepeat = editor.commandBarRegistry.dispatch("/", editor: editor)
        #expect(resRepeat == .handled)
        #expect(editor.buffer.lineIndex == 2)
    }

    @Test func testRepeatedSearchNextPrevious() throws {
        let editor = Editor()
        editor.buffer.lines = [
            "alpha beta alpha",
            "beta alpha",
        ]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0

        editor.searchController.performSearch(query: "alpha")
        #expect(editor.buffer.lineIndex == 0)
        #expect(editor.buffer.columnIndex == 0)
        #expect(editor.buffer.activeSearchMatch?.length == 5)

        editor.processKey(.alt("n"))
        #expect(editor.buffer.lineIndex == 0)
        #expect(editor.buffer.columnIndex == 11)

        editor.processKey(.alt("n"))
        #expect(editor.buffer.lineIndex == 1)
        #expect(editor.buffer.columnIndex == 5)

        editor.processKey(.alt("n"))
        #expect(editor.buffer.lineIndex == 0)
        #expect(editor.buffer.columnIndex == 0)
        #expect(editor.statusMessage == editor.l10n.searchWrappedFound(query: "alpha", line: 1))

        editor.processKey(.alt("p"))
        #expect(editor.buffer.lineIndex == 1)
        #expect(editor.buffer.columnIndex == 5)
        #expect(editor.statusMessage == editor.l10n.searchWrappedFound(query: "alpha", line: 2))
    }

    @Test func testSearchHighlightAndClear() throws {
        let editor = Editor()
        editor.buffer.lines = ["abc"]
        editor.displayConfig.showLineNumbers = false
        editor.displayConfig.showRuler = false

        editor.searchController.performSearch(query: "b")
        let highlighted = editor.renderer.render(editor: editor, rows: 8, cols: 20)
        #expect(highlighted.contains("\u{1B}[43;30mb\u{1B}[0m"))

        editor.buffer.selectionMark = (line: 0, column: 0)
        editor.processKey(.ctrl("G"))
        #expect(editor.buffer.activeSearchMatch == nil)
        #expect(editor.buffer.selectionMark?.line == 0)
        #expect(editor.statusMessage == editor.l10n["status.search_cleared"])

        editor.processKey(.ctrl("G"))
        #expect(editor.buffer.selectionMark == nil)
        #expect(editor.statusMessage == editor.l10n["status.mark_unset"])
    }

    @Test func testSubstituteCurrentLine() throws {
        let editor = Editor()
        editor.buffer.lines = [
            "foo foo foo",
            "foo foo foo",
        ]
        editor.buffer.lineIndex = 0
        editor.buffer.columnIndex = 0

        // s/foo/bar/ replaces 1st occurrence on current line
        let res1 = editor.commandBarRegistry.dispatch("s/foo/bar/", editor: editor)
        #expect(res1 == .handled)
        #expect(editor.buffer.lines[0] == "bar foo foo")
        #expect(editor.buffer.lines[1] == "foo foo foo")

        // s/foo/bar/g replaces all occurrences on current line
        let res2 = editor.commandBarRegistry.dispatch("s/foo/bar/g", editor: editor)
        #expect(res2 == .handled)
        #expect(editor.buffer.lines[0] == "bar bar bar")
        #expect(editor.buffer.lines[1] == "foo foo foo")
    }

    @Test func testSubstituteWholeBufferWithPercent() throws {
        let editor = Editor()
        editor.buffer.lines = [
            "apple banana apple",
            "cherry apple orange",
        ]
        editor.buffer.lineIndex = 0

        // %s,apple,pear,g using comma delimiter across whole buffer
        let res = editor.commandBarRegistry.dispatch("%s,apple,pear,g", editor: editor)
        #expect(res == .handled)
        #expect(editor.buffer.lines[0] == "pear banana pear")
        #expect(editor.buffer.lines[1] == "cherry pear orange")
    }

    @Test func testSubstituteWithSelectionScope() throws {
        let editor = Editor()
        editor.buffer.lines = [
            "Line 1: cat",
            "Line 2: cat",
            "Line 3: cat",
            "Line 4: cat",
        ]
        editor.buffer.lineIndex = 1
        editor.buffer.columnIndex = 0
        editor.buffer.selectionMark = (line: 2, column: 10)

        // s/cat/dog/g within active selection (Lines 2 & 3)
        let res = editor.commandBarRegistry.dispatch("s/cat/dog/g", editor: editor)
        #expect(res == .handled)
        #expect(editor.buffer.lines[0] == "Line 1: cat")
        #expect(editor.buffer.lines[1] == "Line 2: dog")
        #expect(editor.buffer.lines[2] == "Line 3: dog")
        #expect(editor.buffer.lines[3] == "Line 4: cat")
    }

    @Test func testSubstituteRegexAndCaptureGroups() throws {
        let editor = Editor()
        editor.buffer.lines = [
            "item_100 item_200"
        ]
        editor.buffer.lineIndex = 0

        // %s/item_(\\d+)/unit_$1/gr with regex flag 'r' and capture group $1
        let res = editor.commandBarRegistry.dispatch("%s/item_(\\d+)/unit_$1/gr", editor: editor)
        #expect(res == .handled)
        #expect(editor.buffer.lines[0] == "unit_100 unit_200")
    }

    @Test func testRegexSettingCommand() throws {
        let editor = Editor()
        #expect(editor.isRegexSearchEnabled == false)

        _ = editor.commandBarRegistry.dispatch("set regex on", editor: editor)
        #expect(editor.isRegexSearchEnabled == true)

        _ = editor.commandBarRegistry.dispatch("set regex off", editor: editor)
        #expect(editor.isRegexSearchEnabled == false)
    }

    @Test func testCommandBarCompletionForTr() throws {
        let editor = Editor()
        editor.promptLogoMacro()
        editor.processKey(.char("t"))
        editor.processKey(.char("r"))
        #expect(editor.promptInputText == "tr")

        editor.processKey(.tab)
        #expect(editor.promptCompletionText != nil)
        if let completionText = editor.promptCompletionText?.lowercased() {
            #expect(completionText.contains("translit") && completionText.contains("transform"))
        }
    }

    @Test func testHelpBarRenderingWithLongCompletionText() throws {
        let editor = Editor()
        let renderer = Renderer()
        editor.promptLogoMacro()
        editor.processKey(.char("t"))
        editor.processKey(.char("r"))
        editor.processKey(.tab)
        #expect(editor.promptCompletionText != nil)

        let helpBarOutput = renderer.renderHelpBar(cols: 80, promptMode: editor.currentPromptMode, editor: editor)
        #expect(helpBarOutput.contains("transform"))
    }

    @Test func testCommandBarLCPCompletion() throws {
        let editor = Editor()
        editor.promptLogoMacro()

        // Type "tra" and press Tab -> should auto-complete to "trans" (LCP of transform*, translit)
        for ch in "tra" { editor.processKey(.char(ch)) }
        #expect(editor.promptInputText == "tra")
        editor.processKey(.tab)
        #expect(editor.promptInputText == "trans")

        // Type "f" ("transf") and press Tab -> should auto-complete to "transform"
        editor.processKey(.char("f"))
        #expect(editor.promptInputText == "transf")
        editor.processKey(.tab)
        #expect(editor.promptInputText == "transform")

        // Type ".toha" ("transform.toha") and press Tab -> should auto-complete to "transform.tohan"
        for ch in ".toha" { editor.processKey(.char(ch)) }
        #expect(editor.promptInputText == "transform.toha")
        editor.processKey(.tab)
        #expect(editor.promptInputText == "transform.tohan")
    }
}
