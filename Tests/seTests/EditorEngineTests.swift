import Testing
import Foundation
@testable import Editor

@Test func testShiftArrowKeyEnum() throws {
    let keyLeft: Key = .shiftArrowLeft
    let keyRight: Key = .shiftArrowRight
    let keyUp: Key = .shiftArrowUp
    let keyDown: Key = .shiftArrowDown
    #expect(keyLeft != keyRight)
    #expect(keyUp != keyDown)
}

@Test func testEditorUndoStack() throws {
    let editor = Editor()
    #expect(editor.buffer.lines[0] == "")

    editor.saveUndoSnapshot()
    editor.buffer.insertString("Hello World")
    #expect(editor.buffer.lines[0] == "Hello World")

    editor.saveUndoSnapshot()
    editor.buffer.insertString(" - Swift TUI")
    #expect(editor.buffer.lines[0] == "Hello World - Swift TUI")

    editor.performUndo()
    #expect(editor.buffer.lines[0] == "Hello World")

    editor.performUndo()
    #expect(editor.buffer.lines[0] == "")
}

@Test func testCommandRegistry() throws {
    let editor = Editor()
    #expect(editor.commandRegistry.commands.count > 20)

    var executed = false
    let testCmd = Command(id: "test.cmd", name: "Test", description: "Test command", keys: [.ctrl("T")]) { _ in
        executed = true
    }
    let registry = CommandRegistry()
    registry.register(testCmd)

    let handled = registry.dispatch(key: .ctrl("T"), editor: editor)
    #expect(handled == true)
    #expect(executed == true)
}

@Test func testMultiBufferOperations() throws {
    let editor = Editor(filePaths: ["file1.txt", "file2.txt"])
    #expect(editor.buffers.count == 2)
    #expect(editor.currentBufferIndex == 0)
    #expect(editor.buffer.filePath?.contains("file1.txt") == true)

    // Test next buffer
    editor.nextBuffer()
    #expect(editor.currentBufferIndex == 1)
    #expect(editor.buffer.filePath?.contains("file2.txt") == true)

    // Test next buffer wrapping back to 0
    editor.nextBuffer()
    #expect(editor.currentBufferIndex == 0)

    // Test prev buffer wrapping to last
    editor.prevBuffer()
    #expect(editor.currentBufferIndex == 1)

    // Test opening a new buffer
    editor.openNewBuffer(filePath: "file3.txt")
    #expect(editor.buffers.count == 3)
    #expect(editor.currentBufferIndex == 2)
    #expect(editor.buffer.filePath?.contains("file3.txt") == true)

    // Test screen render Title Bar format includes [3/3]
    let output = editor.generateScreenOutput(rows: 24, cols: 80)
    #expect(output.contains("[3/3]"))

    // Test close current buffer
    editor.closeCurrentBuffer()
    #expect(editor.buffers.count == 2)
    #expect(editor.currentBufferIndex == 1)
}

@Test func testEditorProcessKeyInput() throws {
    let editor = Editor()
    #expect(editor.buffer.lines.count == 1)
    #expect(editor.buffer.lines[0] == "")

    // Test typing characters
    editor.processKey(.char("H"))
    editor.processKey(.char("i"))
    #expect(editor.buffer.lines[0] == "Hi")

    // Test Enter
    editor.processKey(.enter)
    #expect(editor.buffer.lines.count == 2)

    // Test typing on second line
    editor.processKey(.char("W"))
    #expect(editor.buffer.lines[1] == "W")

    // Test Backspace
    editor.processKey(.backspace)
    #expect(editor.buffer.lines[1] == "")
}

@Test func testAltLTriggersLogoPrompt() throws {
    let editor = Editor()

    // Test Alt+l (.alt("l"))
    editor.processKey(.alt("l"))
    if case .logoMacro = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Alt+l should trigger LOGO prompt mode")
    }

    editor.currentPromptMode = .none

    // Test Alt+L (.alt("L"))
    editor.processKey(.alt("L"))
    if case .logoMacro = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Alt+L should trigger LOGO prompt mode")
    }

    editor.currentPromptMode = .none

    // Test macOS Option+L character '¬'
    editor.processKey(.char("¬"))
    if case .logoMacro = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Option+L character ¬ should trigger LOGO prompt mode")
    }
}

@Test func testCtrlBackspaceDeleteLineCommand() throws {
    let editor = Editor()
    editor.buffer.lines = ["First Line", "Second Line", "Third Line"]
    editor.buffer.lineIndex = 1

    editor.processKey(.ctrlBackspace)
    #expect(editor.buffer.lines == ["First Line", "Third Line"])

    editor.performUndo()
    #expect(editor.buffer.lines == ["First Line", "Second Line", "Third Line"])
}

@Test func testF4SaveAndExitCommand() throws {
    let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent("test_f4_save_exit.txt").path
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    let editor = Editor(filePath: tmpPath)
    editor.buffer.lines = ["Line 1 for F4 test"]
    editor.buffer.isModified = true

    // Trigger F4 (file.save_exit)
    let handled = editor.commandRegistry.dispatch(key: .f4, editor: editor)
    #expect(handled == true)

    // File should be saved to disk
    let savedContent = try String(contentsOfFile: tmpPath, encoding: .utf8)
    #expect(savedContent == "Line 1 for F4 test")
}

@Test func testCtrlITabInsertion() throws {
    let editor = Editor()
    editor.processKey(.ctrl("I"))
    #expect(editor.buffer.lines[0] == "    ")
}
