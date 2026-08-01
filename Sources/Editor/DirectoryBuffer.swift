import Foundation

public final class DirectoryBuffer: TextBuffer {
    public var directoryPath: String

    override public var isReadOnly: Bool { true }
    override public var allowsLogoExecution: Bool { false }
    override public var isDirectoryBuffer: Bool { true }

    public init(directoryPath: String) {
        let expandedPath = NSString(string: directoryPath).expandingTildeInPath
        self.directoryPath = expandedPath
        super.init(filePath: expandedPath)
        loadDirectory(at: expandedPath)
    }

    public func loadDirectory(at path: String) {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let fileManager = FileManager.default

        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: expandedPath, isDirectory: &isDir), isDir.boolValue else {
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

        if let contents = try? fileManager.contentsOfDirectory(atPath: expandedPath) {
            let sorted = contents.filter { name in
                !name.hasPrefix(".") || name == ".zagorc" || name == ".serc"
            }.sorted { lhs, rhs in
                let lhsPath = (expandedPath as NSString).appendingPathComponent(lhs)
                let rhsPath = (expandedPath as NSString).appendingPathComponent(rhs)
                var lhsIsDir: ObjCBool = false
                var rhsIsDir: ObjCBool = false
                fileManager.fileExists(atPath: lhsPath, isDirectory: &lhsIsDir)
                fileManager.fileExists(atPath: rhsPath, isDirectory: &rhsIsDir)

                if lhsIsDir.boolValue != rhsIsDir.boolValue {
                    return lhsIsDir.boolValue
                }
                return lhs.lowercased() < rhs.lowercased()
            }

            for name in sorted {
                let fullPath = (expandedPath as NSString).appendingPathComponent(name)
                var entryIsDir: ObjCBool = false
                fileManager.fileExists(atPath: fullPath, isDirectory: &entryIsDir)

                if entryIsDir.boolValue {
                    newLines.append("▸ \(name)/")
                } else {
                    let isExec = fileManager.isExecutableFile(atPath: fullPath)
                    newLines.append("  \(name)\(isExec ? "*" : "")")
                }
            }
        }

        self.lines = newLines
        self.lineIndex = min(3, max(0, newLines.count - 1))
        self.columnIndex = 0
    }

    override public func saveFile(to path: String? = nil) throws {
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
            let childDir = (directoryPath as NSString).appendingPathComponent(folderName)
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
            let targetFilePath = (directoryPath as NSString).appendingPathComponent(fileName)
            if isBinaryFile(at: targetFilePath) {
                editor.setStatusMessage(L10n["status.cannot_open_binary_file"])
                return true
            }
            editor.openBuffer(path: targetFilePath)
            return true
        }

        return false
    }

    private func isBinaryFile(at path: String) -> Bool {
        guard let fileHandle = FileHandle(forReadingAtPath: path) else { return false }
        defer { fileHandle.closeFile() }

        let data = fileHandle.readData(ofLength: 8192)
        if data.isEmpty { return false }

        if data.contains(0) { return true }
        if String(data: data, encoding: .utf8) == nil {
            return true
        }

        return false
    }

    @discardableResult
    public func navigateUp(editor: Editor) -> Bool {
        let parentDir = (directoryPath as NSString).deletingLastPathComponent
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
            resolvedPath = NSString(string: targetPath).expandingTildeInPath
        } else if let dirBuffer = buffer as? DirectoryBuffer {
            resolvedPath = dirBuffer.directoryPath
        } else if let filePath = buffer.filePath {
            resolvedPath = (filePath as NSString).deletingLastPathComponent
        } else {
            resolvedPath = FileManager.default.currentDirectoryPath
        }

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: resolvedPath, isDirectory: &isDir), isDir.boolValue else {
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
            currentBufferIndex = existingIndex
            (buffers[existingIndex] as? DirectoryBuffer)?.loadDirectory(at: resolvedPath)
            topVLineIndex = 0
            clearActiveMark()
            startFileWatcherForCurrentBuffer()
            return
        }

        // 3. Otherwise open new DirectoryBuffer
        openNewBuffer(filePath: resolvedPath)
    }
}
