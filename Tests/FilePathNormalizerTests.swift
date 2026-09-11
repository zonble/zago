import Config
import Foundation
import Testing

@testable import Editor

@Suite struct FilePathNormalizerTests {
    // MARK: - 1. isFileURL Tests

    @Test func testIsFileURLBasic() {
        #expect(FilePathNormalizer.isFileURL("file:///Users/zonble/test.dart"))
        #expect(FilePathNormalizer.isFileURL("FILE:///C:/Users/zonble/test.dart"))
        #expect(FilePathNormalizer.isFileURL("File:///Users/zonble/test.dart"))
        #expect(FilePathNormalizer.isFileURL("file://localhost/etc/hosts"))
        #expect(FilePathNormalizer.isFileURL("file://127.0.0.1/etc/hosts"))
        #expect(FilePathNormalizer.isFileURL("<file:///path/to/file>"))
        #expect(FilePathNormalizer.isFileURL("  <file:///path/to/file>  "))
        #expect(FilePathNormalizer.isFileURL("\n  file:///path  \t"))
        #expect(FilePathNormalizer.isFileURL("file:relative/path.txt"))
        #expect(FilePathNormalizer.isFileURL("file://./relative/path.txt"))
        #expect(FilePathNormalizer.isFileURL("file://../sibling/path.txt"))
        #expect(FilePathNormalizer.isFileURL("file://~/notes.md"))
    }

    @Test func testIsFileURLNegativeCases() {
        #expect(!FilePathNormalizer.isFileURL("https://example.com"))
        #expect(!FilePathNormalizer.isFileURL("http://example.com/file"))
        #expect(!FilePathNormalizer.isFileURL("ftp://example.com/file"))
        #expect(!FilePathNormalizer.isFileURL("mailto:user@example.com"))
        #expect(!FilePathNormalizer.isFileURL("/Users/zonble/test.dart"))
        #expect(!FilePathNormalizer.isFileURL("C:\\Users\\zonble\\test.dart"))
        #expect(!FilePathNormalizer.isFileURL("file"))
        #expect(!FilePathNormalizer.isFileURL("filename.txt"))
        #expect(!FilePathNormalizer.isFileURL("files/test.png"))
        #expect(!FilePathNormalizer.isFileURL(""))
        #expect(!FilePathNormalizer.isFileURL("   "))
    }

    // MARK: - 2. fileURLToPath POSIX Tests

