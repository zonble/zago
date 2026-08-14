import Foundation
import ANSIStyle
import Testing

@testable import Editor

@Test func testSearchPromptMiddleSpaceInsertion() throws {
    let editor = Editor()
    editor.promptSearch()

    for ch in "hello" {
        editor.processKey(.char(ch))
    }
    #expect(editor.promptInputText == "hello")
    #expect(editor.promptCursorIndex == 5)

    editor.processKey(.arrowLeft)
    editor.processKey(.arrowLeft)
    editor.processKey(.arrowLeft)
    #expect(editor.promptCursorIndex == 2)

    editor.processKey(.char(" "))

    #expect(editor.promptInputText == "he llo")
    #expect(editor.promptCursorIndex == 3)
}

@Test func testCommandBarNumericGotoShorthand() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two", "three"]

    submitCommandBar("2", editor: editor)

    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 0)
    #expect(editor.logoEngine.lastResult == nil)
}

@Test func testCommandBarColonNumericGotoShorthand() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two", "three"]

    submitCommandBar(":2", editor: editor)

    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 0)
    #expect(editor.logoEngine.lastResult == nil)
}

@Test func testCommandBarNumericGotoWithColumnShorthand() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two", "three"]

    submitCommandBar("3:2", editor: editor)

    #expect(editor.buffer.lineIndex == 2)
    #expect(editor.buffer.columnIndex == 1)

    submitCommandBar("1,3", editor: editor)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 2)
}

@Test func testCommandBarGotoCommandAcceptsLineAndColumn() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two", "three"]

    submitCommandBar("goto 3 2", editor: editor)

    #expect(editor.buffer.lineIndex == 2)
    #expect(editor.buffer.columnIndex == 1)
    #expect(editor.logoEngine.lastResult == nil)

    submitCommandBar("GOTO 1,3", editor: editor)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 2)
    #expect(editor.logoEngine.lastResult == nil)

    submitCommandBar("goto 2:2", editor: editor)

    #expect(editor.buffer.lineIndex == 1)
    #expect(editor.buffer.columnIndex == 1)
    #expect(editor.logoEngine.lastResult == nil)

    submitCommandBar("goto 1 50", editor: editor)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.buffer.columnIndex == 3)
    #expect(editor.logoEngine.lastResult == nil)
}

@Test func testCommandBarLogoExpressionFallback() throws {
    let editor = Editor()

    submitCommandBar("1 + 1", editor: editor)

    #expect(editor.logoEngine.lastResult == "2")
    #expect(editor.statusMessage == "2")
}

@Test func testCommandBarInvalidNumericGotoDoesNotFallThroughToLogo() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two"]

    submitCommandBar("-1", editor: editor)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.logoEngine.lastResult == nil)
    #expect(editor.statusMessage == editor.l10n["status.invalid_line"])

    submitCommandBar("0", editor: editor)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.logoEngine.lastResult == nil)
    #expect(editor.statusMessage == editor.l10n["status.invalid_line"])

    submitCommandBar(":0", editor: editor)

    #expect(editor.buffer.lineIndex == 0)
    #expect(editor.logoEngine.lastResult == nil)
    #expect(editor.statusMessage == editor.l10n["status.invalid_line"])
}

@Test func testCommandBarGotoEndOfFile() throws {
    let editor = Editor()
    editor.buffer.lines = ["one", "two", "three"]
    editor.buffer.lineIndex = 0
    editor.buffer.columnIndex = 0

    submitCommandBar("eof", editor: editor)

    #expect(editor.buffer.lineIndex == 2)
    #expect(editor.buffer.columnIndex == 5)

    submitCommandBar(":end-of-file", editor: editor)

    #expect(editor.buffer.lineIndex == 2)
    #expect(editor.buffer.columnIndex == 5)
}

