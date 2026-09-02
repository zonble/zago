import Foundation

enum CommandBarDispatchResult: Sendable, Equatable {
    case handled
    case noMatch
}

struct CommandBarInput: Sendable, Equatable {
    let raw: String
    let text: String
    let tokens: [String]
    let firstToken: String?
    let rest: String

    init(_ raw: String) {
        self.raw = raw
        self.text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tokens = text.split(whereSeparator: \.isWhitespace).map(String.init)
        let parts = text.split(maxSplits: 1, whereSeparator: \.isWhitespace)
        self.firstToken = parts.first.map(String.init)
        self.rest = parts.count > 1 ? String(parts[1]) : ""
    }

    var lowerFirstToken: String? {
        firstToken?.lowercased()
    }

    var firstTokenIsAllUppercaseWord: Bool {
        guard let firstToken else { return false }
        return firstToken != firstToken.lowercased() && firstToken == firstToken.uppercased()
    }
}

/// Type-safe string enum defining all standard editor command identifiers.
enum CommandID: String, CaseIterable, Sendable, Hashable {
    // Navigation
    case moveRight = "move.right"
    case moveLeft = "move.left"
    case moveUp = "move.up"
    case moveDown = "move.down"
    case moveHome = "move.home"
    case moveEnd = "move.end"
    case movePgdn = "move.pgdn"
    case movePgup = "move.pgup"
    case moveWordForward = "move.word_forward"
    case moveWordBackward = "move.word_backward"

    // Selection
    case selectAll = "select.all"
    case selectLeft = "select.left"
    case selectRight = "select.right"
    case selectUp = "select.up"
    case selectDown = "select.down"
    case selectHome = "select.home"
    case selectEnd = "select.end"
    case selectPgup = "select.pgup"
    case selectPgdn = "select.pgdn"
    case selectWordForward = "select.word_forward"
    case selectWordBackward = "select.word_backward"

    // Editing
    case editDeleteLine = "edit.delete_line"
    case editDelete = "edit.delete"
    case editMark = "edit.mark"
    case editCopy = "edit.copy"
    case editCut = "edit.cut"
    case editUncut = "edit.uncut"
    case editCancelSelection = "edit.cancel_selection"
    case editTab = "edit.tab"
    case editBacktab = "edit.backtab"
    case editUndo = "edit.undo"
    case editRedo = "edit.redo"
    case editJustify = "edit.justify"
    case editSpell = "edit.spell"
    case editEvalLogo = "edit.eval_logo"
    case editToggleComment = "edit.toggle_comment"
    case editJoinLine = "edit.join_line"
    case editSplitLine = "edit.split_line"

    // Search & Cursor
    case searchWhereIs = "search.whereis"
    case searchReplace = "search.replace"
    case searchNext = "search.next"
    case searchPrevious = "search.previous"
    case searchSubstitute = "search.substitute"
    case documentOpenLink = "document.open_link"
    case documentHeadingNext = "document.heading_next"
    case documentHeadingPrevious = "document.heading_previous"
    case documentOutline = "document.outline"
    case cursorGotoLine = "cursor.goto_line"
    case cursorGotoEOF = "cursor.goto_eof"
    case screenRefresh = "screen.refresh"
    case cursorPos = "cursor.pos"

    // Buffer Operations
    case bufferPrev = "buffer.prev"
    case bufferNext = "buffer.next"
    case bufferNew = "buffer.new"

    // File Operations
    case fileOpen = "file.open"
    case fileSave = "file.save"
    case fileWriteOut = "file.write_out"
    case fileInsert = "file.insert"
    case fileDirectory = "file.directory"
    case fileSaveExit = "file.save_exit"
    case fileExit = "file.exit"
    case fileEditConfig = "file.edit_config"
    case fileReloadConfig = "file.reload_config"
    case fileRunLogo = "file.run_logo"
    case openJournal = "tools.journal"

    // Table Mode Operations
    case tableNextCell = "table.next_cell"
    case tablePrevCell = "table.prev_cell"
    case tableAdjustWidthInc = "table.adjust_width_inc"
    case tableAdjustWidthDec = "table.adjust_width_dec"
    case tableAdjustHeightInc = "table.adjust_height_inc"
    case tableAdjustHeightDec = "table.adjust_height_dec"
    case tableCenterText = "table.center_text"
    case tableCellStart = "table.cell_start"
    case tableCellEnd = "table.cell_end"
    case tableClearCell = "table.clear_cell"

    // Canvas Mode Operations
    case canvasDrawLine = "canvas.draw_line"
    case canvasDrawArrow = "canvas.draw_arrow"
    case canvasBlockMark = "canvas.block_mark"
    case canvasCutBlock = "canvas.cut_block"
    case canvasCopyBlock = "canvas.copy_block"
    case canvasPasteBlock = "canvas.paste_block"

