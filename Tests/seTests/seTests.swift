import Testing
import Foundation
@testable import Editor

@Test func testTextBufferBasicEditing() throws {
    let buffer = TextBuffer()
    #expect(buffer.lines == [""])
    #expect(buffer.lineIndex == 0)
    #expect(buffer.columnIndex == 0)

    buffer.insert(character: "H")
    buffer.insert(character: "e")
    buffer.insert(character: "l")
    buffer.insert(character: "l")
    buffer.insert(character: "o")
    #expect(buffer.lines == ["Hello"])
    #expect(buffer.columnIndex == 5)

    buffer.insertNewline()
    #expect(buffer.lines == ["Hello", ""])
    #expect(buffer.lineIndex == 1)
    #expect(buffer.columnIndex == 0)

    buffer.insert(character: "W")
    buffer.insert(character: "o")
    buffer.insert(character: "r")
    buffer.insert(character: "l")
    buffer.insert(character: "d")
    #expect(buffer.lines == ["Hello", "World"])

    buffer.backspace()
    #expect(buffer.lines == ["Hello", "Worl"])
}

@Test func testSoftwrapLayoutEngine() throws {
    let engine = LayoutEngine(wrapColumn: 10)
    let lines = ["1234567890ABCDEFGHIJ12345"] // 25 characters

    let virtualLines = engine.computeVirtualLines(from: lines, viewWidth: 80)
    #expect(virtualLines.count == 3)
    #expect(virtualLines[0].text == "1234567890")
    #expect(virtualLines[1].text == "ABCDEFGHIJ")
    #expect(virtualLines[2].text == "12345")

    // Verify real cursor (0, 15) maps to virtual cursor (1, 5)
    let (vLine, vCol) = engine.getVirtualCursor(lineIndex: 0, columnIndex: 15, virtualLines: virtualLines)
    #expect(vLine == 1)
    #expect(vCol == 5)

    // Verify virtual cursor (1, 5) maps back to real cursor (0, 15)
    let (bLine, bCol) = engine.getBufferCursor(vLineIndex: 1, vColIndex: 5, virtualLines: virtualLines)
    #expect(bLine == 0)
    #expect(bCol == 15)

    // Verify virtual line bounds (Home / End navigation)
    #expect(virtualLines[1].startCol == 10)
    #expect(virtualLines[1].endCol == 20)
}

@Test func testVirtualLineHomeAndEndNavigation() throws {
    let engine = LayoutEngine(wrapColumn: 10)
    let lines = ["1234567890ABCDEFGHIJ12345"] // 25 characters
    let virtualLines = engine.computeVirtualLines(from: lines, viewWidth: 80)

    #expect(virtualLines.count == 3)

    // SubLine 0: "1234567890" (startCol 0, endCol 10)
    let home0 = virtualLines[0].startCol // 0
    let end0 = virtualLines[0].endCol - 1 // 9 (last char of subline 0)
    let (vLineHome0, vColHome0) = engine.getVirtualCursor(lineIndex: 0, columnIndex: home0, virtualLines: virtualLines)
    let (vLineEnd0, vColEnd0) = engine.getVirtualCursor(lineIndex: 0, columnIndex: end0, virtualLines: virtualLines)
    #expect(vLineHome0 == 0)
    #expect(vColHome0 == 0)
    #expect(vLineEnd0 == 0)
    #expect(vColEnd0 == 9)

    // SubLine 1: "ABCDEFGHIJ" (startCol 10, endCol 20)
    let home1 = virtualLines[1].startCol // 10
    let end1 = virtualLines[1].endCol - 1 // 19 (last char of subline 1)
    let (vLineHome1, vColHome1) = engine.getVirtualCursor(lineIndex: 0, columnIndex: home1, virtualLines: virtualLines)
    let (vLineEnd1, vColEnd1) = engine.getVirtualCursor(lineIndex: 0, columnIndex: end1, virtualLines: virtualLines)
    #expect(vLineHome1 == 1)
    #expect(vColHome1 == 0)
    #expect(vLineEnd1 == 1)
    #expect(vColEnd1 == 9)

    // SubLine 2: "12345" (startCol 20, endCol 25, last subline of buffer line)
    let home2 = virtualLines[2].startCol // 20
    let end2 = virtualLines[2].endCol     // 25
    let (vLineHome2, vColHome2) = engine.getVirtualCursor(lineIndex: 0, columnIndex: home2, virtualLines: virtualLines)
    let (vLineEnd2, vColEnd2) = engine.getVirtualCursor(lineIndex: 0, columnIndex: end2, virtualLines: virtualLines)
    #expect(vLineHome2 == 2)
    #expect(vColHome2 == 0)
    #expect(vLineEnd2 == 2)
    #expect(vColEnd2 == 5)
}

