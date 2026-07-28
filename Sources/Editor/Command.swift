import Foundation

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

    // Selection
    case selectLeft = "select.left"
    case selectRight = "select.right"
    case selectUp = "select.up"
    case selectDown = "select.down"

    // Editing
    case editDeleteLine = "edit.delete_line"
    case editDelete = "edit.delete"
    case editMark = "edit.mark"
    case editCut = "edit.cut"
    case editUncut = "edit.uncut"
    case editTab = "edit.tab"
    case editUndo = "edit.undo"
    case editJustify = "edit.justify"
    case editSpell = "edit.spell"

    // Search & Cursor
    case searchWhereIs = "search.whereis"
    case cursorGotoLine = "cursor.goto_line"
    case screenRefresh = "screen.refresh"
    case cursorPos = "cursor.pos"

    // Buffer Operations
    case bufferPrev = "buffer.prev"
    case bufferNext = "buffer.next"
    case bufferNew = "buffer.new"

    // File Operations
    case fileSave = "file.save"
    case fileInsert = "file.insert"
    case fileSaveExit = "file.save_exit"
    case fileExit = "file.exit"

    // Macro & UI
    case macroLogo = "macro.logo"
    case menuShow = "menu.show"
    case helpShow = "help.show"
    case tableToggle = "table.toggle"

    // Test & Custom
    case testCmd = "test.cmd"
    case customMacro = "custom.macro"
}

/// Protocol defining a modeless editor command with metadata, keybindings, and execution action.
public protocol Command {
    var id: CommandID { get }
    var name: String { get }
    var description: String { get }
    var keys: [Key] { get }

    func execute(on editor: Editor)
}

/// Generic block-based command conforming to `Command` protocol.
public struct BlockCommand: Command {
    public let id: CommandID
    public let name: String
    public let description: String
    public let keys: [Key]
    private let closure: (Editor) -> Void

    public init(id: CommandID, name: String, description: String, keys: [Key], action: @escaping (Editor) -> Void) {
        self.id = id
        self.name = name
        self.description = description
        self.keys = keys
        self.closure = action
    }

    public func execute(on editor: Editor) {
        closure(editor)
    }
}

/// Registry managing editor commands, keymaps, and action dispatch.
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
        if let command = keyMap[key] {
            command.execute(on: editor)
            return true
        }
        return false
    }
}
