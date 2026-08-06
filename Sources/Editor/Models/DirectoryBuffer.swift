import Foundation
import Git

public final class DirectoryBuffer: TextBuffer {
    public var directoryPath: String
    public let fileIO: EditorFileIOStrategy
    public let gitService: GitServiceProtocol

    override public var isReadOnly: Bool { true }
    override public var allowsLogoExecution: Bool { false }
    override public var isDirectoryBuffer: Bool { true }

    public init(
        directoryPath: String,
        fileIO: EditorFileIOStrategy,
        gitService: GitServiceProtocol = GitService(),
        language: Language = .detectSystemLanguage()
    ) {
        let expandedPath = fileIO.normalizePath(directoryPath, isDirectory: true)
        self.directoryPath = expandedPath
        self.fileIO = fileIO
        self.gitService = gitService
        super.init()
        self.filePath = expandedPath
        loadDirectory(at: expandedPath, language: language)
    }

    public func loadDirectory(at path: String, language: Language = .detectSystemLanguage()) {
        let expandedPath = fileIO.normalizePath(path, isDirectory: true)

        let info = fileIO.fileInfo(at: expandedPath)
        guard info.exists, info.isDirectory else {
            return
        }

        self.directoryPath = expandedPath
        self.filePath = expandedPath
        self.isModified = false

        let repoInfo = gitService.detectRepository(for: expandedPath)
        let branchStr = (repoInfo?.branchName != nil && !repoInfo!.branchName!.isEmpty) ? " [\(repoInfo!.branchName!)]" : ""
        let gitStatusMap: [String: String]
        if let repoRoot = repoInfo?.repoRootPath {
            gitStatusMap = gitService.fetchDirectoryGitStatus(repoRoot: repoRoot)
        } else {
            gitStatusMap = [:]
        }

        let l10n = L10n(language: language)
        var newLines: [String] = []
        newLines.append(l10n.dirBufHeaderDirectory(expandedPath, branchStr))
        newLines.append(l10n.dirBufHeaderInstructions)
        newLines.append("")
        newLines.append(l10n.dirBufUpDir)

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
                let entryRelPath: String
                if let repoRoot = repoInfo?.repoRootPath, expandedPath.hasPrefix(repoRoot) {
                    var relDir = String(expandedPath.dropFirst(repoRoot.count))
                    if relDir.hasPrefix("/") { relDir.removeFirst() }
                    entryRelPath = relDir.isEmpty ? entry.name : "\(relDir)/\(entry.name)"
                } else {
                    entryRelPath = entry.name
                }

                let rawBadge = gitStatusMap[entryRelPath] ?? gitStatusMap["\(entryRelPath)/"] ?? ""
                let badgePrefix: String
                if rawBadge.isEmpty {
                    badgePrefix = "  "
                } else {
                    let code: String
                    if rawBadge.contains("?") { code = "?" }
                    else if rawBadge.contains("A") { code = "A" }
                    else if rawBadge.contains("M") { code = "M" }
                    else if rawBadge.contains("D") { code = "D" }
                    else if rawBadge.contains("R") { code = "R" }
                    else { code = "M" }
                    badgePrefix = "\(code) "
                }

                if entry.isDirectory {
                    newLines.append("\(badgePrefix)▸ \(entry.name)/")
                } else {
                    newLines.append("\(badgePrefix)\(entry.name)\(entry.isExecutable ? "*" : "")")
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
            editor.setStatusMessage(editor.l10n["status.directory_buffer_readonly"])
            return true
        case .char(let ch):
            if ch.isWhitespace {
                return true
            }
            editor.setStatusMessage(editor.l10n["status.directory_buffer_readonly"])
            return true
        default:
            return false
        }
    }

    @discardableResult
    public func activateEntry(editor: Editor) -> Bool {
        guard lineIndex >= 0 && lineIndex < lines.count else { return false }
        let line = lines[lineIndex]
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedLine == ".. (up a dir)" || trimmedLine.hasPrefix("..") {
            return navigateUp(editor: editor)
        }

        if line.contains("▸ ") {
            let parts = line.components(separatedBy: "▸ ")
            if parts.count >= 2 {
                var folderName = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
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
        }

        if lineIndex >= 4 {
            var rawName = line.trimmingCharacters(in: .newlines)
            if rawName.count >= 2 {
                let firstTwo = rawName.prefix(2)
                if firstTwo == "M " || firstTwo == "? " || firstTwo == "A " || firstTwo == "D " || firstTwo == "R " || firstTwo == "  " {
                    rawName = String(rawName.dropFirst(2))
                }
            }
            let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            var fileName = trimmed
            if fileName.hasSuffix("*") {
                fileName = String(fileName.dropLast())
            }
            let targetFilePath = fileIO.childPath(fileName, in: directoryPath)
            if fileIO.fileInfo(at: targetFilePath).isBinary {
                editor.setStatusMessage(editor.l10n["status.cannot_open_binary_file"])
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
