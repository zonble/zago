@_exported import Config
import Foundation
import LogoEngine
import Syntax

/// Nano-style UI state machine and core editor engine.
public final class Editor {
    let terminal: EditorTerminal
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
    public struct CanvasBlockClipboard: Sendable, Equatable {
        public let width: Int
        public let rows: [String]

        public init(width: Int, rows: [String]) {
            self.width = width
            self.rows = rows
        }
    }
    public var canvasBlockMark: (line: Int, visualColumn: Int)? = nil
    public var canvasBlockMarkEnd: (line: Int, visualColumn: Int)? = nil
    public var canvasBlockClipboard: CanvasBlockClipboard? = nil

    // UI Viewport Scrolling Offset (measured in VirtualLineIndex units)
    var topVLineIndex: Int = 0

    let spellChecker = SpellChecker()

    // Persistent LOGO Macro Engine
    public lazy var logoEngine: LogoEngine = LogoEngine(delegate: self)

    // Prompt state
    var currentPromptMode: PromptMode = .none
    var promptInputText: String = ""
    var promptCursorIndex: Int = 0
    var promptCompletionText: String? = nil
    var lastSearchQuery: String = ""
    struct SearchMatch: Sendable, Equatable {
        let query: String
        let line: Int
        let column: Int
        let length: Int
        let usesRegex: Bool

        init(query: String, line: Int, column: Int, length: Int, usesRegex: Bool) {
            self.query = query
            self.line = line
            self.column = column
            self.length = length
            self.usesRegex = usesRegex
        }
    }
    var activeSearchMatch: SearchMatch? = nil
    var logoPromptHistory: [String] = []
    var logoHistoryIndex: Int = 0

    // Menu Bar state
    public var isMenuBarActive: Bool = false
    public let menuBar = MenuBar()
    private var defaultBaseMode: EditorBaseMode = .text
    private var defaultViewShowRuler = false
    private var defaultViewShowLineNumbers = true
    private var defaultViewShowSubLineNumbers = false
    private var defaultViewWrapColumn: Int? = nil

    // Editor mode state
    public var baseMode: EditorBaseMode {
        get { buffer.baseMode }
        set { buffer.baseMode = newValue }
    }
    public var overlayMode: EditorOverlayMode {
        get { buffer.overlayMode }
        set { buffer.overlayMode = newValue }
    }
    public var canvasVisualColumn: Int {
        get { buffer.canvasVisualColumn }
        set { buffer.canvasVisualColumn = newValue }
    }
    public var canvasHorizontalOffset: Int {
        get { buffer.canvasHorizontalOffset }
        set { buffer.canvasHorizontalOffset = newValue }
    }

    // Table Mode state
    public var isTableModeActive: Bool {
        get { buffer.isTableModeActive }
        set { buffer.isTableModeActive = newValue }
    }
    public var currentTableCell: TableCell? {
        get { buffer.currentTableCell }
        set { buffer.currentTableCell = newValue }
    }
    public var defaultBorderStyle: BorderStyle = .single
    public var isRegexSearchEnabled: Bool = false

    var undoStack: [UndoSnapshot] = []
    let maxUndoStackSize = 100
    var lastMutationTime: Date?
    var lastIsPaste: Bool = false

    let syntaxHighlighter = SyntaxHighlighter()

    public var activeLanguageSyntax: LanguageSyntax? {
        syntaxHighlighter.getSyntaxForLine(
            filePath: buffer.filePath,
            isDirectoryBuffer: buffer.isDirectoryBuffer,
            lines: buffer.lines,
            bufferLineIndex: buffer.lineIndex,
            isEnabled: displayConfig.enableSyntaxHighlight
        )
    }

    public let commandRegistry = CommandRegistry()
    public var commandBarRegistry: CommandRegistry { commandRegistry }
    public let fileWatcher = FileWatcher()
    public var fileIOStrategy: EditorFileIOStrategy

    public struct DisplayConfig: Sendable, Equatable {
        public var showRuler: Bool
        public var showLineNumbers: Bool
        public var showSubLineNumbers: Bool
        public var enableSyntaxHighlight: Bool
        public var autoReload: Bool
        public var tabSize: Int
        public var trimTrailingWhitespaceOnSave: Bool

