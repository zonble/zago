import Foundation

public struct CommandIDCommandBarCommand: CommandBarCommand {
    public let name: String
    public let help: String
    private let names: Set<String>
    private let commandID: CommandID

    public init(names: Set<String>, commandID: CommandID, help: String = "") {
        self.names = names
        self.commandID = commandID
        self.name = names.sorted().first ?? commandID.rawValue
        self.help = help
    }

    public func match(_ input: CommandBarInput) -> Bool {
        guard input.rest.isEmpty, let first = input.lowerFirstToken else {
            return false
        }
        return names.contains(first)
    }

    public func execute(_ input: CommandBarInput, editor: Editor) -> CommandBarDispatchResult {
        _ = editor.commandRegistry.dispatch(id: commandID, editor: editor)
        return .handled
    }
}
