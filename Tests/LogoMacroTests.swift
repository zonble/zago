import Dispatch
import Foundation
import Testing
import TextMetrics

@testable import Editor
@testable import LogoEngine
@testable import TextTransform

final class LogoTestResultBox: @unchecked Sendable {
    var value: String?
    var error: String?
    var status: String?
}

@Test func testTextTransformerAndLogoTranslitPrimitive() throws {
    #expect(try TextTransformer.apply("Zago-CJK-Punctuation", to: "Hello, world!") == "Hello， world！")
    #expect(try TextTransformer.apply("Fullwidth-Halfwidth", to: "ＡＢＣ１２３") == "ABC123")
    #expect(try TextTransformer.apply("Any-Hiragana", to: "Sakura") == "さくら")
    #expect(try TextTransformer.apply("Hant-Hans", to: "繁體中文") == "繁体中文")
    #expect(try TextTransformer.apply("Zago-CJK-Spacing", to: "中文APIv2測試") == "中文 APIv2 測試")
    #expect(try TextTransformer.apply("Zago-CJK-Spacing", to: "中 文  API") == "中文 API")
    #expect(TextAnalyzer.characterCount(in: "a👍🏽中") == 3)
    #expect(TextAnalyzer.cjkCharacterCount(in: "中文，API。かな") == 6)
    #expect(TextAnalyzer.cjkCharacterCount(in: "中\u{30EDE}文") == 3)
    #expect(TextAnalyzer.wordCount(in: "Hello, world! API v2") == 4)
    #expect(TextAnalyzer.emojiCount(in: "A👍🏽🇹🇼1❤️") == 3)
    #expect(TextAnalyzer.lineCount(in: "a\nb\n") == 3)

    let editor = Editor()
    let logoEngine = editor.logoEngine

    logoEngine.execute("TYPE TRANSLIT \"Zago-CJK-Punctuation \"Hello,\"")
    #expect(editor.buffer.lines[0] == "Hello，")

    logoEngine.execute("CLEARBUFFER TYPE TRANSFORM \"Fullwidth-Halfwidth \"ＡＢＣ１２３")
    #expect(editor.buffer.lines[0] == "ABC123")

    logoEngine.execute("CLEARBUFFER TYPE TOHANS \"繁體中文")
    #expect(editor.buffer.lines[0] == "繁体中文")

    logoEngine.execute("CLEARBUFFER TYPE TRANSFORM.TOHANT \"简体中文")
    #expect(editor.buffer.lines[0] == "簡體中文")

    logoEngine.execute("CLEARBUFFER TYPE TOLATIN \"你好嗎？")
    #expect(editor.buffer.lines[0] == "nǐ hǎo ma？")

    logoEngine.execute("CLEARBUFFER TYPE TOHIRAGANA \"Sakura")
    #expect(editor.buffer.lines[0] == "さくら")

    logoEngine.execute("CLEARBUFFER TYPE TRANSFORM.TOKATAKANA \"Sakura")
    #expect(editor.buffer.lines[0] == "サクラ")

    logoEngine.execute("CLEARBUFFER TYPE TOROMAJI \"さくら")
    #expect(editor.buffer.lines[0] == "sakura")

    logoEngine.execute("CLEARBUFFER TYPE SPACING.CJK \"中文API測試")
    #expect(editor.buffer.lines[0] == "中文 API 測試")

    logoEngine.execute("CHARCOUNT \"a👍🏽中")
    #expect(logoEngine.lastResult == "3")

    logoEngine.execute("CHARCOUNT.CJK \"中文，API。かな")
    #expect(logoEngine.lastResult == "6")

    logoEngine.execute("CHARCOUNT.WORDS \"Hello, world! API v2\"")
    #expect(logoEngine.lastResult == "4")

    logoEngine.execute("CHARCOUNT.EMOJI \"A👍🏽🇹🇼1❤️")
    #expect(logoEngine.lastResult == "3")

    logoEngine.execute("CHARCOUNT.LINES \"single")
    #expect(logoEngine.lastResult == "1")

    logoEngine.execute("TRANSLIT \"Zago-Does-Not-Exist \"text")
    #expect(logoEngine.lastError?.message.contains("Zago-Does-Not-Exist") == true)
    #expect(editor.statusMessage == "[Unknown text transform: Zago-Does-Not-Exist]")
}

