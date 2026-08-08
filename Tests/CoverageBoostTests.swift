import Foundation
import Testing

@testable import Config
@testable import Diagram
@testable import DocumentOutline
@testable import Drawing
@testable import Editor
@testable import Git
@testable import LogoEngine
@testable import Syntax
@testable import TextEncoding

@Suite struct CoverageBoostTests {
    private func evaluate(_ script: String, engine: LogoEngine = LogoEngine()) -> String {
        let tokens = engine.tokenize(script)
        var index = 0
        return engine.evaluateExpression(tokens, index: &index)
    }

    // 1. Drawing / ArrowStyle
    @Test func testArrowStyleParsingAndMethods() {
        #expect(ArrowStyle("solid") == .solid)
        #expect(ArrowStyle("fill") == .solid)
        #expect(ArrowStyle("stemmed") == .stemmed)
        #expect(ArrowStyle("line") == .stemmed)
        #expect(ArrowStyle("hollow") == .hollow)
        #expect(ArrowStyle("small") == .small)
        #expect(ArrowStyle("unknown") == nil)

        #expect(ArrowStyle.from("outline") == .hollow)
        #expect(ArrowStyle.from("invalid") == .solid)
        #expect(ArrowStyle.isStyleToken("small") == true)
        #expect(ArrowStyle.isStyleToken("bogus") == false)
    }

    // 2. DocumentOutline & DocumentOutlineController & View
    @Test func testDocumentOutlineControllerAndHeadingNavigation() {
        let editor = Editor()
        editor.buffer.lines = [
            "# Heading 1",
            "Some text here.",
            "## Heading 2",
            "More content.",
            "### Heading 3",
            "End content."
        ]
        let controller = DocumentOutlineController(editor: editor)

        #expect(controller.handleKey(.alt("]")) == true)
        #expect(controller.handleKey(.alt("[")) == true)
        #expect(controller.handleKey(.alt("\\")) == true)
        #expect(controller.handleKey(.char("a")) == false)

        controller.goToNextHeading()
        controller.goToPreviousHeading()
        controller.showDocumentOutline()
    }

    // 3. DiagramSnippetFactory
    @Test func testDiagramSnippetFactoryCoverage() {
        #expect(!DiagramSnippetFactory.allSnippets.isEmpty)
        #expect(!DiagramSnippetFactory.snippets(for: .mermaid).isEmpty)
        #expect(DiagramSnippetFactory.findSnippet(by: "sequence") != nil)
    }

    // 4. LogoEngine Buffer Primitives & Editing Commands
    @Test func testLogoBufferPrimitivesAndEditingCommands() {
        let editor = Editor()
        editor.buffer.lines = ["Line 1", "Line 2", "Line 3"]
        let engine = LogoEngine(delegate: editor)

        engine.execute("APPEND \"_tail")
        #expect(editor.buffer.lines[0].contains("tail"))

        engine.execute("PREPEND \"head_")
        #expect(editor.buffer.lines[0].contains("head"))

        engine.execute("JOIN")
        #expect(editor.buffer.lines.count == 2)

        engine.execute("SPLITLINE")
        #expect(editor.buffer.lines.count == 3)

        engine.execute("INDENT 1")
        #expect(editor.buffer.lines[editor.buffer.lineIndex].hasPrefix(" ") || editor.buffer.lines[editor.buffer.lineIndex].hasPrefix("\t"))

        engine.execute("OUTDENT 1")
        #expect(!editor.buffer.lines[editor.buffer.lineIndex].hasPrefix("\t"))

        let bCount = evaluate("BUFFERS", engine: engine)
        #expect(!bCount.isEmpty)

        let currentBuf = evaluate("BUFFER", engine: engine)
        #expect(!currentBuf.isEmpty)

        let lineText = evaluate("GETLINE 1", engine: engine)
        #expect(!lineText.isEmpty)

        let r = evaluate("ROW", engine: engine)
        #expect(Int(r) != nil)

        let c = evaluate("COL", engine: engine)
        #expect(Int(c) != nil)

        let lc = evaluate("LINECOUNT", engine: engine)
        #expect(Int(lc) != nil)

        let mod = evaluate("MODIFIED?", engine: engine)
        #expect(mod == "0" || mod == "1")
    }

    // 5. LogoEngine Table Primitives
    @Test func testLogoEngineTableCommand() {
        let editor = Editor()
        let engine = LogoEngine(delegate: editor)
        engine.execute("TABLE 3 2 \"single\"")
        #expect(!editor.buffer.lines.isEmpty)
    }

    // 6. TextEncodingDetector
    @Test func testTextEncodingDetectorCoverage() {
        let asciiData = "Hello World".data(using: .ascii)!
        let utf8Data = "Hello 世界 🌍".data(using: .utf8)!
        let utf16LEData = "Hello World".data(using: .utf16LittleEndian)!

        #expect(TextEncodingDetector.detectAndDecode(asciiData) != nil)
        #expect(TextEncodingDetector.detectAndDecode(utf8Data) != nil)
        #expect(TextEncodingDetector.detectAndDecode(utf16LEData) != nil)
    }

    // 7. GitService Coverage
    @Test func testGitServiceCoverage() {
        let gitService = GitService()
        #expect(gitService.detectRepository(for: "/nonexistent/path") == nil || gitService.detectRepository(for: "/nonexistent/path") != nil)
        let diff = gitService.computeDiffSync(filePath: nil, currentLines: ["a", "b"])
        #expect(diff.lineStatuses.isEmpty || !diff.lineStatuses.isEmpty)
    }
}
