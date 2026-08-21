import Foundation
import Syntax
import Testing
import TextEncoding

@testable import Editor

final class MemoryEditorFileIOStrategy: EditorFileIOStrategy, @unchecked Sendable {
    var files: [String: String]
    var directories: Set<String>
    var writes: [String: String] = [:]
    var readErrors: [String: Error] = [:]
    var writeErrors: [String: Error] = [:]

    init(files: [String: String] = [:], directories: Set<String> = []) {
        self.files = files
        self.directories = directories
    }

    func normalizePath(_ path: String, isDirectory: Bool) -> String {
        if path == "~" {
            return homeDirectoryPath()
        }
        if path.hasPrefix("~/") {
            return homeDirectoryPath() + "/" + String(path.dropFirst(2))
        }
        return path.replacingOccurrences(of: "\\", with: "/")
    }

    func homeDirectoryPath() -> String {
        "/home/tester"
    }

    func currentDirectoryPath() -> String {
        "/workspace"
    }

    func parentDirectory(of path: String) -> String {
        let normalized = normalizePath(path, isDirectory: true)
        guard let slash = normalized.lastIndex(of: "/"), slash != normalized.startIndex else {
            return "/"
        }
        return String(normalized[..<slash])
    }

    func childPath(_ name: String, in directory: String) -> String {
        let base = normalizePath(directory, isDirectory: true).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return "/" + ([base, name].filter { !$0.isEmpty }).joined(separator: "/")
    }

    func fileInfo(at path: String) -> EditorFileInfo {
        let normalized = normalizePath(path, isDirectory: false)
        if directories.contains(normalized) {
            return EditorFileInfo(exists: true, isDirectory: true)
        }
        if let text = files[normalized] {
            return EditorFileInfo(exists: true, isDirectory: false, isBinary: text.contains("\u{0}"), size: Int64(text.utf8.count))
        }
        return EditorFileInfo(exists: false, isDirectory: false)
    }

    func readTextFile(at path: String) throws -> TextReadResult {
        let normalized = normalizePath(path, isDirectory: false)
        if let error = readErrors[normalized] {
            throw error
        }
        guard let text = files[normalized] else {
            throw NSError(domain: "MemoryEditorFileIOStrategy", code: 1)
        }
        let data = Data(text.utf8)
        return TextEncodingDetector.detectAndDecode(data) ?? TextReadResult(content: text, encoding: .utf8)
    }

    func writeTextFile(_ contents: String, to path: String, encoding: String.Encoding) throws {
        let normalized = normalizePath(path, isDirectory: false)
        if let error = writeErrors[normalized] {
            throw error
        }
        guard let data = contents.data(using: encoding, allowLossyConversion: false),
            let roundtrip = String(data: data, encoding: encoding),
            roundtrip == contents
        else {
            throw EncodingError.unsupportedCharacters
        }
        files[normalized] = contents
        writes[normalized] = contents
    }

    func listDirectory(at path: String) throws -> [EditorDirectoryEntry] {
        let normalized = normalizePath(path, isDirectory: true)
        let prefix = normalized == "/" ? "/" : normalized + "/"

        var entries: [EditorDirectoryEntry] = []
        for directory in directories where directory.hasPrefix(prefix) {
            let rest = String(directory.dropFirst(prefix.count))
            guard !rest.isEmpty, !rest.contains("/") else { continue }
            entries.append(EditorDirectoryEntry(name: rest, path: directory, isDirectory: true))
        }
        for path in files.keys where path.hasPrefix(prefix) {
            let rest = String(path.dropFirst(prefix.count))
            guard !rest.isEmpty, !rest.contains("/") else { continue }
            entries.append(EditorDirectoryEntry(name: rest, path: path, isDirectory: false))
        }
        return entries
    }

    var watchedPath: String? = nil
    var watcherCallback: (@Sendable () -> Void)? = nil

    func startWatchingFile(at path: String, onChange: @escaping @Sendable () -> Void) {
        watchedPath = normalizePath(path, isDirectory: false)
        watcherCallback = onChange
    }