@Test func testLogoMacroEngine() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    // 1. Basic TYPE and MOVE
    logoEngine.execute("TYPE \"Hello\" MOVE END TYPE \" World\"")
    #expect(editor.buffer.lines[0] == "Hello World")

    // 2. REPEAT loop
    logoEngine.execute("REPEAT 3 [ TYPE \"!\" ]")
    #expect(editor.buffer.lines[0] == "Hello World!!!")

    // 3. TO ... END Procedure definition & EXEC
    logoEngine.execute("TO BULLET MOVE END TYPE \" - item\" END EXEC BULLET")
    #expect(editor.buffer.lines[0] == "Hello World!!! - item")

    // 4. Variables and Arithmetic test
    logoEngine.execute("MAKE \"i\" 1 MAKE \"x\" :i + 5 TYPE :x")
    #expect(editor.buffer.lines[0] == "Hello World!!! - item6")

    // 5. Direct Arithmetic TYPE output & Multiplication
    logoEngine.execute("TYPE \" calc: \" TYPE ( 10 + 20 ) TYPE \" mul: \" TYPE ( 4 * 5 )")
    #expect(editor.buffer.lines[0] == "Hello World!!! - item6 calc: 30 mul: 20")

    // 6. Unspaced and Chained Arithmetic (10+20, 1+2+3)
    logoEngine.execute("TYPE \" nospace: \" TYPE 10+20 TYPE \" chained: \" MAKE \"c\" 1 + 2 + 3 TYPE :c")
    #expect(editor.buffer.lines[0] == "Hello World!!! - item6 calc: 30 mul: 20 nospace: 30 chained: 6")

    // 7. DEL and BS
    logoEngine.execute("BS 3 TYPE \"25\"")
    #expect(editor.buffer.lines[0] == "Hello World!!! - item6 calc: 30 mul: 20 nospace: 30 chained25")

    // 8. Prompt History & Active Hardware Cursor position test
    editor.promptLogoMacro()
    let promptOutput = editor.renderer.render(editor: editor, rows: 24, cols: 80)
    #expect(promptOutput.contains("\u{1B}[22;"))

    editor.processKey(.char("T"))
    editor.processKey(.char("Y"))
    editor.processKey(.enter)
    #expect(editor.logoPromptHistory.last == "TY")

    #expect(LogoPrimitive.from("SET") == nil)

    logoEngine.execute("MAKE \"msg_val\" 42 MSG \"Current Val: \" + :msg_val")
    #expect(editor.statusMessage == "Current Val: 42")
}

@Test func testLogoEngineDelegatePattern() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)
    logoEngine.execute("TYPE \"Hello Delegate\" NL BOX \"Delegate Text\"")
    #expect(editor.buffer.lines[0] == "Hello Delegate")
    #expect(editor.buffer.lines[1] == "┌───────────────┐")
    #expect(editor.buffer.lines[2] == "│ Delegate Text │")
    #expect(editor.buffer.lines[3] == "└───────────────┘")
}

@Test func testLogoEditorBufferPrimitives() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    editor.buffer.lines = ["First Line", "Second Line", "Third Line"]
    editor.buffer.lineIndex = 1
    editor.buffer.columnIndex = 4

    logoEngine.execute("ROW")
    #expect(logoEngine.lastResult == "2")

    logoEngine.execute("COL")
    #expect(logoEngine.lastResult == "5")

    logoEngine.execute("LINECOUNT")
    #expect(logoEngine.lastResult == "3")

    logoEngine.execute("GETLINE 1")
    #expect(logoEngine.lastResult == "First Line")

    logoEngine.execute("GETLINE 2")
    #expect(logoEngine.lastResult == "Second Line")

    logoEngine.execute("GETLINE (1 + 2)")
    #expect(logoEngine.lastResult == "Third Line")

    logoEngine.execute("BUFFERTEXT")
    #expect(logoEngine.lastResult == "First Line\nSecond Line\nThird Line")

    logoEngine.execute("GOTOLINE 1")
    #expect(editor.buffer.lineIndex == 0)

    logoEngine.execute("GOTOLINE (1 + 2)")
    #expect(editor.buffer.lineIndex == 2)

    logoEngine.execute("GOTOCOL 1")
    #expect(editor.buffer.columnIndex == 0)

    logoEngine.execute("GOTOCOL (2 + 3)")
    #expect(editor.buffer.columnIndex == 4)

    logoEngine.execute("SETLINE 1 \"New First Line\"")
    #expect(editor.buffer.lines[0] == "New First Line")

    logoEngine.execute("SETLINE (1 + 1) \"New Second Line\"")
    #expect(editor.buffer.lines[1] == "New Second Line")

    logoEngine.execute("CLEARBUFFER")
    #expect(editor.buffer.lines == [""])
}

