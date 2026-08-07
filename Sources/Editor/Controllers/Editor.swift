@_exported import Config
@_exported import Drawing
import Foundation
import Git
import LogoEngine
import SpellChecker
import Syntax

public typealias SearchMatch = SearchController.SearchMatch

/// Nano-style UI state machine and core editor engine.
public final class Editor: @unchecked Sendable {
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
    public var canvasBlockClipboard: CanvasBlockClipboard? = nil

    // UI Viewport Scrolling Offset (measured in VirtualLineIndex units)
    var topVLineIndex: Int = 0

    let spellChecker = SpellChecker()

    public let gitService: GitServiceProtocol

    /// Git Diff & Repository context for current buffer
    public var gitDiffInfo: GitDiffInfo = .empty

    public var isGitDiffDirty: Bool = true

    public func markGitDiffDirty() {
        isGitDiffDirty = true
    }

    public func updateGitDiffIfNeeded() {
        guard isGitDiffDirty else { return }
        updateGitDiff()
    }

    public func updateGitDiff() {
        isGitDiffDirty = false
        guard displayConfig.showGitDiff else {
            gitDiffInfo = .empty
            return
        }
        gitDiffInfo = gitService.computeDiffSync(filePath: buffer.filePath, currentLines: buffer.lines)
    }

    /// Flag indicating whether the editor is running in interactive TUI mode.
    public internal(set) var isInteractiveMode: Bool = false

    // Persistent LOGO Macro Engine
    public lazy var logoEngine: LogoEngine = LogoEngine(delegate: self)

    // Prompt Controller
    public let promptController = PromptController()

    public var currentPromptMode: PromptMode {
        get { promptController.mode }
        set { promptController.mode = newValue }
    }
    public var promptInputText: String {
        get { promptController.inputText }
        set { promptController.inputText = newValue }
    }
    public var promptCursorIndex: Int {
        get { promptController.cursorIndex }
        set { promptController.cursorIndex = newValue }
    }
    public var promptCompletionText: String? {
        get { promptController.completionText }
        set { promptController.completionText = newValue }
    }
    public var logoPromptHistory: [String] {
        get { promptController.logoHistory }
        set { promptController.logoHistory = newValue }
    }
    public var logoHistoryIndex: Int {
        get { promptController.logoHistoryIndex }
        set { promptController.logoHistoryIndex = newValue }
    }

    // Search Controller
    public let searchController = SearchController()

    public var lastSearchQuery: String {
        get { searchController.lastSearchQuery }
        set { searchController.lastSearchQuery = newValue }
    }

    // Document Outline Controller
    public let documentOutlineController = DocumentOutlineController()

    // Mode & UI Controllers
    public let menuBarController = MenuBarController()
    public let tableModeController = TableModeController()
    public let canvasModeController = CanvasModeController()

    public var isMenuBarActive: Bool {
        get { menuBarController.isActive }
        set { menuBarController.isActive = newValue }
    }

    public var menuBar: MenuBar {
        menuBarController.menuBar
    }
    var defaultBaseMode: EditorBaseMode = .text
    var defaultViewShowRuler = false
    var defaultViewShowLineNumbers = true
    var defaultViewShowSubLineNumbers = false
    var defaultViewWrapColumn: Int? = nil

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
    public var defaultArrowStyle: ArrowStyle = .solid
    public var isRegexSearchEnabled: Bool = false

    var lastMutationTime: Date?
    var lastIsPaste: Bool = false

    let syntaxHighlighter = SyntaxHighlighter()

    /// Returns the language syntax for a specific buffer line index.
    public func syntaxForLine(at lineIndex: Int) -> LanguageSyntax? {
        syntaxHighlighter.getSyntaxForLine(
            filePath: buffer.filePath,
            isDirectoryBuffer: buffer.isDirectoryBuffer,
            lines: buffer.lines,
            bufferLineIndex: lineIndex,
            isEnabled: displayConfig.enableSyntaxHighlight
        )
    }

    public var activeLanguageSyntax: LanguageSyntax? {
        syntaxForLine(at: buffer.lineIndex)
    }