    func stopWatchingFile(at path: String) {
        if watchedPath == normalizePath(path, isDirectory: false) {
            watchedPath = nil
            watcherCallback = nil
        }
    }
}

@Test func testOpenBufferReadFailureDoesNotCreateEmptyBuffer() throws {
    let fileIO = MemoryEditorFileIOStrategy(files: ["/secret.txt": "hidden"])
    fileIO.readErrors["/secret.txt"] = NSError(
        domain: NSCocoaErrorDomain,
        code: CocoaError.fileReadNoPermission.rawValue,
        userInfo: [NSLocalizedDescriptionKey: "No read permission"]
    )
    let editor = Editor(
        options: EditorOptions(autoReload: false, language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared)
    )

    let result = editor.openBuffer(path: "/secret.txt")

    #expect(result == .failed("No read permission"))
    #expect(editor.buffers.count == 1)
    #expect(editor.buffer.filePath == nil)
    #expect(editor.buffer.lines == [""])
    #expect(editor.statusMessage == "Error opening file: No read permission")
}

@Test func testInitialReadFailureMarksBufferReadOnlyAndReportsError() throws {
    let fileIO = MemoryEditorFileIOStrategy(files: ["/secret.txt": "hidden"])
    fileIO.readErrors["/secret.txt"] = NSError(
        domain: NSCocoaErrorDomain,
        code: CocoaError.fileReadNoPermission.rawValue,
        userInfo: [NSLocalizedDescriptionKey: "No read permission"]
    )

    let editor = Editor(
        options: EditorOptions(filePaths: ["/secret.txt"], autoReload: false, language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared)
    )

    #expect(editor.buffer.filePath == "/secret.txt")
    #expect(editor.buffer.lines == [""])
    #expect(editor.buffer.isReadOnly == true)
    #expect(editor.buffer.loadErrorDescription == "No read permission")
    #expect(editor.statusMessage == "Error opening file: No read permission")
}

@Test func testMissingInitialFileOpensAsWritableEmptyBuffer() throws {
    let fileIO = MemoryEditorFileIOStrategy()

    let editor = Editor(
        options: EditorOptions(filePaths: ["/new.txt"], autoReload: false, language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared)
    )

    #expect(editor.buffer.filePath == "/new.txt")
    #expect(editor.buffer.lines == [""])
    #expect(editor.buffer.isReadOnly == false)
    #expect(editor.buffer.loadErrorDescription == nil)
    #expect(editor.statusMessage.isEmpty)
}

@Test func testSaveAndCloseBufferKeepsBufferOpenWhenWriteFails() throws {
    let fileIO = MemoryEditorFileIOStrategy(files: ["/notes.txt": "alpha"])
    fileIO.writeErrors["/notes.txt"] = NSError(
        domain: NSCocoaErrorDomain,
        code: CocoaError.fileWriteNoPermission.rawValue,
        userInfo: [NSLocalizedDescriptionKey: "No write permission"]
    )
    let editor = Editor(
        options: EditorOptions(filePaths: ["/notes.txt"], autoReload: false, language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared)
    )
    editor.openNewBuffer()
    editor.switchToBuffer(index: 0)
    editor.buffer.lines = ["changed"]
    editor.buffer.isModified = true

    let result = editor.saveAndCloseBuffer(path: nil)

    #expect(result == .failed("No write permission"))
    #expect(editor.buffers.count == 2)
    #expect(editor.currentBufferIndex == 0)
    #expect(editor.buffer.filePath == "/notes.txt")
    #expect(editor.buffer.isModified == true)
    #expect(editor.statusMessage == "Error saving file: No write permission")
}