@Test func testLogoEditingCommandsAcceptExpressionArguments() throws {
    let editor = Editor()
    let logoEngine = LogoEngine(delegate: editor)

    logoEngine.execute("TYPE \"a NL (1 + 1) TYPE \"b")
    #expect(editor.buffer.lines == ["a", "", "b"])

    logoEngine.execute("CLEARBUFFER TYPE \"abcdef MOVE LEFT (2 + 1) DELETE (1 + 1)")
    #expect(editor.buffer.lines == ["abcf"])
}

@Test func testPersistentLogoEngineState() {
    let editor = Editor()

    editor.logoEngine.execute("MAKE \"val 42 TO GREET TYPE \"Hi END")
    editor.logoEngine.execute("TYPE :val GREET")
    #expect(editor.buffer.lines[0] == "42Hi")
}

@Test func testCustomLogoBindingUsesPersistentEditorEngine() {
    let editor = Editor()
    var config = EditorConfig()
    config.customKeyBinds[.alt("y")] = "logo: MAKE \"val 7 TO GREET TYPE \"Hi END"
    config.customKeyBinds[.alt("z")] = "logo: TYPE :val GREET"
    editor.applyCustomConfig(config)

    #expect(editor.commandRegistry.dispatch(key: .alt("y"), editor: editor))
    #expect(editor.commandRegistry.dispatch(key: .alt("z"), editor: editor))
    #expect(editor.buffer.lines[0] == "7Hi")
}

@Test func testSercLogoPreludeAndNamedScriptRunOnPersistentEngine() {
    let editor = Editor()
    var config = EditorConfig()
    config.logoPrelude = """
        MAKE "name "Ada
        TO GREET
          TYPE :name
        END
        """
    config.logoScripts["run-greet"] = """
        GREET
        TYPE "!
        """
    config.customKeyBinds[.alt("g")] = "logo:run-greet"
    editor.applyCustomConfig(config)

    #expect(editor.commandRegistry.dispatch(key: .alt("g"), editor: editor))
    #expect(editor.buffer.lines[0] == "Ada!")
}

@Test func testLogoFillPrimitive() {
    let editor = Editor()
    let logoEngine = editor.logoEngine

    logoEngine.execute("CLEARBUFFER FILL 10 \"測\"")
    #expect(editor.buffer.lines[0] == "測測測測測")
    #expect(editor.buffer.lines[0].displayWidth == 10)

    logoEngine.execute("CLEARBUFFER GOTO 1 1 FILL 5 3 \"*\"")
    #expect(editor.buffer.lines[0] == "*****")
    #expect(editor.buffer.lines[1] == "*****")
    #expect(editor.buffer.lines[2] == "*****")

    logoEngine.execute("CLEARBUFFER GOTO 1 1 FILL (2 + 3) (1 + 2) \"#\"")
    #expect(editor.buffer.lines[0] == "#####")
    #expect(editor.buffer.lines[1] == "#####")
    #expect(editor.buffer.lines[2] == "#####")
}

@Test func testLogoSemicolonComments() {
    let editor = Editor()
    let logoEngine = editor.logoEngine

    #expect(logoEngine.tokenize("; whole line comment").isEmpty)
    #expect(logoEngine.tokenize("TYPE \"A\" ; inline comment") == ["TYPE", "\"A\""])
    #expect(logoEngine.tokenize("TYPE \"A;B\" ; inline comment") == ["TYPE", "\"A;B\""])

    logoEngine.execute(
        """
        ; setup comment
        TYPE "A
        ; skipped command: TYPE "x
        TYPE "B ; inline comment
        """)
    #expect(editor.buffer.lines[0] == "AB")
}

@Test func testHeadlessReadWordAndReadCharMode() {
    let editor = Editor()
    #expect(editor.isInteractiveMode == false)

    // In headless mode without stdin, READWORD and READCHAR return empty string without hanging
    editor.logoEngine.execute("MAKE \"w READWORD \"Prompt:")
    #expect(editor.logoEngine.variables["w"] == "")

    editor.logoEngine.execute("MAKE \"c READCHAR \"Prompt:")
    #expect(editor.logoEngine.variables["c"] == "")
}
