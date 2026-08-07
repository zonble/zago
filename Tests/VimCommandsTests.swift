import Foundation
import Testing

@testable import Editor

@Suite struct VimCommandsTests {

    @Test func testVimWriteCommands() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_vim_write_\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let editor = Editor()
        editor.buffer.lines = ["Vim write test"]
        editor.buffer.isModified = true

        // :w <path> or w <path>
        let res1 = editor.commandBarRegistry.dispatch("w \(fileURL.path)", editor: editor)
        #expect(res1 == .handled)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        #expect(editor.buffer.isModified == false)

        // Modify line again
        editor.buffer.lines[0] = "Modified line"
        editor.buffer.isModified = true

        // :w with no args saves to existing path
        let res2 = editor.commandBarRegistry.dispatch(":w", editor: editor)
        #expect(res2 == .handled)
        #expect(try String(contentsOf: fileURL, encoding: .utf8).contains("Modified line"))
        #expect(editor.buffer.isModified == false)
    }

    @Test func testVimQuitCommands() throws {
        let editor = Editor()
        editor.openNewBuffer(filePath: nil)
        editor.openNewBuffer(filePath: nil)
        #expect(editor.buffers.count == 3)

        // q or :q on clean buffer closes current buffer
        let res1 = editor.commandBarRegistry.dispatch(":q", editor: editor)
        #expect(res1 == .handled)
        #expect(editor.buffers.count == 2)

        // Modify remaining buffer
        editor.buffer.lines = ["Unsaved changes"]
        editor.buffer.isModified = true

        // :q on modified buffer triggers confirmation prompt mode
        _ = editor.commandBarRegistry.dispatch("q", editor: editor)
        if case .confirmExitSave = editor.currentPromptMode {
            // Correct prompt mode triggered for unsaved changes
            #expect(Bool(true))
        } else {
            Issue.record("Expected confirmExitSave prompt mode for modified buffer on :q")
        }
        editor.promptController.cancel()

        // :q! or q! forces buffer to close without saving prompt
        let res2 = editor.commandBarRegistry.dispatch(":q!", editor: editor)
        #expect(res2 == .handled)
        #expect(editor.buffers.count == 1)
    }

    @Test func testVimSaveExitAndXCommands() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_vim_x_\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let editor = Editor()
        editor.buffer.filePath = fileURL.path
        editor.buffer.lines = ["Unmodified text"]
        editor.buffer.isModified = false

        let initialBufferCount = editor.buffers.count

        // :x on unmodified file just closes buffer without writing
        let resX1 = editor.commandBarRegistry.dispatch(":x", editor: editor)
        #expect(resX1 == .handled)
        #expect(editor.buffers.count < initialBufferCount || !editor.isRunning)

        // Open new modified buffer
        let editor2 = Editor()
        let fileURL2 = tempDir.appendingPathComponent("test_vim_wq_\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: fileURL2) }
        editor2.buffer.filePath = fileURL2.path
        editor2.buffer.lines = ["Modified text"]
        editor2.buffer.isModified = true

        // :wq saves and closes buffer
        let resWQ = editor2.commandBarRegistry.dispatch(":wq", editor: editor2)
        #expect(resWQ == .handled)
        #expect(FileManager.default.fileExists(atPath: fileURL2.path))
        #expect(try String(contentsOf: fileURL2, encoding: .utf8).contains("Modified text"))
    }
}