    public let commandRegistry = CommandRegistry()
    public var commandBarRegistry: CommandRegistry { commandRegistry }
    public var fileIOStrategy: EditorFileIOStrategy
    public var language: Language = .detectSystemLanguage()
    public var usesExplicitLanguage: Bool = false
    public var l10n: L10n { L10n(language: language) }
    private let configProvider: () -> EditorConfig
    var currentWatchedPath: String? = nil

    public typealias DisplayConfig = RuntimeConfig
    public var runtimeConfig: RuntimeConfig
    public var displayConfig: RuntimeConfig {
        get { runtimeConfig }
        set { runtimeConfig = newValue }
    }
    public var customBoundKeys: Set<Key> = []

    private struct ResolvedConfig {
        let wrapColumn: Int?
        let display: RuntimeConfig
        let language: Language
        let usesExplicitLanguage: Bool
        let spellLanguage: String
        let baseMode: EditorBaseMode
    }

    private static func resolveConfig(options: EditorOptions, config: EditorConfig) -> ResolvedConfig {
        let configuredLanguage = options.language ?? config.language
        let display = RuntimeConfig(
            showRuler: options.showRuler ?? config.showRuler,
            showLineNumbers: options.showLineNumbers ?? config.showLineNumbers,
            showSubLineNumbers: options.showSubLineNumbers ?? config.showSubLineNumbers,
            enableSyntaxHighlight: options.enableSyntax ?? config.enableSyntaxHighlight,
            autoReload: options.autoReload ?? config.autoReload,
            tabSize: config.tabSize,
            smartTab: config.smartTab,
            listIndentSize: config.listIndentSize,
            trimTrailingWhitespaceOnSave: config.trimTrailingWhitespaceOnSave,
            showGitDiff: config.showGitDiff
        )

        return ResolvedConfig(
            wrapColumn: options.wrapColumn ?? config.wrapColumn,
            display: display,
            language: configuredLanguage ?? Language.detectSystemLanguage(),
            usesExplicitLanguage: configuredLanguage != nil,
            spellLanguage: options.spellLanguage ?? config.spellLanguage,
            baseMode: config.startInCanvasMode ? .canvas : .text
        )
    }

    public init(
        options: EditorOptions = EditorOptions(),
        configSource: EditorConfigSource = EditorConfigSource(),
        dependencies: EditorDependencies
    ) {
        self.terminal = dependencies.terminal
        self.fileIOStrategy = dependencies.fileIOStrategy
        self.gitService = dependencies.gitService
        self.configProvider = configSource.reload

        if options.filePaths.isEmpty {
            self.buffers = [TextBuffer()]
        } else {
            self.buffers = options.filePaths.map {
                TextBuffer.makeBuffer(filePath: $0, fileIO: dependencies.fileIOStrategy)
            }
        }
        self.currentBufferIndex = 0

        let resolved = Self.resolveConfig(options: options, config: configSource.initial)
        self.language = resolved.language
        self.usesExplicitLanguage = resolved.usesExplicitLanguage
        self.spellChecker.setLanguage(resolved.spellLanguage)
        self.layoutEngine = LayoutEngine(wrapColumn: resolved.wrapColumn)
        self.runtimeConfig = resolved.display
        self.defaultBaseMode = resolved.baseMode
        self.defaultViewShowRuler = resolved.display.showRuler
        self.defaultViewShowLineNumbers = resolved.display.showLineNumbers
        self.defaultViewShowSubLineNumbers = resolved.display.showSubLineNumbers
        self.defaultViewWrapColumn = layoutEngine.wrapColumn
        for buffer in self.buffers {
            buffer.baseMode = buffer.isDirectoryBuffer ? .text : resolved.baseMode
            buffer.viewShowRuler = defaultViewShowRuler
            buffer.viewShowLineNumbers = defaultViewShowLineNumbers
            buffer.viewShowSubLineNumbers = defaultViewShowSubLineNumbers
            buffer.viewWrapColumn = defaultViewWrapColumn
            if let dirBuf = buffer as? DirectoryBuffer {
                dirBuf.loadDirectory(at: dirBuf.directoryPath, language: self.language)
            }
        }

        self.promptController.editor = self
        self.searchController.editor = self
        self.documentOutlineController.editor = self
        self.menuBarController.editor = self
        self.tableModeController.editor = self
        self.canvasModeController.editor = self

        setupDefaultCommands()
        if isCanvasModeActive {
            syncCanvasCursorFromBuffer()
        }
        applyCustomConfig(configSource.initial)

        startFileWatcherForCurrentBuffer()
    }