        public init(
            showRuler: Bool = false,
            showLineNumbers: Bool = true,
            showSubLineNumbers: Bool = false,
            enableSyntaxHighlight: Bool = true,
            autoReload: Bool = true,
            tabSize: Int = 4,
            trimTrailingWhitespaceOnSave: Bool = false
        ) {
            self.showRuler = showRuler
            self.showLineNumbers = showLineNumbers
            self.showSubLineNumbers = showSubLineNumbers
            self.enableSyntaxHighlight = enableSyntaxHighlight
            self.autoReload = autoReload
            self.tabSize = tabSize
            self.trimTrailingWhitespaceOnSave = trimTrailingWhitespaceOnSave
        }
    }

    public var displayConfig: DisplayConfig

    public init(
        filePaths: [String], wrapColumn: Int? = nil, showRuler: Bool? = nil, showLineNumbers: Bool? = nil,
        showSubLineNumbers: Bool? = nil, enableSyntax: Bool? = nil, autoReload: Bool? = nil, language: Language? = nil,
        fileIOStrategy: EditorFileIOStrategy,
        terminal: EditorTerminal
    ) {
        self.terminal = terminal
        self.fileIOStrategy = fileIOStrategy

        if filePaths.isEmpty {
            self.buffers = [TextBuffer()]
        } else {
            self.buffers = filePaths.map { TextBuffer.makeBuffer(filePath: $0, fileIO: fileIOStrategy) }
        }
        self.currentBufferIndex = 0

        let loadedConfig = ConfigLoader().loadConfig()

        // CLI argument priority > .zagorc config > default
        let finalWrap = wrapColumn ?? loadedConfig.wrapColumn
        let finalRuler = showRuler ?? loadedConfig.showRuler
        let finalLineNumbers = showLineNumbers ?? loadedConfig.showLineNumbers
        let finalSubLineNumbers = showSubLineNumbers ?? loadedConfig.showSubLineNumbers
        let finalSyntax = enableSyntax ?? loadedConfig.enableSyntaxHighlight
        let finalReload = autoReload ?? loadedConfig.autoReload
        let finalLang = language ?? loadedConfig.language ?? Language.detectSystemLanguage()
        let finalTabSize = loadedConfig.tabSize
        let finalTrimTrailingWhitespace = loadedConfig.trimTrailingWhitespaceOnSave
        let initialBaseMode: EditorBaseMode = loadedConfig.startInCanvasMode ? .canvas : .text

        L10n.currentLanguage = finalLang
        self.layoutEngine = LayoutEngine(wrapColumn: finalWrap)
        self.displayConfig = DisplayConfig(
            showRuler: finalRuler, showLineNumbers: finalLineNumbers, showSubLineNumbers: finalSubLineNumbers,
            enableSyntaxHighlight: finalSyntax,
            autoReload: finalReload, tabSize: finalTabSize,
            trimTrailingWhitespaceOnSave: finalTrimTrailingWhitespace)
        self.defaultBaseMode = initialBaseMode
        self.defaultViewShowRuler = finalRuler
        self.defaultViewShowLineNumbers = finalLineNumbers
        self.defaultViewShowSubLineNumbers = finalSubLineNumbers
        self.defaultViewWrapColumn = LayoutEngine.normalizedWrapColumn(finalWrap)
        for buffer in self.buffers {
            buffer.baseMode = buffer.isDirectoryBuffer ? .text : initialBaseMode
            buffer.viewShowRuler = defaultViewShowRuler
            buffer.viewShowLineNumbers = defaultViewShowLineNumbers
            buffer.viewShowSubLineNumbers = defaultViewShowSubLineNumbers
            buffer.viewWrapColumn = defaultViewWrapColumn
        }

        setupDefaultCommands()
        if isCanvasModeActive {
            syncCanvasCursorFromBuffer()
        }
        applyCustomConfig(loadedConfig)

        startFileWatcherForCurrentBuffer()

        fileWatcher.onChange = { [weak self] in
            guard let self = self, self.displayConfig.autoReload else { return }
            self.handleExternalFileChange()
        }
    }

    public convenience init(
        filePath: String? = nil, wrapColumn: Int? = nil, showRuler: Bool? = nil, showLineNumbers: Bool? = nil,
        showSubLineNumbers: Bool? = nil, enableSyntax: Bool? = nil, autoReload: Bool? = nil, language: Language? = nil,
        fileIOStrategy: EditorFileIOStrategy,
        terminal: EditorTerminal
    ) {
        let paths = filePath != nil ? [filePath!] : []
        self.init(
            filePaths: paths, wrapColumn: wrapColumn, showRuler: showRuler, showLineNumbers: showLineNumbers,
            showSubLineNumbers: showSubLineNumbers, enableSyntax: enableSyntax, autoReload: autoReload, language: language,
            fileIOStrategy: fileIOStrategy,
            terminal: terminal)
    }

