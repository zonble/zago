import Foundation
import Testing

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

    func readTextFile(at path: String) throws -> String {
        let normalized = normalizePath(path, isDirectory: false)
        guard let text = files[normalized] else {
            throw NSError(domain: "MemoryEditorFileIOStrategy", code: 1)
        }
        return text
    }

    func writeTextFile(_ contents: String, to path: String) throws {
        let normalized = normalizePath(path, isDirectory: false)
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
}

@Test func testEditorLoadsAndSavesThroughFileIODelegate() throws {
    let fileIO = MemoryEditorFileIOStrategy(files: ["/notes.txt": "alpha\nbeta"])
    let editor = Editor(filePath: "/notes.txt", autoReload: false, language: .en, fileIOStrategy: fileIO)

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
    let editor = Editor(filePath: "/project", autoReload: false, language: .en, fileIOStrategy: fileIO)

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
