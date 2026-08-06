import Foundation

public enum CommandBarDispatchResult: Sendable, Equatable {
    case handled
    case noMatch
}

public struct CommandBarInput: Sendable, Equatable {
    public let raw: String
    public let text: String
    public let tokens: [String]
    public let firstToken: String?
    public let rest: String

    public init(_ raw: String) {
        self.raw = raw
        self.text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tokens = text.split(whereSeparator: \.isWhitespace).map(String.init)
        let parts = text.split(maxSplits: 1, whereSeparator: \.isWhitespace)
        self.firstToken = parts.first.map(String.init)
        self.rest = parts.count > 1 ? String(parts[1]) : ""
    }

    public var lowerFirstToken: String? {
        firstToken?.lowercased()
    }

    public var firstTokenIsAllUppercaseWord: Bool {
        guard let firstToken else { return false }
        return firstToken != firstToken.lowercased() && firstToken == firstToken.uppercased()
    }
}

/// Type-safe string enum defining all standard editor command identifiers.
public enum CommandID: String, CaseIterable, Sendable, Hashable {
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
    case selectLeft = "select.left"
    case selectRight = "select.right"
    case selectUp = "select.up"
    case selectDown = "select.down"
    case selectHome = "select.home"
    case selectEnd = "select.end"

    // Editing
    case editDeleteLine = "edit.delete_line"
    case editDelete = "edit.delete"
    case editMark = "edit.mark"
    case editCopy = "edit.copy"
    case editCut = "edit.cut"
    case editUncut = "edit.uncut"
    case editCancelSelection = "edit.cancel_selection"
    case editTab = "edit.tab"
    case editUndo = "edit.undo"
    case editJustify = "edit.justify"
    case editSpell = "edit.spell"
    case editEvalLogo = "edit.eval_logo"

    // Search & Cursor
    case searchWhereIs = "search.whereis"
    case searchNext = "search.next"
    case searchPrevious = "search.previous"
    case documentOpenLink = "document.open_link"
    case documentHeadingNext = "document.heading_next"
    case documentHeadingPrevious = "document.heading_previous"
    case documentOutline = "document.outline"
    case cursorGotoLine = "cursor.goto_line"
    case screenRefresh = "screen.refresh"
    case cursorPos = "cursor.pos"

    // Buffer Operations
    case bufferPrev = "buffer.prev"
    case bufferNext = "buffer.next"
    case bufferNew = "buffer.new"

    // File Operations
    case fileSave = "file.save"
    case fileWriteOut = "file.write_out"
    case fileInsert = "file.insert"
    case fileDirectory = "file.directory"
    case fileSaveExit = "file.save_exit"
    case fileExit = "file.exit"
    case fileEditConfig = "file.edit_config"
    case fileReloadConfig = "file.reload_config"

    // Macro & UI
    case macroLogo = "macro.logo"
    case logoReference = "logo.reference"
    case logoWorkspace = "logo.workspace"
    case menuShow = "menu.show"
    case helpShow = "help.show"
    case textMode = "mode.text"
    case canvasToggle = "mode.canvas.toggle"
    case tableToggle = "table.toggle"
    case borderStyle = "border.style"
    case diagramInsert = "diagram.insert"
    case diagramMenu = "diagram.menu"

    // Test & Custom
    case testCmd = "test.cmd"
    case customMacro = "custom.macro"
}

/// Unified protocol defining an editor command with metadata, keybindings, CommandBar aliases, and execution logic.
///
/// Implement this protocol to add custom commands, keybindings, or CommandBar macro utilities to `Editor`.
public protocol Command {
    /// Unique command identifier for menu binding and command dispatch.
    var id: CommandID { get }

    /// Human-readable localized title of the command.
    var name: String { get }

    /// Detailed description explaining the purpose of the command.
    var description: String { get }

    /// Default shortcut keybindings that trigger this command.
    var keys: [Key] { get }

    /// CommandBar command aliases (e.g. `["write", "w", "save"]`).
    var commandBarAliases: [String] { get }

    /// Auto-completion candidate names displayed when typing in the CommandBar.
    var completionNames: [String] { get }

    /// Evaluates whether the command can be executed in the current editor state.
    ///
    /// - Parameter editor: Active editor instance.
    /// - Returns: `true` if command is available for execution; otherwise `false`.
    func isAvailable(in editor: Editor) -> Bool

