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
    let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent("test_big5_\(UUID().uuidString).txt").path
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    guard let big5Data = big5Text.data(using: .big5) else {
        Issue.record("Failed to create Big5 data")
        return
    }
    try big5Data.write(to: URL(fileURLWithPath: tmpPath))

    // 1. Open Big5 file in Editor
    let editor = Editor(
        options: EditorOptions(filePaths: [tmpPath], autoReload: false, language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared)
    )
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

@Test func testUTF16BOMAndOtherEncodingsDetection() throws {
    // UTF-16 LE with BOM
    let utf16LEText = "UTF16LE Test"
    var dataLE = Data([0xFF, 0xFE])
    dataLE.append(contentsOf: utf16LEText.data(using: .utf16LittleEndian)!)
    let resultLE = TextEncodingDetector.detectAndDecode(dataLE)
    #expect(resultLE?.encoding == .utf16LittleEndian)
    #expect(resultLE?.content == utf16LEText)

    // UTF-16 BE with BOM
    let utf16BEText = "UTF16BE Test"
    var dataBE = Data([0xFE, 0xFF])
    dataBE.append(contentsOf: utf16BEText.data(using: .utf16BigEndian)!)
    let resultBE = TextEncodingDetector.detectAndDecode(dataBE)
    #expect(resultBE?.encoding == .utf16BigEndian)
    #expect(resultBE?.content == utf16BEText)

    // Empty data handling
    #expect(TextEncodingDetector.detectAndDecode(Data())?.content == "")
}

@Test func testNonUTF8TextFileIsNotDetectedAsBinary() throws {
    let big5Text = "正氣中華報\n交接與傳承故事"
    guard let big5Data = big5Text.data(using: .big5) else {
        Issue.record("Failed to create Big5 test data")
        return
    }
    let fileIO = TestLocalEditorFileIOStrategy.shared
    let tmpPath = fileIO.normalizePath(
        FileManager.default.temporaryDirectory.appendingPathComponent("test_big5_doc_\(UUID().uuidString).md").path,
        isDirectory: false
    )
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    try big5Data.write(to: URL(fileURLWithPath: tmpPath))

    let info = fileIO.fileInfo(at: tmpPath)
    #expect(info.exists == true)
    #expect(info.isBinary == false)
}

@Test func testUTF8FileCutOffAt8192ByteBoundaryIsNotDetectedAsBinary() throws {
    let text = String(repeating: "繁體中文測試文章內容。", count: 500)
    let data = Data(text.utf8)
    #expect(data.count > 8192)

    let fileIO = TestLocalEditorFileIOStrategy.shared
    let tmpPath = fileIO.normalizePath(
        FileManager.default.temporaryDirectory.appendingPathComponent("test_utf8_boundary_\(UUID().uuidString).md").path,
        isDirectory: false
    )
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    try data.write(to: URL(fileURLWithPath: tmpPath))

    let info = fileIO.fileInfo(at: tmpPath)
    #expect(info.exists == true)
    #expect(info.isBinary == false)

    let readResult = try fileIO.readTextFile(at: tmpPath)
    #expect(readResult.encoding == .utf8)
}

@Test func testCJKExtension4ByteUTF8CutOffAt8192ByteBoundary() throws {
    // 𪚥 (U+2A6A5, 4-byte UTF-8: 0xF0 0xAA 0x9A 0xA5) & 𠮷 (U+20BB7, 4-byte UTF-8: 0xF0 0xA0 0xAE 0xB7)
    let text = String(repeating: "𪚥𠮷罕見字與 Emoji 𩸽🚀", count: 400)
    let data = Data(text.utf8)
    #expect(data.count > 8192)

    let fileIO = TestLocalEditorFileIOStrategy.shared
    let tmpPath = fileIO.normalizePath(
        FileManager.default.temporaryDirectory.appendingPathComponent("test_cjk_ext_\(UUID().uuidString).md").path,
        isDirectory: false
    )
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    try data.write(to: URL(fileURLWithPath: tmpPath))

    let info = fileIO.fileInfo(at: tmpPath)
    #expect(info.exists == true)
    #expect(info.isBinary == false)

    let readResult = try fileIO.readTextFile(at: tmpPath)
    #expect(readResult.encoding == .utf8)
}
