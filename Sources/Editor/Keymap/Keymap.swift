import Foundation
import Config

/// Encapsulates a two-way mapping between input Keys and executable CommandIDs.
struct Keymap: Sendable {
    private(set) var keyToCommand: [Key: CommandID] = [:]
    private(set) var commandToKeys: [CommandID: [Key]] = [:]

    init() {}

    /// Resolves a Key event to its bound CommandID.
    func resolve(key: Key) -> CommandID? {
        keyToCommand[key]
    }

    /// Returns the primary/canonical shortcut Key for a given CommandID.
    func shortcut(for commandID: CommandID) -> Key? {
        commandToKeys[commandID]?.first
    }

    /// Returns all Keys bound to a given CommandID in priority order.
    func keys(for commandID: CommandID) -> [Key] {
        commandToKeys[commandID] ?? []
    }

    /// Binds a single key to a command, placing it at the front of the command's shortcut list.
    mutating func bind(key: Key, to commandID: CommandID) {
        keyToCommand[key] = commandID
        var list = commandToKeys[commandID, default: []].filter { $0 != key }
        list.insert(key, at: 0)
        commandToKeys[commandID] = list
    }

    /// Registers a command with multiple keys in preference order.
    mutating func register(_ commandID: CommandID, _ keys: Key...) {
        register(commandID, keys: keys)
    }

    /// Registers a command with an array of keys in preference order.
    mutating func register(_ commandID: CommandID, keys: [Key]) {
        for key in keys {
            keyToCommand[key] = commandID
        }
        commandToKeys[commandID] = keys
    }

    /// Unbinds a key from any command it was mapped to.
    mutating func unbind(key: Key) {
        guard let commandID = keyToCommand.removeValue(forKey: key) else { return }
        let remaining = (commandToKeys[commandID] ?? []).filter { $0 != key }
        if remaining.isEmpty {
            commandToKeys.removeValue(forKey: commandID)
        } else {
            commandToKeys[commandID] = remaining
        }
    }

    /// Clears all keybindings in this keymap.
    mutating func removeAll() {
        keyToCommand.removeAll()
        commandToKeys.removeAll()
    }
}
