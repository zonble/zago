import Foundation

/// Nano-style UI state machine and core editor engine.
public final class Editor {
    let terminal: Terminal
    public let buffer: TextBuffer
    public let layoutEngine: LayoutEngine

    var isRunning = true
    var statusMessage: String = ""
    var statusMessageTime: Date?

    var clipboardText: String? = nil
    var selectionMark: (line: Int, column: Int)? = nil

    // UI Viewport Scrolling Offset (measured in VirtualLineIndex units)
    var topVLineIndex: Int = 0

    let spellChecker = SpellChecker()

    // Prompt state
    var currentPromptMode: PromptMode = .none
    var promptInputText: String = ""
    var lastSearchQuery: String = ""

    var undoStack: [UndoSnapshot] = []
    let maxUndoStackSize = 100
    var lastMutationTime: Date?
    var lastIsPaste: Bool = false

    let syntaxHighlighter = SyntaxHighlighter()
    public let commandRegistry = CommandRegistry()
    public let fileWatcher = FileWatcher()

    public struct DisplayConfig: Sendable, Equatable {
        public var showRuler: Bool
        public var enableSyntaxHighlight: Bool
        public var autoReload: Bool

        public init(showRuler: Bool = false, enableSyntaxHighlight: Bool = true, autoReload: Bool = true) {
            self.showRuler = showRuler
            self.enableSyntaxHighlight = enableSyntaxHighlight
            self.autoReload = autoReload
        }
    }

    public var displayConfig: DisplayConfig

    public init(filePath: String? = nil, wrapColumn: Int? = nil, showRuler: Bool? = nil, enableSyntax: Bool? = nil, autoReload: Bool? = nil, language: Language? = nil) {
        self.terminal = Terminal()
        self.buffer = TextBuffer(filePath: filePath)

        let loadedConfig = ConfigLoader().loadConfig()

        // CLI argument priority > .serc config > default
        let finalWrap = wrapColumn ?? loadedConfig.wrapColumn
        let finalRuler = showRuler ?? loadedConfig.showRuler
        let finalSyntax = enableSyntax ?? loadedConfig.enableSyntaxHighlight
        let finalReload = autoReload ?? loadedConfig.autoReload
        let finalLang = language ?? loadedConfig.language ?? Language.detectSystemLanguage()

        L10n.currentLanguage = finalLang
        self.layoutEngine = LayoutEngine(wrapColumn: finalWrap)
        self.displayConfig = DisplayConfig(showRuler: finalRuler, enableSyntaxHighlight: finalSyntax, autoReload: finalReload)

        setupDefaultCommands()
        applyCustomConfig(loadedConfig)

        if let path = buffer.filePath {
            fileWatcher.start(path: path)
        }

        fileWatcher.onChange = { [weak self] in
            guard let self = self, self.displayConfig.autoReload else { return }
            self.handleExternalFileChange()
        }
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
    private func applyCustomConfig(_ config: EditorConfig) {
        for key in config.unbindKeys {
            commandRegistry.unbind(key: key)
        }

        for (key, cmdId) in config.customKeyBinds {
            if let cmd = commandRegistry.commands.first(where: { $0.id == cmdId }) {
                commandRegistry.bind(key: key, command: cmd)
            }
        }

        if config.syntaxErrorCount > 0 {
            setStatusMessage(L10n.configLoadedWithErrors(config.syntaxErrorCount))
        }
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
    func setStatusMessage(_ msg: String) {
        self.statusMessage = msg
        self.statusMessageTime = Date()
    }

    /// Returns ordered start and end coordinates for selection range.
    func getOrderedRange(mark1: (line: Int, column: Int), mark2: (line: Int, column: Int)) -> (start: (line: Int, column: Int), end: (line: Int, column: Int)) {
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
