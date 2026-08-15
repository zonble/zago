import Testing
import Foundation
@testable import Config
@testable import Editor

@Suite struct LineEndingTests {

    @Test func testLineEndingDetection() throws {
        #expect(LineEnding.detect(in: "line1\nline2\n") == .lf)
        #expect(LineEnding.detect(in: "line1\r\nline2\r\n") == .crlf)
        #expect(LineEnding.detect(in: "line1\rline2\r") == .cr)
        #expect(LineEnding.detect(in: "single line without newline") == .lf)
    }

    @Test func testReplaceContentsPreservesLineEndingAndTrailingNewline() throws {
        let buffer = TextBuffer()

        // 1. Unix LF with trailing newline
        buffer.replaceContents("hello\nworld\n")
        #expect(buffer.lineEnding == LineEnding.lf)
        #expect(buffer.hasTrailingNewline == true)
        #expect(buffer.lines == ["hello", "world"])

        // 2. DOS CRLF with trailing newline
        buffer.replaceContents("hello\r\nworld\r\n")
        #expect(buffer.lineEnding == LineEnding.crlf)
        #expect(buffer.hasTrailingNewline == true)
        #expect(buffer.lines == ["hello", "world"])

        // 3. Mac CR with trailing newline
        buffer.replaceContents("hello\rworld\r")
        #expect(buffer.lineEnding == LineEnding.cr)
        #expect(buffer.hasTrailingNewline == true)
        #expect(buffer.lines == ["hello", "world"])

        // 4. File without trailing newline
        buffer.replaceContents("hello\nworld")
        #expect(buffer.lineEnding == LineEnding.lf)
        #expect(buffer.hasTrailingNewline == false)
        #expect(buffer.lines == ["hello", "world"])
    }

    @Test func testSaveBufferPreservesLineEndingAndAppendsTrailingNewlineByDefault() throws {
        let fileIO = MemoryEditorFileIOStrategy(files: ["/tmp/crlf.txt": "first\r\nsecond\r\n"])
        let editor = Editor(dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared))
        editor.loadFileContent(into: editor.buffer, path: "/tmp/crlf.txt")

        #expect(editor.buffer.lineEnding == LineEnding.crlf)
        #expect(editor.buffer.lines == ["first", "second"])

        // Add a line and save
        editor.buffer.lines.append("third")
        editor.saveBufferContent(to: "/tmp/crlf.txt")

        let saved = fileIO.files["/tmp/crlf.txt"]
        #expect(saved == "first\r\nsecond\r\nthird\r\n")
    }

    @Test func testNoTrailingNewlinePreservation() throws {
        let fileIO = MemoryEditorFileIOStrategy(files: ["/tmp/notrailing.txt": "first\nsecond"])
        let editor = Editor(dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared))
        editor.loadFileContent(into: editor.buffer, path: "/tmp/notrailing.txt")

        #expect(editor.buffer.hasTrailingNewline == false)

        // Preserves absence of trailing newline
        editor.saveBufferContent(to: "/tmp/notrailing.txt")
        #expect(fileIO.files["/tmp/notrailing.txt"] == "first\nsecond")
    }

    @Test func testMixedLineEndingsMajorityVote() throws {
        // Mostly Unix with one CRLF line -> resolves to LF
        let mostlyLF = "line1\nline2\nline3\nline4\r\nline5\n"
        #expect(LineEnding.detect(in: mostlyLF) == LineEnding.lf)

        // Mostly DOS with one LF line -> resolves to CRLF
        let mostlyCRLF = "line1\r\nline2\r\nline3\r\nline4\nline5\r\n"
        #expect(LineEnding.detect(in: mostlyCRLF) == LineEnding.crlf)
    }

    @Test func testInjectedDefaultLineEndingOption() throws {
        let options = EditorOptions(defaultLineEnding: .crlf)
        let editor = Editor(
            options: options,
            dependencies: EditorDependencies(fileIOStrategy: TestLocalEditorFileIOStrategy.shared, terminal: TestEditorTerminal.shared)
        )

        // Newly created empty buffer uses the injected platform default
        #expect(editor.buffer.lineEnding == LineEnding.crlf)
    }
}
