@_exported import Config
@_exported import Drawing
import Foundation
import Git
import LogoEngine
import LogoLocalization
import SpellChecker
import Syntax

typealias SearchMatch = SearchController.SearchMatch

public typealias CanvasBlockClipboardType = CanvasBlockClipboard

extension Editor {
    public typealias CanvasBlockClipboard = CanvasBlockClipboardType
}

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

    let clipboardCoordinator: ClipboardCoordinator

    var clipboardText: String? {
        get { clipboardCoordinator.clipboardText }
        set { clipboardCoordinator.clipboardText = newValue }
    }
    var canvasBlockClipboard: CanvasBlockClipboard? {
        get { clipboardCoordinator.canvasBlockClipboard }
        set { clipboardCoordinator.canvasBlockClipboard = newValue }
    }

    /// History log lines recorded by LOGO commands, stored internally until user opens *LOGO Output* buffer.
    var logoOutputHistory: [String] = []

    let spellChecker = SpellChecker()

    let gitService: GitServiceProtocol
    let gitCoordinator: GitCoordinator

    /// Git Diff & Repository context for current buffer
    var gitDiffInfo: GitDiffInfo {
        get { gitCoordinator.currentDiffInfo }
        set { gitCoordinator.currentDiffInfo = newValue }
    }

    var isGitDiffDirty: Bool {
        get { gitCoordinator.isDirty }
        set { gitCoordinator.isDirty = newValue }
    }

    func markGitDiffDirty() {
        gitCoordinator.markDirty()
    }

    func updateGitDiffIfNeeded() {
        gitCoordinator.updateIfNeeded(
            filePath: buffer.filePath,
            currentLines: buffer.lines,
            showGitDiff: displayConfig.showGitDiff,
            isScratchBuffer: buffer.isScratchBuffer
        )
    }

    func updateGitDiff() {
        gitCoordinator.update(
            filePath: buffer.filePath,
            currentLines: buffer.lines,
            showGitDiff: displayConfig.showGitDiff,
            isScratchBuffer: buffer.isScratchBuffer
        )
    }

    /// Flag indicating whether the editor is running in interactive TUI mode.
    var isInteractiveMode: Bool = false

    private var initialLogoVariable: [String: String]
    // Persistent LOGO Macro Engine
    lazy var logoEngine: LogoEngine = LogoEngine(
        delegate: self,
        initialVariables: initialLogoVariable
    )

    let promptController = PromptController()
    let externalRequestService = ExternalRequestService()

    // Keymap Manager
    let keymapManager = KeymapManager()

    /// Active Editor Mode used for Layered Keymap resolution.
    var currentMode: EditorMode {
        if promptController.isActive {
            return .prompt
        }
        if menuBarController.isActive {
            return .menu
        }
        if isTableModeActive {
            return .table
        }
        if isCanvasModeActive {
            return .canvas
        }
        return .text
    }

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
    var defaultLineEnding: LineEnding = .lf
    var fillColumn: Int = 72

    public var launchToJournal: Bool = false
    public var journalFolder: String? = nil

    var isRegexSearchEnabled: Bool = false

    var lastMutationTime: Date? {
        get { clipboardCoordinator.lastMutationTime }
        set { clipboardCoordinator.lastMutationTime = newValue }
    }
    var lastIsPaste: Bool {
        get { clipboardCoordinator.lastIsPaste }
        set { clipboardCoordinator.lastIsPaste = newValue }
    }

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
    let fileWatcherCoordinator: FileWatcherCoordinator
    var language: Language = .detectSystemLanguage()
    var usesExplicitLanguage: Bool = false
    var l10n: L10n { L10n(language: language) }
    private let configProvider: () -> EditorConfig
    var currentWatchedPath: String? {
        fileWatcherCoordinator.currentWatchedPath
    }

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
    var maxFileSizeBytes: Int64 = 50 * 1024 * 1024
    var largeFileThresholdBytes: Int64 = 5 * 1024 * 1024
    var backup: Bool = false
    var backupDir: String? = nil
    var customBoundKeys: Set<Key> = []
    public weak var effectDelegate: (any EditorEffectDelegate)?
    let proposalQueue = ProposalQueue()
    public let historyStore: any AIHistoryStoring
    private let editorLoopRequests = EditorLoopRequestQueue()
    #if !os(WASI)
        private var editorLoopThread: Thread?
    #endif

    public struct BoundaryDragScrollState: Equatable, Sendable {
        public var lastEvent: MouseEvent
        public var intervalMs: Int

        public init(lastEvent: MouseEvent, intervalMs: Int) {
            self.lastEvent = lastEvent
            self.intervalMs = intervalMs
        }
    }

    public var activeBoundaryDragState: BoundaryDragScrollState?

    /// Executes one continuous auto-scroll step when holding the mouse at or beyond boundaries.
    public func performBoundaryDragAutoScrollTick() {
        guard let state = activeBoundaryDragState else { return }
        handleMouseEvent(state.lastEvent)
    }

    private struct ResolvedConfig {
        let wrapColumn: Int?
        let display: RuntimeConfig
        let language: Language
        let usesExplicitLanguage: Bool
        let spellLanguage: String
        let baseMode: EditorBaseMode
        let backup: Bool
        let backupDir: String?
        let launchToJournal: Bool
        let journalFolder: String?
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
            noNewlines: config.noNewlines,
            showGitDiff: config.showGitDiff,
            ipcEnabled: options.ipcEnabled ?? config.ipcEnabled,
            enableMouse: options.enableMouse ?? config.enableMouse
        )

        return ResolvedConfig(
            wrapColumn: options.wrapColumn ?? config.wrapColumn,
            display: display,
            language: configuredLanguage ?? Language.detectSystemLanguage(),
            usesExplicitLanguage: configuredLanguage != nil,
            spellLanguage: options.spellLanguage ?? config.spellLanguage,
            baseMode: config.startInCanvasMode ? .canvas : .text,
            backup: options.backup ?? config.backup,
            backupDir: options.backupDir ?? config.backupDir,
            launchToJournal: options.launchToJournal ?? config.launchToJournal,
            journalFolder: options.journalFolder ?? config.journalFolder
        )
    }

    public init(
        options: EditorOptions = EditorOptions(),
        configSource: EditorConfigSource = EditorConfigSource(),
        dependencies: EditorDependencies,
        initialVariables: [String: String]? = [:]
    ) {
        self.initialLogoVariable = initialVariables ?? [:]
        self.terminal = dependencies.terminal
        self.fileIOStrategy = dependencies.fileIOStrategy
        self.fileWatcherCoordinator = FileWatcherCoordinator(fileIOStrategy: dependencies.fileIOStrategy)
        self.gitService = dependencies.gitService
        self.gitCoordinator = GitCoordinator(gitService: dependencies.gitService)
        self.historyStore = dependencies.historyStore
        self.clipboardCoordinator = ClipboardCoordinator(strategy: dependencies.clipboardStrategy)
        self.configProvider = configSource.reload

        let resolved = Self.resolveConfig(options: options, config: configSource.initial)

        let initialBuffers: [TextBuffer]
        let shouldLaunchJournal = options.filePaths.isEmpty && resolved.launchToJournal && options.pipedInput == nil
        if shouldLaunchJournal {
            let journalPath = Self.resolveTodayJournalPath(
                configuredFolder: resolved.journalFolder,
                fileIO: dependencies.fileIOStrategy
            )
            let journalBuffer = Self.makeBuffer(
                filePath: journalPath,
                fileIO: dependencies.fileIOStrategy,
                gitService: dependencies.gitService,
                language: options.language ?? configSource.initial.language ?? .detectSystemLanguage()
            )
            Self.populateNewJournalBufferIfNeeded(journalBuffer, fileIO: dependencies.fileIOStrategy)
            initialBuffers = [journalBuffer]
        } else if options.filePaths.isEmpty {
            initialBuffers = [TextBuffer()]
        } else {
            initialBuffers = options.filePaths.map {
                Self.makeBuffer(
                    filePath: $0,
                    fileIO: dependencies.fileIOStrategy,
                    gitService: dependencies.gitService,
                    language: options.language ?? configSource.initial.language ?? .detectSystemLanguage()
                )
            }
        }
        self.bufferCoordinator = BufferCoordinator(buffers: initialBuffers)

        self.language = resolved.language
        self.usesExplicitLanguage = resolved.usesExplicitLanguage
        self.spellChecker.setLanguage(resolved.spellLanguage)
        self.layoutEngine = LayoutEngine(wrapColumn: resolved.wrapColumn)
        self.runtimeConfig = resolved.display
        self.debugMode = configSource.initial.debugMode
        self.defaultBaseMode = resolved.baseMode
        self.backup = resolved.backup
        self.backupDir = resolved.backupDir
        self.launchToJournal = resolved.launchToJournal
        self.journalFolder = resolved.journalFolder
        self.defaultViewShowRuler = resolved.display.showRuler
        self.defaultViewShowLineNumbers = resolved.display.showLineNumbers
        self.defaultViewShowSubLineNumbers = resolved.display.showSubLineNumbers
        self.defaultViewWrapColumn = layoutEngine.wrapColumn
        self.defaultLineEnding = options.defaultLineEnding ?? .lf
        self.fillColumn = options.fillColumn ?? configSource.initial.fillColumn
        for buffer in self.buffers {
            buffer.lineEnding = defaultLineEnding
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
            } else if let path = buffer.filePath {
                _ = loadFileContent(into: buffer, path: path, reportStatus: false)
                if shouldLaunchJournal && path == Self.resolveTodayJournalPath(configuredFolder: resolved.journalFolder, fileIO: dependencies.fileIOStrategy) {
                    Self.populateNewJournalBufferIfNeeded(buffer, fileIO: dependencies.fileIOStrategy)
                }
            }
        }
        loadCurrentViewSettingsFromBuffer()

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
            reportOperationResult(.failed(loadError, message: l10n.errorOpeningFile(error: loadError)))
        }
        if let initLine = options.initialLine {
            goToLocation(line: initLine, column: options.initialColumn)
        }
        if isCanvasModeActive {
            syncCanvasCursorFromBuffer()
        }
        applyCustomConfig(configSource.initial)
        if let explicitPreset = options.keymapPreset {
            keymapManager.loadPreset(explicitPreset)
        }

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
        reportOperationResult(.succeeded(message: l10n.editingConfig(configPath)))
    }

    /// Reloads configuration settings from ~/.serc or ./.serc files.
    func reloadConfig() {
        let loadedConfig = configProvider()
        applyReloadedConfig(loadedConfig)
        reportOperationResult(.succeeded(message: l10n["status.config_reloaded"]))
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
        self.fillColumn = loadedConfig.fillColumn
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
        syntaxHighlighter.maxLineHighlightLength = config.maxLineHighlightLength
        maxFileSizeBytes = config.maxFileSizeBytes
        largeFileThresholdBytes = config.largeFileThresholdBytes
        backup = config.backup
        backupDir = config.backupDir
        launchToJournal = config.launchToJournal
        journalFolder = config.journalFolder
        customBoundKeys = Set(config.customKeyBinds.keys)
        defaultBorderStyle = config.defaultBorderStyle
        defaultArrowStyle = config.defaultArrowStyle
        spellChecker.setLanguage(config.spellLanguage)

        for dialectId in config.loadedDialects {
            if let dialect = LogoLocalizationRegistry.dialect(for: dialectId) {
                logoEngine.register(plugin: dialect)
            }
        }
        if language == .zh_TW && !logoEngine.pluginRegistry.contains(id: "zh-TW") {
            logoEngine.register(plugin: LogoTraditionalChinesePlugin())
        }
        syntaxHighlighter.updateLogoDialects(logoEngine.pluginRegistry.registeredPlugins)

        let prelude = config.logoPrelude.trimmingCharacters(in: .whitespacesAndNewlines)
        if !prelude.isEmpty {
            logoEngine.execute(prelude)
        }

        if let preset = KeymapPreset(rawValue: config.keymapPreset.lowercased()) {
            keymapManager.loadPreset(preset)
        }

        for key in config.unbindKeys {
            commandRegistry.unbind(key: key)
            keymapManager.unbind(key: key)
        }

        for (key, cmdId) in config.customKeyBinds {
            if let script = resolveLogoScript(for: cmdId, using: config) {
                let scriptLabel =
                    cmdId.hasPrefix("logo:")
                    ? String(cmdId.dropFirst(5)) : (cmdId.hasPrefix("macro:") ? String(cmdId.dropFirst(6)) : cmdId)
                let customCmd = BlockCommand(
                    id: .customMacro, name: "Macro", description: "Execute LOGO script '\(scriptLabel)'"
                ) { editor in
                    editor.runLogoScript(script)
                }
                commandRegistry.bind(key: key, command: customCmd)
                keymapManager.bind(key: key, commandID: .customMacro)
            } else if let targetId = CommandID(rawValue: cmdId) {
                if let cmd = commandRegistry.commands.first(where: { $0.id == targetId }) {
                    commandRegistry.bind(key: key, command: cmd)
                    keymapManager.bind(key: key, commandID: targetId)
                }
            }
        }

        for (modeStr, binds) in config.customModeKeyBinds {
            guard let mode = EditorMode(rawValue: modeStr.lowercased()) else { continue }
            for (key, cmdId) in binds {
                if let targetId = CommandID(rawValue: cmdId) {
                    keymapManager.bind(key: key, commandID: targetId, mode: mode)
                }
            }
        }

        if config.syntaxErrorCount > 0 {
            reportOperationResult(
                .failed("Config syntax errors", message: l10n.configLoadedWithErrors(config.syntaxErrorCount)))
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
        #if !os(WASI)
            editorLoopThread = Thread.current
            defer {
                editorLoopThread = nil
                isInteractiveMode = false
                effectDelegate?.editor(self, didEmit: .ipcEnabled(false))
                terminal.setMouseTracking(enabled: false)
                terminal.clearScreen()
                terminal.showCursor()
                terminal.disableRawMode()
            }
        #else
            defer {
                isInteractiveMode = false
                effectDelegate?.editor(self, didEmit: .ipcEnabled(false))
                terminal.setMouseTracking(enabled: false)
                terminal.clearScreen()
                terminal.showCursor()
                terminal.disableRawMode()
            }
        #endif

        do {
            try terminal.enableRawMode()
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            if let data = (message + "\n").data(using: .utf8) {
                FileHandle.standardError.write(data)
            }
            return
        }

        if displayConfig.enableMouse {
            terminal.setMouseTracking(enabled: true)
        }

        if displayConfig.ipcEnabled {
            effectDelegate?.editor(self, didEmit: .ipcEnabled(true))
        }

        while isRunning {
            drainExternalRequests()
            refreshScreen()
            let timeout = activeBoundaryDragState?.intervalMs
            let inputEvent = terminal.readInputEvent(timeoutMs: timeout)
            drainExternalRequests()

            guard let event = inputEvent else {
                performBoundaryDragAutoScrollTick()
                continue
            }

            // Event coalescing for mouse drag: if additional mouse drag events are queued in the terminal input stream,
            // process them in memory and coalesce to the latest position before triggering a full screen redraw.
            if case .mouse(let mouseEvent) = event, case .drag = mouseEvent.action {
                handleMouseEvent(mouseEvent)
                while terminal.hasPendingInput() {
                    let nextEvent = terminal.readInputEvent()
                    if case .mouse(let nextMouse) = nextEvent, case .drag = nextMouse.action {
                        handleMouseEvent(nextMouse)
                    } else {
                        switch nextEvent {
                        case .key(let key):
                            activeBoundaryDragState = nil
                            if key == .resize {
                                renderer.invalidateScreenCache()
                                terminal.clearScreen()
                            } else {
                                processKey(key)
                            }
                        case .mouse(let m):
                            handleMouseEvent(m)
                        case .openFile(let path):
                            activeBoundaryDragState = nil
                            if let existingIndex = buffers.firstIndex(where: { $0.filePath == path }) {
                                switchToBuffer(index: existingIndex)
                            } else {
                                openNewBuffer(filePath: path)
                            }
                            renderer.invalidateScreenCache()
                        }
                        break
                    }
                }
                continue
            }

            switch event {
            case .key(let key):
                activeBoundaryDragState = nil
                if key == .resize {
                    renderer.invalidateScreenCache()
                    terminal.clearScreen()
                    continue
                }
                processKey(key)
            case .mouse(let mouseEvent):
                handleMouseEvent(mouseEvent)
            case .openFile(let path):
                activeBoundaryDragState = nil
                if let existingIndex = buffers.firstIndex(where: { $0.filePath == path }) {
                    switchToBuffer(index: existingIndex)
                } else {
                    openNewBuffer(filePath: path)
                }
                renderer.invalidateScreenCache()
            }
        }
    }

    public func performOnEditorLoop<T>(timeout: TimeInterval = 0.5, _ operation: @escaping () -> T) throws -> T {
        #if os(WASI)
            return operation()
        #else
            if !isInteractiveMode || Thread.current === editorLoopThread {
                return operation()
            }

            let request = EditorLoopRequest(operation: operation)
            editorLoopRequests.enqueue {
                request.execute()
            }
            terminal.wakeup()
            return try request.wait(timeout: timeout)
        #endif
    }

    func drainExternalRequests() {
        editorLoopRequests.drain()
    }

    /// Sets status message to display in the bottom status line.
    public func setStatusMessage(_ msg: String) {
        self.statusMessage = msg
        self.statusMessageTime = Date()
    }

    func applyOperationResult(_ result: EditorOperationResult) {
        if let message = result.statusMessage {
            setStatusMessage(message)
        }
    }

    @discardableResult
    func reportOperationResult(_ result: EditorOperationResult) -> EditorOperationResult {
        applyOperationResult(result)
        return result
    }

    /// Returns the current buffer as plain text without exposing its mutable model.
    func currentBufferText() -> String {
        buffer.lines.joined(separator: "\n")
    }

    /// Returns headless LOGO output directly from current buffer text.
    public func headlessOutput() -> String {
        currentBufferText()
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