    func startFileWatcherForCurrentBuffer() {
        if let path = buffer.filePath {
            fileWatcher.start(path: path)
        } else {
            fileWatcher.stop()
        }
    }

    func saveCurrentViewSettingsToBuffer() {
        guard !buffers.isEmpty, currentBufferIndex >= 0, currentBufferIndex < buffers.count else { return }
        let current = buffers[currentBufferIndex]
        current.viewShowRuler = displayConfig.showRuler
        current.viewShowLineNumbers = displayConfig.showLineNumbers
        current.viewShowSubLineNumbers = displayConfig.showSubLineNumbers
        current.viewWrapColumn = layoutEngine.wrapColumn
    }

    func loadCurrentViewSettingsFromBuffer() {
        guard !buffers.isEmpty, currentBufferIndex >= 0, currentBufferIndex < buffers.count else { return }
        let current = buffers[currentBufferIndex]
        displayConfig.showRuler = current.viewShowRuler
        displayConfig.showLineNumbers = current.viewShowLineNumbers
        displayConfig.showSubLineNumbers = current.viewShowSubLineNumbers
        layoutEngine.setWrapColumn(current.viewWrapColumn)
    }

    func switchToBuffer(index: Int) {
        guard index >= 0, index < buffers.count else { return }
        saveCurrentViewSettingsToBuffer()
        currentBufferIndex = index
        loadCurrentViewSettingsFromBuffer()
        topVLineIndex = 0
        clearActiveMark()
        startFileWatcherForCurrentBuffer()
    }

    /// Switches to next open buffer in sequence.
    public func nextBuffer() {
        guard buffers.count > 1 else { return }
        switchToBuffer(index: (currentBufferIndex + 1) % buffers.count)
    }

    /// Switches to previous open buffer in sequence.
    public func prevBuffer() {
        guard buffers.count > 1 else { return }
        switchToBuffer(index: (currentBufferIndex - 1 + buffers.count) % buffers.count)
    }

    /// Opens a new buffer for given file path or empty buffer.
    public func openNewBuffer(filePath: String? = nil) {
        saveCurrentViewSettingsToBuffer()
        let newBuf = TextBuffer.makeBuffer(filePath: filePath, fileIO: fileIOStrategy)
        newBuf.baseMode = newBuf.isDirectoryBuffer ? .text : defaultBaseMode
        newBuf.viewShowRuler = defaultViewShowRuler
        newBuf.viewShowLineNumbers = defaultViewShowLineNumbers
        newBuf.viewShowSubLineNumbers = defaultViewShowSubLineNumbers
        newBuf.viewWrapColumn = defaultViewWrapColumn
        buffers.append(newBuf)
        currentBufferIndex = buffers.count - 1
        loadCurrentViewSettingsFromBuffer()
        topVLineIndex = 0
        clearActiveMark()
        startFileWatcherForCurrentBuffer()
    }

    /// Opens ~/.zagorc in a buffer for editing. Creates ~/.zagorc with default template if it does not exist.
    public func editConfig() {
        let homeDir = fileIOStrategy.homeDirectoryPath()
        let zagorcPath = (homeDir as NSString).appendingPathComponent(".zagorc")
        let sercPath = (homeDir as NSString).appendingPathComponent(".serc")

        let configPath: String
        if fileIOStrategy.fileInfo(at: zagorcPath).exists {
            configPath = zagorcPath
        } else if fileIOStrategy.fileInfo(at: sercPath).exists {
            configPath = sercPath
        } else {
            _ = try? ConfigLoader.generateDefaultConfigFile(targetPath: zagorcPath)
            configPath = zagorcPath
        }

        if let existingIndex = buffers.firstIndex(where: { $0.filePath == configPath }) {
            switchToBuffer(index: existingIndex)
        } else {
            openNewBuffer(filePath: configPath)
        }
        setStatusMessage(L10n.editingConfig(configPath))
    }

    /// Reloads configuration settings from ~/.serc or ./.serc files.
    public func reloadConfig() {
        let loadedConfig = ConfigLoader().loadConfig()
        applyReloadedConfig(loadedConfig)
        setStatusMessage(L10n["status.config_reloaded"])
    }