    deinit {
        stopFileWatcherForCurrentBuffer()
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
            _ = try? ConfigLoader.generateDefaultConfigFile(
                targetPath: zagorcPath, provider: StrategyConfigFileProvider(strategy: fileIOStrategy))
            configPath = zagorcPath
        }

        if let existingIndex = buffers.firstIndex(where: { $0.filePath == configPath }) {
            switchToBuffer(index: existingIndex)
        } else {
            openNewBuffer(filePath: configPath)
        }
        setStatusMessage(l10n.editingConfig(configPath))
    }

    /// Reloads configuration settings from ~/.serc or ./.serc files.
    public func reloadConfig() {
        let loadedConfig = configProvider()
        applyReloadedConfig(loadedConfig)
        setStatusMessage(l10n["status.config_reloaded"])
    }

    /// Applies reloadable configuration without changing per-editor runtime modes.
    func applyReloadedConfig(_ loadedConfig: EditorConfig) {
        let resolved = Self.resolveConfig(options: EditorOptions(), config: loadedConfig)
        self.defaultViewWrapColumn = LayoutEngine.normalizedWrapColumn(resolved.wrapColumn)
        self.defaultViewShowRuler = resolved.display.showRuler
        self.defaultViewShowLineNumbers = resolved.display.showLineNumbers
        self.defaultViewShowSubLineNumbers = resolved.display.showSubLineNumbers
        self.layoutEngine.setWrapColumn(defaultViewWrapColumn)
        self.displayConfig = resolved.display
        self.defaultBaseMode = resolved.baseMode
        saveCurrentViewSettingsToBuffer()
        if loadedConfig.language != nil {
            self.language = resolved.language
            self.usesExplicitLanguage = true
        }
        applyCustomConfig(loadedConfig)
    }

    /// Deletes current line with Undo snapshot tracking.
    public func deleteCurrentLine() {
        if isTableModeActive, currentTableCell != nil {
            tableModeController.deleteCurrentTableCellLine()
            return
        }
        buffer.deleteLine()
    }

    /// Applies custom user configuration loaded from ~/.serc or ./.serc files.
    func applyCustomConfig(_ config: EditorConfig) {
        customBoundKeys = Set(config.customKeyBinds.keys)
        defaultBorderStyle = config.defaultBorderStyle
        defaultArrowStyle = config.defaultArrowStyle
        spellChecker.setLanguage(config.spellLanguage)

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
            setStatusMessage(l10n.configLoadedWithErrors(config.syntaxErrorCount))
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
        isInteractiveMode = true
        defer {
            isInteractiveMode = false
            terminal.clearScreen()
            terminal.showCursor()
            terminal.disableRawMode()
        }

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

    public func clearActiveMark() {
        buffer.selectionMark = nil
        buffer.canvasBlockMark = nil
        buffer.canvasBlockMarkEnd = nil
        buffer.activeSearchMatch = nil
    }

    @discardableResult
    func deleteTextSelectionIfNeeded(updateClipboard: Bool, saveSnapshot: Bool = true) -> Bool {
        guard let mark = buffer.selectionMark else { return false }
        if isTableModeActive, let cell = currentTableCell {
            return tableModeController.deleteTableSelectionIfNeeded(cell: cell, updateClipboard: updateClipboard)
        }
        let cursor = (line: buffer.lineIndex, column: buffer.columnIndex)
        let (start, end) = TextBuffer.getOrderedRange(mark1: mark, mark2: cursor)
        guard start.line != end.line || start.column != end.column else {
            buffer.selectionMark = nil
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
        buffer.selectionMark = nil
        buffer.clampCursor()
        return true
    }
}
