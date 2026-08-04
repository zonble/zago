import Foundation
import Testing
import TextEncoding

@testable import Editor

private final class MemoryEditorFileIOStrategy: EditorFileIOStrategy, @unchecked Sendable {
    var files: [String: String]
    var directories: Set<String>
    var writes: [String: String] = [:]

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
            return EditorFileInfo(exists: true, isDirectory: false, isBinary: text.contains("\u{0}"))
        }
        return EditorFileInfo(exists: false, isDirectory: false)
    }

    func readTextFile(at path: String) throws -> TextReadResult {
        let normalized = normalizePath(path, isDirectory: false)
        guard let text = files[normalized] else {
            throw NSError(domain: "MemoryEditorFileIOStrategy", code: 1)
        }
        let data = Data(text.utf8)
        return TextEncodingDetector.detectAndDecode(data) ?? TextReadResult(content: text, encoding: .utf8)
    }

    func writeTextFile(_ contents: String, to path: String, encoding: String.Encoding) throws {
        let normalized = normalizePath(path, isDirectory: false)
        guard contents.data(using: encoding) != nil else {
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
    var watcherCallback: (() -> Void)? = nil

    func startWatchingFile(at path: String, onChange: @escaping () -> Void) {
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

@Test func testEditorLoadsAndSavesThroughFileIODelegate() throws {
    let fileIO = MemoryEditorFileIOStrategy(files: ["/notes.txt": "alpha\nbeta"])
    let editor = Editor(
        filePath: "/notes.txt",
        autoReload: false,
        language: .en,
        fileIOStrategy: fileIO,
        terminal: TestEditorTerminal.shared)

    #expect(editor.buffer.lines == ["alpha", "beta"])

    editor.buffer.lines = ["changed"]
    editor.buffer.isModified = true
    editor.saveBuffer(path: nil)

    #expect(fileIO.writes["/notes.txt"] == "changed")
    #expect(editor.buffer.isModified == false)
}

@Test func testDirectoryBufferUsesFileIODelegate() throws {
    let fileIO = MemoryEditorFileIOStrategy(
        files: ["/project/readme.txt": "hello"],
        directories: ["/project", "/project/src"]
    )
    let editor = Editor(
        filePath: "/project",
        autoReload: false,
        language: .en,
        fileIOStrategy: fileIO,
        terminal: TestEditorTerminal.shared)

    #expect(editor.buffer is DirectoryBuffer)
    #expect(editor.buffer.lines.contains("▸ src/"))
    #expect(editor.buffer.lines.contains("  readme.txt"))

    let dirBuffer = try #require(editor.buffer as? DirectoryBuffer)
    dirBuffer.lineIndex = try #require(dirBuffer.lines.firstIndex(of: "  readme.txt"))
    #expect(dirBuffer.activateEntry(editor: editor) == true)

    #expect(editor.buffer.isDirectoryBuffer == false)
    #expect(editor.buffer.filePath == "/project/readme.txt")
    #expect(editor.buffer.lines == ["hello"])
}

@Test func testEditorFileIOStrategyWatchNotificationTrigger() throws {
    let fileIO = MemoryEditorFileIOStrategy(files: ["/notes.txt": "alpha\nbeta"])
    let editor = Editor(filePath: "/notes.txt", autoReload: true, language: .en, fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared)

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
    let editor = Editor(filePath: "/notes.txt", autoReload: true, language: .en, fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared)

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


