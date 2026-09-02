import Foundation
import Git

public enum DirectorySortField: String, Sendable, CaseIterable {
    case name
    case creationDate = "created"
    case modificationDate = "modified"
}

public enum DirectorySortOrder: String, Sendable, CaseIterable {
    case ascending = "asc"
    case descending = "desc"
}

public struct DirectorySortOption: Sendable, Equatable {
    public var field: DirectorySortField
    public var order: DirectorySortOrder

    public init(field: DirectorySortField = .name, order: DirectorySortOrder = .ascending) {
        self.field = field
        self.order = order
    }

    public mutating func toggleOrder() {
        order = (order == .ascending) ? .descending : .ascending
    }

    public mutating func cycle() {
        switch (field, order) {
        case (.name, .ascending):
            order = .descending
        case (.name, .descending):
            field = .creationDate
            order = .ascending
        case (.creationDate, .ascending):
            order = .descending
        case (.creationDate, .descending):
            field = .modificationDate
            order = .ascending
        case (.modificationDate, .ascending):
            order = .descending
        case (.modificationDate, .descending):
            field = .name
            order = .ascending
        }
    }

    public func displayName(language: Language) -> String {
        let isZh = language == .zh_TW
        let fieldName: String
        switch field {
        case .name: fieldName = isZh ? "名稱" : "Name"
        case .creationDate: fieldName = isZh ? "建立" : "Created"
        case .modificationDate: fieldName = isZh ? "修改" : "Modified"
        }
        let orderSymbol = (order == .ascending) ? "▲" : "▼"
        return "\(fieldName) \(orderSymbol)"
    }
}

final class DirectoryBuffer: TextBuffer {
    var directoryPath: String
    let fileIO: EditorFileIOStrategy
    let gitService: GitServiceProtocol
    var sortOption: DirectorySortOption = DirectorySortOption()

    override var isReadOnly: Bool {
        get { true }
        set {}
    }
    override var allowsLogoExecution: Bool { false }
    override var isDirectoryBuffer: Bool { true }
    override var viewWrapColumn: Int? {
        get { nil }
        set {}
    }

    var currentLanguage: Language

    init(
        directoryPath: String,
        fileIO: EditorFileIOStrategy,
        gitService: GitServiceProtocol = GitService(),
        language: Language = .detectSystemLanguage(),
        sortOption: DirectorySortOption = DirectorySortOption()
    ) {
        let expandedPath = fileIO.normalizePath(directoryPath, isDirectory: true)
        self.directoryPath = expandedPath
        self.fileIO = fileIO
        self.gitService = gitService
        self.currentLanguage = language
        self.sortOption = sortOption
        super.init()
        self.filePath = expandedPath
        loadDirectory(at: expandedPath, language: language)
    }

    func setSortOption(_ option: DirectorySortOption, editor: Editor? = nil) {
        self.sortOption = option
        loadDirectory(at: directoryPath, language: currentLanguage)
        editor?.renderer.invalidateScreenCache()
        if let editor {
            let msg = String(format: editor.l10n["status.dir_sorted"], sortOption.displayName(language: currentLanguage))
            editor.reportOperationResult(.succeeded(message: msg))
        }
    }