@Test func testChineseDisplayWidthAndSoftwrap() throws {
    let ch: Character = "中"
    #expect(ch.displayWidth == 2)

    let str = "中文測試"
    #expect(str.displayWidth == 8)
    #expect(str.paddedToDisplayWidth(10) == "中文測試  ")

    // Test CJK softwrap: wrapColumn = 6 (accommodates 3 CJK characters per line)
    let engine = LayoutEngine(wrapColumn: 6)
    let lines = ["一二三四五六"] // 6 CJK characters, total display width 12
    let virtualLines = engine.computeVirtualLines(from: lines, viewWidth: 80)

    #expect(virtualLines.count == 2)
    #expect(virtualLines[0].text == "一二三")
    #expect(virtualLines[1].text == "四五六")
}

@Test func testJustifyParagraph() throws {
    let buffer = TextBuffer()
    buffer.lines = [
        "Swift is a powerful and intuitive",
        "programming language created by Apple",
        "for building apps.",
        "",
        "Second paragraph."
    ]
    buffer.lineIndex = 0

    // Justify the first paragraph with target width 30
    buffer.justifyParagraph(targetWidth: 30)

    #expect(buffer.lines[0] == "Swift is a powerful and")
    #expect(buffer.lines[1] == "intuitive programming language")
    #expect(buffer.lines[2] == "created by Apple for building")
    #expect(buffer.lines[3] == "apps.")
    #expect(buffer.lines[4] == "")
    #expect(buffer.lines[5] == "Second paragraph.")
}

@Test func testChineseAndMixedJustifyParagraph() throws {
    let buffer = TextBuffer()
    buffer.lines = [
        "這是一段很長的中文字段落，用來測試視覺對齊演算法",
        "是否能在指定寬度內正確折行。"
    ]
    buffer.lineIndex = 0

    // Justify Chinese paragraph with target width 12 (6 CJK characters per line)
    buffer.justifyParagraph(targetWidth: 12)

    #expect(buffer.lines[0] == "這是一段很長")
    #expect(buffer.lines[1] == "的中文字段落")
    #expect(buffer.lines[2] == "，用來測試視")
    #expect(buffer.lines[3] == "覺對齊演算法")
    #expect(buffer.lines[4] == "是否能在指定")
    #expect(buffer.lines[5] == "寬度內正確折")
    #expect(buffer.lines[6] == "行。")
}

@Test func testCutRangeAndInsertString() throws {
    let buffer = TextBuffer()
    buffer.lines = ["Hello World!", "Second Line"]

    // Cut "World" (line 0, col 6 to line 0, col 11)
    let cut = buffer.cutRange(start: (0, 6), end: (0, 11))
    #expect(cut == "World")
    #expect(buffer.lines[0] == "Hello !")

    // Insert "Swift " at (0, 6)
    buffer.lineIndex = 0
    buffer.columnIndex = 6
    buffer.insertString("Swift ")
    #expect(buffer.lines[0] == "Hello Swift !")
}

@Test func testTerminalDisplayWidthHelpers() throws {
    #expect(Character("A").displayWidth == 1)
    #expect(Character("中").displayWidth == 2)
    #expect("Hello".displayWidth == 5)
    #expect("中文".displayWidth == 4)
    #expect("Hello".paddedToDisplayWidth(10) == "Hello     ")
}

@Test func testTextBufferFileOperations() throws {
    let tempDir = FileManager.default.temporaryDirectory
    let tempFile = tempDir.appendingPathComponent("test_se_\(UUID().uuidString).txt").path

    let buffer = TextBuffer()
    buffer.lines = ["Line 1", "Line 2", "Line 3"]
    try buffer.saveFile(to: tempFile)
    #expect(FileManager.default.fileExists(atPath: tempFile))

    let newBuffer = TextBuffer()
    let count = try newBuffer.insertFile(at: tempFile)
    #expect(count == 3)
    #expect(newBuffer.lines[0] == "Line 1")
    #expect(newBuffer.lines[1] == "Line 2")
    #expect(newBuffer.lines[2] == "Line 3")

    try? FileManager.default.removeItem(atPath: tempFile)
}

