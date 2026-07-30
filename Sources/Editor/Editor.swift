import Foundation
import LogoEngine

/// Nano-style UI state machine and core editor engine.
public final class Editor {
    let terminal: Terminal
    public var buffers: [TextBuffer] = []
    public var currentBufferIndex: Int = 0

    /// Active text buffer.
    public var buffer: TextBuffer {
        get {
            if buffers.isEmpty {
                buffers.append(TextBuffer())
            }
            let idx = max(0, min(currentBufferIndex, buffers.count - 1))
            return buffers[idx]
        }
        set {
            if buffers.isEmpty {
                buffers.append(newValue)
            } else {
                let idx = max(0, min(currentBufferIndex, buffers.count - 1))
                buffers[idx] = newValue
            }
        }
    }
    public let layoutEngine: LayoutEngine
    public let renderer = Renderer()

    var isRunning = true
    var statusMessage: String = ""
    var statusMessageTime: Date?

    var clipboardText: String? = nil
    var selectionMark: (line: Int, column: Int)? = nil

    // UI Viewport Scrolling Offset (measured in VirtualLineIndex units)
    var topVLineIndex: Int = 0

    let spellChecker = SpellChecker()

    // Persistent LOGO Macro Engine
    public lazy var logoEngine: LogoEngine = LogoEngine(delegate: self)

    // Prompt state
    var currentPromptMode: PromptMode = .none
    var promptInputText: String = ""
    var promptCursorIndex: Int = 0
    var lastSearchQuery: String = ""
    var logoPromptHistory: [String] = []
    var logoHistoryIndex: Int = 0

    // Menu Bar state
    public var isMenuBarActive: Bool = false
    public let menuBar = MenuBar()

    // Table Mode state
    public var isTableModeActive: Bool = false
    public var currentTableCell: TableCell? = nil
    public var defaultBorderStyle: BorderStyle = .single

    var undoStack: [UndoSnapshot] = []
    let maxUndoStackSize = 100
    var lastMutationTime: Date?
    var lastIsPaste: Bool = false

    let syntaxHighlighter = SyntaxHighlighter()
    public let commandRegistry = CommandRegistry()
    public let fileWatcher = FileWatcher()

    public struct DisplayConfig: Sendable, Equatable {
        public var showRuler: Bool
        public var showLineNumbers: Bool
        public var enableSyntaxHighlight: Bool
        public var autoReload: Bool
        public var tabSize: Int

        public init(
            showRuler: Bool = false,
            showLineNumbers: Bool = true,
            enableSyntaxHighlight: Bool = true,
            autoReload: Bool = true,
            tabSize: Int = 4
        ) {
            self.showRuler = showRuler
            self.showLineNumbers = showLineNumbers
            self.enableSyntaxHighlight = enableSyntaxHighlight
            self.autoReload = autoReload
            self.tabSize = tabSize
        }
    }

    public var displayConfig: DisplayConfig

    public init(
        filePaths: [String], wrapColumn: Int? = nil, showRuler: Bool? = nil, enableSyntax: Bool? = nil,
        autoReload: Bool? = nil, language: Language? = nil
    ) {
        self.terminal = Terminal()

        if filePaths.isEmpty {
            self.buffers = [TextBuffer()]
        } else {
            self.buffers = filePaths.map { TextBuffer(filePath: $0) }
        }
        self.currentBufferIndex = 0

        let loadedConfig = ConfigLoader().loadConfig()

        // CLI argument priority > .serc config > default
        let finalWrap = wrapColumn ?? loadedConfig.wrapColumn
        let finalRuler = showRuler ?? loadedConfig.showRuler
        let finalLineNumbers = loadedConfig.showLineNumbers
        let finalSyntax = enableSyntax ?? loadedConfig.enableSyntaxHighlight
        let finalReload = autoReload ?? loadedConfig.autoReload
        let finalLang = language ?? loadedConfig.language ?? Language.detectSystemLanguage()
        let finalTabSize = loadedConfig.tabSize

        L10n.currentLanguage = finalLang
        self.layoutEngine = LayoutEngine(wrapColumn: finalWrap)
        self.displayConfig = DisplayConfig(
            showRuler: finalRuler, showLineNumbers: finalLineNumbers, enableSyntaxHighlight: finalSyntax,
            autoReload: finalReload, tabSize: finalTabSize)

        setupDefaultCommands()
        applyCustomConfig(loadedConfig)

        startFileWatcherForCurrentBuffer()

        fileWatcher.onChange = { [weak self] in
            guard let self = self, self.displayConfig.autoReload else { return }
            self.handleExternalFileChange()
        }
    }