    // Prompt Mode Operations
    case promptConfirm = "prompt.confirm"
    case promptCancel = "prompt.cancel"
    case promptComplete = "prompt.complete"
    case promptHistoryPrev = "prompt.history_prev"
    case promptHistoryNext = "prompt.history_next"
    case promptClearLine = "prompt.clear_line"

    // Macro & UI
    case macroLogo = "macro.logo"
    case logoReference = "logo.reference"
    case styleDSLReference = "style.dsl.reference"
    case logoWorkspace = "logo.workspace"
    case logoOutput = "logo.output"
    case logoClearOutput = "logo.clear_output"
    case logoCanvas = "logo.canvas"
    case logoDebug = "logo.debug"
    case menuShow = "menu.show"
    case helpShow = "help.show"
    case helpDescribeKey = "help.describe_key"
    case helpDescribeCommand = "help.describe_command"
    case textMode = "mode.text"
    case canvasToggle = "mode.canvas.toggle"
    case tableToggle = "table.toggle"
    case zeroToggle = "view.zero.toggle"
    case indicatorToggle = "view.indicator.toggle"
    case borderStyle = "border.style"
    case diagramInsert = "diagram.insert"
    case diagramMenu = "diagram.menu"
    case symbolPicker = "symbol.picker"

    // Test & Custom
    case testCmd = "test.cmd"
    case customMacro = "custom.macro"

    // AI Proposal
    case proposalAccept = "proposal.accept"
    case proposalReject = "proposal.reject"
    case proposalNext = "proposal.next"
    case proposalPrev = "proposal.prev"
    case proposalMockAI = "proposal.mockAI"
}

/// Unified protocol defining an editor command with metadata, keybindings, CommandBar aliases, and execution logic.
protocol Command {
    /// Unique command identifier for menu binding and command dispatch.
    var id: CommandID { get }

    /// Human-readable localized title of the command.
    var name: String { get }

    /// Human-readable description of what this command accomplishes.
    var description: String { get }

    /// Localization string key for the command description.
    var descriptionKey: String { get }

    /// CommandBar command aliases (e.g. `["write", "w", "save"]`).
    var commandBarAliases: [String] { get }

    /// Auto-completion candidate names displayed when typing in the CommandBar.
    var completionNames: [String] { get }

    /// Evaluates whether the command can be executed in the current editor state.
    func isAvailable(in editor: Editor) -> Bool

    /// Checks if typed CommandBar input matches this command.
    func match(_ input: CommandBarInput) -> Bool

    /// Executes command logic directly on the editor instance.
    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult

    /// Executes command logic with CommandBar arguments, returning typed operation status.
    @discardableResult
    func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult
}

extension Command {
    var descriptionKey: String {
        "command.\(id.rawValue).description"
    }
    var commandBarAliases: [String] { [] }
    var completionNames: [String] { commandBarAliases }

    func isAvailable(in editor: Editor) -> Bool { true }

    func match(_ input: CommandBarInput) -> Bool {
        guard let first = input.lowerFirstToken else { return false }
        return commandBarAliases.contains(first)
    }

    @discardableResult
    func execute(with input: CommandBarInput, on editor: Editor) -> EditorOperationResult {
        execute(on: editor)
    }
}

/// Generic block-based command conforming to `Command` protocol.
struct BlockCommand: Command {
    let id: CommandID
    let name: String
    let description: String
    let descriptionKey: String
    let commandBarAliases: [String]
    private let closure: (Editor) -> Void

    init(
        id: CommandID,
        name: String,
        description: String,
        descriptionKey: String? = nil,
        commandBarAliases: [String] = [],
        action: @escaping (Editor) -> Void
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.descriptionKey = descriptionKey ?? "command.\(id.rawValue).description"
        self.commandBarAliases = commandBarAliases
        self.closure = action
    }

    func execute(on editor: Editor) -> EditorOperationResult {
        closure(editor)
        return .succeeded
    }
}

/// Unified registry managing editor commands and CommandBar prompt dispatch.
final class CommandRegistry {
    private var customKeyMap: [Key: any Command] = [:]
    private var commandMap: [CommandID: any Command] = [:]
    private(set) var commands: [any Command] = []

    init() {}

    /// Registers a command conforming to `Command` protocol.
    func register(_ command: any Command) {
        commands.append(command)
        commandMap[command.id] = command
    }

    /// Binds a specific key to a command.
    func bind(key: Key, command: any Command) {
        customKeyMap[key] = command
    }

    /// Unbinds a specific key mapping.
    func unbind(key: Key) {
        customKeyMap.removeValue(forKey: key)
    }

    /// Returns custom command bound to key if any.
    func customCommand(for key: Key) -> Command? {
        customKeyMap[key]
    }

