import Foundation
import Testing

@testable import Config
@testable import Editor
@testable import LogoEngine

private func eval(_ script: String, engine: LogoEngine = LogoEngine()) -> String {
    let tokens = engine.tokenize(script)
    var index = 0
    return engine.evaluateExpression(tokens, index: &index)
}

private final class NonInteractiveInputTerminal: EditorTerminal, @unchecked Sendable {
    var writes: [String] = []
    private var lines: [String]
    private var chars: [String]

    init(lines: [String] = [], chars: [String] = []) {
        self.lines = lines
        self.chars = chars
    }

    func enableRawMode() throws {}
    func disableRawMode() {}
    func getWindowSize() -> (rows: Int, cols: Int) { (24, 80) }
    func readKey() -> Key { .esc }
    func readPendingText(firstChar: Character) -> String { String(firstChar) }
    func write(_ text: String) { writes.append(text) }
    func hideCursor() {}
    func showCursor() {}
    func clearScreen() {}
    func readNonInteractiveLine(prompt: String) -> String? { lines.isEmpty ? nil : lines.removeFirst() }
    func readNonInteractiveChar(prompt: String) -> String? { chars.isEmpty ? nil : chars.removeFirst() }
}

@Test func testLogoStringSearchAndIndexPrimitives() throws {
    let engine = LogoEngine()

    // 1. indexof, lastindexof, indexesof
    #expect(eval("indexof \"a \"banana", engine: engine) == "2")
    #expect(eval("indexof \"a \"banana 3", engine: engine) == "4")
    #expect(eval("lastindexof \"a \"banana", engine: engine) == "6")
    #expect(eval("indexesof \"a \"banana", engine: engine) == "[2 4 6]")
    #expect(eval("indexesof \"x \"banana", engine: engine) == "[]")

    // 2. contains?, startswith?, endswith?
    #expect(eval("contains? \"world \"hello_world", engine: engine) == "true")
    #expect(eval("contains? \"foo \"hello_world", engine: engine) == "false")
    #expect(eval("startswith? \"H \"Hello_Title", engine: engine) == "true")
    #expect(eval("endswith? \".md \"file.md", engine: engine) == "true")
}

@Test func testLogoStringSubstringAndTransformPrimitives() throws {
    let engine = LogoEngine()

    // 1. substring, replace, trim, repeatstr, padleft, padright
    #expect(eval("substring \"Hello_World 1 5", engine: engine) == "Hello")
    #expect(eval("replace \"foo \"bar \"foo_text_foo", engine: engine) == "bar_text_bar")
    #expect(eval("trim \"hello_world", engine: engine) == "hello_world")
    #expect(eval("repeatstr 5 \"X", engine: engine) == "XXXXX")
    #expect(eval("padleft 5 \"0 \"42", engine: engine) == "00042")
    #expect(eval("padright 6 \". \"item", engine: engine) == "item..")
}

@Test func testLogoStringSplitJoinAndFormattingPrimitives() throws {
    let engine = LogoEngine()

    // 1. split & join
    #expect(eval("split \", \"apple,banana,orange", engine: engine) == "[apple banana orange]")
    #expect(eval("implode \", \" [apple banana]", engine: engine) == "apple, banana")

    // 2. lines & unlines
    #expect(eval("unlines [A B]", engine: engine) == "A\nB")

    // 3. format / sprintf
    #expect(eval("format \"Line_%d:_%s [42 \"Text]", engine: engine) == "Line_42:_Text")
    #expect(eval("format |%d) %s -> %dA%dB| 3 \"1234 1 2", engine: engine) == "3) 1234 -> 1A2B")
    #expect(eval("format \"%s_%s [A B]", engine: engine) == "A_B")
}

@Test func testLogoVerticalBarWordsAndSubstringEndIndexCompatibility() throws {
    let engine = LogoEngine()

    #expect(eval("count [|#@ $ .#| |#  #  #|]", engine: engine) == "2")
    #expect(eval("item 1 [|#@ $ .#| |#  #  #|]", engine: engine) == "#@ $ .#")
    #expect(eval("substring |#@ $ .#| 6 6", engine: engine) == ".")
    #expect(eval("substring \"abcdef 3 2", engine: engine) == "cd")
}

@Test func testLogoComparisonExpressionsCanFeedLogicPrimitives() throws {
    let editor = Editor()

    editor.runLogoScript("MAKE \"a \"1 MAKE \"b \"2 MAKE \"c \"3 IFELSE AND (:a = :b) (:b = :c) [ APPEND \"bad ] [ APPEND \"ok ]")

    #expect(editor.buffer.lines.joined(separator: "\n").contains("ok"))
}

@Test func testLogoNonInteractiveReadFlushKeepsBufferWritable() throws {
    let terminal = NonInteractiveInputTerminal(lines: ["q"], chars: ["q"])
    let editor = Editor(
        options: EditorOptions(),
        dependencies: EditorDependencies(
            fileIOStrategy: TestLocalEditorFileIOStrategy.shared,
            terminal: terminal
        )
    )

    editor.runLogoScript("APPEND \"before MAKE \"word READWORD \"Prompt: APPEND :word MAKE \"key READCHAR \"Key: APPEND :key")

    #expect(terminal.writes.contains { $0.contains("before") })
    #expect(editor.logoEngine.hasUncaughtError == false)
    #expect(editor.buffer.lines.joined(separator: "\n").contains("q"))
}

@Test func testLogoStringRegexPrimitives() throws {
    let engine = LogoEngine()

    // 1. regex_match?, regex_replace, regex_find
    #expect(eval("regex_match? \"^A+ \"AAA_Title", engine: engine) == "true")
    #expect(eval("regex_replace \"cat \"dog \"the_cat", engine: engine) == "the_dog")
    #expect(eval("regex_find \"123 \"Item_123_456", engine: engine) == "[123]")
}
