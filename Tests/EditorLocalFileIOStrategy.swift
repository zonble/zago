import Editor
import Foundation
import TextEncoding

#if os(Windows)
public let testAtomicallyOption = false
#else
public let testAtomicallyOption = true
#endif

final class TestLocalEditorFileIOStrategy: EditorFileIOStrategy, @unchecked Sendable {
    static let shared = TestLocalEditorFileIOStrategy()

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func normalizePath(_ path: String, isDirectory: Bool = false) -> String {
        let expanded = expandTilde(path)
        guard isDirectory else {
            return expanded
        }
        return URL(fileURLWithPath: expanded, isDirectory: true).standardizedFileURL.path
    }

    func homeDirectoryPath() -> String {
        fileManager.homeDirectoryForCurrentUser.path
    }

    func currentDirectoryPath() -> String {
        fileManager.currentDirectoryPath
    }

    func parentDirectory(of path: String) -> String {
        URL(fileURLWithPath: path, isDirectory: true).deletingLastPathComponent().path
    }

    func childPath(_ name: String, in directory: String) -> String {
        URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent(name).path
    }

    func fileInfo(at path: String) -> EditorFileInfo {
        let normalized = normalizePath(path, isDirectory: false)
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: normalized, isDirectory: &isDir)
        guard exists else {
            return EditorFileInfo(exists: false, isDirectory: false)
        }

        let attrs = try? fileManager.attributesOfItem(atPath: normalized)
        return EditorFileInfo(
            exists: true,
            isDirectory: isDir.boolValue,
            isBinary: isDir.boolValue ? false : isBinaryFile(at: normalized),
            isExecutable: isDir.boolValue ? false : fileManager.isExecutableFile(atPath: normalized),
            modificationDate: attrs?[.modificationDate] as? Date
        )
    }

    func readTextFile(at path: String) throws -> TextReadResult {
        let normalized = normalizePath(path, isDirectory: false)
        let data = try Data(contentsOf: URL(fileURLWithPath: normalized))
        guard let result = TextEncodingDetector.detectAndDecode(data) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        return result
    }

    func writeTextFile(_ contents: String, to path: String, encoding: String.Encoding) throws {
        let normalized = normalizePath(path, isDirectory: false)
        // NOTE (Cross-Platform Pitfall): On Windows (swift-corelibs-foundation using WideCharToMultiByte),
        // contents.data(using: encoding, allowLossyConversion: false) may silently replace unmappable
        // characters (e.g. Emoji in Big5) with default fallback characters ('?') instead of returning nil.
        // We perform a strict roundtrip equality check (roundtrip == contents) to ensure non-lossy
        // encoding validation consistently across macOS, Linux, and Windows.
        guard let data = contents.data(using: encoding, allowLossyConversion: false),
              let roundtrip = String(data: data, encoding: encoding),
              roundtrip == contents else {
            throw EncodingError.unsupportedCharacters
        }
        #if os(Windows)
        try data.write(to: URL(fileURLWithPath: normalized), options: [])
        #else
        try data.write(to: URL(fileURLWithPath: normalized), options: .atomic)
        #endif
    }

    func listDirectory(at path: String) throws -> [EditorDirectoryEntry] {
        let normalized = normalizePath(path, isDirectory: true)
        return try fileManager.contentsOfDirectory(atPath: normalized).map { name in
            let fullPath = childPath(name, in: normalized)
            let info = fileInfo(at: fullPath)
            return EditorDirectoryEntry(
                name: name,
                path: fullPath,
                isDirectory: info.isDirectory,
                isExecutable: info.isExecutable
            )
        }
    }

    private func expandTilde(_ path: String) -> String {
        #if os(Windows)
            let hasTildePrefix = path == "~" || path.hasPrefix("~/") || path.hasPrefix("~\\")
        #else
            let hasTildePrefix = path == "~" || path.hasPrefix("~/")
        #endif
        guard hasTildePrefix else {
            return path
        }

        let home = homeDirectoryPath()
        guard path.count > 1 else {
            return home
        }

        let rest = String(path.dropFirst(2))
        #if os(Windows)
            let components = rest.split(whereSeparator: { $0 == "/" || $0 == "\\" }).map(String.init)
        #else
            let components = rest.split(separator: "/").map(String.init)
        #endif
        return components.reduce(URL(fileURLWithPath: home, isDirectory: true)) { url, component in
            url.appendingPathComponent(component)
        }.path
    }

    private func isBinaryFile(at path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        guard let fileData = try? Data(contentsOf: url, options: [.uncached]) else {
            return true
        }
        let data = Data(fileData.prefix(8192))
        if data.isEmpty { return false }
        let hasUTF16BOM = (data.count >= 2 && ((data[0] == 0xFE && data[1] == 0xFF) || (data[0] == 0xFF && data[1] == 0xFE)))
        if !hasUTF16BOM && data.contains(0) {
            return true
        }

        // NOTE (Cross-Platform Pitfall & UTF-8 Truncation):
        // When checking a file prefix (e.g. 8192 bytes), a 3-byte CJK or 4-byte CJK Extension (CJK Ext-B~I) / Emoji UTF-8 character
        // may be sliced in half at byte 8192. String(data:encoding:.utf8) fails on incomplete
        // trailing UTF-8 sequences and returns nil, which would falsely mark valid UTF-8 text
        // files as binary. We iteratively trim trailing non-ASCII bytes (0x80+) cut off at the
        // 8192-byte boundary (up to 3 trailing bytes for 4-byte UTF-8 sequences) until valid UTF-8
        // decoding succeeds or all boundary bytes are checked.
        var checkBuffer = data
        while !checkBuffer.isEmpty {
            if String(data: checkBuffer, encoding: .utf8) != nil {
                return false
            }
            let last = checkBuffer.last!
            if (last & 0x80) != 0 {
                checkBuffer.removeLast()
            } else {
                break
            }
        }

        return TextEncodingDetector.detectAndDecode(data) == nil
    }
}

