import Foundation

public final class DirectoryBuffer: TextBuffer {
    public var directoryPath: String
    public let fileIO: EditorFileIOStrategy

    override public var isReadOnly: Bool { true }
    override public var allowsLogoExecution: Bool { false }
    override public var isDirectoryBuffer: Bool { true }

    public init(
        directoryPath: String,
        fileIO: EditorFileIOStrategy
    ) {
        let expandedPath = fileIO.normalizePath(directoryPath, isDirectory: true)
        self.directoryPath = expandedPath
        self.fileIO = fileIO
        super.init()
        self.filePath = expandedPath
        loadDirectory(at: expandedPath)
    }

    public func loadDirectory(at path: String) {
        let expandedPath = fileIO.normalizePath(path, isDirectory: true)

        let info = fileIO.fileInfo(at: expandedPath)
        guard info.exists, info.isDirectory else {
            return
        }

        self.directoryPath = expandedPath
        self.filePath = expandedPath
        self.isModified = false

        var newLines: [String] = []
        newLines.append("\" Directory: \(expandedPath)")
        newLines.append("\" Press Enter on a file to open, or on a folder to navigate")
        newLines.append("")
        newLines.append(".. (up a dir)")

        if let contents = try? fileIO.listDirectory(at: expandedPath) {
            let sorted = contents.filter { entry in
                !entry.name.hasPrefix(".") || entry.name == ".zagorc" || entry.name == ".serc"
            }.sorted { lhs, rhs in
                if lhs.isDirectory != rhs.isDirectory {
                    return lhs.isDirectory
                }
                return lhs.name.lowercased() < rhs.name.lowercased()
            }

            for entry in sorted {
                if entry.isDirectory {
                    newLines.append("▸ \(entry.name)/")
                } else {
                    newLines.append("  \(entry.name)\(entry.isExecutable ? "*" : "")")
                }
            }
        }

        self.lines = newLines
        self.lineIndex = min(3, max(0, newLines.count - 1))
        self.columnIndex = 0
    }

    override public func saveFile(
        to path: String? = nil,
        fileIO: EditorFileIOStrategy,
        encoding: String.Encoding? = nil
    ) throws {
        // Directory buffers are read-only, do not overwrite directory with text
    }

    override public func handleKey(_ key: Key, editor: Editor) -> Bool {
        switch key {
        case .enter:
            _ = activateEntry(editor: editor)
            return true
        case .backspace, .char("b"), .char("u"):
            _ = navigateUp(editor: editor)
            return true
        case .arrowUp, .arrowDown, .arrowLeft, .arrowRight, .home, .end, .pageUp, .pageDown, .resize:
            return false
        case .delete, .ctrlBackspace:
            editor.setStatusMessage(L10n["status.directory_buffer_readonly"])
            return true
        case .char(let ch):
            if ch.isWhitespace {
                return true
            }
            editor.setStatusMessage(L10n["status.directory_buffer_readonly"])
            return true
        default:
            return false
        }
    }

    @discardableResult
    public func activateEntry(editor: Editor) -> Bool {
        guard lineIndex >= 0 && lineIndex < lines.count else { return false }
        let trimmedLine = lines[lineIndex].trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedLine == ".. (up a dir)" || trimmedLine.hasPrefix("..") {
            return navigateUp(editor: editor)
        }

        if trimmedLine.hasPrefix("▸ ") {
            var folderName = String(trimmedLine.dropFirst(2))
            if folderName.hasSuffix("/") {
                folderName = String(folderName.dropLast())
            }
            let childDir = fileIO.childPath(folderName, in: directoryPath)
            loadDirectory(at: childDir)
            editor.topVLineIndex = 0
            editor.clearActiveMark()
            editor.startFileWatcherForCurrentBuffer()
            return true
        }

        if lines[lineIndex].hasPrefix("  ") {
            let rawLine = lines[lineIndex].trimmingCharacters(in: .newlines)
            var fileName = String(rawLine.dropFirst(2))
            if fileName.hasSuffix("*") {
                fileName = String(fileName.dropLast())
            }
            let targetFilePath = fileIO.childPath(fileName, in: directoryPath)
            if fileIO.fileInfo(at: targetFilePath).isBinary {
                editor.setStatusMessage(L10n["status.cannot_open_binary_file"])
                return true
            }
            editor.openBuffer(path: targetFilePath)
            return true
        }

        return false
    }

    @discardableResult
    public func navigateUp(editor: Editor) -> Bool {
        let parentDir = fileIO.parentDirectory(of: directoryPath)
        if !parentDir.isEmpty && parentDir != directoryPath {
            loadDirectory(at: parentDir)
            editor.topVLineIndex = 0
            editor.clearActiveMark()
            editor.startFileWatcherForCurrentBuffer()
            return true
        }
        return false
    }
}

extension Editor {
    /// Opens current working directory or specified directory path in a DirectoryBuffer.
    public func openDirectoryBuffer(path: String? = nil) {
        let targetPath = path?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedPath: String
        if let targetPath, !targetPath.isEmpty {
            resolvedPath = fileIOStrategy.normalizePath(targetPath, isDirectory: true)
        } else if let dirBuffer = buffer as? DirectoryBuffer {
            resolvedPath = dirBuffer.directoryPath
        } else if let filePath = buffer.filePath {
            resolvedPath = fileIOStrategy.parentDirectory(of: filePath)
        } else {
            resolvedPath = fileIOStrategy.normalizePath(fileIOStrategy.currentDirectoryPath(), isDirectory: true)
        }

        let info = fileIOStrategy.fileInfo(at: resolvedPath)
        guard info.exists, info.isDirectory else {
            setStatusMessage(L10n["status.no_such_buffer"])
            return
        }

        // 1. If current active buffer is ALREADY a DirectoryBuffer for resolvedPath: reload in place
        if let dirBuffer = buffer as? DirectoryBuffer, dirBuffer.directoryPath == resolvedPath {
            dirBuffer.loadDirectory(at: resolvedPath)
            startFileWatcherForCurrentBuffer()
            return
        }

        // 2. If another open buffer is ALREADY a DirectoryBuffer for resolvedPath: switch to it
        if let existingIndex = buffers.firstIndex(where: { ($0 as? DirectoryBuffer)?.directoryPath == resolvedPath }) {
            switchToBuffer(index: existingIndex)
            (buffers[existingIndex] as? DirectoryBuffer)?.loadDirectory(at: resolvedPath)
            startFileWatcherForCurrentBuffer()
            return
        }

        // 3. Otherwise open new DirectoryBuffer
        openNewBuffer(filePath: resolvedPath)
    }
}