@Test func testTextBufferDeleteAndClamp() throws {
    let buffer = TextBuffer()
    buffer.lines = ["ABC"]
    buffer.lineIndex = 0
    buffer.columnIndex = 1

    buffer.delete() // Deletes 'B'
    #expect(buffer.lines[0] == "AC")

    buffer.columnIndex = 100
    buffer.clampCursor()
    #expect(buffer.columnIndex == 2)
}

@Test func testHelpViewInstantiation() throws {
    let terminal = Terminal()
    let helpView = HelpView(terminal: terminal)
    _ = helpView
}

@Test func testSpellChecker() throws {
    let checker = SpellChecker()
    #expect(checker.isCorrect("hello") == true)
    #expect(checker.isCorrect("swift") == true)
    #expect(checker.isCorrect("中文測試") == true)

    let buffer = TextBuffer()
    buffer.lines = ["這是一段中文測試", "the hello world", "qxzywkwk misspelled"]
    let target = checker.findNextMisspelled(in: buffer)
    #expect(target != nil)
    #expect(target?.word == "qxzywkwk")
}

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

@Test func testWordStarRuler() throws {
    let editor = Editor(showRuler: true)
    #expect(editor.displayConfig.showRuler == true)
    #expect(editor.displayConfig.enableSyntaxHighlight == true)

    let ruler20 = editor.generateWordStarRuler(width: 20)
    #expect(ruler20 == "----!----1----!----2")

    let ruler30 = editor.generateWordStarRuler(width: 30)
    #expect(ruler30 == "----!----1----!----2----!----3")
}

