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
    let testCmd = BlockCommand(id: .testCmd, name: "Test", description: "Test command", keys: [.ctrl("T")]) { _ in
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

@Test func testMenuBarActivationAndNavigation() throws {
    let editor = Editor()
    #expect(editor.isMenuBarActive == false)

    // Press ESC in normal mode (should NOT activate Menu Bar)
    editor.processKey(.esc)
    #expect(editor.isMenuBarActive == false)

    // 1. Press F1 to activate Menu Bar
    editor.processKey(.f1)
    #expect(editor.isMenuBarActive == true)
    #expect(editor.menuBar.categoryIndex == 0)

    // 2. Press Right Arrow to switch to Edit category (index 1)
    editor.processKey(.arrowRight)
    #expect(editor.menuBar.categoryIndex == 1)

    // 3. Press Down Arrow to navigate items in Edit menu
    editor.processKey(.arrowDown)
    #expect(editor.menuBar.itemIndex == 1)

    // 4. Press letter 's' to jump to Search menu (index 2)
    editor.processKey(.char("s"))
    #expect(editor.menuBar.categoryIndex == 2)

    // 5. Press ESC to close Menu Bar
    editor.processKey(.esc)
    #expect(editor.isMenuBarActive == false)

    // 6. Press Ctrl+M to activate Menu Bar
    editor.processKey(.ctrl("M"))
    #expect(editor.isMenuBarActive == true)
    editor.processKey(.esc)
    #expect(editor.isMenuBarActive == false)

    // 7. Test executing menu item via Enter
    editor.processKey(.f1) // Activate menu
    editor.menuBar.categoryIndex = 4 // Tools category
    editor.menuBar.itemIndex = 0 // LOGO Macro
    editor.processKey(.enter) // Execute
    #expect(editor.isMenuBarActive == false)
    if case .logoMacro = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Enter on LOGO item should trigger LOGO prompt mode")
    }

    // 8. Test Goto Line from Search menu (category 2, item 2)
    editor.currentPromptMode = .none
    editor.processKey(.f1)
    editor.menuBar.categoryIndex = 2 // Search category
    editor.menuBar.itemIndex = 2 // Goto Line
    editor.processKey(.enter)
    #expect(editor.isMenuBarActive == false)
    if case .gotoLine = editor.currentPromptMode {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Enter on Goto Line item should trigger gotoLine prompt mode")
    }
}

@Test func testSearchPromptMiddleSpaceInsertion() throws {
    let editor = Editor()
    editor.promptSearch()

    // Type "hello"
    for ch in "hello" {
        editor.processPromptKey(.char(ch))
    }
    #expect(editor.promptInputText == "hello")
    #expect(editor.promptCursorIndex == 5)

    // Move cursor left 3 times (between 'e' and 'l')
    editor.processPromptKey(.arrowLeft)
    editor.processPromptKey(.arrowLeft)
    editor.processPromptKey(.arrowLeft)
    #expect(editor.promptCursorIndex == 2)

    // Type space ' '
    editor.processPromptKey(.char(" "))

    // Expect "he llo", NOT "hello "!
    #expect(editor.promptInputText == "he llo")
    #expect(editor.promptCursorIndex == 3)
}
