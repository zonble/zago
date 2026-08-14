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
    let bufferCoordinator: BufferCoordinator

    var buffers: [TextBuffer] {
        get { bufferCoordinator.buffers }
        set { bufferCoordinator.buffers = newValue }
    }

    var currentBufferIndex: Int {
        get { bufferCoordinator.activeIndex }
        set { bufferCoordinator.activeIndex = newValue }
    }

    /// Active text buffer.
    var buffer: TextBuffer {
        get { bufferCoordinator.activeBuffer }
        set { bufferCoordinator.activeBuffer = newValue }
    }
    let layoutEngine: LayoutEngine
    let renderer = Renderer()

    var isRunning = true
    var statusMessage: String = ""
    var statusMessageTime: Date?

    var clipboardText: String? = nil
    var canvasBlockClipboard: CanvasBlockClipboard? = nil

    /// History log lines recorded by LOGO commands, stored internally until user opens *LOGO Output* buffer.
    var logoOutputHistory: [String] = []

    // UI Viewport Scrolling Offset (measured in VirtualLineIndex units)
    var topVLineIndex: Int = 0

    let spellChecker = SpellChecker()

    let gitService: GitServiceProtocol

    /// Git Diff & Repository context for current buffer
    var gitDiffInfo: GitDiffInfo = .empty

    var isGitDiffDirty: Bool = true

    func markGitDiffDirty() {
        isGitDiffDirty = true
    }

    func updateGitDiffIfNeeded() {
        guard isGitDiffDirty else { return }
        updateGitDiff()
    }

    func updateGitDiff() {
        isGitDiffDirty = false
        guard displayConfig.showGitDiff, !buffer.isScratchBuffer else {
            gitDiffInfo = .empty
            return
        }
        gitDiffInfo = gitService.computeDiffSync(filePath: buffer.filePath, currentLines: buffer.lines)
    }

    /// Flag indicating whether the editor is running in interactive TUI mode.
    var isInteractiveMode: Bool = false

    private var initialLogoVariable: [String: String]
    // Persistent LOGO Macro Engine
    lazy var logoEngine: LogoEngine = LogoEngine(
        delegate: self,
        initialVariables: initialLogoVariable
    )

    // Prompt Controller
    let promptController = PromptController()

    // Search Controller
    let searchController = SearchController()

    // Document Outline Controller
    let documentOutlineController = DocumentOutlineController()

    // Mode & UI Controllers
    let menuBarController = MenuBarController()
    let tableModeController = TableModeController()
    let canvasModeController = CanvasModeController()
    let debuggerController = DebuggerController()

    var defaultBaseMode: EditorBaseMode = .text
    var defaultViewShowRuler = false
    var defaultViewShowLineNumbers = true
    var defaultViewShowSubLineNumbers = false
    var defaultViewWrapColumn: Int? = nil

    var isRegexSearchEnabled: Bool = false

    var lastMutationTime: Date?
    var lastIsPaste: Bool = false

    let syntaxHighlighter = SyntaxHighlighter()

    /// Returns the language syntax for a specific buffer line index.
    func syntaxForLine(at lineIndex: Int) -> LanguageSyntax? {
        syntaxHighlighter.getSyntaxForLine(
            filePath: buffer.filePath,
            isDirectoryBuffer: buffer.isDirectoryBuffer,
            lines: buffer.lines,
            bufferLineIndex: lineIndex,
            isEnabled: displayConfig.enableSyntaxHighlight
        )
    }

    var activeLanguageSyntax: LanguageSyntax? {
        syntaxForLine(at: buffer.lineIndex)
    }

    let commandRegistry = CommandRegistry()
    var commandBarRegistry: CommandRegistry { commandRegistry }
    var fileIOStrategy: EditorFileIOStrategy
    var language: Language = .detectSystemLanguage()
    var usesExplicitLanguage: Bool = false
    var l10n: L10n { L10n(language: language) }
    private let configProvider: () -> EditorConfig
    var currentWatchedPath: String? = nil

    typealias DisplayConfig = RuntimeConfig
    var runtimeConfig: RuntimeConfig
    var displayConfig: RuntimeConfig {
        get { runtimeConfig }
        set { runtimeConfig = newValue }
    }
    var debugMode = false

    var isLogoUIEnabled: Bool {
        debugMode || buffer.filePath?.lowercased().hasSuffix(".logo") == true
    }
    var customBoundKeys: Set<Key> = []
    public weak var effectDelegate: (any EditorEffectDelegate)?
    let proposalQueue = ProposalQueue()
    private let editorLoopRequests = EditorLoopRequestQueue()
    private var editorLoopThread: Thread?

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
            listWrapIndent: config.listWrapIndent,
            trimTrailingWhitespaceOnSave: config.trimTrailingWhitespaceOnSave,
            showGitDiff: config.showGitDiff,
            ipcEnabled: options.ipcEnabled ?? config.ipcEnabled
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
        dependencies: EditorDependencies,
        initialVariables: [String: String]? = [:],
    ) {
        self.initialLogoVariable = initialVariables ?? [:]
        self.terminal = dependencies.terminal
        self.fileIOStrategy = dependencies.fileIOStrategy
        self.gitService = dependencies.gitService
        self.configProvider = configSource.reload

        let initialBuffers: [TextBuffer]
        if options.filePaths.isEmpty {
            initialBuffers = [TextBuffer()]
        } else {
            initialBuffers = options.filePaths.map {
                TextBuffer.makeBuffer(filePath: $0, fileIO: dependencies.fileIOStrategy)
            }
        }
        self.bufferCoordinator = BufferCoordinator(buffers: initialBuffers)

        let resolved = Self.resolveConfig(options: options, config: configSource.initial)
        self.language = resolved.language
        self.usesExplicitLanguage = resolved.usesExplicitLanguage
        self.spellChecker.setLanguage(resolved.spellLanguage)
        self.layoutEngine = LayoutEngine(wrapColumn: resolved.wrapColumn)
        self.runtimeConfig = resolved.display
        self.debugMode = configSource.initial.debugMode
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
            buffer.borderStyle = configSource.initial.defaultBorderStyle
            buffer.arrowStyle = configSource.initial.defaultArrowStyle
            buffer.onLineCountChanged = { [weak self] aboveLine, delta in
                self?.proposalQueue.adjustLineOffsets(aboveLine: aboveLine, delta: delta)
            }
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
        if let piped = options.pipedInput {
            buffer.lines = piped.components(separatedBy: .newlines)
            buffer.isModified = false
        }
        if options.readOnly == true {
            buffer.isReadOnly = true
        }
        if let loadError = buffer.loadErrorDescription {
            setStatusMessage(l10n.errorOpeningFile(error: loadError))
        }
        if let initLine = options.initialLine {
            goToLocation(line: initLine, column: options.initialColumn)
        }
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
    func editConfig() {
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
    func reloadConfig() {
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
        self.debugMode = loadedConfig.debugMode
        self.defaultBaseMode = resolved.baseMode
        saveCurrentViewSettingsToBuffer()
        if loadedConfig.language != nil {
            self.language = resolved.language
            self.usesExplicitLanguage = true
        }
        applyCustomConfig(loadedConfig)
    }

    /// Deletes current line with Undo snapshot tracking.
    func deleteCurrentLine() {
        if isTableModeActive, currentTableCell != nil {
            tableModeController.deleteCurrentTableCellLine()
            return
        }
        buffer.deleteLine()
    }

    /// Applies custom user configuration loaded from ~/.serc or ./.serc files.
    func applyCustomConfig(_ config: EditorConfig) {
        syntaxHighlighter.loadNanoRCContent(config.nanoRCContent)
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
        editorLoopThread = Thread.current
        defer {
            editorLoopThread = nil
            isInteractiveMode = false
            effectDelegate?.editor(self, didEmit: .ipcEnabled(false))
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

        if displayConfig.ipcEnabled {
            effectDelegate?.editor(self, didEmit: .ipcEnabled(true))
        }

        while isRunning {
            drainExternalRequests()
            refreshScreen()
            let key = terminal.readKey()
            drainExternalRequests()
            if key == .resize {
                renderer.invalidateScreenCache()
                terminal.clearScreen()
                continue
            }
            processKey(key)
        }
    }

    public func performOnEditorLoop<T>(timeout: TimeInterval = 0.5, _ operation: @escaping () -> T) throws -> T {
        if !isInteractiveMode || Thread.current === editorLoopThread {
            return operation()
        }

        let request = EditorLoopRequest(operation: operation)
        editorLoopRequests.enqueue {
            request.execute()
        }
        terminal.wakeup()
        return try request.wait(timeout: timeout)
    }

    func drainExternalRequests() {
        editorLoopRequests.drain()
    }

    /// Sets status message to display in the bottom status line.
    public func setStatusMessage(_ msg: String) {
        self.statusMessage = msg
        self.statusMessageTime = Date()
    }

    /// Returns the current buffer as plain text without exposing its mutable model.
    func currentBufferText() -> String {
        buffer.lines.joined(separator: "\n")
    }

    /// Returns headless LOGO output without exposing the mutable output history.
    public func headlessOutput() -> String {
        let output = logoOutputHistory.filter { line in
            !(line.hasPrefix("--- [") && line.contains("] Run: "))
        }
        return output.isEmpty ? currentBufferText() : output.joined(separator: "\n")
    }

    func clearActiveMark() {
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
