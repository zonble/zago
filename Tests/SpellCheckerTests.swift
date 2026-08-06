import Foundation
import Testing

@testable import Config
@testable import Editor
@testable import SpellChecker

@Suite(.serialized)
struct SpellCheckerTests {
    @Test func testSpellCheckerBasicCorrectness() throws {
    let checker = SpellChecker()
    #expect(checker.isCorrect("hello") == true)
    #expect(checker.isCorrect("swift") == true)
    #expect(checker.isCorrect("editor") == true)
    #expect(checker.isCorrect("中文測試") == true)
    #expect(checker.isCorrect("12345") == true)
    #expect(checker.isCorrect("v1.0.0") == true)
}

@Test func testSpellCheckerIgnoreAndSuggestions() throws {
    let checker = SpellChecker()
    let unknownWord = "qxzywkwk"

    #expect(checker.isCorrect(unknownWord) == false)

    checker.ignoreWord(unknownWord)
    #expect(checker.isCorrect(unknownWord) == true)

    let suggestions = checker.suggestions(for: "helo")
    #expect(!suggestions.isEmpty)
}

@Test func testMarkdownCodeBlockAndInlineCodeSkipping() throws {
    let checker = SpellChecker()

    let mdBuffer = TextBuffer()
    mdBuffer.lines = [
        "```swift",
        "qxzywkwk = 123",
        "```",
        "這是一段中文測試",
        "the hello world",
        "qxzywkwk misspelled"
    ]

    // Misspelled word inside fenced code block should be skipped
    let target = checker.findNextMisspelled(in: mdBuffer, syntaxName: "Markdown")
    #expect(target != nil)
    #expect(target?.line == 5)
    #expect(target?.word == "qxzywkwk")

    // Test inline code skipping (`code`)
    let inlineBuffer = TextBuffer()
    inlineBuffer.lines = [
        "This is `qxzywkwk` inside code.",
        "This is qxzywkwk outside code."
    ]
    let inlineTarget = checker.findNextMisspelled(in: inlineBuffer, syntaxName: "Markdown")
    #expect(inlineTarget != nil)
    #expect(inlineTarget?.line == 1)
    #expect(inlineTarget?.word == "qxzywkwk")
}

@Test func testOrgModeCodeBlockSkipping() throws {
    let checker = SpellChecker()

    let orgBuffer = TextBuffer()
    orgBuffer.lines = [
        "#+BEGIN_SRC swift",
        "misspelledword = 123",
        "#+END_SRC",
        "normal text"
    ]
    #expect(checker.findNextMisspelled(in: orgBuffer, syntaxName: "Org-mode") == nil)

    // Test Org-mode inline verbatim/code (=code=, ~code~)
    let orgInline = TextBuffer()
    orgInline.lines = [
        "Here is =misspelledword= inside verbatim.",
        "Here is misspelledword outside."
    ]
    let target = checker.findNextMisspelled(in: orgInline, syntaxName: "Org-mode")
    #expect(target != nil)
    #expect(target?.line == 1)
}

@Test func testAsciiDocCodeBlockSkipping() throws {
    let checker = SpellChecker()

    let adocBuffer = TextBuffer()
    adocBuffer.lines = [
        "----",
        "misspelledword = 123",
        "----",
        "normal text"
    ]
    #expect(checker.findNextMisspelled(in: adocBuffer, syntaxName: "AsciiDoc") == nil)
}

@Test func testReSTCodeBlockSkipping() throws {
    let checker = SpellChecker()

    let rstBuffer = TextBuffer()
    rstBuffer.lines = [
        ".. code-block:: python",
        "misspelledword = 123",
        "",
        "normal text"
    ]
    #expect(checker.findNextMisspelled(in: rstBuffer, syntaxName: "reStructuredText") == nil)
}

@Test func testFallbackAndUnixEngines() throws {
    let engines: [SpellCheckerEngine] = [
        FallbackCheckerEngine(language: "en_US"),
        UnixSpellCheckerEngine(language: "en_US"),
        WindowsSpellCheckerEngine(language: "en_US")
    ]

    for engine in engines {
        #expect(engine.language == "en_US")

        // Test basic correctness
        #expect(engine.isCorrect("project") == true)
        #expect(engine.isCorrect("document") == true)
        #expect(engine.isCorrect("qxzywkwk") == false)

        // Test ignoreWord
        engine.ignoreWord("qxzywkwk")
        #expect(engine.isCorrect("qxzywkwk") == true)

        // Test addWordToDictionary
        engine.addWordToDictionary("mycustomterm")
        #expect(engine.isCorrect("mycustomterm") == true)

        // Test suggestions
        let suggestions = engine.suggestions(for: "helo")
        #expect(!suggestions.isEmpty)

        // Test language property switching
        engine.language = "de_DE"
        #expect(engine.language == "de_DE")
    }
}

@Test func testSpellLanguageConfigDirective() throws {
    struct TestLocalConfigFileProvider: ConfigFileProvider {
        func homeDirectoryPath() -> String { FileManager.default.homeDirectoryForCurrentUser.path }
        func currentDirectoryPath() -> String { FileManager.default.currentDirectoryPath }
        func fileExists(atPath path: String) -> Bool {
            FileManager.default.fileExists(atPath: path) || FileManager.default.fileExists(atPath: URL(fileURLWithPath: path).path)
        }
        func readString(atPath path: String) throws -> String {
            try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
        }
        func writeString(_ content: String, toPath path: String) throws {
            try content.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
        }
    }
    let loader = ConfigLoader(provider: TestLocalConfigFileProvider())
    var config = EditorConfig()
    let rawPath = FileManager.default.temporaryDirectory
        .appendingPathComponent("test_spell_lang_\(UUID().uuidString).zagorc").path
    let tmpPath = TestLocalEditorFileIOStrategy().normalizePath(rawPath, isDirectory: false)
    let sampleConfig = "set spell-language de_DE\n"
    try sampleConfig.write(to: URL(fileURLWithPath: tmpPath), atomically: testAtomicallyOption, encoding: .utf8)
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    loader.parseConfigFile(at: tmpPath, into: &config)
    #expect(config.spellLanguage.lowercased() == "de_de")
}
}
