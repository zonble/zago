import Testing

@testable import Editor
@testable import Syntax

@Suite struct DocumentOutlineTests {
    @Test func testMarkdownHeadings() throws {
        let lines = [
            "# Title",
            "",
            "Intro",
            "## Search Workflow",
            "```",
            "# Not a heading",
            "```",
            "Setext Title",
            "============",
            "Setext Subtitle",
            "---------------",
        ]

        let outline = DocumentOutlineParser.parse(
            lines: lines,
            language: MarkdownSyntaxDefinition().buildLanguageSyntax()
        )

        #expect(outline.headings == [
            DocumentHeading(lineIndex: 0, level: 1, title: "Title", marker: "#"),
            DocumentHeading(lineIndex: 3, level: 2, title: "Search Workflow", marker: "##"),
            DocumentHeading(lineIndex: 7, level: 1, title: "Setext Title", marker: "="),
            DocumentHeading(lineIndex: 9, level: 2, title: "Setext Subtitle", marker: "-"),
        ])
    }

    @Test func testOrgHeadings() throws {
        let lines = [
            "* Overview",
            "body",
            "** Details",
            "*** Notes",
        ]

        let outline = DocumentOutlineParser.parse(
            lines: lines,
            language: OrgModeSyntaxDefinition().buildLanguageSyntax()
        )

        #expect(outline.headings.map(\.lineIndex) == [0, 2, 3])
        #expect(outline.headings.map(\.level) == [1, 2, 3])
        #expect(outline.headings.map(\.title) == ["Overview", "Details", "Notes"])
    }

    @Test func testReStructuredTextHeadingsInferLevelsByMarkerOrder() throws {
        let lines = [
            "Manual",
            "======",
            "",
            "Usage",
            "-----",
            "",
            "Deep Section",
            "~~~~~~~~~~~~",
            "",
            "Another Usage",
            "-------------",
        ]

        let outline = DocumentOutlineParser.parse(
            lines: lines,
            language: ReSTSyntaxDefinition().buildLanguageSyntax()
        )

        #expect(outline.headings == [
            DocumentHeading(lineIndex: 0, level: 1, title: "Manual", marker: "="),
            DocumentHeading(lineIndex: 3, level: 2, title: "Usage", marker: "-"),
            DocumentHeading(lineIndex: 6, level: 3, title: "Deep Section", marker: "~"),
            DocumentHeading(lineIndex: 9, level: 2, title: "Another Usage", marker: "-"),
        ])
    }

    @Test func testAsciiDocHeadings() throws {
        let lines = [
            "= Manual",
            "intro",
            "== Chapter",
            "====== Deep",
        ]

        let outline = DocumentOutlineParser.parse(
            lines: lines,
            language: AsciiDocSyntaxDefinition().buildLanguageSyntax()
        )

        #expect(outline.headings == [
            DocumentHeading(lineIndex: 0, level: 1, title: "Manual", marker: "="),
            DocumentHeading(lineIndex: 2, level: 2, title: "Chapter", marker: "=="),
            DocumentHeading(lineIndex: 3, level: 6, title: "Deep", marker: "======"),
        ])
    }

    @Test func testFallbackOutlineDoesNotDuplicateUnderlineHeadings() throws {
        let lines = [
            "Title",
            "=====",
            "",
            "## Markdown",
        ]

        let outline = DocumentOutlineParser.parse(lines: lines, language: nil)

        #expect(outline.headings == [
            DocumentHeading(lineIndex: 0, level: 1, title: "Title", marker: "="),
            DocumentHeading(lineIndex: 3, level: 2, title: "Markdown", marker: "##"),
        ])
    }

    @Test func testHeadingNavigationWraps() throws {
        let editor = Editor()
        editor.buffer.filePath = "notes.md"
        editor.buffer.lines = [
            "# Title",
            "body",
            "## Middle",
            "body",
            "## End",
        ]
        editor.buffer.lineIndex = 2
        editor.buffer.columnIndex = 4

        #expect(editor.commandRegistry.dispatch(key: .alt("]"), editor: editor))
        #expect(editor.buffer.lineIndex == 4)
        #expect(editor.buffer.columnIndex == 0)
        #expect(editor.statusMessage == "[ Heading 3/3: ## End ]")

        #expect(editor.commandRegistry.dispatch(key: .alt("]"), editor: editor))
        #expect(editor.buffer.lineIndex == 0)
        #expect(editor.statusMessage == "[ Heading 1/3: # Title ]")

        #expect(editor.commandRegistry.dispatch(key: .alt("["), editor: editor))
        #expect(editor.buffer.lineIndex == 4)
        #expect(editor.statusMessage == "[ Heading 3/3: ## End ]")
    }

    @Test func testHeadingNavigationNoHeadingsAndDisabledModes() throws {
        let editor = Editor()
        editor.buffer.filePath = "notes.md"
        editor.buffer.lines = ["plain text"]

        #expect(editor.commandRegistry.dispatch(id: .documentHeadingNext, editor: editor))
        #expect(editor.statusMessage == editor.l10n["status.no_headings"])

        editor.switchToCanvasMode()
        #expect(editor.commandRegistry.dispatch(id: .documentHeadingNext, editor: editor))
        #expect(editor.statusMessage == editor.l10n["status.heading_nav_disabled_canvas"])
    }

    @Test func testHeadingNavigationUnsupportedFormatDoesNotParseCommentsAsHeadings() throws {
        let editor = Editor()
        editor.buffer.filePath = "script.sh"
        editor.buffer.lines = [
            "# This is a shell comment",
            "echo hello",
        ]
        editor.buffer.lineIndex = 1

        #expect(editor.commandRegistry.dispatch(id: .documentHeadingNext, editor: editor))
        #expect(editor.buffer.lineIndex == 1)
        #expect(editor.statusMessage == editor.l10n["status.heading_nav_unsupported_format"])
    }

    @Test func testOutlineRowsFormatLineNumbersAndIndentation() throws {
        let rows = DocumentOutlineView.rows(for: [
            DocumentHeading(lineIndex: 0, level: 1, title: "Overview", marker: "#"),
            DocumentHeading(lineIndex: 11, level: 2, title: "Search Workflow", marker: "##"),
            DocumentHeading(lineIndex: 43, level: 3, title: "Same-file links", marker: "###"),
        ])

        #expect(rows == [
            "   1  # Overview",
            "  12    ## Search Workflow",
            "  44      ### Same-file links",
        ])
    }
}