@Test func testCommandBarOpenNewAndBufferShorthand() throws {
    let editor = Editor()
    editor.buffer.filePath = "first.txt"

    submitCommandBar("open second.txt", editor: editor)

    #expect(editor.buffers.count == 2)
    #expect(editor.currentBufferIndex == 1)
    #expect(editor.buffer.filePath == "second.txt")

    submitCommandBar("new", editor: editor)

    #expect(editor.buffers.count == 3)
    #expect(editor.currentBufferIndex == 2)
    #expect(editor.buffer.filePath == nil)

    submitCommandBar("buffer prev", editor: editor)
    #expect(editor.currentBufferIndex == 1)

    submitCommandBar("buffer 1", editor: editor)
    #expect(editor.currentBufferIndex == 0)

    submitCommandBar("buffer 99", editor: editor)
    #expect(editor.currentBufferIndex == 0)
    #expect(editor.statusMessage == editor.l10n["status.no_such_buffer"])
}

@Test func testCommandBarUppercaseBufferUsesCommandBarCommand() throws {
    let editor = Editor()
    editor.buffer.filePath = "first.txt"
    editor.openNewBuffer(filePath: "second.txt")
    editor.currentBufferIndex = 0

    submitCommandBar("BUFFER 2", editor: editor)

    #expect(editor.currentBufferIndex == 1)
}

@Test func testCommandBarWriteShorthandUsesEditorSavePath() throws {
    let path = FileManager.default.temporaryDirectory.appendingPathComponent(
        "zago_command_bar_write_\(UUID().uuidString).txt"
    ).path
    defer { try? FileManager.default.removeItem(atPath: path) }
    let editor = Editor()
    editor.buffer.lines = ["command bar write"]
    editor.buffer.isModified = true

    submitCommandBar("write \(path)", editor: editor)

    #expect(try String(contentsOfFile: path, encoding: .utf8) == "command bar write")
    #expect(editor.buffer.filePath == path)
    #expect(editor.buffer.isModified == false)
}

@Test func testCommandBarUppercaseSaveUsesEditorCommand() throws {
    let path = FileManager.default.temporaryDirectory.appendingPathComponent(
        "zago_command_bar_save_\(UUID().uuidString).txt"
    ).path
    defer { try? FileManager.default.removeItem(atPath: path) }
    let editor = Editor(filePath: path)
    editor.buffer.lines = ["command bar save"]
    editor.buffer.isModified = true

    submitCommandBar("SAVE", editor: editor)

    #expect(try String(contentsOfFile: path, encoding: .utf8) == "command bar save")
    #expect(editor.buffer.isModified == false)
}

@Test func testCommandBarSettingCommandsAreEditorCommands() throws {
    let editor = Editor()
    editor.displayConfig.showRuler = false
    editor.displayConfig.showLineNumbers = true
    editor.displayConfig.enableSyntaxHighlight = true

    submitCommandBar("SET RULER ON", editor: editor)
    #expect(editor.displayConfig.showRuler == true)

    submitCommandBar("set linenumbers off", editor: editor)
    #expect(editor.displayConfig.showLineNumbers == false)

    submitCommandBar("set syntax off", editor: editor)
    #expect(editor.displayConfig.enableSyntaxHighlight == false)

    submitCommandBar("set trim-trailing-whitespace on", editor: editor)
    #expect(editor.displayConfig.trimTrailingWhitespaceOnSave == true)

    submitCommandBar("unset trim-trailing-whitespace", editor: editor)
    #expect(editor.displayConfig.trimTrailingWhitespaceOnSave == false)

    submitCommandBar("set wrap 4", editor: editor)
    #expect(editor.layoutEngine.wrapColumn == 10)

    submitCommandBar("unset wrap", editor: editor)
    #expect(editor.layoutEngine.wrapColumn == nil)

    submitCommandBar("set canvas-mode on", editor: editor)
    #expect(editor.isCanvasModeActive == true)

    submitCommandBar("SET CANVAS-MODE OFF", editor: editor)
    #expect(editor.isCanvasModeActive == false)

    submitCommandBar("unset canvas-mode", editor: editor)
    #expect(editor.isCanvasModeActive == false)
}

@Test func testCommandBarSetTabShowsSettingCompletions() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "SET " {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "SET ")
    #expect(editor.promptCompletionText?.contains("wrap") == true)
    #expect(editor.promptCompletionText?.contains("linenumbers") == true)
    #expect(editor.promptCompletionText?.contains("sublinenumbers") == true)
    #expect(editor.promptCompletionText?.contains("canvas-mode") == true)
    #expect(editor.promptCompletionText?.contains("syntax") == true)
    #expect(editor.promptCompletionText?.hasPrefix("SET: ") == true)
}