    @Test func testFileURLToPathPosix() {
        #expect(
            FilePathNormalizer.fileURLToPath("file:///Users/zonble/Work/kenwood_app/lib/blocs/ble_list/ble_list_state.dart")
                == "/Users/zonble/Work/kenwood_app/lib/blocs/ble_list/ble_list_state.dart"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file://localhost/Users/zonble/test.txt")
                == "/Users/zonble/test.txt"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file:///etc/hosts")
                == "/etc/hosts"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file://./relative/file.txt")
                == "./relative/file.txt"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file://../sibling/file.txt")
                == "../sibling/file.txt"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file://~/Documents/notes.md")
                == "~/Documents/notes.md"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("<file:///Users/zonble/notes.md>")
                == "/Users/zonble/notes.md"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("/regular/posix/path.txt")
                == "/regular/posix/path.txt"
        )
    }

    // MARK: - 3. fileURLToPath Windows Tests

    @Test func testFileURLToPathWindowsDrive() {
        #expect(
            FilePathNormalizer.fileURLToPath("file:///C:/Users/zonble/Documents/test.txt")
                == "C:/Users/zonble/Documents/test.txt"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file:///c:/Users/zonble/Documents/test.txt")
                == "c:/Users/zonble/Documents/test.txt"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file:///D:/Projects/zago/Package.swift")
                == "D:/Projects/zago/Package.swift"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file://localhost/C:/Users/zonble/Documents/test.txt")
                == "C:/Users/zonble/Documents/test.txt"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file://localhost/c:/Users/zonble/Documents/test.txt")
                == "c:/Users/zonble/Documents/test.txt"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file:///C%3A/Users/zonble/Documents/test.txt")
                == "C:/Users/zonble/Documents/test.txt"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file:///c%3a/Users/zonble/Documents/test.txt")
                == "c:/Users/zonble/Documents/test.txt"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file://C:/Users/zonble/Documents/test.txt")
                == "C:/Users/zonble/Documents/test.txt"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file://server/share/file.txt")
                == "server/share/file.txt"
        )
    }

    // MARK: - 4. fileURLToPath Percent-Encoding Tests

    @Test func testFileURLToPathPercentEncoding() {
        #expect(
            FilePathNormalizer.fileURLToPath("file:///Users/zonble/My%20Folder/%E6%B8%AC%E8%A9%A6.dart")
                == "/Users/zonble/My Folder/測試.dart"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file:///Users/zonble/%E5%B0%88%E6%A1%88/%E6%96%87%E4%BB%B6.txt")
                == "/Users/zonble/專案/文件.txt"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file:///Users/zonble/%E3%83%86%E3%82%B9%E3%83%88/%ED%85%8C%EC%8A%A4%ED%8A%B8.txt")
                == "/Users/zonble/テスト/테스트.txt"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file:///Users/zonble/%F0%9F%90%A7/penguin.txt")
                == "/Users/zonble/🐧/penguin.txt"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file:///Users/zonble/hello%2Bworld%231%40home.txt")
                == "/Users/zonble/hello+world#1@home.txt"
        )
        #expect(
            FilePathNormalizer.fileURLToPath("file:///Users/zonble/malformed%ZZname.txt")
                == "/Users/zonble/malformed%ZZname.txt"
        )
    }

    // MARK: - 5. parseLocation Tests

    @Test func testParseLocationWithAnchors() {
        // #L<line>
        let res1 = FilePathNormalizer.parseLocation(from: "file:///Users/zonble/app.dart#L42")
        #expect(res1.filePath == "/Users/zonble/app.dart")
        #expect(res1.line == 42)
        #expect(res1.column == nil)

        // #L<line>C<col>
        let res2 = FilePathNormalizer.parseLocation(from: "file:///Users/zonble/app.dart#L42C15")
        #expect(res2.filePath == "/Users/zonble/app.dart")
        #expect(res2.line == 42)
        #expect(res2.column == 15)

        // #L<line>c<col>
        let res2b = FilePathNormalizer.parseLocation(from: "file:///Users/zonble/app.dart#L42c15")
        #expect(res2b.filePath == "/Users/zonble/app.dart")
        #expect(res2b.line == 42)
        #expect(res2b.column == 15)

        // #L<line>:<col>
        let res3 = FilePathNormalizer.parseLocation(from: "file:///Users/zonble/app.dart#L42:15")
        #expect(res3.filePath == "/Users/zonble/app.dart")
        #expect(res3.line == 42)
        #expect(res3.column == 15)

        // #<line>
        let res3b = FilePathNormalizer.parseLocation(from: "file:///Users/zonble/app.dart#99")
        #expect(res3b.filePath == "/Users/zonble/app.dart")
        #expect(res3b.line == 99)
        #expect(res3b.column == nil)

        // :<line>:<col>
        let res4 = FilePathNormalizer.parseLocation(from: "file:///Users/zonble/app.dart:100:20")
        #expect(res4.filePath == "/Users/zonble/app.dart")
        #expect(res4.line == 100)
        #expect(res4.column == 20)

        // :<line>
        let res5 = FilePathNormalizer.parseLocation(from: "file:///Users/zonble/app.dart:100")
        #expect(res5.filePath == "/Users/zonble/app.dart")
        #expect(res5.line == 100)
        #expect(res5.column == nil)

        // Plain POSIX path with colon line
        let res5b = FilePathNormalizer.parseLocation(from: "/home/user/script.py:75:12")
        #expect(res5b.filePath == "/home/user/script.py")
        #expect(res5b.line == 75)
        #expect(res5b.column == 12)

        // Windows drive path with colon line and col
        let res6 = FilePathNormalizer.parseLocation(from: "C:\\Users\\zonble\\app.dart:55:10")
        #expect(res6.filePath == "C:\\Users\\zonble\\app.dart")
        #expect(res6.line == 55)
        #expect(res6.column == 10)

        // Windows drive path with colon line only
        let res6b = FilePathNormalizer.parseLocation(from: "C:\\Users\\zonble\\app.dart:55")
        #expect(res6b.filePath == "C:\\Users\\zonble\\app.dart")
        #expect(res6b.line == 55)
        #expect(res6b.column == nil)

        // Windows drive path without line numbers (C: must not be mistaken for line number)
        let res7 = FilePathNormalizer.parseLocation(from: "C:\\Users\\zonble\\app.dart")
        #expect(res7.filePath == "C:\\Users\\zonble\\app.dart")
        #expect(res7.line == nil)
        #expect(res7.column == nil)

        let res7b = FilePathNormalizer.parseLocation(from: "D:/Projects/zago/main.swift")
        #expect(res7b.filePath == "D:/Projects/zago/main.swift")
        #expect(res7b.line == nil)
        #expect(res7b.column == nil)

        // Empty string
        let res8 = FilePathNormalizer.parseLocation(from: "")
        #expect(res8.filePath == "")
        #expect(res8.line == nil)
        #expect(res8.column == nil)
    }

    // MARK: - 6. Editor openBuffer Tests

    @Test func testEditorOpenBufferWithFileURLAndLineAnchor() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("sample.txt")
        let content = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5"
        try content.write(to: testFile, atomically: true, encoding: .utf8)

        let editor = Editor()
        let fileUrlString = testFile.absoluteString + "#L3"
        let result = editor.openBuffer(path: fileUrlString)

        #expect(result == .succeeded)
        #expect(editor.buffer.lineIndex == 2)
        #expect(editor.buffer.columnIndex == 0)
    }

    @Test func testEditorOpenBufferWithLineAndColumnAnchor() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("code.swift")
        let content = "func alpha() {}\nfunc beta() {\n    let val = 42\n}"
        try content.write(to: testFile, atomically: true, encoding: .utf8)

        let editor = Editor()
        let fileUrlString = testFile.absoluteString + "#L3C9"
        let result = editor.openBuffer(path: fileUrlString)

        #expect(result == .succeeded)
        #expect(editor.buffer.lineIndex == 2)
        #expect(editor.buffer.columnIndex == 8)
    }

    @Test func testEditorOpenBufferWithColonSyntax() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("test.py")
        let content = "print('1')\nprint('2')\nprint('3')"
        try content.write(to: testFile, atomically: true, encoding: .utf8)

        let editor = Editor()
        let fileUrlString = testFile.absoluteString + ":2:7"
        let result = editor.openBuffer(path: fileUrlString)

        #expect(result == .succeeded)
        #expect(editor.buffer.lineIndex == 1)
        #expect(editor.buffer.columnIndex == 6)
    }

    @Test func testEditorOpenBufferSwitchesExistingBuffer() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile1 = tempDir.appendingPathComponent("file1.txt")
        let testFile2 = tempDir.appendingPathComponent("file2.txt")
        try "A1\nA2\nA3\nA4".write(to: testFile1, atomically: true, encoding: .utf8)
        try "B1\nB2\nB3\nB4".write(to: testFile2, atomically: true, encoding: .utf8)

        let editor = Editor()
        _ = editor.openBuffer(path: testFile1.path)
        _ = editor.openBuffer(path: testFile2.path)
        #expect(editor.buffer.filePath?.hasSuffix("file2.txt") == true)

        // Reopen file1 via file URL with jump to line 3
        let result = editor.openBuffer(path: testFile1.absoluteString + "#L3")
        #expect(result == .succeeded)
        #expect(editor.buffer.filePath?.hasSuffix("file1.txt") == true)
        #expect(editor.buffer.lineIndex == 2)
    }

    @Test func testEditorOpenBufferWithPercentEncodedCJKName() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("測試 筆記.md")
        let content = "# 標題\n內文第一行\n內文第二行"
        try content.write(to: testFile, atomically: true, encoding: .utf8)

        let editor = Editor()
        let fileUrlString = testFile.absoluteString + "#L2"
        let result = editor.openBuffer(path: fileUrlString)

        #expect(result == .succeeded)
        #expect(editor.buffer.lines.count == 3)
        #expect(editor.buffer.lineIndex == 1)
    }

    // MARK: - 7. File Operations (Save & Insert) with file:// URLs

    @Test func testEditorSaveBufferWithFileURL() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let targetFile = tempDir.appendingPathComponent("saved_output.txt")
        let editor = Editor()
        editor.buffer.replaceContents("Hello from Zago!", filePath: nil, isModified: true)

        let result = editor.saveBufferContent(to: targetFile.absoluteString)
        #expect(result == .succeeded)

        let saved = try String(contentsOf: targetFile, encoding: .utf8)
        #expect(saved.contains("Hello from Zago!"))
    }

    @Test func testEditorInsertFileContentWithFileURL() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let sourceFile = tempDir.appendingPathComponent("source.txt")
        try "Inserted Line A\nInserted Line B\n".write(to: sourceFile, atomically: true, encoding: .utf8)

        let editor = Editor()
        editor.buffer.replaceContents("Original\n", filePath: nil, isModified: false)

        let result = editor.insertFileContent(from: sourceFile.absoluteString)
        #expect(result == .succeeded)
        #expect(editor.buffer.lines.contains("Inserted Line A"))
    }

    // MARK: - 8. Prompt Tab Completion Tests

    @Test func testPromptTabCompletionWithFileURLSingleMatch() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let subDir = tempDir.appendingPathComponent("myfolder")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        let subFile = subDir.appendingPathComponent("target.txt")
        try "hello".write(to: subFile, atomically: true, encoding: .utf8)

        let editor = Editor()
        editor.promptOpenFilePath()

        let typedPrefix = "file://" + tempDir.path + "/my"
        editor.promptInputText = typedPrefix
        editor.promptCursorIndex = typedPrefix.count

        editor.processKey(.tab)

        #expect(editor.promptInputText.hasPrefix("file://" + tempDir.path + "/myfolder/"))
    }

    @Test func testPromptTabCompletionAmbiguousMatches() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileA = tempDir.appendingPathComponent("alpha_one.txt")
        let fileB = tempDir.appendingPathComponent("alpha_two.txt")
        try "1".write(to: fileA, atomically: true, encoding: .utf8)
        try "2".write(to: fileB, atomically: true, encoding: .utf8)

        let editor = Editor()
        editor.promptOpenFilePath()

        let typedPrefix = "file://" + tempDir.path + "/al"
        editor.promptInputText = typedPrefix
        editor.promptCursorIndex = typedPrefix.count

        editor.processKey(.tab)

        // Common prefix "alpha_" should be autocompleted
        #expect(editor.promptInputText == "file://" + tempDir.path + "/alpha_")
    }

    // MARK: - 9. DocumentLinkParser with file:// URLs

    @Test func testDocumentLinkParserWithFileURLAndAnchor() {
        let markdownLine = "See [State Class](file:///Users/zonble/Work/app/state.dart#L42C10) for details."
        let link = DocumentLinkParser.link(atColumn: 10, in: markdownLine)
        #expect(link != nil)
        #expect(link?.target == "file:///Users/zonble/Work/app/state.dart#L42C10")

        let parsed = DocumentLinkParser.parseTarget(link!.target)
        #expect(parsed?.path == "/Users/zonble/Work/app/state.dart")
        #expect(parsed?.anchor == "L42C10")
    }

    @Test func testDocumentLinkParserWithPercentEncodedFileURL() {
        let markdownLine = "Open [Doc](file:///Users/zonble/My%20Folder/%E6%96%87%E4%BB%B6.md#section-one)"
        let link = DocumentLinkParser.link(atColumn: 12, in: markdownLine)
        #expect(link != nil)

        let parsed = DocumentLinkParser.parseTarget(link!.target)
        #expect(parsed?.path == "/Users/zonble/My Folder/文件.md")
        #expect(parsed?.anchor == "section-one")
    }
}