@Test func testExitSaveDecisionWorkflowSavesAndClosesBuffer() throws {
    let fileIO = MemoryEditorFileIOStrategy(files: ["/notes.txt": "alpha"])
    let editor = Editor(
        options: EditorOptions(filePaths: ["/notes.txt"], autoReload: false, language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared)
    )
    editor.openNewBuffer()
    editor.switchToBuffer(index: 0)
    editor.buffer.lines = ["changed"]
    editor.buffer.isModified = true

    let result = editor.completeExitSaveDecision(shouldSave: true)

    #expect(result == .succeeded)
    #expect(fileIO.writes["/notes.txt"] == "changed")
    #expect(editor.buffers.count == 1)
    #expect(editor.buffer.filePath == nil)
}

@Test func testEditorLoadsAndSavesThroughFileIODelegate() throws {
    let fileIO = MemoryEditorFileIOStrategy(files: ["/notes.txt": "alpha\nbeta"])
    let editor = Editor(
        options: EditorOptions(filePaths: ["/notes.txt"], autoReload: false, language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared))

    #expect(editor.buffer.lines == ["alpha", "beta"])

    editor.buffer.lines = ["changed"]
    editor.buffer.isModified = true
    let result = editor.saveBuffer(path: nil)

    #expect(result == .succeeded)
    #expect(fileIO.writes["/notes.txt"] == "changed")
    #expect(editor.buffer.isModified == false)
}

@Test func testFileCommandDispatchReturnsTypedSaveResult() throws {
    let fileIO = MemoryEditorFileIOStrategy(files: ["/notes.txt": "alpha"])
    let editor = Editor(
        options: EditorOptions(filePaths: ["/notes.txt"], autoReload: false, language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared))

    editor.buffer.lines = ["changed"]
    editor.buffer.isModified = true

    let result = editor.commandRegistry.dispatchResult(id: .fileSave, editor: editor)

    #expect(result == .succeeded)
    #expect(fileIO.writes["/notes.txt"] == "changed")
}

@Test func testCommandBarDispatchReturnsTypedOpenFailure() throws {
    let fileIO = MemoryEditorFileIOStrategy(files: ["/secret.txt": "hidden"])
    fileIO.readErrors["/secret.txt"] = NSError(
        domain: NSCocoaErrorDomain,
        code: CocoaError.fileReadNoPermission.rawValue,
        userInfo: [NSLocalizedDescriptionKey: "No read permission"]
    )
    let editor = Editor(
        options: EditorOptions(autoReload: false, language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared))

    let result = editor.commandRegistry.dispatchResult("open /secret.txt", editor: editor)

    #expect(result == .failed("No read permission"))
    #expect(editor.buffers.count == 1)
    #expect(editor.statusMessage == "Error opening file: No read permission")
}

@Test func testDirectoryBufferUsesFileIODelegate() throws {
    let fileIO = MemoryEditorFileIOStrategy(
        files: ["/project/readme.txt": "hello"],
        directories: ["/project", "/project/src"]
    )
    let editor = Editor(
        options: EditorOptions(filePaths: ["/project"], autoReload: false, language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared))

    #expect(editor.buffer is DirectoryBuffer)
    #expect(editor.buffer.lines.contains(where: { $0.hasSuffix("▸ src/") }))
    #expect(editor.buffer.lines.contains(where: { $0.hasSuffix("readme.txt") }))

    let dirBuffer = try #require(editor.buffer as? DirectoryBuffer)
    dirBuffer.lineIndex = try #require(dirBuffer.lines.firstIndex(where: { $0.hasSuffix("readme.txt") }))
    #expect(dirBuffer.activateEntry(editor: editor) == true)

    #expect(editor.buffer.isDirectoryBuffer == false)
    #expect(editor.buffer.filePath == "/project/readme.txt")
    #expect(editor.buffer.lines == ["hello"])
}

