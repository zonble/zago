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
}

@Test func testLogoStringRegexPrimitives() throws {
    let engine = LogoEngine()

    // 1. regex_match?, regex_replace, regex_find
    #expect(eval("regex_match? \"^A+ \"AAA_Title", engine: engine) == "true")
    #expect(eval("regex_replace \"cat \"dog \"the_cat", engine: engine) == "the_dog")
    #expect(eval("regex_find \"123 \"Item_123_456", engine: engine) == "[123]")
}