    public convenience init(
        filePath: String? = nil, wrapColumn: Int? = nil, showRuler: Bool? = nil, enableSyntax: Bool? = nil,
        autoReload: Bool? = nil, language: Language? = nil
    ) {
        let paths = filePath != nil ? [filePath!] : []
        self.init(
            filePaths: paths, wrapColumn: wrapColumn, showRuler: showRuler, enableSyntax: enableSyntax,
            autoReload: autoReload, language: language)
    }

    private func startFileWatcherForCurrentBuffer() {
        if let path = buffer.filePath {
            fileWatcher.start(path: path)
        } else {
            fileWatcher.stop()
        }
    }

    /// Switches to next open buffer in sequence.
    public func nextBuffer() {
        guard buffers.count > 1 else { return }
        currentBufferIndex = (currentBufferIndex + 1) % buffers.count
        topVLineIndex = 0
        selectionMark = nil
        startFileWatcherForCurrentBuffer()
    }

    /// Switches to previous open buffer in sequence.
    public func prevBuffer() {
        guard buffers.count > 1 else { return }
        currentBufferIndex = (currentBufferIndex - 1 + buffers.count) % buffers.count
        topVLineIndex = 0
        selectionMark = nil
        startFileWatcherForCurrentBuffer()
    }

    /// Opens a new buffer for given file path or empty buffer.
    public func openNewBuffer(filePath: String? = nil) {
        let newBuf = TextBuffer(filePath: filePath)
        buffers.append(newBuf)
        currentBufferIndex = buffers.count - 1
        topVLineIndex = 0
        selectionMark = nil
        startFileWatcherForCurrentBuffer()
    }

    /// Opens ~/.zagorc in a buffer for editing. Creates ~/.zagorc with default template if it does not exist.
    public func editConfig() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let zagorcPath = (homeDir as NSString).appendingPathComponent(".zagorc")
        let sercPath = (homeDir as NSString).appendingPathComponent(".serc")

        let configPath: String
        if FileManager.default.fileExists(atPath: zagorcPath) {
            configPath = zagorcPath
        } else if FileManager.default.fileExists(atPath: sercPath) {
            configPath = sercPath
        } else {
            _ = try? ConfigLoader.generateDefaultConfigFile(targetPath: zagorcPath)
            configPath = zagorcPath
        }