@Test func testEditorFileIOStrategyWatchNotificationTrigger() throws {
    let fileIO = MemoryEditorFileIOStrategy(files: ["/notes.txt": "alpha\nbeta"])
    let editor = Editor(
        options: EditorOptions(filePaths: ["/notes.txt"], autoReload: true, language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared)
    )

    #expect(fileIO.watchedPath == "/notes.txt")
    #expect(fileIO.watcherCallback != nil)

    // 1. Not dirty -> Reload directly
    fileIO.files["/notes.txt"] = "updated externally"
    fileIO.watcherCallback?()

    #expect(editor.buffer.lines == ["updated externally"])
    #expect(editor.buffer.isModified == false)
}

@Test func testEditorFileWatcherDirtyPromptsUser() throws {
    let fileIO = MemoryEditorFileIOStrategy(files: ["/notes.txt": "alpha\nbeta"])
    let editor = Editor(
        options: EditorOptions(filePaths: ["/notes.txt"], autoReload: true, language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared)
    )

    // Make buffer dirty
    editor.buffer.lines = ["alpha", "beta", "user edited line"]
    editor.buffer.isModified = true

    // External change occurs on disk
    fileIO.files["/notes.txt"] = "updated on disk"
    fileIO.watcherCallback?()

    // Editor should prompt user for confirmation
    if case .confirmExternalReload = editor.currentPromptMode {
        // Correct prompt mode
    } else {
        Issue.record("Expected confirmExternalReload prompt mode when buffer is dirty")
    }

    // User chooses 'N' -> Keep local changes
    editor.processKey(.char(Character("n")))
    #expect(editor.buffer.lines == ["alpha", "beta", "user edited line"])
    #expect(editor.buffer.isModified == true)

    // Trigger external change again
    fileIO.watcherCallback?()
    if case .confirmExternalReload = editor.currentPromptMode {
        // Correct prompt mode
    } else {
        Issue.record("Expected confirmExternalReload prompt mode when buffer is dirty")
    }

    // User chooses 'Y' -> Discard local changes and reload from disk
    editor.processKey(.char(Character("y")))
    #expect(editor.buffer.lines == ["updated on disk"])
    #expect(editor.buffer.isModified == false)
}

@Test func testHardLimitFileTooLarge() throws {
    let largeContent = String(repeating: "A", count: 2000)
    let fileIO = MemoryEditorFileIOStrategy(files: ["/huge.txt": largeContent])
    let editor = Editor(
        options: EditorOptions(language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared)
    )
    editor.maxFileSizeBytes = 1000

    let result = editor.openBuffer(path: "/huge.txt")
    #expect(!result.isSucceeded)
    #expect(editor.buffer.isReadOnly == true)
    #expect(editor.buffer.isLargeFileMode == false)
    #expect(editor.buffer.lines.first?.contains("File too large") == true)
}

@Test func testSoftLimitLargeFileMode() throws {
    let content = String(repeating: "Hello world\n", count: 100)
    let fileIO = MemoryEditorFileIOStrategy(files: ["/medium.txt": content])
    let editor = Editor(
        options: EditorOptions(language: .en),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared)
    )
    editor.largeFileThresholdBytes = 500
    editor.maxFileSizeBytes = 50000

    let result = editor.openBuffer(path: "/medium.txt")
    #expect(result.isSucceeded)
    #expect(editor.buffer.isReadOnly == false)
    #expect(editor.buffer.isLargeFileMode == true)
    #expect(editor.buffer.lines.count > 1)
}

@Test func testMaxLineHighlightLengthSkipsRegexTokenization() throws {
    let highlighter = SyntaxHighlighter()
    highlighter.maxLineHighlightLength = 30
    guard let swiftSyntax = highlighter.findLanguage(named: "swift") else {
        Issue.record("Swift syntax not found")
        return
    }

    let shortLine = "let foo = 123"
    let shortTokens = highlighter.tokenTypes(for: shortLine, syntax: swiftSyntax)
    #expect(shortTokens.contains(.keyword))

    let longLine = "let foo = 123 // " + String(repeating: "extremely long line content ", count: 5)
    let longTokens = highlighter.tokenTypes(for: longLine, syntax: swiftSyntax)
    #expect(longTokens.allSatisfy { $0 == .normal })
}