    /// Dispatches a command by its type-safe `CommandID`.
    /// Returns `true` if a command was found and executed.
    func dispatch(id: CommandID, editor: Editor) -> Bool {
        if let command = commandMap[id] {
            editor.applyOperationResult(command.execute(on: editor))
            return true
        }
        return false
    }

    /// Dispatches a command by ID and returns a typed command result.
    func dispatchResult(id: CommandID, editor: Editor) -> EditorOperationResult {
        guard let command = commandMap[id] else { return .failed("Command not found") }
        let result = command.execute(on: editor)
        editor.applyOperationResult(result)
        return result
    }

    /// Dispatches a command by raw ID string (for string/config compatibility).
    func dispatch(idString: String, editor: Editor) -> Bool {
        guard let id = CommandID(rawValue: idString) else { return false }
        return dispatch(id: id, editor: editor)
    }

    /// Dispatches a raw ID string and returns a typed command result.
    func dispatchResult(idString: String, editor: Editor) -> EditorOperationResult {
        guard let id = CommandID(rawValue: idString) else { return .failed("Command not found") }
        return dispatchResult(id: id, editor: editor)
    }

    /// Dispatches a key input to its registered command action.
    /// Returns `true` if a command was found and executed.
    func dispatch(key: Key, editor: Editor) -> Bool {
        if editor.isTableModeActive && editor.customBoundKeys.contains(key) {
            return false
        }
        if let command = customKeyMap[key], command.id == .customMacro {
            editor.applyOperationResult(command.execute(on: editor))
            return true
        }
        if let commandID = editor.keymapManager.resolve(key: key, in: editor.currentMode) {
            if dispatch(id: commandID, editor: editor) {
                return true
            }
        }
        if let command = customKeyMap[key] {
            editor.applyOperationResult(command.execute(on: editor))
            return true
        }
        return false
    }

    /// Dispatches a key input and returns a typed command result.
    func dispatchResult(key: Key, editor: Editor) -> EditorOperationResult {
        if editor.isTableModeActive && editor.customBoundKeys.contains(key) {
            return .noOp
        }
        if let command = customKeyMap[key], command.id == .customMacro {
            let result = command.execute(on: editor)
            editor.applyOperationResult(result)
            return result
        }
        if let commandID = editor.keymapManager.resolve(key: key, in: editor.currentMode) {
            let result = dispatchResult(id: commandID, editor: editor)
            if !result.isFailed {
                return result
            }
        }
        if let command = customKeyMap[key] {
            let result = command.execute(on: editor)
            editor.applyOperationResult(result)
            return result
        }
        return .noOp
    }

    /// Dispatches raw string input from CommandBar to matching registered command.
    func dispatch(_ rawInput: String, editor: Editor) -> CommandBarDispatchResult {
        let input = CommandBarInput(rawInput)
        guard !input.text.isEmpty else { return .handled }

        for command in commands where command.match(input) {
            guard command.isAvailable(in: editor) else {
                if command.id == .logoDebug { return .noMatch }
                editor.reportOperationResult(
                    .failed(
                        editor.l10n["status.directory_buffer_readonly"],
                        message: editor.l10n["status.directory_buffer_readonly"]))
                return .handled
            }
            editor.applyOperationResult(command.execute(with: input, on: editor))
            return .handled
        }

        guard editor.buffer.allowsLogoExecution else {
            editor.reportOperationResult(
                .failed(
                    editor.l10n["status.directory_buffer_readonly"],
                    message: editor.l10n["status.directory_buffer_readonly"]))
            return .handled
        }

        return .noMatch
    }

    /// Dispatches raw string input from CommandBar and returns typed operation status.
    func dispatchResult(_ rawInput: String, editor: Editor) -> EditorOperationResult {
        let input = CommandBarInput(rawInput)
        guard !input.text.isEmpty else { return .noOp }

        for command in commands where command.match(input) {
            guard command.isAvailable(in: editor) else {
                if command.id == .logoDebug { return .noOp }
                let message = editor.l10n["status.directory_buffer_readonly"]
                return editor.reportOperationResult(.failed(message, message: message))
            }
            let result = command.execute(with: input, on: editor)
            editor.applyOperationResult(result)
            return result
        }

        guard editor.buffer.allowsLogoExecution else {
            let message = editor.l10n["status.directory_buffer_readonly"]
            return editor.reportOperationResult(.failed(message, message: message))
        }

        return .noOp
    }

    /// Returns sorted list of available CommandBar completion names for Tab completion.
    func completionNames(for editor: Editor) -> [String] {
        let available = commands.filter { $0.isAvailable(in: editor) }
        return Array(Set(available.flatMap(\.completionNames))).sorted()
    }
}
