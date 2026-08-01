import Foundation
import Testing

@testable import Editor

@Suite struct DirectoryBufferTests {

    @Test func testDirectoryBufferInitializationAndFormatting() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_\(UUID().uuidString)")
        let subDir = workDir.appendingPathComponent("subfolder")
        let fileURL = workDir.appendingPathComponent("notes.md")

        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        try "# Notes".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: workDir) }

        // Test Factory method TextBuffer.makeBuffer(filePath:)
        let buffer = TextBuffer.makeBuffer(filePath: workDir.path)
        #expect(buffer is DirectoryBuffer)
        #expect(buffer.isDirectoryBuffer == true)
        #expect(buffer.isReadOnly == true)
        #expect(buffer.allowsLogoExecution == false)

        let dirBuffer = buffer as! DirectoryBuffer
        #expect(dirBuffer.lines.count >= 5)
        #expect(dirBuffer.lines[0].contains("\" Directory:"))
        #expect(dirBuffer.lines[3] == ".. (up a dir)")

        // Contains subfolder and file
        #expect(dirBuffer.lines.contains("▸ subfolder/"))
        #expect(dirBuffer.lines.contains("  notes.md"))
    }

    @Test func testDirectoryBufferNavigationAndFileOpening() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_dir_nav_\(UUID().uuidString)")
        let subDir = workDir.appendingPathComponent("subfolder")
        let fileURL = workDir.appendingPathComponent("target.txt")

        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        try "Target file content".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: workDir) }

        let editor = Editor(filePath: workDir.path)
        #expect(editor.buffer is DirectoryBuffer)

        let dirBuffer = editor.buffer as! DirectoryBuffer

        // Find line index for subfolder
        if let idx = dirBuffer.lines.firstIndex(of: "▸ subfolder/") {
            dirBuffer.lineIndex = idx
            let handled = dirBuffer.activateEntry(editor: editor)
            #expect(handled == true)
            #expect(dirBuffer.directoryPath.hasSuffix("subfolder"))
        } else {
            Issue.record("Expected ▸ subfolder/ line in directory buffer")
        }

        // Navigate up
        let upHandled = dirBuffer.navigateUp(editor: editor)
        #expect(upHandled == true)
        #expect(dirBuffer.directoryPath == workDir.path)

        // Open target.txt
        if let fileIdx = dirBuffer.lines.firstIndex(of: "  target.txt") {
            dirBuffer.lineIndex = fileIdx
            let fileHandled = dirBuffer.activateEntry(editor: editor)
            #expect(fileHandled == true)
            // Editor should now have opened target.txt as a TextBuffer
            #expect(editor.buffer.isDirectoryBuffer == false)
            #expect(editor.buffer.lines.first == "Target file content")
        } else {
            Issue.record("Expected   target.txt line in directory buffer")
        }
    }

    @Test func testDirAndLsCommandBarCommands() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let editor = Editor()
        let initialBufCount = editor.buffers.count

        let res = editor.commandBarRegistry.dispatch("dir \(tempDir.path)", editor: editor)
        #expect(res == .handled)
        #expect(editor.buffer is DirectoryBuffer)
        #expect(editor.buffer.isDirectoryBuffer == true)
        #expect(editor.buffers.count == initialBufCount + 1)

        // Running dir again while already in same directory buffer reuses buffer instead of creating duplicate
        let res2 = editor.commandBarRegistry.dispatch("ls \(tempDir.path)", editor: editor)
        #expect(res2 == .handled)
        #expect(editor.buffer is DirectoryBuffer)
        #expect(editor.buffers.count == initialBufCount + 1)
    }

    @Test func testDirectoryBufferReadOnlyAndLogoBlock() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let editor = Editor(filePath: tempDir.path)
        #expect(editor.buffer.isDirectoryBuffer == true)

        let initialLinesCount = editor.buffer.lines.count

        // Enter on empty line 2 does not insert a newline
        editor.buffer.lineIndex = 2
        let enterHandled = editor.buffer.handleKey(.enter, editor: editor)
        #expect(enterHandled == true)
        #expect(editor.buffer.lines.count == initialLinesCount)

        // Typing character in DirectoryBuffer returns true (handled) and blocks mutation
        let handledChar = editor.buffer.handleKey(.char("a"), editor: editor)
        #expect(handledChar == true)
        #expect(editor.statusMessage == L10n["status.directory_buffer_readonly"])

        // Evaluating LOGO in DirectoryBuffer is blocked
        editor.evalLogoCode()
        #expect(editor.statusMessage == L10n["status.directory_buffer_readonly"])
    }

    @Test func testDirectoryBufferBinaryFileBlockingAndMenuVisibility() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let workDir = tempDir.appendingPathComponent("test_bin_\(UUID().uuidString)")
        let binFile = workDir.appendingPathComponent("app.bin")

        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        let binaryData = Data([0x00, 0x01, 0x02, 0xFF, 0xFE])
        try binaryData.write(to: binFile)
        defer { try? FileManager.default.removeItem(at: workDir) }

        let editor = Editor(filePath: workDir.path)
        #expect(editor.buffer is DirectoryBuffer)

        let dirBuffer = editor.buffer as! DirectoryBuffer
        if let idx = dirBuffer.lines.firstIndex(where: { $0.contains("app.bin") }) {
            dirBuffer.lineIndex = idx
            dirBuffer.activateEntry(editor: editor)
            #expect(editor.statusMessage == L10n["status.cannot_open_binary_file"])
            #expect(editor.buffer.isDirectoryBuffer == true)
        } else {
            Issue.record("Expected app.bin entry in directory buffer")
        }

        // Verify mode toggle menu items are hidden in Directory Mode
        editor.menuBar.updateCategories(for: editor)
        let editCategory = editor.menuBar.categories.first(where: { $0.titleKey == "menu.edit" })
        #expect(editCategory != nil)
        let modeItems = editCategory?.items.filter {
            ["menu.edit.text_editing_mode", "menu.edit.canvas_mode", "menu.edit.table_editing_mode"].contains(
                $0.titleKey)
        }
        #expect(modeItems?.isEmpty == true)
    }
}
