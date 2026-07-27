import Foundation

/// Represents a modeless editor command with metadata, keybindings, and action closure.
public struct Command {
    public let id: String
    public let name: String
    public let description: String
    public let keys: [Key]
    public let action: (Editor) -> Void

    public init(id: String, name: String, description: String, keys: [Key], action: @escaping (Editor) -> Void) {
        self.id = id
        self.name = name
        self.description = description
        self.keys = keys
        self.action = action
    }
}

/// Registry managing editor commands, keymaps, and action dispatch.
public final class CommandRegistry {
    private var keyMap: [Key: Command] = [:]
    private(set) public var commands: [Command] = []

    public init() {}

    /// Registers a command and maps its associated keybindings.
    public func register(_ command: Command) {
        commands.append(command)
        for key in command.keys {
            keyMap[key] = command
        }
    }

    /// Binds a specific key to a command.
    public func bind(key: Key, command: Command) {
        keyMap[key] = command
    }

    /// Unbinds a specific key mapping.
    public func unbind(key: Key) {
        keyMap.removeValue(forKey: key)
    }

    /// Dispatches a command by its ID string.
    /// Returns `true` if a command was found and executed.
    public func dispatch(id: String, editor: Editor) -> Bool {
        if let command = commands.first(where: { $0.id == id }) {
            command.action(editor)
            return true
        }
        return false
    }

    /// Dispatches a key input to its registered command action.
    /// Returns `true` if a command was found and executed.
    public func dispatch(key: Key, editor: Editor) -> Bool {
        if let command = keyMap[key] {
            command.action(editor)
            return true
        }
        return false
    }
}