final class TestEditorTerminal: EditorTerminal, @unchecked Sendable {
    static let shared = TestEditorTerminal()

    var rows = 24
    var cols = 80

    func enableRawMode() throws {
    }

    func disableRawMode() {
    }

    func getWindowSize() -> (rows: Int, cols: Int) {
        (rows, cols)
    }

    func readKey() -> Key {
        .esc
    }

    func readPendingText(firstChar: Character) -> String {
        String(firstChar)
    }

    func write(_ text: String) {
    }

    func hideCursor() {
    }

    func showCursor() {
    }

    func clearScreen() {
    }
}

extension Editor {
    convenience init(
        filePath: String? = nil,
        wrapColumn: Int? = nil,
        showRuler: Bool? = nil,
        showLineNumbers: Bool? = nil,
        showSubLineNumbers: Bool? = nil,
        enableSyntax: Bool? = nil,
        autoReload: Bool? = nil,
        language: Language? = nil
    ) {
        self.init(
            options: EditorOptions(
                filePaths: filePath.map { [$0] } ?? [],
                wrapColumn: wrapColumn,
                showRuler: showRuler,
                showLineNumbers: showLineNumbers,
                showSubLineNumbers: showSubLineNumbers,
                enableSyntax: enableSyntax,
                autoReload: autoReload,
                language: language
            ),
            dependencies: EditorDependencies(
                fileIOStrategy: TestLocalEditorFileIOStrategy.shared,
                terminal: TestEditorTerminal.shared
            )
        )
    }

    convenience init(
        filePaths: [String],
        wrapColumn: Int? = nil,
        showRuler: Bool? = nil,
        showLineNumbers: Bool? = nil,
        showSubLineNumbers: Bool? = nil,
        enableSyntax: Bool? = nil,
        autoReload: Bool? = nil,
        language: Language? = nil
    ) {
        self.init(
            options: EditorOptions(
                filePaths: filePaths,
                wrapColumn: wrapColumn,
                showRuler: showRuler,
                showLineNumbers: showLineNumbers,
                showSubLineNumbers: showSubLineNumbers,
                enableSyntax: enableSyntax,
                autoReload: autoReload,
                language: language
            ),
            dependencies: EditorDependencies(
                fileIOStrategy: TestLocalEditorFileIOStrategy.shared,
                terminal: TestEditorTerminal.shared
            )
        )
    }
}

extension TextBuffer {
    static func makeBuffer(filePath: String?) -> TextBuffer {
        makeBuffer(filePath: filePath, fileIO: TestLocalEditorFileIOStrategy.shared)
    }

    func reloadFile() throws {
        try reloadFile(fileIO: TestLocalEditorFileIOStrategy.shared)
    }

    func saveFile(to path: String? = nil) throws {
        try saveFile(to: path, fileIO: TestLocalEditorFileIOStrategy.shared)
    }

    func insertFile(at path: String) throws -> Int {
        try insertFile(at: path, fileIO: TestLocalEditorFileIOStrategy.shared)
    }
}