        if let existingIndex = buffers.firstIndex(where: { $0.filePath == configPath }) {
            currentBufferIndex = existingIndex
            topVLineIndex = 0
            selectionMark = nil
            startFileWatcherForCurrentBuffer()
        } else {
            openNewBuffer(filePath: configPath)
        }
        setStatusMessage("[ Editing \(configPath) ]")
    }

    /// Reloads configuration settings from ~/.serc or ./.serc files.
    public func reloadConfig() {
        let loadedConfig = ConfigLoader().loadConfig()
        self.layoutEngine.wrapColumn = loadedConfig.wrapColumn
        self.displayConfig.showRuler = loadedConfig.showRuler
        self.displayConfig.showLineNumbers = loadedConfig.showLineNumbers
        self.displayConfig.enableSyntaxHighlight = loadedConfig.enableSyntaxHighlight
        self.displayConfig.autoReload = loadedConfig.autoReload
        self.displayConfig.tabSize = loadedConfig.tabSize
        if let lang = loadedConfig.language {
            L10n.currentLanguage = lang
        }
        applyCustomConfig(loadedConfig)
        setStatusMessage("[ Config reloaded ]")
    }

    /// Closes current active buffer. If no buffers remain, exits editor.
    public func closeCurrentBuffer() {
        guard !buffers.isEmpty else {
            isRunning = false
            return
        }

        buffers.remove(at: currentBufferIndex)
        if buffers.isEmpty {
            isRunning = false
        } else {
            currentBufferIndex = max(0, min(currentBufferIndex, buffers.count - 1))
            topVLineIndex = 0
            selectionMark = nil
            startFileWatcherForCurrentBuffer()
        }
    }

    /// Deletes current line with Undo snapshot tracking.
    public func deleteCurrentLine() {
        if isTableModeActive, currentTableCell != nil {
            deleteCurrentTableCellLine()
            return
        }
        buffer.deleteLine()
    }

    /// Handles external file system modifications detected by FileWatcher.
    public func handleExternalFileChange() {
        guard displayConfig.autoReload, buffer.filePath != nil else { return }

        if buffer.isModified {
            currentPromptMode = .confirmExternalReload(completion: { [weak self] reload in
                guard let self = self else { return }
                if reload {
                    do {
                        try self.buffer.reloadFile()
                        self.buffer.isModified = false
                        self.setStatusMessage(L10n["status.file_reloaded"])
                    } catch {
                        self.setStatusMessage(error.localizedDescription)
                    }
                } else {
                    self.setStatusMessage(L10n["status.kept_local"])
                }
            })
            setStatusMessage(L10n["prompt.confirm_reload"])
        } else {
            do {
                try buffer.reloadFile()
                setStatusMessage(L10n["status.file_reloaded"])
            } catch {
                setStatusMessage(error.localizedDescription)
            }
        }
    }

    /// Applies custom user configuration loaded from ~/.serc or ./.serc files.
    func applyCustomConfig(_ config: EditorConfig) {
        let prelude = config.logoPrelude.trimmingCharacters(in: .whitespacesAndNewlines)
        if !prelude.isEmpty {
            logoEngine.execute(prelude)
        }

        for key in config.unbindKeys {
            commandRegistry.unbind(key: key)
        }

        for (key, cmdId) in config.customKeyBinds {
            if let script = resolveLogoScript(for: cmdId, using: config) {
                let customCmd = BlockCommand(
                    id: .customMacro, name: "Macro", description: "Custom LOGO macro", keys: [key]
                ) { editor in
                    editor.runLogoScript(script)
                }
                commandRegistry.bind(key: key, command: customCmd)
            } else if let targetId = CommandID(rawValue: cmdId) {
                if let cmd = commandRegistry.commands.first(where: { $0.id == targetId }) {
                    commandRegistry.bind(key: key, command: cmd)
                }
            }
        }

        if config.syntaxErrorCount > 0 {
            setStatusMessage(L10n.configLoadedWithErrors(config.syntaxErrorCount))
        }
    }

    private func resolveLogoScript(for cmdId: String, using config: EditorConfig) -> String? {
        let lowercased = cmdId.lowercased()
        let payload: String

        if lowercased.hasPrefix("macro:") {
            payload = String(cmdId.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if lowercased.hasPrefix("logo:") {
            payload = String(cmdId.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return nil
        }

        return config.logoScripts[payload] ?? payload
    }

    /// Starts the editor event loop.
    public func run() {
        terminal.enableRawMode()
        Terminal.hideCursor()

        defer {
            Terminal.clearScreen()
            Terminal.showCursor()
            terminal.disableRawMode()
        }

        while isRunning {
            refreshScreen()
            let key = terminal.readKey()
            processKey(key)
        }
    }

    /// Sets status message to display in the bottom status line.
    public func setStatusMessage(_ msg: String) {
        self.statusMessage = msg
        self.statusMessageTime = Date()
    }

    /// Returns ordered start and end coordinates for selection range.
    func getOrderedRange(mark1: (line: Int, column: Int), mark2: (line: Int, column: Int)) -> (
        start: (line: Int, column: Int), end: (line: Int, column: Int)
    ) {
        if mark1.line < mark2.line {
            return (start: mark1, end: mark2)
        } else if mark1.line > mark2.line {
            return (start: mark2, end: mark1)
        } else {
            if mark1.column <= mark2.column {
                return (start: mark1, end: mark2)
            } else {
                return (start: mark2, end: mark1)
            }
        }
    }

    /// Checks if a buffer character (line, col) is within the current selection mark range.
    func isCharacterSelected(line: Int, col: Int) -> Bool {
        guard let mark = selectionMark else { return false }
        let (start, end) = getOrderedRange(mark1: mark, mark2: (line: buffer.lineIndex, column: buffer.columnIndex))

        if line < start.line || line > end.line {
            return false
        }
        if line > start.line && line < end.line {
            return true
        }
        if start.line == end.line {
            return col >= start.column && col < end.column
        }
        if line == start.line {
            return col >= start.column
        }
        if line == end.line {
            return col < end.column
        }
        return false
    }
}