    /// Checks if typed CommandBar input matches this command.
    ///
    /// - Parameter input: Parsed CommandBar input token stream.
    /// - Returns: `true` if input matches command aliases.
    func match(_ input: CommandBarInput) -> Bool

    /// Executes command logic directly on the editor instance.
    ///
    /// - Parameter editor: Active editor instance.
    func execute(on editor: Editor)

    /// Executes command logic with CommandBar arguments, returning dispatch result status.
    ///
    /// - Parameters:
    ///   - input: Parsed CommandBar input containing arguments.
    ///   - editor: Active editor instance.
    /// - Returns: Result status (`.handled`, `.passThrough`, or `.invalidArguments`).
    func execute(with input: CommandBarInput, on editor: Editor) -> CommandBarDispatchResult
}

extension Command {
    public var keys: [Key] { [] }
    public var commandBarAliases: [String] { [] }
    public var completionNames: [String] { commandBarAliases }

    public func isAvailable(in editor: Editor) -> Bool { true }

    public func match(_ input: CommandBarInput) -> Bool {
        guard let first = input.lowerFirstToken else { return false }
        return commandBarAliases.contains(first)
    }

    public func execute(with input: CommandBarInput, on editor: Editor) -> CommandBarDispatchResult {
        execute(on: editor)
        return .handled
    }
}

/// Generic block-based command conforming to `Command` protocol.
public struct BlockCommand: Command {
    public let id: CommandID
    public let name: String
    public let description: String
    public let keys: [Key]
    public let commandBarAliases: [String]
    private let closure: (Editor) -> Void

    public init(
        id: CommandID,
        name: String,
        description: String,
        keys: [Key] = [],
        commandBarAliases: [String] = [],
        action: @escaping (Editor) -> Void
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.keys = keys
        self.commandBarAliases = commandBarAliases
        self.closure = action
    }

    public func execute(on editor: Editor) {
        closure(editor)
    }
}

/// Unified registry managing editor commands, keymaps, and CommandBar prompt dispatch.
public final class CommandRegistry {
    private var keyMap: [Key: any Command] = [:]
    private(set) public var commands: [any Command] = []

    public init() {}

    /// Registers a command conforming to `Command` protocol and maps its associated keybindings.
    public func register(_ command: any Command) {
        commands.append(command)
        for key in command.keys {
            keyMap[key] = command
        }
    }

    /// Binds a specific key to a command.
    public func bind(key: Key, command: any Command) {
        keyMap[key] = command
    }

    /// Unbinds a specific key mapping.
    public func unbind(key: Key) {
        keyMap.removeValue(forKey: key)
    }

    /// Dispatches a command by its type-safe `CommandID`.
    /// Returns `true` if a command was found and executed.
    public func dispatch(id: CommandID, editor: Editor) -> Bool {
        if let command = commands.first(where: { $0.id == id }) {
            command.execute(on: editor)
            return true
        }
        return false
    }

    /// Dispatches a command by raw ID string (for string/config compatibility).
    public func dispatch(idString: String, editor: Editor) -> Bool {
        guard let id = CommandID(rawValue: idString) else { return false }
        return dispatch(id: id, editor: editor)
    }

    /// Dispatches a key input to its registered command action.
    /// Returns `true` if a command was found and executed.
    public func dispatch(key: Key, editor: Editor) -> Bool {
        if editor.isTableModeActive && editor.customBoundKeys.contains(key) {
            return false
        }
        if let command = keyMap[key] {
            command.execute(on: editor)
            return true
        }
        return false
    }

    /// Dispatches raw string input from CommandBar to matching registered command.
    public func dispatch(_ rawInput: String, editor: Editor) -> CommandBarDispatchResult {
        let input = CommandBarInput(rawInput)
        guard !input.text.isEmpty else { return .handled }

        for command in commands where command.match(input) {
            guard command.isAvailable(in: editor) else {
                editor.setStatusMessage(editor.l10n["status.directory_buffer_readonly"])
                return .handled
            }
            return command.execute(with: input, on: editor)
        }

        guard editor.buffer.allowsLogoExecution else {
            editor.setStatusMessage(editor.l10n["status.directory_buffer_readonly"])
            return .handled
        }

        return .noMatch
    }

    /// Returns sorted list of available CommandBar completion names for Tab completion.
    public func completionNames(for editor: Editor) -> [String] {
        let available = commands.filter { $0.isAvailable(in: editor) }
        return Array(Set(available.flatMap(\.completionNames))).sorted()
    }
}