@Test func testCommandBarSetTabCompletesUniqueSettingPrefix() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "set li" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "set li")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarSetValueTabShowsValueCompletions() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "set syntax " {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "set syntax ")
    #expect(editor.promptCompletionText?.contains("on") == true)
    #expect(editor.promptCompletionText?.contains("off") == true)
}

@Test func testCommandBarSetCanvasModeValueTabShowsValueCompletions() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "set canvas-mode " {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "set canvas-mode ")
    #expect(editor.promptCompletionText?.contains("on") == true)
    #expect(editor.promptCompletionText?.contains("off") == true)
}

@Test func testCommandBarTabCompletesLogoKeyword() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "drawb" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "drawbox ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarTabCompletesCommandBarCommand() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "QUI" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "QUIT ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarTabCompletesHyphenatedCommandBarCommand() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "save-" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "save-exit ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarTabShowsMixedCommandAndLogoCompletions() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "sa" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "save")
    #expect(editor.promptCompletionText?.contains("save") == true)
    #expect(editor.promptCompletionText?.contains("save-exit") == true)
}

@Test func testCommandBarCompletionClearsOnEsc() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "sa" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)
    #expect(editor.promptCompletionText != nil)

    editor.processKey(.esc)
    #expect(editor.promptCompletionText == nil)
    #expect(editor.statusMessage.contains("save") == false)
}

@Test func testCommandBarTabCompletesTokenWithLeadingContext() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "box 10 drawb" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "box 10 drawbox ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarTabCompletesTokenAfterBracket() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "REPEAT 5 [drawb" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.tab)

    #expect(editor.promptInputText == "REPEAT 5 [drawbox ")
    #expect(editor.promptCursorIndex == editor.promptInputText.count)
}

@Test func testCommandBarExitAndSaveExitCommands() throws {
    let savePath = FileManager.default.temporaryDirectory.appendingPathComponent(
        "zago_command_bar_save_exit_\(UUID().uuidString).txt"
    ).path
    defer { try? FileManager.default.removeItem(atPath: savePath) }

    let editor = Editor()
    editor.buffer.filePath = "first.txt"
    editor.openNewBuffer(filePath: savePath)
    editor.buffer.lines = ["save and exit"]
    editor.buffer.isModified = true

    submitCommandBar("save-exit", editor: editor)

    #expect(try String(contentsOfFile: savePath, encoding: .utf8) == "save and exit")
    #expect(editor.buffers.count == 1)
    #expect(editor.currentBufferIndex == 0)

    editor.openNewBuffer(filePath: "third.txt")
    submitCommandBar("quit", editor: editor)

    #expect(editor.buffers.count == 1)
    #expect(editor.currentBufferIndex == 0)
}

@Test func testCommandBarSelectionCopyCutAndPaste() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "hello" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.shiftArrowLeft)
    editor.processKey(.shiftArrowLeft)
    #expect(editor.promptController.selectionRange() == 3..<5)

    let rendered = editor.renderer.formatPromptLine(editor: editor, cols: 80).text
    #expect(rendered.contains("\(ANSIStyle.boldInverse)lo"))

    editor.processKey(.alt("W"))
    #expect(editor.clipboardText == "lo")
    #expect(editor.promptInputText == "hello")

    editor.processKey(.ctrl("K"))
    #expect(editor.clipboardText == "lo")
    #expect(editor.promptInputText == "hel")
    #expect(editor.promptCursorIndex == 3)
    #expect(editor.promptController.selectionRange() == nil)

    editor.processKey(.ctrl("U"))
    #expect(editor.promptInputText == "hello")
    #expect(editor.promptCursorIndex == 5)

    editor.processKey(.shiftArrowLeft)
    editor.processKey(.char("!"))
    #expect(editor.promptInputText == "hell!")
    #expect(editor.promptCursorIndex == 5)
}