    /// Applies reloadable configuration without changing per-editor runtime modes.
    func applyReloadedConfig(_ loadedConfig: EditorConfig) {
        self.defaultViewWrapColumn = LayoutEngine.normalizedWrapColumn(loadedConfig.wrapColumn)
        self.defaultViewShowRuler = loadedConfig.showRuler
        self.defaultViewShowLineNumbers = loadedConfig.showLineNumbers
        self.defaultViewShowSubLineNumbers = loadedConfig.showSubLineNumbers
        self.layoutEngine.setWrapColumn(defaultViewWrapColumn)
        self.displayConfig.showRuler = loadedConfig.showRuler
        self.displayConfig.showLineNumbers = loadedConfig.showLineNumbers
        self.displayConfig.showSubLineNumbers = loadedConfig.showSubLineNumbers
        self.displayConfig.enableSyntaxHighlight = loadedConfig.enableSyntaxHighlight
        self.displayConfig.autoReload = loadedConfig.autoReload
        self.displayConfig.tabSize = loadedConfig.tabSize
        self.displayConfig.trimTrailingWhitespaceOnSave = loadedConfig.trimTrailingWhitespaceOnSave
        self.defaultBaseMode = loadedConfig.startInCanvasMode ? .canvas : .text
        saveCurrentViewSettingsToBuffer()
        if let lang = loadedConfig.language {
            L10n.currentLanguage = lang
        }
        applyCustomConfig(loadedConfig)
    }

    /// Closes current active buffer. If no buffers remain, exits editor.
    public func closeCurrentBuffer() {
        guard !buffers.isEmpty else {
            isRunning = false
            return
        }

        saveCurrentViewSettingsToBuffer()
        buffers.remove(at: currentBufferIndex)
        if buffers.isEmpty {
            isRunning = false
        } else {
            currentBufferIndex = max(0, min(currentBufferIndex, buffers.count - 1))
            loadCurrentViewSettingsFromBuffer()
            topVLineIndex = 0
            clearActiveMark()
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
                        try self.buffer.reloadFile(fileIO: self.fileIOStrategy)
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
                try buffer.reloadFile(fileIO: fileIOStrategy)
                setStatusMessage(L10n["status.file_reloaded"])
            } catch {
                setStatusMessage(error.localizedDescription)
            }
        }
    }

    /// Applies custom user configuration loaded from ~/.serc or ./.serc files.
    func applyCustomConfig(_ config: EditorConfig) {
        defaultBorderStyle = config.defaultBorderStyle

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
        do {
            try terminal.enableRawMode()
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            if let data = (message + "\n").data(using: .utf8) {
                FileHandle.standardError.write(data)
            }
            return
        }
        terminal.hideCursor()

        defer {
            terminal.clearScreen()
            terminal.showCursor()
            terminal.disableRawMode()
        }

        while isRunning {
            refreshScreen()
            let key = terminal.readKey()
            if key == .resize {
                terminal.clearScreen()
                continue
            }
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

    /// Checks if a buffer character (line, col) is within the current linear selection range.
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

    func isLineSelected(line: Int) -> Bool {
        guard let mark = selectionMark else { return false }
        let (start, end) = getOrderedRange(mark1: mark, mark2: (line: buffer.lineIndex, column: buffer.columnIndex))
        if start.line == end.line {
            return line == start.line && start.column != end.column
        }
        return line >= start.line && line <= end.line
    }

    public func clearActiveMark() {
        selectionMark = nil
        canvasBlockMark = nil
        canvasBlockMarkEnd = nil
        activeSearchMatch = nil
    }

    @discardableResult
    func deleteTextSelectionIfNeeded(updateClipboard: Bool, saveSnapshot: Bool = true) -> Bool {
        guard let mark = selectionMark else { return false }
        let cursor = (line: buffer.lineIndex, column: buffer.columnIndex)
        let (start, end) = getOrderedRange(mark1: mark, mark2: cursor)
        guard start.line != end.line || start.column != end.column else {
            selectionMark = nil
            return false
        }

        if saveSnapshot {
            saveUndoSnapshot()
        }
        let cutText = buffer.cutRange(
            start: (line: start.line, col: start.column), end: (line: end.line, col: end.column))
        if updateClipboard {
            clipboardText = cutText
        }
        buffer.lineIndex = start.line
        buffer.columnIndex = start.column
        selectionMark = nil
        buffer.clampCursor()
        return true
    }
}