@Test func testConfigLoaderAndKeyParser() throws {
    let parsedCtrlF = KeyParser.parse("ctrl-f")
    #expect(parsedCtrlF == .ctrl("f"))

    let parsedF1 = KeyParser.parse("f1")
    #expect(parsedF1 == .f1)

    let parsedUp = KeyParser.parse("up")
    #expect(parsedUp == .arrowUp)

    let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent("test_.serc").path
    let sampleConfig = """
    # Sample serc configuration
    set wrap 80
    set ruler true
    set autoreload true
    bind ctrl-f move.left
    unbind f1
    invalid syntax line
    """
    try sampleConfig.write(toFile: tmpPath, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    let loader = ConfigLoader()
    var config = EditorConfig()
    loader.parseConfigFile(at: tmpPath, into: &config)

    #expect(config.wrapColumn == 80)
    #expect(config.showRuler == true)
    #expect(config.autoReload == true)
    #expect(config.customKeyBinds[.ctrl("f")] == "move.left")
    #expect(config.unbindKeys.contains(.f1))
    #expect(config.syntaxErrorCount == 1)
}

@Test func testFileWatcherAndAutoReload() throws {
    let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("test_fs_watcher.txt").path
    try "Initial line\n".write(toFile: tmpFile, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(atPath: tmpFile) }

    let editor = Editor(filePath: tmpFile, autoReload: true)
    #expect(editor.displayConfig.autoReload == true)

    // Test external change reloading when unmodified
    try "Modified externally\n".write(toFile: tmpFile, atomically: true, encoding: .utf8)

    // Trigger reload
    editor.handleExternalFileChange()
    #expect(editor.buffer.lines.first == "Modified externally")
}

@Test func testSyntaxHighlighter() throws {
    let highlighter = SyntaxHighlighter()

    let swiftLang = highlighter.detectLanguage(for: "main.swift")
    #expect(swiftLang != nil)
    #expect(swiftLang?.name == "Swift")

    let pythonLang = highlighter.detectLanguage(for: "script.py")
    #expect(pythonLang != nil)
    #expect(pythonLang?.name == "Python")

    let jsonLang = highlighter.detectLanguage(for: "package.json")
    #expect(jsonLang != nil)
    #expect(jsonLang?.name == "JSON")

    if let lang = swiftLang {
        let highlighted = highlighter.highlight(line: "func hello() { return }", syntax: lang)
        #expect(highlighted.contains("\u{1B}[1;36m"))
    }
}

@Test func testNanoRCParser() throws {
    let tmpNanoRC = FileManager.default.temporaryDirectory.appendingPathComponent("test.nanorc").path
    let content = """
    # Sample nanorc file
    syntax "customlang" "\\.custom$"
    color cyan "\\b(foo|bar)\\b"
    color green "\"([^\"]*)\""
    """
    try content.write(toFile: tmpNanoRC, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(atPath: tmpNanoRC) }

    let highlighter = SyntaxHighlighter()
    highlighter.parseNanoRCFile(at: tmpNanoRC)

    let customLang = highlighter.detectLanguage(for: "file.custom")
    #expect(customLang != nil)
    #expect(customLang?.name == "customlang")
}

@Test func testLocalization() throws {
    L10n.currentLanguage = .en
    #expect(L10n.helpGetHelp == "Get Help")
    #expect(L10n.helpExit == "Exit")
    #expect(L10n.readLines(10) == "[ Read 10 line(s) ]")
    #expect(L10n.wroteToFile("test.txt") == "[ Wrote to test.txt ]")
    #expect(L10n.configLoadedWithErrors(2) == "[ Config loaded with 2 syntax error(s) ]")
    #expect(L10n.cursorInfo(currentLine: 5, totalLines: 20, percent: 25, currentCol: 3, totalCol: 10) == "line 5/20 (25%), col 3/10")
    #expect(L10n.foundQueryAtLine(query: "foo", line: 12) == "Found \"foo\" at line 12")
    #expect(L10n.searchWrappedFound(query: "foo", line: 12) == "Search wrapped, found \"foo\" at line 12")
    #expect(L10n.notFound(query: "bar") == "\"bar\" not found")
    #expect(L10n.insertedLines(5) == "[ Inserted 5 lines ]")
    #expect(L10n.errorInsertingFile(error: "Access denied") == "Error inserting file: Access denied")
    #expect(L10n.errorSavingFile(error: "Disk full") == "Error saving file: Disk full")
    #expect(L10n.replacedWord(target: "helo", newWord: "hello") == "Replaced 'helo' with 'hello'")

    L10n.currentLanguage = .zh_TW
    #expect(L10n.helpGetHelp == "輔助說明")
    #expect(L10n.helpExit == "離開")
    #expect(L10n.readLines(10) == "[ 已讀取 10 行 ]")
    #expect(L10n.wroteToFile("test.txt") == "[ 已儲存至 test.txt ]")
    #expect(L10n.configLoadedWithErrors(2) == "[ 已載入設定檔（含有 2 個語法錯誤）]")
    #expect(L10n.cursorInfo(currentLine: 5, totalLines: 20, percent: 25, currentCol: 3, totalCol: 10) == "第 5/20 行 (25%), 第 3/10 欄")
    #expect(L10n.foundQueryAtLine(query: "foo", line: 12) == "於第 12 行找到 \"foo\"")
    #expect(L10n.searchWrappedFound(query: "foo", line: 12) == "搜尋回到開頭，於第 12 行找到 \"foo\"")
    #expect(L10n.notFound(query: "bar") == "找不到 \"bar\"")
    #expect(L10n.insertedLines(5) == "[ 已插入 5 行內容 ]")
    #expect(L10n.errorInsertingFile(error: "Access denied") == "插入檔案錯誤：Access denied")
    #expect(L10n.errorSavingFile(error: "Disk full") == "儲存檔案錯誤：Disk full")
    #expect(L10n.replacedWord(target: "helo", newWord: "hello") == "已將 'helo' 替換為 'hello'")
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

@Test func testScreenRenderLayoutAndHeight() throws {
    let editor = Editor()
    let screenRows = 24
    let screenCols = 80

    // Test without ruler (1 title + 20 main + 1 status + 2 help = 24 rows)
    let outputNoRuler = editor.generateScreenOutput(rows: screenRows, cols: screenCols)
    let cleanNoRuler = outputNoRuler.hasPrefix("\u{1B}[H") ? String(outputNoRuler.dropFirst(3)) : outputNoRuler
    let linesNoRuler = cleanNoRuler.components(separatedBy: "\r\n")

    // Verify title bar on line 0 (with inverted video ANSI)
    #expect(linesNoRuler[0].contains("se"))
    #expect(linesNoRuler[0].contains("\u{1B}[7m"))

    // Output must consist of exactly 24 screen line chunks (23 \r\n separators)
    #expect(linesNoRuler.count == 24)

    // Test with ruler (1 title + 1 ruler + 19 main + 1 status + 2 help = 24 rows)
    editor.displayConfig.showRuler = true
    let outputWithRuler = editor.generateScreenOutput(rows: screenRows, cols: screenCols)
    let cleanWithRuler = outputWithRuler.hasPrefix("\u{1B}[H") ? String(outputWithRuler.dropFirst(3)) : outputWithRuler
    let linesWithRuler = cleanWithRuler.components(separatedBy: "\r\n")

    #expect(linesWithRuler[0].contains("se"))
    #expect(linesWithRuler[0].contains("\u{1B}[7m"))
    #expect(linesWithRuler[1].contains("!")) // Ruler line

    #expect(linesWithRuler.count == 24)
}