@Test func testCommandBarMiddleSelectionTurnsOffInverseForSubsequentText() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "hello world" {
        editor.processKey(.char(ch))
    }
    // Cursor at index 5 ("hello" | " world")
    editor.promptCursorIndex = 5
    editor.processKey(.shiftArrowLeft)
    editor.processKey(.shiftArrowLeft)
    #expect(editor.promptController.selectionRange() == 3..<5)

    let rendered = editor.renderer.formatPromptLine(editor: editor, cols: 80).text
    // Selected range 'lo' should be bold inverse
    #expect(rendered.contains("\(ANSIStyle.boldInverse)lo"))
    // Subsequent text ' world' must follow inverseOff (\u{1B}[27m) and not be inverse
    #expect(rendered.contains("\(ANSIStyle.inverseOff) world"))
}

@Test func testCommandBarCtrlKWithoutSelectionCutsToEnd() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "hello world" {
        editor.processKey(.char(ch))
    }
    editor.promptCursorIndex = 6

    editor.processKey(.ctrl("K"))

    #expect(editor.clipboardText == "world")
    #expect(editor.promptInputText == "hello ")
    #expect(editor.promptCursorIndex == 6)
}

@Test func testCommandBarShiftLeftCompatibleSequencesSelectOneCharacter() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "hello" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.ctrlShift("B"))

    #expect(editor.promptCursorIndex == 4)
    #expect(editor.promptController.selectionRange() == 4..<5)
}

@Test func testCommandBarOpeningPromptClearsStaleSelectionAnchor() throws {
    let editor = Editor()
    editor.promptLogoMacro()
    for ch in "hello" {
        editor.processKey(.char(ch))
    }
    editor.processKey(.shiftArrowLeft)
    #expect(editor.promptController.selectionRange() == 4..<5)

    editor.promptTableDimensions()
    editor.processKey(.shiftArrowLeft)

    #expect(editor.promptInputText == "3 3 16")
    #expect(editor.promptCursorIndex == editor.promptInputText.count - 1)
    #expect(editor.promptController.selectionRange() == editor.promptInputText.count - 1..<editor.promptInputText.count)
}

@Test func testCommandBarCtrlXExitsEditor() throws {
    let editor = Editor()
    editor.isRunning = true
    editor.promptLogoMacro()
    for ch in "partial command" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.ctrl("X"))

    #expect(editor.isRunning == false)
    if case .none = editor.currentPromptMode {
    } else {
        Issue.record("Expected ^X from command bar to clear the active prompt")
    }
    #expect(editor.promptInputText.isEmpty)
}

@Test func testCommandBarCtrlXPromptsBeforeExitingModifiedBuffer() throws {
    let editor = Editor()
    editor.isRunning = true
    editor.buffer.isModified = true
    editor.promptLogoMacro()
    for ch in "partial command" {
        editor.processKey(.char(ch))
    }

    editor.processKey(.ctrl("X"))

    if case .confirmExitSave = editor.currentPromptMode {
        #expect(editor.isRunning == true)
        #expect(editor.promptInputText.isEmpty)
    } else {
        Issue.record("Expected ^X from command bar to open exit-save confirmation for modified buffer")
    }
}

@Test func testCommandBarDiagramAndOutlineAndBorderAliases() throws {
    let editor = Editor()

    #expect(editor.isMenuBarActive == false)
    submitCommandBar("diagram", editor: editor)
    #expect(editor.isMenuBarActive == true)
    editor.isMenuBarActive = false

    submitCommandBar("snippets", editor: editor)
    #expect(editor.isMenuBarActive == true)
    editor.isMenuBarActive = false

    let initialStyle = editor.defaultBorderStyle
    submitCommandBar("border", editor: editor)
    #expect(editor.defaultBorderStyle != initialStyle)

    let nextStyle = editor.defaultBorderStyle
    submitCommandBar("border-style", editor: editor)
    #expect(editor.defaultBorderStyle != nextStyle)

    editor.buffer.lines = ["# Title", "Content"]
    submitCommandBar("toc", editor: editor)
    submitCommandBar("headings", editor: editor)
    submitCommandBar("outline", editor: editor)
}

private func submitCommandBar(_ text: String, editor: Editor) {
    editor.promptLogoMacro()
    for ch in text {
        editor.processKey(.char(ch))
    }
    editor.processKey(.enter)
}