    func loadDirectory(at path: String, language: Language? = nil) {
        if let lang = language {
            self.currentLanguage = lang
        }
        let expandedPath = fileIO.normalizePath(path, isDirectory: true)

        let info = fileIO.fileInfo(at: expandedPath)
        guard info.exists, info.isDirectory else {
            return
        }

        let hadExistingListing = self.lines.count > Self.headerLineCount
        let isSameDirectory = (expandedPath == self.directoryPath && hadExistingListing)
        self.directoryPath = expandedPath
        self.filePath = expandedPath
        self.isModified = false

        let repoInfo = gitService.detectRepository(for: expandedPath)
        let branchStr =
            (repoInfo?.branchName != nil && !repoInfo!.branchName!.isEmpty) ? " [\(repoInfo!.branchName!)]" : ""
        let gitStatusMap: [String: String]
        if let repoRoot = repoInfo?.repoRootPath {
            gitStatusMap = gitService.fetchDirectoryGitStatus(repoRoot: repoRoot)
        } else {
            gitStatusMap = [:]
        }

        let l10n = L10n(language: currentLanguage)
        var newLines: [String] = []
        newLines.append(l10n.dirBufHeaderDirectory(expandedPath, branchStr))
        newLines.append(l10n.dirBufHeaderInstructions)
        newLines.append("")
        newLines.append("  \(l10n.dirBufUpDir)")

        if let contents = try? fileIO.listDirectory(at: expandedPath) {
            let sorted = contents.sorted { lhs, rhs in
                if lhs.isDirectory != rhs.isDirectory {
                    return lhs.isDirectory
                }
                switch self.sortOption.field {
                case .name:
                    let cmp = lhs.name.localizedStandardCompare(rhs.name)
                    return self.sortOption.order == .ascending ? (cmp == .orderedAscending) : (cmp == .orderedDescending)
                case .creationDate:
                    let d1 = lhs.creationDate ?? .distantPast
                    let d2 = rhs.creationDate ?? .distantPast
                    if d1 != d2 {
                        return self.sortOption.order == .ascending ? (d1 < d2) : (d1 > d2)
                    }
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                case .modificationDate:
                    let d1 = lhs.modificationDate ?? .distantPast
                    let d2 = rhs.modificationDate ?? .distantPast
                    if d1 != d2 {
                        return self.sortOption.order == .ascending ? (d1 < d2) : (d1 > d2)
                    }
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
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
                    if rawBadge.contains("?") {
                        code = "?"
                    } else if rawBadge.contains("A") {
                        code = "A"
                    } else if rawBadge.contains("M") {
                        code = "M"
                    } else if rawBadge.contains("D") {
                        code = "D"
                    } else if rawBadge.contains("R") {
                        code = "R"
                    } else {
                        code = "M"
                    }
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
        let minSelectableLine = min(firstEntryLineIndex, max(0, newLines.count - 1))
        if isSameDirectory {
            self.lineIndex = max(minSelectableLine, min(self.lineIndex, max(0, newLines.count - 1)))
        } else {
            self.lineIndex = minSelectableLine
            self.topVLineIndex = 0
        }
        self.columnIndex = 0
    }

    /// Number of fixed header lines preceding the first actionable entry (`.. (up a dir)`).
    static let headerLineCount: Int = 3

    /// Index of the first actionable entry line (`.. (up a dir)`).
    var firstEntryLineIndex: Int {
        lines.count > Self.headerLineCount ? Self.headerLineCount : 0
    }

    override func clampCursor() {
        if lines.isEmpty {
            lines = [""]
            lineIndex = 0
            columnIndex = 0
            return
        }
        lineIndex = max(firstEntryLineIndex, min(lineIndex, lines.count - 1))
        columnIndex = 0
    }

    override func handleKey(_ key: Key, editor: Editor) -> Bool {
        switch key {
        case .enter:
            _ = activateEntry(editor: editor)
            return true
        case .backspace, .char("b"), .char("u"):
            _ = navigateUp(editor: editor)
            return true
        case .arrowDown, .char("j"), .char("J"):
            if !self.lines.isEmpty {
                self.lineIndex = min(self.lines.count - 1, self.lineIndex + 1)
                self.columnIndex = 0
                editor.renderer.invalidateScreenCache()
            }
            return true
        case .arrowUp, .char("k"), .char("K"):
            if !self.lines.isEmpty {
                self.lineIndex = max(firstEntryLineIndex, self.lineIndex - 1)
                self.columnIndex = 0
                editor.renderer.invalidateScreenCache()
            }
            return true
        case .home:
            if !self.lines.isEmpty {
                self.lineIndex = firstEntryLineIndex
                self.columnIndex = 0
                editor.renderer.invalidateScreenCache()
            }
            return true
        case .end:
            if !self.lines.isEmpty {
                self.lineIndex = self.lines.count - 1
                self.columnIndex = 0
                editor.renderer.invalidateScreenCache()
            }
            return true
        case .pageDown, .ctrl("V"):
            if !self.lines.isEmpty {
                self.lineIndex = min(self.lines.count - 1, self.lineIndex + 10)
                self.columnIndex = 0
                editor.renderer.invalidateScreenCache()
            }
            return true
        case .pageUp, .ctrl("Y"):
            if !self.lines.isEmpty {
                self.lineIndex = max(firstEntryLineIndex, self.lineIndex - 10)
                self.columnIndex = 0
                editor.renderer.invalidateScreenCache()
            }
            return true
        case .arrowLeft, .arrowRight, .resize:
            return false
        case .char("s"), .char("S"):
            sortOption.cycle()
            loadDirectory(at: directoryPath, language: currentLanguage)
            editor.renderer.invalidateScreenCache()
            let msg = String(format: editor.l10n["status.dir_sorted"], sortOption.displayName(language: currentLanguage))
            editor.reportOperationResult(.succeeded(message: msg))
            return true
        case .char("o"), .char("O"):
            sortOption.toggleOrder()
            loadDirectory(at: directoryPath, language: currentLanguage)
            editor.renderer.invalidateScreenCache()
            let msg = String(format: editor.l10n["status.dir_sorted"], sortOption.displayName(language: currentLanguage))
            editor.reportOperationResult(.succeeded(message: msg))
            return true
        case .delete, .ctrlBackspace, .altBackspace:
            editor.reportOperationResult(.noOp(message: editor.l10n["status.directory_buffer_readonly"]))
            return true
        case .char(let ch):
            if ch.isWhitespace {
                return true
            }
            editor.reportOperationResult(.noOp(message: editor.l10n["status.directory_buffer_readonly"]))
            return true
        default:
            return false
        }
    }

    @discardableResult
    func activateEntry(editor: Editor) -> Bool {
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
                loadDirectory(at: childDir, language: currentLanguage)
                editor.topVLineIndex = 0
                editor.clearActiveMark()
                editor.startFileWatcherForCurrentBuffer()
                editor.renderer.invalidateScreenCache()
                return true
            }
        }

        if lineIndex >= 4 {
            var rawName = line.trimmingCharacters(in: .newlines)
            if rawName.count >= 2 {
                let firstTwo = rawName.prefix(2)
                if firstTwo == "M " || firstTwo == "? " || firstTwo == "A " || firstTwo == "D " || firstTwo == "R "
                    || firstTwo == "  "
                {
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
                editor.reportOperationResult(.noOp(message: editor.l10n["status.cannot_open_binary_file"]))
                return true
            }
            editor.openBuffer(path: targetFilePath)
            return true
        }

        return false
    }

    @discardableResult
    func navigateUp(editor: Editor) -> Bool {
        let parentDir = fileIO.parentDirectory(of: directoryPath)
        if !parentDir.isEmpty && parentDir != directoryPath {
            loadDirectory(at: parentDir, language: currentLanguage)
            editor.topVLineIndex = 0
            editor.clearActiveMark()
            editor.startFileWatcherForCurrentBuffer()
            editor.renderer.invalidateScreenCache()
            return true
        }
        return false
    }
}
