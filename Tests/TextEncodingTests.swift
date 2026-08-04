import Foundation
import Testing

@testable import Editor
@testable import TextEncoding

@Test func testUTF8Detection() throws {
    let utf8Text = "Hello, 世界！"
    let data = Data(utf8Text.utf8)
    let result = TextEncodingDetector.detectAndDecode(data)

    #expect(result != nil)
    #expect(result?.content == utf8Text)
    #expect(result?.encoding == .utf8)
}

@Test func testUTF8BOMDetection() throws {
    let utf8Text = "BOM Test"
    var data = Data([0xEF, 0xBB, 0xBF])
    data.append(contentsOf: utf8Text.utf8)

    let result = TextEncodingDetector.detectAndDecode(data)
    #expect(result != nil)
    #expect(result?.content == utf8Text)
    #expect(result?.encoding == .utf8)
}

@Test func testBig5Detection() throws {
    let big5Text = "中文測試"
    guard let big5Data = big5Text.data(using: .big5) else {
        Issue.record("Failed to create Big5 test data")
        return
    }

    let result = TextEncodingDetector.detectAndDecode(big5Data)
    #expect(result != nil)
    #expect(result?.content == big5Text)
    #expect(result?.encoding == .big5)
}

@Test func testEncodingDisplayName() throws {
    #expect(TextEncodingDetector.displayName(for: .utf8) == "UTF-8")
    #expect(TextEncodingDetector.displayName(for: .big5) == "Big5")
    #expect(TextEncodingDetector.displayName(for: .shiftJISCustom) == "Shift-JIS")
}

@Test func testEditorOpensBig5AndPromptsFallbackOnUnsupportedChars() throws {
    let big5Text = "繁體中文檔案"
    let fileIO = TestLocalEditorFileIOStrategy.shared
    let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent("test_big5_.txt").path
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    guard let big5Data = big5Text.data(using: .big5) else {
        Issue.record("Failed to create Big5 data")
        return
    }
    try big5Data.write(to: URL(fileURLWithPath: tmpPath))

    // 1. Open Big5 file in Editor
    let editor = Editor(filePath: tmpPath, autoReload: false, language: .en, fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared)
    #expect(editor.buffer.fileEncoding == .big5)
    #expect(editor.buffer.lines == ["繁體中文檔案"])

    // 2. Add incompatible emoji/characters
    editor.buffer.lines = ["繁體中文檔案 🚀 Emoji"]
    editor.buffer.isModified = true

    // 3. Attempt save -> Should trigger confirmEncodingFallback prompt
    editor.saveBuffer(path: nil)
    if case .confirmEncodingFallback(let origEncoding, _) = editor.currentPromptMode {
        #expect(origEncoding == .big5)
    } else {
        Issue.record("Expected confirmEncodingFallback prompt mode")
    }

    // 4. Respond 'Y' -> Should convert to UTF-8 and save
    editor.processKey(.char(Character("y")))
    #expect(editor.buffer.fileEncoding == .utf8)
    #expect(editor.buffer.isModified == false)

    // Verify saved content on disk is valid UTF-8
    let savedRead = try fileIO.readTextFile(at: tmpPath)
    #expect(savedRead.encoding == .utf8)
    #expect(savedRead.content == "繁體中文檔案 🚀 Emoji")
}
